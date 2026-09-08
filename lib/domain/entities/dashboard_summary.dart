import 'package:equatable/equatable.dart';

class SalesDashboardSummary extends Equatable {
  const SalesDashboardSummary({
    required this.assignedLeads,
    required this.todayFollowUps,
    required this.monthlyConversions,
    required this.pendingDocuments,
    required this.recentActivity,
  });

  final int assignedLeads;
  final int todayFollowUps;
  final int monthlyConversions;
  final int pendingDocuments;
  final List<String> recentActivity;

  @override
  List<Object?> get props => [
        assignedLeads,
        todayFollowUps,
        monthlyConversions,
        pendingDocuments,
        recentActivity,
      ];
}

class AdminDashboardSummary extends Equatable {
  const AdminDashboardSummary({
    required this.totalTeamRevenue,
    required this.pipelineValue,
    required this.pendingApprovals,
    required this.teamPerformance,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    this.newUserAppLeadsToday = 0,
    this.unassignedUserAppLeads = 0,
    this.casesStuckInResubmitRequired = 0,
    this.pendingCollaborationRequests = 0,
  });

  final double totalTeamRevenue;
  final double pipelineValue;
  final int pendingApprovals;
  final Map<String, int> teamPerformance;
  final List<double> weeklyRevenue;
  final List<double> monthlyRevenue;
  final int newUserAppLeadsToday;
  final int unassignedUserAppLeads;
  final int casesStuckInResubmitRequired;
  final int pendingCollaborationRequests;

  @override
  List<Object?> get props => [
        totalTeamRevenue,
        pipelineValue,
        pendingApprovals,
        teamPerformance,
        weeklyRevenue,
        monthlyRevenue,
        newUserAppLeadsToday,
        unassignedUserAppLeads,
        casesStuckInResubmitRequired,
        pendingCollaborationRequests,
      ];
}

class IntegrationDashboardMetrics extends Equatable {
  const IntegrationDashboardMetrics({
    required this.newUserAppLeadsToday,
    required this.unassignedUserAppLeads,
    required this.casesStuckInResubmitRequired,
    required this.pendingCollaborationRequests,
  });

  final int newUserAppLeadsToday;
  final int unassignedUserAppLeads;
  final int casesStuckInResubmitRequired;
  final int pendingCollaborationRequests;

  @override
  List<Object?> get props => [
        newUserAppLeadsToday,
        unassignedUserAppLeads,
        casesStuckInResubmitRequired,
        pendingCollaborationRequests,
      ];
}
