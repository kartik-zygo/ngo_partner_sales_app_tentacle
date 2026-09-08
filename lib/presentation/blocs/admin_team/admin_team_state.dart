part of 'admin_team_bloc.dart';

enum AdminTeamStatus { initial, loading, success }

class AdminTeamState extends Equatable {
  const AdminTeamState({
    this.status = AdminTeamStatus.initial,
    this.members = const [],
    this.leads = const [],
    this.assignmentHistory = const [],
    this.supportTickets = const [],
    this.selectedTicket,
    this.collaborationOpportunities = const [],
    this.leadAssignments = const {},
    this.message,
    this.createdMemberTempPassword,
  });

  final AdminTeamStatus status;
  final List<TeamMember> members;
  final List<Lead> leads;
  final List<String> assignmentHistory;
  final List<SupportTicket> supportTickets;
  final SupportTicket? selectedTicket;
  final List<CollaborationOpportunity> collaborationOpportunities;
  // Local cache: leadId -> memberId. Survives API reloads since the server
  // doesn't return the assignedTo field in the leads list response.
  final Map<String, String> leadAssignments;
  final String? message;
  // Set only after a successful creation; cleared on the next reload.
  final String? createdMemberTempPassword;

  AdminTeamState copyWith({
    AdminTeamStatus? status,
    List<TeamMember>? members,
    List<Lead>? leads,
    List<String>? assignmentHistory,
    List<SupportTicket>? supportTickets,
    SupportTicket? selectedTicket,
    bool clearSelectedTicket = false,
    List<CollaborationOpportunity>? collaborationOpportunities,
    Map<String, String>? leadAssignments,
    String? message,
    String? createdMemberTempPassword,
    bool clearTempPassword = false,
  }) {
    return AdminTeamState(
      status: status ?? this.status,
      members: members ?? this.members,
      leads: leads ?? this.leads,
      assignmentHistory: assignmentHistory ?? this.assignmentHistory,
      supportTickets: supportTickets ?? this.supportTickets,
      selectedTicket: clearSelectedTicket ? null : (selectedTicket ?? this.selectedTicket),
      collaborationOpportunities: collaborationOpportunities ?? this.collaborationOpportunities,
      leadAssignments: leadAssignments ?? this.leadAssignments,
      message: message ?? this.message,
      createdMemberTempPassword: clearTempPassword
          ? null
          : (createdMemberTempPassword ?? this.createdMemberTempPassword),
    );
  }

  @override
  List<Object?> get props => [
        status,
        members,
        leads,
        assignmentHistory,
        supportTickets,
        selectedTicket,
        collaborationOpportunities,
        leadAssignments,
        message,
        createdMemberTempPassword,
      ];
}
