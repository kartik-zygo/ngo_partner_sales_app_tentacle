import '../entities/client_case.dart';
import '../entities/collaboration_opportunity.dart';
import '../entities/cross_app_notification_event.dart';
import '../entities/dashboard_summary.dart';
import '../entities/follow_up_task.dart';
import '../entities/lead.dart';
import '../entities/quotation_request.dart';
import '../entities/support_call_request.dart';
import '../entities/support_ticket.dart';
import '../entities/user_action_payload.dart';
import '../repositories/sales_repository.dart';

class GetSalesDashboardUseCase {
  GetSalesDashboardUseCase(this._repository);
  final SalesRepository _repository;

  Future<SalesDashboardSummary> call(String userId) {
    return _repository.getDashboardSummary(userId);
  }
}

class GetLeadsUseCase {
  GetLeadsUseCase(this._repository);
  final SalesRepository _repository;

  Future<List<Lead>> call({String? assignedToUserId}) {
    return _repository.getLeads(assignedToUserId: assignedToUserId);
  }
}

class UpsertLeadUseCase {
  UpsertLeadUseCase(this._repository);
  final SalesRepository _repository;

  Future<Lead> call(Lead lead) => _repository.upsertLead(lead);
}

class DeleteLeadUseCase {
  DeleteLeadUseCase(this._repository);
  final SalesRepository _repository;

  Future<void> call(String leadId) => _repository.deleteLead(leadId);
}

class UpdateLeadStatusUseCase {
  UpdateLeadStatusUseCase(this._repository);
  final SalesRepository _repository;

  Future<Lead> call(String leadId, LeadStatus status) {
    return _repository.updateLeadStatus(leadId, status);
  }
}

class AddLeadNoteUseCase {
  AddLeadNoteUseCase(this._repository);
  final SalesRepository _repository;

  Future<Lead> call(String leadId, String note) {
    return _repository.addLeadNote(leadId, note);
  }
}

class GetTasksUseCase {
  GetTasksUseCase(this._repository);
  final SalesRepository _repository;

  Future<List<FollowUpTask>> call({String? userId}) {
    return _repository.getTasks(userId: userId);
  }
}

class AddTaskUseCase {
  AddTaskUseCase(this._repository);
  final SalesRepository _repository;

  Future<FollowUpTask> call(FollowUpTask task) => _repository.addTask(task);
}

class CompleteTaskUseCase {
  CompleteTaskUseCase(this._repository);
  final SalesRepository _repository;

  Future<FollowUpTask> call(String taskId) => _repository.completeTask(taskId);
}

class RescheduleTaskUseCase {
  RescheduleTaskUseCase(this._repository);
  final SalesRepository _repository;

  Future<FollowUpTask> call(String taskId, DateTime newDate) {
    return _repository.rescheduleTask(taskId, newDate);
  }
}

class GetClientCasesUseCase {
  GetClientCasesUseCase(this._repository);
  final SalesRepository _repository;

  Future<List<ClientCase>> call({String? createdByUserId}) {
    return _repository.getClientCases(createdByUserId: createdByUserId);
  }
}

class CreateClientCaseUseCase {
  CreateClientCaseUseCase(this._repository);
  final SalesRepository _repository;

  Future<ClientCase> call(ClientCase clientCase) {
    return _repository.createClientCase(clientCase);
  }
}

class CreateLeadFromUserActionUseCase {
  CreateLeadFromUserActionUseCase(this._repository);
  final SalesRepository _repository;

  Future<Lead> call(UserActionPayload action) {
    return _repository.createLeadFromUserAction(action);
  }
}

class SyncCaseStatusUseCase {
  SyncCaseStatusUseCase(this._repository);
  final SalesRepository _repository;

  Future<ClientCase> call({
    required String caseId,
    required UserCaseStatus targetStatus,
    required String updatedBy,
    String? reason,
  }) {
    return _repository.syncCaseStatus(
      caseId: caseId,
      targetStatus: targetStatus,
      updatedBy: updatedBy,
      reason: reason,
    );
  }
}

class RequestCaseDocumentsUseCase {
  RequestCaseDocumentsUseCase(this._repository);
  final SalesRepository _repository;

  Future<ClientCase> call({
    required String caseId,
    required List<String> documents,
    required String reason,
    DateTime? dueDate,
    required String requestedBy,
  }) {
    return _repository.requestCaseDocuments(
      caseId: caseId,
      documents: documents,
      reason: reason,
      dueDate: dueDate,
      requestedBy: requestedBy,
    );
  }
}

class MarkDocumentsResubmittedUseCase {
  MarkDocumentsResubmittedUseCase(this._repository);
  final SalesRepository _repository;

  Future<ClientCase> call({required String caseId, required String userId}) {
    return _repository.markDocumentsResubmitted(caseId: caseId, userId: userId);
  }
}

class PushUserNotificationEventUseCase {
  PushUserNotificationEventUseCase(this._repository);
  final SalesRepository _repository;

