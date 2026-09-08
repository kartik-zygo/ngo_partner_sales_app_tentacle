import '../entities/approval_request.dart';
import '../entities/collaboration_opportunity.dart';
import '../entities/dashboard_summary.dart';
import '../entities/lead.dart';
import '../entities/revenue_record.dart';
import '../entities/payment_request.dart';
import '../entities/service_order.dart';
import '../entities/service_package.dart';
import '../entities/support_ticket.dart';
import '../entities/team_member.dart';
import '../repositories/admin_repository.dart';

class GetAdminDashboardUseCase {
  GetAdminDashboardUseCase(this._repository);
  final AdminRepository _repository;

  Future<AdminDashboardSummary> call() => _repository.getDashboardSummary();
}

class GetIntegrationDashboardMetricsUseCase {
  GetIntegrationDashboardMetricsUseCase(this._repository);
  final AdminRepository _repository;

  Future<IntegrationDashboardMetrics> call() {
    return _repository.getIntegrationDashboardMetrics();
  }
}

class GetAllLeadsUseCase {
  GetAllLeadsUseCase(this._repository);
  final AdminRepository _repository;

  Future<List<Lead>> call() => _repository.getAllLeads();
}

class AssignLeadUseCase {
  AssignLeadUseCase(this._repository);
  final AdminRepository _repository;

  Future<Lead> call({
    required String leadId,
    required String teamMemberId,
    required String assignedBy,
  }) {
    return _repository.assignLead(
      leadId: leadId,
      teamMemberId: teamMemberId,
      assignedBy: assignedBy,
    );
  }
}

class ReassignLeadUseCase {
  ReassignLeadUseCase(this._repository);
  final AdminRepository _repository;

  Future<Lead> call({
    required String leadId,
    required String teamMemberId,
    required String assignedBy,
  }) {
    return _repository.reassignLead(
      leadId: leadId,
      teamMemberId: teamMemberId,
      assignedBy: assignedBy,
    );
  }
}

class GetTeamMembersUseCase {
  GetTeamMembersUseCase(this._repository);
  final AdminRepository _repository;

  Future<List<TeamMember>> call() => _repository.getTeamMembers();
}

class UpsertTeamMemberUseCase {
  UpsertTeamMemberUseCase(this._repository);
  final AdminRepository _repository;

  Future<TeamMember> call(TeamMember member) => _repository.upsertTeamMember(member);
}

class SetTeamMemberActiveUseCase {
  SetTeamMemberActiveUseCase(this._repository);
  final AdminRepository _repository;

  Future<TeamMember> call(String id, bool isActive) {
    return _repository.setTeamMemberActive(id, isActive);
  }
}

class GetServicePackagesUseCase {
  GetServicePackagesUseCase(this._repository);
  final AdminRepository _repository;

  Future<List<ServicePackage>> call({
    String? category,
    String? search,
    bool includeInactive = false,
  }) =>
      _repository.getServicePackages(
        category: category,
        search: search,
        includeInactive: includeInactive,
      );
}

class UpsertServicePackageUseCase {
  UpsertServicePackageUseCase(this._repository);
  final AdminRepository _repository;

  Future<ServicePackage> call(ServicePackage servicePackage) {
    return _repository.upsertServicePackage(servicePackage);
  }
}

class ToggleServicePackageUseCase {
  ToggleServicePackageUseCase(this._repository);
  final AdminRepository _repository;

  Future<ServicePackage> call(String id, bool isActive) {
    return _repository.toggleServicePackage(id, isActive);
  }
}

class GetApprovalRequestsUseCase {
  GetApprovalRequestsUseCase(this._repository);
  final AdminRepository _repository;

  Future<List<ApprovalRequest>> call() => _repository.getApprovalRequests();
}

class DecideApprovalUseCase {
  DecideApprovalUseCase(this._repository);
  final AdminRepository _repository;

  Future<ApprovalRequest> call(String id, ApprovalStatus status) {
    return _repository.decideApproval(id, status);
  }
}

class GetRevenueRecordsUseCase {
  GetRevenueRecordsUseCase(this._repository);
  final AdminRepository _repository;

  Future<List<RevenueRecord>> call(DateTime from, DateTime to) {
    return _repository.getRevenueRecords(from, to);
  }
}

class ExportReportUseCase {
  ExportReportUseCase(this._repository);
  final AdminRepository _repository;

  Future<String> call(DateTime from, DateTime to) {
    return _repository.exportReport(from, to);
  }
}

class GetReportExportHistoryUseCase {
  GetReportExportHistoryUseCase(this._repository);
  final AdminRepository _repository;

