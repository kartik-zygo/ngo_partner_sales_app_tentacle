import '../entities/client_case.dart';
import '../entities/collaboration_opportunity.dart';
import '../entities/cross_app_notification_event.dart';
import '../entities/dashboard_summary.dart';
import '../entities/follow_up_task.dart';
import '../entities/lead.dart';
import '../entities/service_order.dart';
import '../entities/support_call_request.dart';
import '../entities/support_ticket.dart';
import '../entities/user_action_payload.dart';

abstract class SalesRepository {
  Future<SalesDashboardSummary> getDashboardSummary(String userId);

  Future<List<Lead>> getLeads({String? assignedToUserId});
  Future<Lead> upsertLead(Lead lead);
  Future<void> deleteLead(String leadId);
  Future<Lead> updateLeadStatus(String leadId, LeadStatus status);
  Future<Lead> addLeadNote(String leadId, String note);

  Future<List<FollowUpTask>> getTasks({String? userId});
  Future<FollowUpTask> addTask(FollowUpTask task);
  Future<FollowUpTask> completeTask(String taskId);
  Future<FollowUpTask> rescheduleTask(String taskId, DateTime newDate);

  Future<List<ClientCase>> getClientCases({String? createdByUserId});
  Future<ClientCase> createClientCase(ClientCase clientCase);

  Future<Lead> createLeadFromUserAction(UserActionPayload action);
  Future<ClientCase> syncCaseStatus({
    required String caseId,
    required UserCaseStatus targetStatus,
    required String updatedBy,
    String? reason,
  });
  Future<ClientCase> requestCaseDocuments({
    required String caseId,
    required List<String> documents,
    required String reason,
    DateTime? dueDate,
    required String requestedBy,
  });
  Future<ClientCase> markDocumentsResubmitted({
    required String caseId,
    required String userId,
  });

  Future<CrossAppNotificationEvent> pushUserNotificationEvent(
    CrossAppNotificationEvent event,
  );
  Future<List<CrossAppNotificationEvent>> getQueuedUserNotificationEvents();

  Future<List<SupportTicket>> getSupportTickets({String? assignedToSalesId});
  Future<SupportTicket> getTicketById(String id);
  Future<SupportTicket> updateSupportTicket({
    required String ticketId,
    required SupportTicketStatus status,
    required String actor,
    String? message,
  });
  Future<SupportTicket> addTicketUpdate(
    String ticketId,
    String message, {
    bool isInternal,
  });
  Future<SupportTicket> escalateTicket(String ticketId, String reason);

  Future<List<SupportCallRequest>> getSupportCalls();
  Future<SupportCallRequest> updateSupportCallStatus({
    required String callId,
    required SupportCallStatus status,
    required String actorId,
    required String actorName,
  });
  Future<Map<String, dynamic>> getAgoraToken(String callId);

  Future<List<CollaborationOpportunity>> getCollaborationOpportunities();

  Future<List<ServiceOrder>> getOrders({
    String? status,
    String? fulfillmentStatus,
    String? serviceId,
    String? search,
    DateTime? from,
    DateTime? to,
    int page,
    int limit,
  });
  Future<ServiceOrder> getOrderById(String id);
  Future<ServiceOrder> updateOrderFulfillment(
    String id, {
    required String fulfillmentStatus,
    String? adminNotes,
  });
}
