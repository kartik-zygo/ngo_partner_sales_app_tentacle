import '../entities/approval_request.dart';
import '../entities/collaboration_opportunity.dart';
import '../entities/dashboard_summary.dart';
import '../entities/lead.dart';
import '../entities/payment_request.dart';
import '../entities/revenue_record.dart';
import '../entities/service_order.dart';
import '../entities/service_package.dart';
import '../entities/support_ticket.dart';
import '../entities/team_member.dart';

abstract class AdminRepository {
  Future<AdminDashboardSummary> getDashboardSummary();
  Future<IntegrationDashboardMetrics> getIntegrationDashboardMetrics();

  Future<List<Lead>> getAllLeads();
  Future<Lead> assignLead({
    required String leadId,
    required String teamMemberId,
    required String assignedBy,
  });
  Future<Lead> reassignLead({
    required String leadId,
    required String teamMemberId,
    required String assignedBy,
  });

  Future<List<TeamMember>> getTeamMembers();
  Future<TeamMember> upsertTeamMember(TeamMember member);
  Future<TeamMember> setTeamMemberActive(String id, bool isActive);

  Future<List<ServicePackage>> getServicePackages({
    String? category,
    String? search,
    bool includeInactive = false,
  });
  Future<List<String>> getServiceCategories();
  Future<ServicePackage> upsertServicePackage(ServicePackage servicePackage);
  Future<ServicePackage> toggleServicePackage(String id, bool isActive);
  Future<void> deleteServicePackage(String id);

  Future<List<ApprovalRequest>> getApprovalRequests();
  Future<ApprovalRequest> decideApproval(String id, ApprovalStatus status);

  Future<List<RevenueRecord>> getRevenueRecords(DateTime from, DateTime to);
  Future<String> exportReport(DateTime from, DateTime to);
  Future<List<String>> getReportExportHistory();
  Future<List<String>> getAssignmentHistory();

  Future<List<SupportTicket>> getSupportTickets();
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
  Future<SupportTicket> assignTicket(String ticketId, String assignedTo);

  Future<List<CollaborationOpportunity>> getCollaborationOpportunities();

  Future<List<ServiceOrder>> getOrders({
    String? status,
    String? fulfillmentStatus,
    String? serviceId,
    String? userId,
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

  Future<List<PaymentRequest>> getPaymentRequests({
    String? status,
    String? paymentMethod,
    String? orderId,
    String? userId,
    String? serviceId,
    String? search,
    DateTime? from,
    DateTime? to,
    int page,
    int limit,
  });
  Future<PaymentRequest> getPaymentRequestById(String id);
  Future<PaymentRequest> decidePaymentRequest(
    String id, {
    required String decision,
    String? reviewNotes,
  });
}
