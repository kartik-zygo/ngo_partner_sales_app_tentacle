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
import '../../domain/entities/revenue_record.dart';
import '../../domain/entities/service_order.dart';
import '../../domain/entities/service_package.dart';
import '../../domain/entities/support_call_request.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/team_member.dart';
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
    final byStatus = (body['leadsByStatus'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final wonCount = byStatus
        .firstWhere((e) => e['status'] == 'won', orElse: () => {'count': 0})['count'] as int? ?? 0;
    return SalesDashboardSummary(
      assignedLeads: body['leadsTotal'] as int? ?? 0,
      todayFollowUps: body['tasksPending'] as int? ?? 0,
      monthlyConversions: wonCount,
      pendingDocuments: body['openTickets'] as int? ?? 0,
      recentActivity: byStatus
          .map((e) => '${e['status']}: ${e['count']}')
          .toList(),
    );
  }

  Future<AdminDashboardSummary> getAdminDashboard() async {
    final res = await _dio.get('/dashboard/admin');
    final body = _data(res) as Map<String, dynamic>;
    final casesByStatus = (body['casesByStatus'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final teamPerf = <String, int>{
      for (final s in casesByStatus)
        (s['status'] as String): int.tryParse(s['count'].toString()) ?? 0,
    };
    return AdminDashboardSummary(
      totalTeamRevenue: (body['totalRevenue'] as num?)?.toDouble() ?? 0,
      pipelineValue: (body['totalLeads'] as int? ?? 0) * 5000.0,
      pendingApprovals: 0,
      teamPerformance: teamPerf,
      weeklyRevenue: const [],
      monthlyRevenue: const [],
    );
  }

  Future<IntegrationDashboardMetrics> getIntegrationMetrics() async {
    final res = await _dio.get('/dashboard/integration-metrics');
    final body = _data(res) as Map<String, dynamic>;
    final inbox = (body['inboxByStatus'] as List? ?? []).cast<Map<String, dynamic>>();
    final outbox = (body['outboxByStatus'] as List? ?? []).cast<Map<String, dynamic>>();
    final pendingInbox = inbox
        .firstWhere((e) => e['status'] == 'pending', orElse: () => {'count': 0})['count'] as int? ?? 0;
    final pendingOutbox = outbox
        .firstWhere((e) => e['status'] == 'pending', orElse: () => {'count': 0})['count'] as int? ?? 0;
    return IntegrationDashboardMetrics(
      newUserAppLeadsToday: pendingInbox,
      unassignedUserAppLeads: pendingOutbox,
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
    String sortOrder = 'desc',
  }) async {
    final res = await _dio.get('/leads', queryParameters: {
      'page': page,
      'limit': limit,
      'sortOrder': sortOrder,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (assignedTo != null) 'assignedTo': assignedTo,
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
    return list.cast<String>();
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
    return body['fileUrl'] as String? ?? body['id'] as String? ?? '';
  }

  Future<List<String>> getReportExportHistory({int page = 1, int limit = 20}) async {
    final res = await _dio.get('/reports/export-history', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final list = _data(res) as List;
    return list
        .cast<Map<String, dynamic>>()
        .map((e) => e['fileUrl'] as String? ?? e['id'] as String? ?? '')
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
    final notes = (json['notes'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((n) => LeadNote(
              message: n['content'] as String? ?? '',
              createdAt: _parseDate(n['createdAt']) ?? DateTime.now(),
            ))
        .toList();

    return Lead(
      id: json['id'] as String,
      organization: json['contactName'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      phone: json['contactPhone'] as String? ?? '',
      email: json['contactEmail'] as String? ?? '',
      status: _parseLeadStatus(json['status'] as String? ?? 'newLead'),
      source: _parseLeadSource(json['source'] as String? ?? 'manual'),
      assignedToSalesId: json['assignedTo'] as String?,
      userId: json['userId'] as String?,
      serviceId: json['serviceId'] as String?,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      notes: notes,
      activity: const [],
      timeline: const [],
      userAppContext: const [],
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
              round: d['round'] as int? ?? 1,
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
      assignedToSalesId: json['assignedTo'] as String?,
      isEscalated: json['isEscalated'] as bool? ?? false,
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
      message: json['message'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      isConvertedToLead: json['status'] == 'converted',
      linkedLeadId: json['leadId'] as String?,
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
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      targetRole: AppRole.sales,
      isRead: json['isRead'] as bool? ?? false,
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
      price: (json['basePrice'] as num?)?.toDouble() ?? 0,
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
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
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
      amountClaimed: (json['amountClaimed'] as num?)?.toDouble() ?? 0,
      orderAmount: (json['orderAmount'] as num?)?.toDouble(),
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
      date: _parseDate(json['recordedAt']) ?? DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      source: json['revenueType'] as String? ?? '',
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
    try {
      return DateTime.parse(value as String);
    } catch (_) {
      return null;
    }
  }
}