  Future<List<String>> call() {
    return _repository.getReportExportHistory();
  }
}

class GetAssignmentHistoryUseCase {
  GetAssignmentHistoryUseCase(this._repository);
  final AdminRepository _repository;

  Future<List<String>> call() {
    return _repository.getAssignmentHistory();
  }
}

class GetAdminSupportTicketsUseCase {
  GetAdminSupportTicketsUseCase(this._repository);
  final AdminRepository _repository;

  Future<List<SupportTicket>> call() => _repository.getSupportTickets();
}

class GetAdminTicketByIdUseCase {
  GetAdminTicketByIdUseCase(this._repository);
  final AdminRepository _repository;

  Future<SupportTicket> call(String id) => _repository.getTicketById(id);
}

class UpdateAdminSupportTicketUseCase {
  UpdateAdminSupportTicketUseCase(this._repository);
  final AdminRepository _repository;

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

class AddAdminTicketUpdateUseCase {
  AddAdminTicketUpdateUseCase(this._repository);
  final AdminRepository _repository;

  Future<SupportTicket> call(
    String ticketId,
    String message, {
    bool isInternal = false,
  }) {
    return _repository.addTicketUpdate(ticketId, message, isInternal: isInternal);
  }
}

class EscalateAdminTicketUseCase {
  EscalateAdminTicketUseCase(this._repository);
  final AdminRepository _repository;

  Future<SupportTicket> call(String ticketId, String reason) {
    return _repository.escalateTicket(ticketId, reason);
  }
}

class AssignTicketUseCase {
  AssignTicketUseCase(this._repository);
  final AdminRepository _repository;

  Future<SupportTicket> call(String ticketId, String assignedTo) {
    return _repository.assignTicket(ticketId, assignedTo);
  }
}

class GetAdminCollaborationOpportunitiesUseCase {
  GetAdminCollaborationOpportunitiesUseCase(this._repository);
  final AdminRepository _repository;

  Future<List<CollaborationOpportunity>> call() {
    return _repository.getCollaborationOpportunities();
  }
}

class GetServiceCategoriesUseCase {
  GetServiceCategoriesUseCase(this._repository);
  final AdminRepository _repository;

  Future<List<String>> call() => _repository.getServiceCategories();
}

class DeleteServicePackageUseCase {
  DeleteServicePackageUseCase(this._repository);
  final AdminRepository _repository;

  Future<void> call(String id) => _repository.deleteServicePackage(id);
}

class GetOrdersUseCase {
  GetOrdersUseCase(this._repository);
  final AdminRepository _repository;

  Future<List<ServiceOrder>> call({
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
    return _repository.getOrders(
      status: status,
      fulfillmentStatus: fulfillmentStatus,
      serviceId: serviceId,
      userId: userId,
      search: search,
      from: from,
      to: to,
      page: page,
      limit: limit,
    );
  }
}

class GetOrderByIdUseCase {
  GetOrderByIdUseCase(this._repository);
  final AdminRepository _repository;

  Future<ServiceOrder> call(String id) => _repository.getOrderById(id);
}

class UpdateOrderFulfillmentUseCase {
  UpdateOrderFulfillmentUseCase(this._repository);
  final AdminRepository _repository;

  Future<ServiceOrder> call(
    String id, {
    required String fulfillmentStatus,
    String? adminNotes,
  }) {
    return _repository.updateOrderFulfillment(
      id,
      fulfillmentStatus: fulfillmentStatus,
      adminNotes: adminNotes,
    );
  }
}

class GetPaymentRequestsUseCase {
  GetPaymentRequestsUseCase(this._repository);
  final AdminRepository _repository;

  Future<List<PaymentRequest>> call({
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
    return _repository.getPaymentRequests(
      status: status,
      paymentMethod: paymentMethod,
      orderId: orderId,
      userId: userId,
      serviceId: serviceId,
      search: search,
      from: from,
      to: to,
      page: page,
      limit: limit,
    );
  }
}

class GetPaymentRequestByIdUseCase {
  GetPaymentRequestByIdUseCase(this._repository);
  final AdminRepository _repository;

  Future<PaymentRequest> call(String id) =>
      _repository.getPaymentRequestById(id);
}

class DecidePaymentRequestUseCase {
  DecidePaymentRequestUseCase(this._repository);
  final AdminRepository _repository;

  Future<PaymentRequest> call(
    String id, {
    required String decision,
    String? reviewNotes,
  }) {
    return _repository.decidePaymentRequest(
      id,
      decision: decision,
      reviewNotes: reviewNotes,
    );
  }
}