  Future<CrossAppNotificationEvent> call(CrossAppNotificationEvent event) {
    return _repository.pushUserNotificationEvent(event);
  }
}

class GetQueuedUserNotificationEventsUseCase {
  GetQueuedUserNotificationEventsUseCase(this._repository);
  final SalesRepository _repository;

  Future<List<CrossAppNotificationEvent>> call() {
    return _repository.getQueuedUserNotificationEvents();
  }
}

class GetSupportTicketsUseCase {
  GetSupportTicketsUseCase(this._repository);
  final SalesRepository _repository;

  Future<List<SupportTicket>> call({String? assignedToSalesId}) {
    return _repository.getSupportTickets(assignedToSalesId: assignedToSalesId);
  }
}

class GetTicketByIdUseCase {
  GetTicketByIdUseCase(this._repository);
  final SalesRepository _repository;

  Future<SupportTicket> call(String id) => _repository.getTicketById(id);
}

class UpdateSupportTicketUseCase {
  UpdateSupportTicketUseCase(this._repository);
  final SalesRepository _repository;

  Future<SupportTicket> call({
    required String ticketId,
    required SupportTicketStatus status,
    required String actor,
    String? message,
  }) {
    return _repository.updateSupportTicket(
      ticketId: ticketId,
      status: status,
      actor: actor,
      message: message,
    );
  }
}

class AddTicketUpdateUseCase {
  AddTicketUpdateUseCase(this._repository);
  final SalesRepository _repository;

  Future<SupportTicket> call(
    String ticketId,
    String message, {
    bool isInternal = false,
  }) {
    return _repository.addTicketUpdate(ticketId, message, isInternal: isInternal);
  }
}

class EscalateTicketUseCase {
  EscalateTicketUseCase(this._repository);
  final SalesRepository _repository;

  Future<SupportTicket> call(String ticketId, String reason) {
    return _repository.escalateTicket(ticketId, reason);
  }
}

class GetSupportCallsUseCase {
  GetSupportCallsUseCase(this._repository);
  final SalesRepository _repository;

  Future<List<SupportCallRequest>> call() {
    return _repository.getSupportCalls();
  }
}

class UpdateSupportCallStatusUseCase {
  UpdateSupportCallStatusUseCase(this._repository);
  final SalesRepository _repository;

  Future<SupportCallRequest> call({
    required String callId,
    required SupportCallStatus status,
    required String actorId,
    required String actorName,
  }) {
    return _repository.updateSupportCallStatus(
      callId: callId,
      status: status,
      actorId: actorId,
      actorName: actorName,
    );
  }
}

class GetCollaborationOpportunitiesUseCase {
  GetCollaborationOpportunitiesUseCase(this._repository);
  final SalesRepository _repository;

  Future<List<CollaborationOpportunity>> call() {
    return _repository.getCollaborationOpportunities();
  }
}

class GetAgoraTokenUseCase {
  GetAgoraTokenUseCase(this._repository);
  final SalesRepository _repository;

  Future<Map<String, dynamic>> call(String callId) {
    return _repository.getAgoraToken(callId);
  }
}

// ── Quotations ───────────────────────────────────────────────────────────────

class GetQuotationsUseCase {
  GetQuotationsUseCase(this._repository);
  final SalesRepository _repository;

  Future<List<QuotationRequest>> call({
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
    return _repository.getQuotations(
      assignedTo: assignedTo,
      status: status,
      search: search,
      serviceId: serviceId,
      userId: userId,
      from: from,
      to: to,
      page: page,
      limit: limit,
    );
  }
}

class GetQuotationByIdUseCase {
  GetQuotationByIdUseCase(this._repository);
  final SalesRepository _repository;

  Future<QuotationRequest> call(String id) =>
      _repository.getQuotationById(id);
}

class GetSalesRepsUseCase {
  GetSalesRepsUseCase(this._repository);
  final SalesRepository _repository;

  Future<List<SalesRepOption>> call() => _repository.getSalesReps();
}

class AssignQuotationUseCase {
  AssignQuotationUseCase(this._repository);
  final SalesRepository _repository;

  Future<QuotationRequest> call(
    String id, {
    required String assignedTo,
    String? note,
  }) {
    return _repository.assignQuotation(id, assignedTo: assignedTo, note: note);
  }
}

class UpdateQuotationStatusUseCase {
  UpdateQuotationStatusUseCase(this._repository);
  final SalesRepository _repository;

  Future<QuotationRequest> call(
    String id, {
    required LeadStatus status,
    String? note,
  }) {
    return _repository.updateQuotationStatus(id, status: status, note: note);
  }
}

class AddQuotationNoteUseCase {
  AddQuotationNoteUseCase(this._repository);
  final SalesRepository _repository;

  Future<QuotationRequest> call(String id, String content) =>
      _repository.addQuotationNote(id, content);
}
