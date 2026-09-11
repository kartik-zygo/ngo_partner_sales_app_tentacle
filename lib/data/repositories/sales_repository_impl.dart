import '../../domain/entities/client_case.dart';
import '../../domain/entities/collaboration_opportunity.dart';
import '../../domain/entities/cross_app_notification_event.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/follow_up_task.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/quotation_request.dart';
import '../../domain/entities/service_order.dart';
import '../../domain/entities/support_call_request.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/user_action_payload.dart';
import '../../domain/repositories/sales_repository.dart';
import '../datasources/remote_data_source.dart';

class SalesRepositoryImpl implements SalesRepository {
  SalesRepositoryImpl(this._remote);

  final RemoteDataSource _remote;

  @override
  Future<SalesDashboardSummary> getDashboardSummary(String userId) {
    return _remote.getSalesDashboard();
  }

  // LEADS

  @override
  Future<List<Lead>> getLeads({String? assignedToUserId}) {
    return _remote.getLeads(assignedTo: assignedToUserId, limit: 50);
  }

  @override
  Future<Lead> upsertLead(Lead lead) async {
    if (lead.id.startsWith('lead_') || lead.id.isEmpty) {
      // New lead — create via API
      return _remote.createLead(
        contactName: lead.contactName,
        contactEmail: lead.email.isEmpty ? null : lead.email,
        contactPhone: lead.phone.isEmpty ? null : lead.phone,
        source: lead.source.name,
        serviceId: lead.serviceId,
        notes: lead.notes.isNotEmpty ? lead.notes.first.message : null,
      );
    }
    // Existing lead update not supported directly; return as-is
    return lead;
  }

  @override
  Future<void> deleteLead(String leadId) => _remote.deleteLead(leadId);

  @override
  Future<Lead> updateLeadStatus(String leadId, LeadStatus status) {
    return _remote.updateLeadStatus(leadId, status.name);
  }

  @override
  Future<Lead> addLeadNote(String leadId, String note) {
    return _remote.addLeadNote(leadId, note);
  }

  // TASKS

  @override
  Future<List<FollowUpTask>> getTasks({String? userId}) {
    return _remote.getTasks(limit: 50);
  }

  @override
  Future<FollowUpTask> addTask(FollowUpTask task) {
    return _remote.createTask(
      leadId: task.leadId.isEmpty ? null : task.leadId,
      assignedTo: task.leadId,
      description: task.title,
      dueAt: task.dueDate,
    );
  }

  @override
  Future<FollowUpTask> completeTask(String taskId) {
    return _remote.completeTask(taskId);
  }

  @override
  Future<FollowUpTask> rescheduleTask(String taskId, DateTime newDate) {
    return _remote.rescheduleTask(taskId, newDate);
  }

  // CASES

  @override
  Future<List<ClientCase>> getClientCases({String? createdByUserId}) {
    return _remote.getCases(userId: createdByUserId, limit: 50);
  }

  @override
  Future<ClientCase> createClientCase(ClientCase clientCase) {
    return _remote.createCase(
      userId: clientCase.createdByUserId,
      serviceId: clientCase.serviceId,
      notes: clientCase.resubmitReason,
    );
  }

  @override
  Future<ClientCase> syncCaseStatus({
    required String caseId,
    required UserCaseStatus targetStatus,
    required String updatedBy,
    String? reason,
  }) {
    return _remote.updateCaseStatus(
      caseId,
      targetStatus.label,
      rejectionReason: reason,
    );
  }

  @override
  Future<ClientCase> requestCaseDocuments({
    required String caseId,
    required List<String> documents,
    required String reason,
    DateTime? dueDate,
    required String requestedBy,
  }) {
    return _remote.createDocumentRequest(
      caseId: caseId,
      requiredDocuments: documents,
      message: reason,
      dueDate: dueDate,
    );
  }

  @override
  Future<ClientCase> markDocumentsResubmitted({
    required String caseId,
    required String userId,
  }) {
    return _remote.updateCaseStatus(caseId, UserCaseStatus.underReview.label);
  }

  // SUPPORT TICKETS

  @override
  Future<List<SupportTicket>> getSupportTickets({String? assignedToSalesId}) {
    return _remote.getTickets(assignedTo: assignedToSalesId, limit: 50);
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

  // SUPPORT CALLS

  @override
  Future<List<SupportCallRequest>> getSupportCalls() {
    return _remote.getSupportCalls(limit: 50);
  }

  @override
  Future<SupportCallRequest> updateSupportCallStatus({
    required String callId,
    required SupportCallStatus status,
    required String actorId,
    required String actorName,
  }) {
    return _remote.updateCallStatus(callId, status.apiValue);
  }

  @override
  Future<Map<String, dynamic>> getAgoraToken(String callId) {
    return _remote.getAgoraToken(callId);
  }

  // COLLABORATIONS

  @override
  Future<List<CollaborationOpportunity>> getCollaborationOpportunities() {
    return _remote.getCollaborations(limit: 50);
  }

  // CROSS-APP — not applicable with real API; return stubs

  @override
  Future<Lead> createLeadFromUserAction(UserActionPayload action) async {
    return _remote.createLead(
      contactName: action.userName,
      contactEmail: action.userEmail,
      contactPhone: action.userPhone,
      source: 'userApp',
      serviceId: action.serviceId,
      notes: action.message,
    );
  }

  @override
  Future<CrossAppNotificationEvent> pushUserNotificationEvent(
    CrossAppNotificationEvent event,
  ) async {
    return event;
  }

  @override
  Future<List<CrossAppNotificationEvent>> getQueuedUserNotificationEvents() async {
    return const [];
  }

  // ORDERS

  @override
  Future<List<ServiceOrder>> getOrders({
    String? status,
    String? fulfillmentStatus,
    String? serviceId,
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

  // QUOTATIONS

  @override
  Future<List<QuotationRequest>> getQuotations({
    String? assignedTo,
    String? status,
    String? search,
    String? serviceId,
    String? userId,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 50,
  }) {
    return _remote.getQuotations(
      page: page,
      limit: limit,
      assignedTo: assignedTo,
      status: status,
      search: search,
      serviceId: serviceId,
      userId: userId,
      from: from,
      to: to,
    );
  }

  @override
  Future<QuotationRequest> getQuotationById(String id) =>
      _remote.getQuotationById(id);

  @override
  Future<List<SalesRepOption>> getSalesReps() =>
      _remote.getQuotationSalesReps();

  @override
  Future<QuotationRequest> assignQuotation(
    String id, {
    required String assignedTo,
    String? note,
  }) {
    return _remote.assignQuotation(id, assignedTo: assignedTo, note: note);
  }

  @override
  Future<QuotationRequest> updateQuotationStatus(
    String id, {
    required LeadStatus status,
    String? note,
  }) {
    // The endpoint speaks the lead pipeline, and LeadStatus.name already
    // matches those wire values.
    return _remote.updateQuotationStatus(id, status: status.name, note: note);
  }

  @override
  Future<QuotationRequest> addQuotationNote(String id, String content) =>
      _remote.addQuotationNote(id, content);
}
