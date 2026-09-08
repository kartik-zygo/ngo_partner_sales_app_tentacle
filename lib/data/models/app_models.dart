import '../../domain/entities/app_notification.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/client_case.dart';
import '../../domain/entities/follow_up_task.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/revenue_record.dart';
import '../../domain/entities/service_package.dart';
import '../../domain/entities/team_member.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.phone,
    super.organizationName,
    super.isActive,
  });

  factory AppUserModel.fromEntity(AppUser user) => AppUserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        organizationName: user.organizationName,
        isActive: user.isActive,
      );
}

class LeadModel extends Lead {
  const LeadModel({
    required super.id,
    required super.organization,
    required super.contactName,
    required super.phone,
    required super.email,
    required super.status,
    required super.createdAt,
    super.updatedAt,
    super.source,
    super.userId,
    super.userName,
    super.userEmail,
    super.userPhone,
    super.serviceId,
    super.serviceName,
    super.assignedToSalesId,
    super.notes,
    super.activity,
    super.timeline,
    super.userAppContext,
  });

  factory LeadModel.fromEntity(Lead lead) => LeadModel(
        id: lead.id,
        organization: lead.organization,
        contactName: lead.contactName,
        phone: lead.phone,
        email: lead.email,
        status: lead.status,
        createdAt: lead.createdAt,
        updatedAt: lead.updatedAt,
        source: lead.source,
        userId: lead.userId,
        userName: lead.userName,
        userEmail: lead.userEmail,
        userPhone: lead.userPhone,
        serviceId: lead.serviceId,
        serviceName: lead.serviceName,
        assignedToSalesId: lead.assignedToSalesId,
        notes: lead.notes,
        activity: lead.activity,
        timeline: lead.timeline,
        userAppContext: lead.userAppContext,
      );
}

class FollowUpTaskModel extends FollowUpTask {
  const FollowUpTaskModel({
    required super.id,
    required super.leadId,
    required super.title,
    required super.dueDate,
    required super.status,
  });

  factory FollowUpTaskModel.fromEntity(FollowUpTask task) => FollowUpTaskModel(
        id: task.id,
        leadId: task.leadId,
        title: task.title,
        dueDate: task.dueDate,
        status: task.status,
      );
}

class ClientCaseModel extends ClientCase {
  const ClientCaseModel({
    required super.id,
    required super.organizationName,
    required super.selectedServiceIds,
    required super.documentChecklist,
    required super.submittedAt,
    required super.createdByUserId,
    super.status,
  });

  factory ClientCaseModel.fromEntity(ClientCase clientCase) => ClientCaseModel(
        id: clientCase.id,
        organizationName: clientCase.organizationName,
        selectedServiceIds: clientCase.selectedServiceIds,
        documentChecklist: clientCase.documentChecklist,
        submittedAt: clientCase.submittedAt,
        createdByUserId: clientCase.createdByUserId,
        status: clientCase.status,
      );
}

class ServicePackageModel extends ServicePackage {
  const ServicePackageModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    super.isActive,
  });

  factory ServicePackageModel.fromEntity(ServicePackage servicePackage) =>
      ServicePackageModel(
        id: servicePackage.id,
        name: servicePackage.name,
        description: servicePackage.description,
        price: servicePackage.price,
        isActive: servicePackage.isActive,
      );
}

class TeamMemberModel extends TeamMember {
  const TeamMemberModel({
    required super.id,
    required super.name,
    required super.email,
    required super.region,
    required super.activeLeads,
    required super.wonDeals,
    super.isActive,
  });

  factory TeamMemberModel.fromEntity(TeamMember member) => TeamMemberModel(
        id: member.id,
        name: member.name,
        email: member.email,
        region: member.region,
        activeLeads: member.activeLeads,
        wonDeals: member.wonDeals,
        isActive: member.isActive,
      );
}

class ApprovalRequestModel extends ApprovalRequest {
  const ApprovalRequestModel({
    required super.id,
    required super.title,
    required super.reason,
    required super.requestedBy,
    required super.amount,
    required super.status,
    required super.createdAt,
  });

  factory ApprovalRequestModel.fromEntity(ApprovalRequest request) =>
      ApprovalRequestModel(
        id: request.id,
        title: request.title,
        reason: request.reason,
        requestedBy: request.requestedBy,
        amount: request.amount,
        status: request.status,
        createdAt: request.createdAt,
      );
}

class RevenueRecordModel extends RevenueRecord {
  const RevenueRecordModel({
    required super.id,
    required super.date,
    required super.amount,
    required super.source,
  });

  factory RevenueRecordModel.fromEntity(RevenueRecord record) => RevenueRecordModel(
        id: record.id,
        date: record.date,
        amount: record.amount,
        source: record.source,
      );
}

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.createdAt,
    required super.targetRole,
    super.isRead,
  });

  factory AppNotificationModel.fromEntity(AppNotification notification) =>
      AppNotificationModel(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        createdAt: notification.createdAt,
        targetRole: notification.targetRole,
        isRead: notification.isRead,
      );
}
