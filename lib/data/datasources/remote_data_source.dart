import 'package:dio/dio.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/case_document_request.dart';
import '../../domain/entities/client_case.dart';
import '../../domain/entities/collaboration_opportunity.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/follow_up_task.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/quotation_request.dart';
import '../../domain/entities/revenue_record.dart';
import '../../domain/entities/service_order.dart';
import '../../domain/entities/service_package.dart';
import '../../domain/entities/support_call_request.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/services/secure_storage_service.dart';

class RemoteDataSource {
  RemoteDataSource(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> loginRaw(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _data(res) as Map<String, dynamic>;
  }

  Future<AppUser> getMe() async {
    final res = await _dio.get('/auth/me');
    final body = _data(res) as Map<String, dynamic>;
    return _parseUser(body);
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    await _dio.patch('/auth/me/profile', data: {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
  }

  /// `DELETE /auth/me`. The server re-checks [password], removes the account
  /// and revokes every session. Returns its confirmation message.
  Future<String> deleteAccount({required String password, String? reason}) async {
    try {
      final res = await _dio.delete('/auth/me', data: {
        'password': password,
        'confirm': 'DELETE',
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
      final body = _data(res);
      return body is Map ? (body['message'] ?? '').toString() : '';
    } on DioException catch (e) {
      throw _accountDeletionError(e);
    }
  }

  AccountDeletionException _accountDeletionError(DioException e) {
    final data = e.response?.data;
    final serverMessage = data is Map && data['error'] is Map
        ? (data['error'] as Map)['message'] as String?
        : null;
    switch (e.response?.statusCode) {
      case null:
        return const AccountDeletionException(
          'Could not reach the server. Check your connection and try again.',
        );
      case 401:
        return const AccountDeletionException(
          'Incorrect password. Please check it and try again.',
        );
      case 409:
        return AccountDeletionException(
          serverMessage ??
              'You are the only active admin. Make another team member an '
                  'admin before deleting this account.',
        );
      default:
        return AccountDeletionException(
          serverMessage ?? 'Could not delete your account. Please try again.',
        );
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {
      // Best-effort; always clear local tokens
    }
    await _storage.clearTokens();
  }

  // ---------------------------------------------------------------------------
  // DASHBOARD
  // ---------------------------------------------------------------------------

  Future<SalesDashboardSummary> getSalesDashboard() async {
    final res = await _dio.get('/dashboard/sales');
    final body = _data(res) as Map<String, dynamic>;
    final byStatus = _mapList(body['leadsByStatus']);
    return SalesDashboardSummary(
      assignedLeads: _int(body['leadsTotal']),
      todayFollowUps: _int(body['tasksPending']),
      monthlyConversions: _countFor(byStatus, 'won'),
      pendingDocuments: _int(body['openTickets']),
      recentActivity: byStatus
          .map((e) => '${e['status']}: ${_int(e['count'])}')
          .toList(),
    );
  }

  Future<AdminDashboardSummary> getAdminDashboard() async {
    final res = await _dio.get('/dashboard/admin');
    final body = _data(res) as Map<String, dynamic>;
    final teamPerf = <String, int>{
      for (final s in _mapList(body['casesByStatus']))
        '${s['status']}': _int(s['count']),
    };
    return AdminDashboardSummary(
      totalTeamRevenue: _double(body['totalRevenue']),
      pipelineValue: _int(body['totalLeads']) * 5000.0,
      pendingApprovals: 0,
      teamPerformance: teamPerf,
      weeklyRevenue: const [],
      monthlyRevenue: const [],
    );
  }

  Future<IntegrationDashboardMetrics> getIntegrationMetrics() async {
    final res = await _dio.get('/dashboard/integration-metrics');
    final body = _data(res) as Map<String, dynamic>;
    return IntegrationDashboardMetrics(
      newUserAppLeadsToday: _countFor(_mapList(body['inboxByStatus']), 'pending'),
      unassignedUserAppLeads: _countFor(_mapList(body['outboxByStatus']), 'pending'),
      casesStuckInResubmitRequired: 0,
      pendingCollaborationRequests: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // LEADS
  // ---------------------------------------------------------------------------

  Future<List<Lead>> getLeads({
    int page = 1,
    int limit = 50,
    String? status,
    String? source,
    String? assignedTo,
    String? serviceId,
    String sortOrder = 'desc',
    String sortBy = 'created_at',
  }) async {
    final res = await _dio.get('/leads', queryParameters: {
      'page': page,
      'limit': limit,
      'sortOrder': sortOrder,
      // The server now only accepts created_at / updated_at / status here.
      'sortBy': sortBy,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (serviceId != null) 'serviceId': serviceId,
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseLead).toList();
  }

  Future<Lead> getLeadById(String id) async {
    final res = await _dio.get('/leads/$id');
    return _parseLead(_data(res) as Map<String, dynamic>);
  }

  Future<Lead> createLead({
    required String contactName,
    String? contactEmail,
    String? contactPhone,
    String source = 'manual',
    String? serviceId,
    String? notes,
  }) async {
    final res = await _dio.post('/leads', data: {
      'contactName': contactName,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      'source': source,
      if (serviceId != null) 'serviceId': serviceId,
      if (notes != null) 'notes': notes,
    });
    return _parseLead(_data(res) as Map<String, dynamic>);
  }

  Future<Lead> updateLeadStatus(String id, String status, {String? reason}) async {
    final res = await _dio.patch('/leads/$id/status', data: {
      'status': status,
      if (reason != null) 'reason': reason,
    });
    return _parseLead(_data(res) as Map<String, dynamic>);
  }

  Future<Lead> addLeadNote(String id, String content) async {
    final res = await _dio.post('/leads/$id/notes', data: {'content': content});
    return _parseLead(_data(res) as Map<String, dynamic>);
  }

  Future<Lead> assignLead(String id, String assignedTo) async {
    final res = await _dio.post('/leads/$id/assign', data: {'assignedTo': assignedTo});
    return _parseLead(_data(res) as Map<String, dynamic>);
  }

  Future<Lead> reassignLead(String id, String assignedTo) async {
    final res = await _dio.post('/leads/$id/reassign', data: {'assignedTo': assignedTo});
    return _parseLead(_data(res) as Map<String, dynamic>);
  }

  Future<void> deleteLead(String id) async {
    await _dio.delete('/leads/$id');
  }

  // ---------------------------------------------------------------------------
  // QUOTATIONS
  // ---------------------------------------------------------------------------

  Future<List<QuotationRequest>> getQuotations({
    int page = 1,
    int limit = 50,
    String? assignedTo,
    String? status,
    String? search,
    String? serviceId,
    String? userId,
    DateTime? from,
    DateTime? to,
    String sortOrder = 'desc',
  }) async {
    final res = await _dio.get('/quotations', queryParameters: {
      'page': page,
      'limit': limit,
      'sortOrder': sortOrder,
      // `me` and `unassigned` are accepted alongside a rep's UUID.
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (serviceId != null) 'serviceId': serviceId,
      if (userId != null) 'userId': userId,
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseQuotation).toList();
  }

  Future<QuotationRequest> getQuotationById(String id) async {
    final res = await _dio.get('/quotations/$id');
    return _parseQuotation(_data(res) as Map<String, dynamic>);
  }

  Future<List<SalesRepOption>> getQuotationSalesReps() async {
    final res = await _dio.get('/quotations/sales-reps');
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseSalesRep).toList();
  }

  /// ADMIN only — SALES callers get a 403.
  Future<QuotationRequest> assignQuotation(
    String id, {
    required String assignedTo,
    String? note,
  }) async {
    try {
      final res = await _dio.post('/quotations/$id/assign', data: {
        'assignedTo': assignedTo,
        if (note != null && note.isNotEmpty) 'note': note,
      });
      return _parseQuotation(_data(res) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _quotationError(e);
    }
  }

  /// [status] takes the *lead* pipeline vocabulary — contacted, qualified,
  /// proposalSent, won, lost. `note` is required on lost.
  Future<QuotationRequest> updateQuotationStatus(
    String id, {
    required String status,
    String? note,
  }) async {
    try {
      final res = await _dio.patch('/quotations/$id/status', data: {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      });
      return _parseQuotation(_data(res) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _quotationError(e);
    }
  }

  Future<QuotationRequest> addQuotationNote(String id, String content) async {
    final res = await _dio.post('/quotations/$id/notes', data: {
      'content': content,
    });
    return _parseQuotation(_data(res) as Map<String, dynamic>);
  }

  /// Maps the documented failures onto typed exceptions so the bloc can tell
  /// "refetch and retry" apart from "you are not allowed to do this".
  Exception _quotationError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final error = (data is Map && data['error'] is Map)
        ? Map<String, dynamic>.from(data['error'] as Map)
        : const <String, dynamic>{};
    final message = error['message'] as String? ?? e.message ?? 'Request failed';
    final code = error['code'] as String?;

    if (status == 409) return QuotationConflictException(message);
    if (status == 403) return QuotationForbiddenException(message);
    if (code == 'INVALID_STATUS_TRANSITION') {
      return InvalidStatusTransitionException(message);
    }
    return Exception(message);
  }

  // ---------------------------------------------------------------------------
  // TASKS
  // ---------------------------------------------------------------------------

  Future<List<FollowUpTask>> getTasks({int page = 1, int limit = 50}) async {
    final res = await _dio.get('/tasks', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseTask).toList();
  }

  Future<FollowUpTask> createTask({
    String? leadId,
    required String assignedTo,
    required String description,
    required DateTime dueAt,
  }) async {
    final res = await _dio.post('/tasks', data: {
      if (leadId != null) 'leadId': leadId,
      'assignedTo': assignedTo,
      'description': description,
      'dueAt': dueAt.toIso8601String(),
    });
    return _parseTask(_data(res) as Map<String, dynamic>);
  }

  Future<FollowUpTask> completeTask(String id) async {
    final res = await _dio.patch('/tasks/$id/complete');
    return _parseTask(_data(res) as Map<String, dynamic>);
  }

  Future<FollowUpTask> rescheduleTask(String id, DateTime dueAt) async {
    final res = await _dio.patch('/tasks/$id/reschedule', data: {
      'dueAt': dueAt.toIso8601String(),
    });
    return _parseTask(_data(res) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // CASES
  // ---------------------------------------------------------------------------

  Future<List<ClientCase>> getCases({
    int page = 1,
    int limit = 20,
    String? status,
    String? userId,
  }) async {
    final res = await _dio.get('/cases', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (userId != null) 'userId': userId,
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseCase).toList();
  }

  Future<ClientCase> getCaseById(String id) async {
    final res = await _dio.get('/cases/$id');
    return _parseCase(_data(res) as Map<String, dynamic>);
  }

  Future<ClientCase> createCase({
    required String userId,
    String? leadId,
    String? serviceId,
    String? notes,
  }) async {
    final res = await _dio.post('/cases', data: {
      'userId': userId,
      if (leadId != null) 'leadId': leadId,
      if (serviceId != null) 'serviceId': serviceId,
      if (notes != null) 'notes': notes,
    });
    return _parseCase(_data(res) as Map<String, dynamic>);
  }

  Future<ClientCase> updateCaseStatus(
    String id,
    String status, {
    String? rejectionReason,
  }) async {
    final res = await _dio.patch('/cases/$id/status', data: {
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    });
    return _parseCase(_data(res) as Map<String, dynamic>);
  }

  Future<ClientCase> createDocumentRequest({
    required String caseId,
    required List<String> requiredDocuments,
    String? message,
    DateTime? dueDate,
    int? round,
  }) async {
    await _dio.post('/cases/$caseId/document-requests', data: {
      'requiredDocuments': requiredDocuments,
      if (message != null) 'message': message,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      if (round != null) 'round': round,
    });
    // Re-fetch case to return the updated entity
    final caseRes = await _dio.get('/cases/$caseId');
    return _parseCase(_data(caseRes) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // SUPPORT TICKETS
  // ---------------------------------------------------------------------------

  Future<List<SupportTicket>> getTickets({
    int page = 1,
    int limit = 20,
    String? status,
    String? assignedTo,
  }) async {
    final res = await _dio.get('/tickets', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (assignedTo != null) 'assignedTo': assignedTo,
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseTicket).toList();
  }

  Future<SupportTicket> getTicketById(String id) async {
    final res = await _dio.get('/tickets/$id');
    return _parseTicket(_data(res) as Map<String, dynamic>);
  }

  Future<SupportTicket> updateTicketStatus(
    String id,
    String status, {
    String? message,
    bool isInternal = false,
  }) async {
    final res = await _dio.patch('/tickets/$id/status', data: {
      'status': status,
      if (message != null) 'message': message,
      'isInternal': isInternal,
    });
    return _parseTicket(_data(res) as Map<String, dynamic>);
  }

  Future<SupportTicket> addTicketUpdate(
    String id,
    String message, {
    bool isInternal = false,
  }) async {
    final res = await _dio.post('/tickets/$id/updates', data: {
      'message': message,
      'isInternal': isInternal,
    });
    return _parseTicket(_data(res) as Map<String, dynamic>);
  }

  Future<SupportTicket> escalateTicket(String id, String reason) async {
    final res = await _dio.post('/tickets/$id/escalate', data: {'reason': reason});
    return _parseTicket(_data(res) as Map<String, dynamic>);
  }

  Future<SupportTicket> assignTicket(String id, String assignedTo) async {
    final res = await _dio.post('/tickets/$id/assign', data: {'assignedTo': assignedTo});
    return _parseTicket(_data(res) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // SUPPORT CALLS (Agora)
  // ---------------------------------------------------------------------------

  Future<List<SupportCallRequest>> getSupportCalls({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get('/support-calls', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseCall).toList();
  }

  Future<SupportCallRequest> getSupportCallById(String id) async {
    final res = await _dio.get('/support-calls/$id');
    return _parseCall(_data(res) as Map<String, dynamic>);
  }

  Future<SupportCallRequest> updateCallStatus(String id, String status) async {
    final res = await _dio.patch('/support-calls/$id/status', data: {'status': status});
    return _parseCall(_data(res) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getAgoraToken(String callId) async {
    final res = await _dio.get('/support-calls/$callId/agora-token');
    return _data(res) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // COLLABORATIONS
  // ---------------------------------------------------------------------------

  Future<List<CollaborationOpportunity>> getCollaborations({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get('/collaborations', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseCollaboration).toList();
  }

  Future<CollaborationOpportunity> updateCollaborationStatus(
    String id,
    String status, {
    String? reviewNotes,
  }) async {
    final res = await _dio.patch('/collaborations/$id/status', data: {
      'status': status,
      if (reviewNotes != null) 'reviewNotes': reviewNotes,
    });
    return _parseCollaboration(_data(res) as Map<String, dynamic>);
  }

  Future<Lead> convertCollaborationToLead(
    String id, {
    String? contactName,
    String? contactEmail,
    String? notes,
  }) async {
    final res = await _dio.post('/collaborations/$id/convert-to-lead', data: {
      if (contactName != null) 'contactName': contactName,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (notes != null) 'notes': notes,
    });
    return _parseLead(_data(res) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // APPROVALS
  // ---------------------------------------------------------------------------

  Future<List<ApprovalRequest>> getApprovals({
    int page = 1,
    int limit = 20,
    String status = 'pending',
  }) async {
    final res = await _dio.get('/approvals', queryParameters: {
      'page': page,
      'limit': limit,
      'status': status,
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseApproval).toList();
  }

  Future<ApprovalRequest> createApproval({
    required String entityType,
    required String entityId,
    required String reason,
  }) async {
    final res = await _dio.post('/approvals', data: {
      'entityType': entityType,
      'entityId': entityId,
      'reason': reason,
    });
    return _parseApproval(_data(res) as Map<String, dynamic>);
  }

  Future<ApprovalRequest> decideApproval(
    String id,
    String status, {
    String? decisionNotes,
  }) async {
    final res = await _dio.patch('/approvals/$id/decision', data: {
      'status': status,
      if (decisionNotes != null) 'decisionNotes': decisionNotes,
    });
    return _parseApproval(_data(res) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS
  // ---------------------------------------------------------------------------

  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get('/notifications', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseNotification).toList();
  }

  Future<AppNotification> markNotificationRead(String id) async {
    final res = await _dio.patch('/notifications/$id/read');
    return _parseNotification(_data(res) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // ADMIN — TEAM
  // ---------------------------------------------------------------------------

  Future<List<TeamMember>> getTeamMembers({int page = 1, int limit = 20}) async {
    final res = await _dio.get('/admin/team', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseTeamMember).toList();
  }

  Future<TeamMember> getTeamMemberById(String id) async {
    final res = await _dio.get('/admin/team/$id');
    return _parseTeamMember(_data(res) as Map<String, dynamic>);
  }

  Future<TeamMember> createTeamMember({
    required String email,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final res = await _dio.post('/admin/team', data: {
      'email': email,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
    });
    return _parseTeamMember(_data(res) as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.patch('/auth/me/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<TeamMember> updateTeamMember(
    String id, {
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    final res = await _dio.patch('/admin/team/$id', data: {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    return _parseTeamMember(_data(res) as Map<String, dynamic>);
  }

  Future<TeamMember> toggleTeamMemberActive(String id) async {
    final res = await _dio.patch('/admin/team/$id/toggle');
    return _parseTeamMember(_data(res) as Map<String, dynamic>);
  }

  Future<void> deleteTeamMember(String id) async {
    await _dio.delete('/admin/team/$id');
  }

  // ---------------------------------------------------------------------------
  // ADMIN — SERVICES
  // ---------------------------------------------------------------------------

  Future<List<ServicePackage>> getServices({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    bool includeInactive = false,
  }) async {
    final res = await _dio.get('/services', queryParameters: {
      'page': page,
      'limit': limit,
      if (category != null) 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
      if (includeInactive) 'includeInactive': 'true',
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseService).toList();
  }

  Future<List<String>> getServiceCategories() async {
    final res = await _dio.get('/services/categories');
    final list = _data(res) as List;
    return list.map((e) => e.toString()).toList();
  }

  Future<ServicePackage> getServiceById(String id) async {
    final res = await _dio.get('/services/$id');
    return _parseService(_data(res) as Map<String, dynamic>);
  }

  Future<ServicePackage> createService({
    required String name,
    String? description,
    String? category,
    double? basePrice,
  }) async {
    final res = await _dio.post('/services', data: {
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (basePrice != null) 'basePrice': basePrice,
    });
    return _parseService(_data(res) as Map<String, dynamic>);
  }

  Future<ServicePackage> updateService(
    String id, {
    String? name,
    String? description,
    String? category,
    double? basePrice,
  }) async {
    final res = await _dio.patch('/services/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (basePrice != null) 'basePrice': basePrice,
    });
    return _parseService(_data(res) as Map<String, dynamic>);
  }

  Future<ServicePackage> toggleService(String id) async {
    final res = await _dio.patch('/services/$id/toggle');
    return _parseService(_data(res) as Map<String, dynamic>);
  }

  Future<void> deleteService(String id) async {
    await _dio.delete('/services/$id');
  }

  // ---------------------------------------------------------------------------
  // ORDERS
  // ---------------------------------------------------------------------------

  Future<List<ServiceOrder>> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
    String? fulfillmentStatus,
    String? serviceId,
    String? userId,
    String? search,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _dio.get('/orders', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (fulfillmentStatus != null) 'fulfillmentStatus': fulfillmentStatus,
      if (serviceId != null) 'serviceId': serviceId,
      if (userId != null) 'userId': userId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseOrder).toList();
  }

  Future<ServiceOrder> getOrderById(String id) async {
    final res = await _dio.get('/orders/$id');
    return _parseOrder(_data(res) as Map<String, dynamic>);
  }

  Future<ServiceOrder> updateOrderFulfillment(
    String id, {
    required String fulfillmentStatus,
    String? adminNotes,
  }) async {
    final res = await _dio.patch('/orders/$id/fulfillment', data: {
      'fulfillmentStatus': fulfillmentStatus,
      if (adminNotes != null) 'adminNotes': adminNotes,
    });
    return _parseOrder(_data(res) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // MANUAL PAYMENT APPROVALS
  // ---------------------------------------------------------------------------

  Future<List<PaymentRequest>> getPaymentRequests({
    int page = 1,
    int limit = 20,
    String? status,
    String? paymentMethod,
    String? orderId,
    String? userId,
    String? serviceId,
    String? search,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _dio.get('/orders/payment-requests', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (orderId != null) 'orderId': orderId,
      if (userId != null) 'userId': userId,
      if (serviceId != null) 'serviceId': serviceId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parsePaymentRequest).toList();
  }

  Future<PaymentRequest> getPaymentRequestById(String id) async {
    final res = await _dio.get('/orders/payment-requests/$id');
    return _parsePaymentRequest(_data(res) as Map<String, dynamic>);
  }

  Future<PaymentRequest> decidePaymentRequest(
    String id, {
    required String decision,
    String? reviewNotes,
  }) async {
    final res = await _dio.patch(
      '/orders/payment-requests/$id/decision',
      data: {
        'decision': decision,
        if (reviewNotes != null && reviewNotes.isNotEmpty)
          'reviewNotes': reviewNotes,
      },
    );
    return _parsePaymentRequest(_data(res) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // ADMIN — REVENUE REPORTS
  // ---------------------------------------------------------------------------

  Future<List<RevenueRecord>> getRevenueRecords({
    int page = 1,
    int limit = 20,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _dio.get('/reports/revenue', queryParameters: {
      'page': page,
      'limit': limit,
      if (from != null) 'from': from.toIso8601String().split('T').first,
      if (to != null) 'to': to.toIso8601String().split('T').first,
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>().map(_parseRevenueRecord).toList();
  }

  Future<String> exportReport({
    required String reportType,
    Map<String, dynamic>? filters,
  }) async {
    final res = await _dio.post('/reports/export', data: {
      'reportType': reportType,
      if (filters != null) 'filters': filters,
    });
    final body = _data(res) as Map<String, dynamic>;
    return (body['fileUrl'] ?? body['file_url'] ?? body['id'] ?? '').toString();
  }

  Future<List<String>> getReportExportHistory({int page = 1, int limit = 20}) async {
    final res = await _dio.get('/reports/export-history', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final list = _data(res) as List;
    return list
        .cast<Map<String, dynamic>>()
        // Export history is served as raw snake_case rows.
        .map((e) => (e['fileUrl'] ?? e['file_url'] ?? e['id'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // ADMIN — AUDIT LOGS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAuditLogs({
    int page = 1,
    int limit = 20,
    String? entityType,
    String? entityId,
    String? actorId,
  }) async {
    final res = await _dio.get('/audit/logs', queryParameters: {
      'page': page,
      'limit': limit,
      if (entityType != null) 'entityType': entityType,
      if (entityId != null) 'entityId': entityId,
      if (actorId != null) 'actorId': actorId,
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ---------------------------------------------------------------------------
  // INTEGRATION EVENTS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getUserEvents({
    int page = 1,
    int limit = 20,
    String? userId,
  }) async {
    final res = await _dio.get('/integration/user-events', queryParameters: {
      'page': page,
      'limit': limit,
      if (userId != null) 'userId': userId,
    });
    final list = _data(res) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ---------------------------------------------------------------------------
  // ENTITY PARSERS
  // ---------------------------------------------------------------------------

  AppUser _parseUser(Map<String, dynamic> body) {
    final user = body['user'] as Map<String, dynamic>? ?? body;
    final profile = body['profile'] as Map<String, dynamic>? ?? const {};
    final roles = (user['roles'] as List? ?? ['SALES']).cast<String>();
    final isAdmin = roles.contains('ADMIN');

    final firstName = profile['firstName'] as String? ?? '';
    final lastName = profile['lastName'] as String? ?? '';
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();

    return AppUser(
      id: user['id'] as String,
      name: fullName.isEmpty ? (user['email'] as String? ?? '') : fullName,
      email: user['email'] as String? ?? '',
      role: isAdmin ? AppRole.admin : AppRole.sales,
      phone: profile['phone'] as String?,
      isActive: user['isActive'] as bool? ?? true,
    );
  }

  Lead _parseLead(Map<String, dynamic> json) {
    // `notes` is the lead's free-text field (a String) on the list and detail
    // payloads, but a list of note rows on older responses. Casting the String
    // to a List crashed every screen that loads leads.
    final rawNotes = json['notes'];
    final notes = rawNotes is List
        ? _mapList(rawNotes)
            .map((n) => LeadNote(
                  message: (n['content'] ?? n['message'] ?? '').toString(),
                  createdAt: _parseDate(n['createdAt'] ?? n['created_at']) ??
                      DateTime.now(),
                ))
            .toList()
        : rawNotes is String && rawNotes.trim().isNotEmpty
            ? [
                LeadNote(
                  message: rawNotes.trim(),
                  createdAt: _parseDate(json['updatedAt']) ??
                      _parseDate(json['createdAt']) ??
                      DateTime.now(),
                ),
              ]
            : <LeadNote>[];

    final assignee = _parseAssignee(json['assignedTo']);

    return Lead(
      id: json['id'] as String,
      organization: json['contactName'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      phone: json['contactPhone'] as String? ?? '',
      email: json['contactEmail'] as String? ?? '',
      status: _parseLeadStatus(json['status'] as String? ?? 'newLead'),
      source: _parseLeadSource(json['source'] as String? ?? 'manual'),
      assignedToSalesId: assignee.id,
      assignedToName: assignee.name,
      assignedToEmail: assignee.email,
      assignedAt: _parseDate(json['assignedAt']),
      quotationRequestId: json['quotationRequestId'] as String?,
      quotationReference: json['quotationReference'] as String?,
      userId: json['userId'] as String?,
      serviceId: json['serviceId'] as String?,
      serviceName: json['serviceName'] as String?,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      notes: notes,
      activity: (json['activity'] as List? ?? [])
          .map((e) => e is Map
              ? (e['message'] ?? e['description'] ?? '').toString()
              : e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      timeline: const [],
      userAppContext: const [],
    );
  }

  /// `assignedTo` is an object (id, name, email) on the newer lead and
  /// quotation payloads, but a bare id on older ones and on write responses.
  ({String? id, String? name, String? email}) _parseAssignee(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return (
        id: map['id'] as String?,
        name: _displayName(map),
        email: map['email'] as String?,
      );
    }
    if (raw is String && raw.isNotEmpty) {
      return (id: raw, name: null, email: null);
    }
    return (id: null, name: null, email: null);
  }

  /// Prefers an explicit `name`, else assembles it from the profile, else
  /// falls back to the email so a row is never blank.
  String? _displayName(Map<String, dynamic> map) {
    final name = map['name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();

    final profile = map['profile'] as Map<String, dynamic>? ?? const {};
    final first = (map['firstName'] ?? profile['firstName']) as String? ?? '';
    final last = (map['lastName'] ?? profile['lastName']) as String? ?? '';
    final full = [first.trim(), last.trim()].where((p) => p.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;

    return map['email'] as String?;
  }

  QuotationRequest _parseQuotation(Map<String, dynamic> json) {
    final assignee = _parseAssignee(json['assignedTo']);
    final leadStatusRaw = json['leadStatus'] as String?;

    return QuotationRequest(
      id: json['id'] as String,
      reference: json['reference'] as String? ?? '',
      userId: json['userId'] as String?,
      serviceId: json['serviceId'] as String?,
      serviceName: json['serviceName'] as String? ?? '',
      serviceCategory: json['serviceCategory'] as String?,
      leadId: json['leadId'] as String?,
      leadStatus:
          leadStatusRaw == null ? null : _parseLeadStatus(leadStatusRaw),
      contactName: json['contactName'] as String? ?? '',
      contactEmail: json['contactEmail'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      organizationName: json['organizationName'] as String?,
      message: json['message'] as String?,
      status: QuotationStatusX.fromApi(json['status'] as String?),
      statusLabel: json['statusLabel'] as String? ?? '',
      assignedTo: assignee.id,
      assignedToName: assignee.name ?? json['salesRepName'] as String?,
      assignedToEmail: assignee.email,
      assignedAt: _parseDate(json['assignedAt']),
      closedAt: _parseDate(json['closedAt']),
      source: json['source'] as String? ?? 'userApp',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      notes: (json['notes'] as List? ?? [])
          .whereType<Map>()
          .map((n) => QuotationNote(
                content: (n['content'] ?? n['message'] ?? '').toString(),
                createdAt: _parseDate(n['createdAt'] ?? n['created_at']) ??
                    DateTime.now(),
                author: n['authorName'] as String? ??
                    n['createdByName'] as String? ??
                    (n['author'] is Map
                        ? _displayName(
                            Map<String, dynamic>.from(n['author'] as Map))
                        : null),
              ))
          .toList(),
      activity: (json['activity'] as List? ?? [])
          .whereType<Map>()
          .map((a) => QuotationActivity(
                // Activity rows come straight from `lead_activity`, so they
                // carry `activity_type` / `created_at` rather than a message.
                message: (a['message'] ??
                        a['description'] ??
                        a['event'] ??
                        _activityLabel(a['activityType'] ?? a['activity_type']) ??
                        '')
                    .toString(),
                createdAt: _parseDate(a['createdAt'] ?? a['created_at']) ??
                    DateTime.now(),
                performedBy: a['performedBy'] as String? ??
                    a['performedByName'] as String?,
              ))
          .where((a) => a.message.isNotEmpty)
          .toList(),
    );
  }

  SalesRepOption _parseSalesRep(Map<String, dynamic> json) {
    return SalesRepOption(
      id: json['id'] as String,
      name: _displayName(json) ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      openRequests: _int(json['openRequests']),
    );
  }

  FollowUpTask _parseTask(Map<String, dynamic> json) {
    return FollowUpTask(
      id: json['id'] as String,
      leadId: json['leadId'] as String? ?? '',
      title: json['description'] as String? ?? '',
      dueDate: _parseDate(json['dueAt']) ?? DateTime.now(),
      status: _parseTaskStatus(json['status'] as String? ?? 'pending'),
    );
  }

  ClientCase _parseCase(Map<String, dynamic> json) {
    final docRequests = (json['documentRequests'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((d) => CaseDocumentRequest(
              round: _int(d['round'], 1),
              requestedAt: _parseDate(d['createdAt']) ?? DateTime.now(),
              requestedBy: '',
              reason: d['message'] as String? ?? '',
              documents: (d['requiredDocuments'] as List? ?? []).cast<String>(),
              dueDate: _parseDate(d['dueDate']),
            ))
        .toList();

    final lead = json['lead'] as Map<String, dynamic>?;
    final orgName = json['organizationName'] as String?
        ?? lead?['contactName'] as String?
        ?? 'Case ${(json['id'] as String? ?? '').substring(0, 8)}';

    return ClientCase(
      id: json['id'] as String,
      organizationName: orgName,
      selectedServiceIds: json['serviceId'] != null ? [json['serviceId'] as String] : const [],
      documentChecklist: const {},
      submittedAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      createdByUserId: json['userId'] as String? ?? '',
      userId: json['userId'] as String?,
      serviceId: json['serviceId'] as String?,
      status: _parseCaseStatus(json['status'] as String? ?? 'submitted'),
      rejectionReason: json['rejectionReason'] as String?,
      documentRequests: docRequests,
      statusHistory: const [],
    );
  }

  SupportTicket _parseTicket(Map<String, dynamic> json) {
    final updates = (json['updates'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((u) => SupportTicketUpdate(
              message: u['message'] as String? ?? '',
              by: u['authorId'] as String? ?? u['by'] as String? ?? '',
              createdAt: _parseDate(u['createdAt']) ?? DateTime.now(),
              status: u['status'] != null
                  ? _parseTicketStatus(u['status'] as String)
                  : null,
              isInternal: u['isInternal'] as bool? ?? false,
            ))
        .toList();

    return SupportTicket(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ??
          (json['user'] as Map<String, dynamic>?)?['email'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      status: _parseTicketStatus(json['status'] as String? ?? 'open'),
      assignedToSalesId: _parseAssignee(json['assignedTo']).id,
      // The tickets API names this field `escalated`.
      isEscalated: (json['isEscalated'] ?? json['escalated']) == true,
      updates: updates,
    );
  }

  SupportCallRequest _parseCall(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final profile = user?['profile'] as Map<String, dynamic>?;
    final firstName = profile?['firstName'] as String? ?? '';
    final lastName = profile?['lastName'] as String? ?? '';
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    final displayName = fullName.isNotEmpty
        ? fullName
        : user?['name'] as String?
            ?? user?['email'] as String?
            ?? json['userName'] as String?
            ?? '';
    return SupportCallRequest(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      userName: displayName,
      userEmail: user?['email'] as String? ?? '',
      userPhone: profile?['phone'] as String? ?? '',
      organization: json['organizationName'] as String? ?? '',
      targetTeam: json['targetTeam'] as String? ?? 'sales',
      type: (json['callType'] as String?) == 'video'
          ? SupportCallType.video
          : SupportCallType.voice,
      status: _parseCallStatus(json['status'] as String? ?? 'ringing'),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      salesAgentId: json['acceptedBy'] as String?,
    );
  }

  CollaborationOpportunity _parseCollaboration(Map<String, dynamic> json) {
    return CollaborationOpportunity(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      ngoName: json['organizationName'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      contactEmail: json['contactEmail'] as String? ?? '',
      // The collaborations API sends `proposal` / `convertedLeadId`.
      message: (json['message'] ?? json['proposal'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      isConvertedToLead:
          json['status'] == 'converted' || json['convertedLeadId'] != null,
      linkedLeadId: (json['leadId'] ?? json['convertedLeadId']) as String?,
    );
  }

  ApprovalRequest _parseApproval(Map<String, dynamic> json) {
    final entityType = json['entityType'] as String? ?? '';
    final entityId = json['entityId'] as String? ?? '';
    return ApprovalRequest(
      id: json['id'] as String,
      title: '$entityType: $entityId',
      reason: json['reason'] as String? ?? '',
      requestedBy: json['requestedBy'] as String? ??
          (json['requester'] as Map<String, dynamic>?)?['email'] as String? ?? '',
      amount: 0,
      status: _parseApprovalStatus(json['status'] as String? ?? 'pending'),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  AppNotification _parseNotification(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: (json['body'] ?? json['message'] ?? '').toString(),
      // The notifications endpoint returns raw snake_case rows.
      createdAt:
          _parseDate(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
      targetRole: AppRole.sales,
      isRead: (json['isRead'] ?? json['is_read']) == true,
    );
  }

  TeamMember _parseTeamMember(Map<String, dynamic> json) {
    final firstName = json['firstName'] as String? ?? '';
    final lastName = json['lastName'] as String? ?? '';
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    return TeamMember(
      id: json['id'] as String,
      name: fullName.isEmpty ? (json['email'] as String? ?? '') : fullName,
      email: json['email'] as String? ?? '',
      region: '',
      activeLeads: 0,
      wonDeals: 0,
      isActive: json['isActive'] as bool? ?? true,
      tempPassword: json['tempPassword'] as String?,
    );
  }

  ServicePackage _parseService(Map<String, dynamic> json) {
    return ServicePackage(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: _double(json['basePrice'] ?? json['base_price']),
      category: json['category'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  ServiceOrder _parseOrder(Map<String, dynamic> json) {
    final requests = (json['paymentRequests'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_parsePaymentRequest)
        .toList();

    final latestStatus = json['latestPaymentRequestStatus'] as String?;

    return ServiceOrder(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      serviceId: json['serviceId'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      amount: _double(json['amount']),
      currency: json['currency'] as String? ?? 'INR',
      status: OrderPaymentStatus.fromApi(json['status'] as String?),
      fulfillmentStatus: _parseFulfillmentStatus(json['fulfillmentStatus'] as String?),
      adminNotes: json['adminNotes'] as String?,
      fulfillmentUpdatedBy: json['fulfillmentUpdatedBy'] as String?,
      fulfillmentUpdatedAt: _parseDate(json['fulfillmentUpdatedAt']),
      customerName: json['customerName'] as String? ?? '',
      customerEmail: json['customerEmail'] as String? ?? '',
      customerPhone: json['customerPhone'] as String?,
      notes: json['notes'] as String?,
      paidAt: _parseDate(json['paidAt']),
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      latestPaymentRequestId: json['latestPaymentRequestId'] as String?,
      latestPaymentRequestStatus: latestStatus == null
          ? null
          : PaymentRequestStatus.fromApi(latestStatus),
      paymentRequests: requests,
    );
  }

  PaymentRequest _parsePaymentRequest(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      paymentMethod: PaymentMethod.fromApi(json['paymentMethod'] as String?),
      referenceNumber: json['referenceNumber'] as String? ?? '',
      amountClaimed: _double(json['amountClaimed']),
      orderAmount:
          json['orderAmount'] == null ? null : _double(json['orderAmount']),
      amountMatchesOrder: json['amountMatchesOrder'] as bool? ?? true,
      paidAt: _parseDate(json['paidAt']),
      payerName: json['payerName'] as String?,
      payerNote: json['payerNote'] as String?,
      proofUrl: json['proofUrl'] as String?,
      status: PaymentRequestStatus.fromApi(json['status'] as String?),
      orderStatus: json['orderStatus'] as String?,
      serviceName: json['serviceName'] as String?,
      customerName: json['customerName'] as String?,
      customerEmail: json['customerEmail'] as String?,
      customerPhone: json['customerPhone'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      reviewerEmail: json['reviewerEmail'] as String?,
      reviewNotes: json['reviewNotes'] as String?,
      reviewedAt: _parseDate(json['reviewedAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  RevenueRecord _parseRevenueRecord(Map<String, dynamic> json) {
    return RevenueRecord(
      id: json['id'] as String,
      // `/reports/revenue` returns raw rows: snake_case, DECIMAL as a string
      // ("10000.00"), which crashed the reports screen on a num cast.
      date: _parseDate(
            json['recordedAt'] ?? json['revenueDate'] ?? json['revenue_date'],
          ) ??
          DateTime.now(),
      amount: _double(json['amount']),
      source: (json['revenueType'] ?? json['revenue_type'] ?? '').toString(),
    );
  }

  // ---------------------------------------------------------------------------
  // ENUM PARSERS
  // ---------------------------------------------------------------------------

  LeadStatus _parseLeadStatus(String s) {
    switch (s) {
      case 'contacted':
        return LeadStatus.contacted;
      case 'qualified':
        return LeadStatus.qualified;
      case 'proposalSent':
        return LeadStatus.proposalSent;
      case 'won':
        return LeadStatus.won;
      case 'lost':
        return LeadStatus.lost;
      default:
        return LeadStatus.newLead;
    }
  }

  LeadSource _parseLeadSource(String s) {
    switch (s) {
      case 'userApp':
        return LeadSource.userApp;
      case 'campaign':
        return LeadSource.campaign;
      case 'collaboration':
        return LeadSource.collaboration;
      default:
        return LeadSource.manual;
    }
  }

  TaskStatus _parseTaskStatus(String s) {
    switch (s) {
      case 'completed':
        return TaskStatus.completed;
      case 'rescheduled':
        return TaskStatus.rescheduled;
      default:
        return TaskStatus.pending;
    }
  }

  UserCaseStatus _parseCaseStatus(String s) {
    switch (s) {
      case 'filingInProgress':
        return UserCaseStatus.filingInProgress;
      case 'underReview':
        return UserCaseStatus.underReview;
      case 'resubmitRequired':
        return UserCaseStatus.resubmitRequired;
      case 'approved':
        return UserCaseStatus.approved;
      case 'rejected':
        return UserCaseStatus.rejected;
      default:
        return UserCaseStatus.submitted;
    }
  }

  SupportTicketStatus _parseTicketStatus(String s) {
    switch (s) {
      case 'inProgress':
        return SupportTicketStatus.inProgress;
      case 'waitingForUser':
        return SupportTicketStatus.waitingForUser;
      case 'resolved':
        return SupportTicketStatus.resolved;
      case 'closed':
        return SupportTicketStatus.closed;
      default:
        return SupportTicketStatus.open;
    }
  }

  SupportCallStatus _parseCallStatus(String s) {
    switch (s) {
      case 'accepted':
        return SupportCallStatus.accepted;
      case 'rejected':
        return SupportCallStatus.rejected;
      case 'ended':
        return SupportCallStatus.ended;
      default:
        return SupportCallStatus.ringing;
    }
  }

  ApprovalStatus _parseApprovalStatus(String s) {
    switch (s) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.pending;
    }
  }

  FulfillmentStatus _parseFulfillmentStatus(String? s) {
    switch (s) {
      case 'processing':
        return FulfillmentStatus.processing;
      case 'completed':
        return FulfillmentStatus.completed;
      case 'refund_initiated':
        return FulfillmentStatus.refundInitiated;
      case 'refunded':
        return FulfillmentStatus.refunded;
      default:
        return FulfillmentStatus.none;
    }
  }

  // ---------------------------------------------------------------------------
  // COMMUNITY HUB
  // ---------------------------------------------------------------------------

  Future<List<CommunityPost>> getCommunityPosts({
    int page = 1,
    int limit = 30,
    String sort = 'newest',
    String? tag,
    String? search,
  }) async {
    final res = await _dio.get('/community/posts', queryParameters: {
      'page': page,
      'limit': limit,
      'sort': sort,
      if (tag != null && tag.isNotEmpty) 'tag': tag,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (_data(res) as List)
        .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityPost> getCommunityPost(String id) async {
    final res = await _dio.get('/community/posts/$id');
    return CommunityPost.fromJson(_data(res) as Map<String, dynamic>);
  }

  Future<CommunityAnswer> addCommunityAnswer(String postId, String body) async {
    final res =
        await _dio.post('/community/posts/$postId/answers', data: {'body': body});
    return CommunityAnswer.fromJson(_data(res) as Map<String, dynamic>);
  }

  Future<CommunityVoteResult> voteCommunityPost(String postId, int value) async {
    final res =
        await _dio.post('/community/posts/$postId/vote', data: {'value': value});
    return CommunityVoteResult.fromJson(_data(res) as Map<String, dynamic>);
  }

  Future<CommunityVoteResult> voteCommunityAnswer(String answerId, int value) async {
    final res = await _dio
        .post('/community/answers/$answerId/vote', data: {'value': value});
    return CommunityVoteResult.fromJson(_data(res) as Map<String, dynamic>);
  }

  Future<void> deleteCommunityPost(String postId) async {
    await _dio.delete('/community/posts/$postId');
  }

  Future<void> deleteCommunityAnswer(String answerId) async {
    await _dio.delete('/community/answers/$answerId');
  }

  Future<CommunityPost> setCommunityPostClosed(String postId, bool closed) async {
    final res = await _dio
        .patch('/community/posts/$postId/close', data: {'closed': closed});
    return CommunityPost.fromJson(_data(res) as Map<String, dynamic>);
  }

  Future<List<CommunityTag>> getCommunityTags() async {
    final res = await _dio.get('/community/tags');
    return (_data(res) as List)
        .map((e) => CommunityTag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  dynamic _data(Response<dynamic> res) {
    final body = res.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  /// Postgres returns COUNT (bigint) and DECIMAL columns as JSON strings, so a
  /// numeric field can arrive as `3`, `"3"` or `"10000.00"` depending on the
  /// query. These accept all three instead of throwing on a hard cast.
  int _int(dynamic value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    if (value is String) return num.tryParse(value)?.toInt() ?? fallback;
    return fallback;
  }

  double _double(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  List<Map<String, dynamic>> _mapList(dynamic value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : const [];

  /// `count` for [status] in a `[{status, count}]` group-by result.
  int _countFor(List<Map<String, dynamic>> rows, String status) => _int(
        rows.firstWhere(
          (r) => r['status'] == status,
          orElse: () => const {},
        )['count'],
      );

  /// `status_changed` / `statusChanged` → `Status changed`.
  String? _activityLabel(dynamic type) {
    if (type == null) return null;
    final words = type
        .toString()
        .replaceAllMapped(RegExp(r'(?<=[a-z])([A-Z])'), (m) => ' ${m[1]}')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .trim()
        .toLowerCase();
    if (words.isEmpty) return null;
    return words[0].toUpperCase() + words.substring(1);
  }
}
