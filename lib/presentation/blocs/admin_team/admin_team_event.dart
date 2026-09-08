part of 'admin_team_bloc.dart';

sealed class AdminTeamEvent extends Equatable {
  const AdminTeamEvent();

  @override
  List<Object?> get props => [];
}

class AdminTeamLoaded extends AdminTeamEvent {
  const AdminTeamLoaded();
}

class TeamMemberSaved extends AdminTeamEvent {
  const TeamMemberSaved(this.member);

  final TeamMember member;

  @override
  List<Object?> get props => [member];
}

class TeamMemberActivationChanged extends AdminTeamEvent {
  const TeamMemberActivationChanged({required this.memberId, required this.isActive});

  final String memberId;
  final bool isActive;

  @override
  List<Object?> get props => [memberId, isActive];
}

class LeadAssignmentRequested extends AdminTeamEvent {
  const LeadAssignmentRequested({
    required this.leadId,
    required this.teamMemberId,
    required this.assignedBy,
  });

  final String leadId;
  final String teamMemberId;
  final String assignedBy;

  @override
  List<Object?> get props => [leadId, teamMemberId, assignedBy];
}

class LeadReassignmentRequested extends AdminTeamEvent {
  const LeadReassignmentRequested({
    required this.leadId,
    required this.teamMemberId,
    required this.assignedBy,
  });

  final String leadId;
  final String teamMemberId;
  final String assignedBy;

  @override
  List<Object?> get props => [leadId, teamMemberId, assignedBy];
}

class AdminSupportTicketUpdated extends AdminTeamEvent {
  const AdminSupportTicketUpdated({
    required this.ticketId,
    required this.status,
    required this.actor,
    this.message,
  });

  final String ticketId;
  final SupportTicketStatus status;
  final String actor;
  final String? message;

  @override
  List<Object?> get props => [ticketId, status, actor, message];
}

class TicketSelected extends AdminTeamEvent {
  const TicketSelected(this.ticketId);

  final String ticketId;

  @override
  List<Object?> get props => [ticketId];
}

class TicketUpdateAdded extends AdminTeamEvent {
  const TicketUpdateAdded({
    required this.ticketId,
    required this.message,
    this.isInternal = false,
  });

  final String ticketId;
  final String message;
  final bool isInternal;

  @override
  List<Object?> get props => [ticketId, message, isInternal];
}

class TicketEscalated extends AdminTeamEvent {
  const TicketEscalated({required this.ticketId, required this.reason});

  final String ticketId;
  final String reason;

  @override
  List<Object?> get props => [ticketId, reason];
}

class TicketAssigned extends AdminTeamEvent {
  const TicketAssigned({required this.ticketId, required this.assignedTo});

  final String ticketId;
  final String assignedTo;

  @override
  List<Object?> get props => [ticketId, assignedTo];
}
