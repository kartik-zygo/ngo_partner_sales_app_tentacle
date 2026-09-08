import '../../domain/entities/approval_request.dart';
import '../../domain/entities/collaboration_opportunity.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/revenue_record.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/service_order.dart';
import '../../domain/entities/service_package.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._remote);

  final RemoteDataSource _remote;

  @override
  Future<AdminDashboardSummary> getDashboardSummary() {
    return _remote.getAdminDashboard();
  }

  @override
  Future<IntegrationDashboardMetrics> getIntegrationDashboardMetrics() {
    return _remote.getIntegrationMetrics();
  }

  // LEADS

  @override
  Future<List<Lead>> getAllLeads() {
    return _remote.getLeads(limit: 100);
  }

  @override
  Future<Lead> assignLead({
    required String leadId,
    required String teamMemberId,
    required String assignedBy,
  }) {
    return _remote.assignLead(leadId, teamMemberId);
  }

  @override
  Future<Lead> reassignLead({
    required String leadId,
    required String teamMemberId,
    required String assignedBy,
  }) {
    return _remote.reassignLead(leadId, teamMemberId);
  }

  // TEAM

  @override
  Future<List<TeamMember>> getTeamMembers() {
    return _remote.getTeamMembers(limit: 100);
  }

  @override
  Future<TeamMember> upsertTeamMember(TeamMember member) async {
    final parts = member.name.trim().split(' ');
    final first = parts.first;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    if (member.id.isEmpty || member.id.startsWith('tm_')) {
      return _remote.createTeamMember(
        email: member.email,
        firstName: first,
        lastName: last,
        phone: null,
      );
    }
    return _remote.updateTeamMember(member.id, firstName: first, lastName: last);
  }

  @override
  Future<TeamMember> setTeamMemberActive(String id, bool isActive) async {
    final current = await _remote.getTeamMemberById(id);
    if (current.isActive == isActive) return current;
    return _remote.toggleTeamMemberActive(id);
  }

  // SERVICES

  @override
  Future<List<ServicePackage>> getServicePackages({
    String? category,
    String? search,
    bool includeInactive = false,
  }) {
    return _remote.getServices(
      limit: 100,
      category: category,
      search: search,
      includeInactive: includeInactive,
    );
  }

  @override
  Future<List<String>> getServiceCategories() {
    return _remote.getServiceCategories();
  }

  @override
  Future<ServicePackage> upsertServicePackage(ServicePackage servicePackage) async {
    if (servicePackage.id.isEmpty || servicePackage.id.startsWith('svc_')) {
      return _remote.createService(
        name: servicePackage.name,
        description: servicePackage.description,
        category: servicePackage.category,
        basePrice: servicePackage.price > 0 ? servicePackage.price : null,
      );
    }
    return _remote.updateService(
      servicePackage.id,
      name: servicePackage.name,
      description: servicePackage.description,
      category: servicePackage.category,
      basePrice: servicePackage.price > 0 ? servicePackage.price : null,
    );
  }

  @override
  Future<ServicePackage> toggleServicePackage(String id, bool isActive) {
    return _remote.toggleService(id);
  }

  @override
  Future<void> deleteServicePackage(String id) {
    return _remote.deleteService(id);
  }

  // ORDERS

  @override
  Future<List<ServiceOrder>> getOrders({
    String? status,
    String? fulfillmentStatus,
    String? serviceId,
    String? userId,
    String? search,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) {
    return _remote.getOrders(
      page: page,
      limit: limit,
      status: status,
      fulfillmentStatus: fulfillmentStatus,
      serviceId: serviceId,
      userId: userId,
      search: search,
      from: from,
      to: to,
    );
  }

  @override
  Future<ServiceOrder> getOrderById(String id) {
    return _remote.getOrderById(id);
  }

  @override
  Future<ServiceOrder> updateOrderFulfillment(
    String id, {
    required String fulfillmentStatus,
    String? adminNotes,
  }) {
    return _remote.updateOrderFulfillment(
      id,
      fulfillmentStatus: fulfillmentStatus,
      adminNotes: adminNotes,
    );
  }

  @override
  Future<List<PaymentRequest>> getPaymentRequests({
    String? status,
    String? paymentMethod,
    String? orderId,
    String? userId,
    String? serviceId,
    String? search,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) {
    return _remote.getPaymentRequests(
      page: page,
      limit: limit,
      status: status,
      paymentMethod: paymentMethod,
      orderId: orderId,
      userId: userId,
      serviceId: serviceId,
      search: search,
      from: from,
      to: to,
    );
  }

  @override
  Future<PaymentRequest> getPaymentRequestById(String id) {
    return _remote.getPaymentRequestById(id);
  }

  @override
  Future<PaymentRequest> decidePaymentRequest(
    String id, {
    required String decision,
    String? reviewNotes,
  }) {
    return _remote.decidePaymentRequest(
      id,
      decision: decision,
      reviewNotes: reviewNotes,
    );
  }

  // APPROVALS

  @override
  Future<List<ApprovalRequest>> getApprovalRequests() {
    return _remote.getApprovals(status: 'pending', limit: 50);
  }

  @override
  Future<ApprovalRequest> decideApproval(String id, ApprovalStatus status) {
    return _remote.decideApproval(id, status.name);
  }

  // REVENUE REPORTS

  @override
  Future<List<RevenueRecord>> getRevenueRecords(DateTime from, DateTime to) {
    return _remote.getRevenueRecords(from: from, to: to, limit: 100);
  }

  @override
  Future<String> exportReport(DateTime from, DateTime to) {
    return _remote.exportReport(
      reportType: 'revenue',
      filters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      },
    );
  }

  @override
  Future<List<String>> getReportExportHistory() {
    return _remote.getReportExportHistory(limit: 50);
  }

  // ASSIGNMENT HISTORY — derived from lead activity; return empty for now

  @override
  Future<List<String>> getAssignmentHistory() async {
    return const [];
  }

  // SUPPORT TICKETS

  @override
  Future<List<SupportTicket>> getSupportTickets() {
    return _remote.getTickets(limit: 100);
  }

  @override
  Future<SupportTicket> getTicketById(String id) {
    return _remote.getTicketById(id);
  }

  @override
  Future<SupportTicket> updateSupportTicket({
    required String ticketId,
    required SupportTicketStatus status,
    required String actor,
    String? message,
  }) {
    return _remote.updateTicketStatus(ticketId, status.apiValue, message: message);
  }

  @override
  Future<SupportTicket> addTicketUpdate(
    String ticketId,
    String message, {
    bool isInternal = false,
  }) {
    return _remote.addTicketUpdate(ticketId, message, isInternal: isInternal);
  }

  @override
  Future<SupportTicket> escalateTicket(String ticketId, String reason) {
    return _remote.escalateTicket(ticketId, reason);
  }

  @override
  Future<SupportTicket> assignTicket(String ticketId, String assignedTo) {
    return _remote.assignTicket(ticketId, assignedTo);
  }

  // COLLABORATIONS

  @override
  Future<List<CollaborationOpportunity>> getCollaborationOpportunities() {
    return _remote.getCollaborations(limit: 50);
  }
}
