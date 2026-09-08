import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/collaboration_opportunity.dart';
import '../../../domain/entities/lead.dart';
import '../../../domain/entities/support_ticket.dart';
import '../../../domain/entities/team_member.dart';
import '../../../domain/usecases/admin_usecases.dart';

part 'admin_team_event.dart';
part 'admin_team_state.dart';

class AdminTeamBloc extends Bloc<AdminTeamEvent, AdminTeamState> {
  AdminTeamBloc({
    required GetAllLeadsUseCase getAllLeadsUseCase,
    required GetTeamMembersUseCase getTeamMembersUseCase,
    required UpsertTeamMemberUseCase upsertTeamMemberUseCase,
    required SetTeamMemberActiveUseCase setTeamMemberActiveUseCase,
    required AssignLeadUseCase assignLeadUseCase,
    required ReassignLeadUseCase reassignLeadUseCase,
    required GetAssignmentHistoryUseCase getAssignmentHistoryUseCase,
    required GetAdminSupportTicketsUseCase getAdminSupportTicketsUseCase,
    required GetAdminTicketByIdUseCase getAdminTicketByIdUseCase,
    required UpdateAdminSupportTicketUseCase updateAdminSupportTicketUseCase,
    required AddAdminTicketUpdateUseCase addAdminTicketUpdateUseCase,
    required EscalateAdminTicketUseCase escalateAdminTicketUseCase,
    required AssignTicketUseCase assignTicketUseCase,
    required GetAdminCollaborationOpportunitiesUseCase getAdminCollaborationOpportunitiesUseCase,
  })  : _getAllLeadsUseCase = getAllLeadsUseCase,
        _getTeamMembersUseCase = getTeamMembersUseCase,
        _upsertTeamMemberUseCase = upsertTeamMemberUseCase,
        _setTeamMemberActiveUseCase = setTeamMemberActiveUseCase,
        _assignLeadUseCase = assignLeadUseCase,
        _reassignLeadUseCase = reassignLeadUseCase,
        _getAssignmentHistoryUseCase = getAssignmentHistoryUseCase,
        _getAdminSupportTicketsUseCase = getAdminSupportTicketsUseCase,
        _getAdminTicketByIdUseCase = getAdminTicketByIdUseCase,
        _updateAdminSupportTicketUseCase = updateAdminSupportTicketUseCase,
        _addAdminTicketUpdateUseCase = addAdminTicketUpdateUseCase,
        _escalateAdminTicketUseCase = escalateAdminTicketUseCase,
        _assignTicketUseCase = assignTicketUseCase,
        _getAdminCollaborationOpportunitiesUseCase = getAdminCollaborationOpportunitiesUseCase,
        super(const AdminTeamState()) {
    on<AdminTeamLoaded>(_onLoaded);
    on<TeamMemberSaved>(_onMemberSaved);
    on<TeamMemberActivationChanged>(_onActivationChanged);
    on<LeadAssignmentRequested>(_onAssignmentRequested);
    on<LeadReassignmentRequested>(_onReassignmentRequested);
    on<AdminSupportTicketUpdated>(_onSupportTicketUpdated);
    on<TicketSelected>(_onTicketSelected);
    on<TicketUpdateAdded>(_onTicketUpdateAdded);
    on<TicketEscalated>(_onTicketEscalated);
    on<TicketAssigned>(_onTicketAssigned);
  }

  final GetAllLeadsUseCase _getAllLeadsUseCase;
  final GetTeamMembersUseCase _getTeamMembersUseCase;
  final UpsertTeamMemberUseCase _upsertTeamMemberUseCase;
  final SetTeamMemberActiveUseCase _setTeamMemberActiveUseCase;
  final AssignLeadUseCase _assignLeadUseCase;
  final ReassignLeadUseCase _reassignLeadUseCase;
  final GetAssignmentHistoryUseCase _getAssignmentHistoryUseCase;
  final GetAdminSupportTicketsUseCase _getAdminSupportTicketsUseCase;
  final GetAdminTicketByIdUseCase _getAdminTicketByIdUseCase;
  final UpdateAdminSupportTicketUseCase _updateAdminSupportTicketUseCase;
  final AddAdminTicketUpdateUseCase _addAdminTicketUpdateUseCase;
  final EscalateAdminTicketUseCase _escalateAdminTicketUseCase;
  final AssignTicketUseCase _assignTicketUseCase;
  final GetAdminCollaborationOpportunitiesUseCase _getAdminCollaborationOpportunitiesUseCase;

  Future<void> _onLoaded(AdminTeamLoaded event, Emitter<AdminTeamState> emit) async {
    emit(state.copyWith(status: AdminTeamStatus.loading));
    final members = await _getTeamMembersUseCase();
    final leads = await _getAllLeadsUseCase();
    final history = await _getAssignmentHistoryUseCase();
    final supportTickets = await _getAdminSupportTicketsUseCase();
    final collab = await _getAdminCollaborationOpportunitiesUseCase();
    emit(state.copyWith(
      status: AdminTeamStatus.success,
      members: members,
      leads: leads,
      assignmentHistory: history,
      supportTickets: supportTickets,
      collaborationOpportunities: collab,
      clearTempPassword: true,
    ));
  }

  Future<void> _onMemberSaved(TeamMemberSaved event, Emitter<AdminTeamState> emit) async {
    final saved = await _upsertTeamMemberUseCase(event.member);
    add(const AdminTeamLoaded());
    emit(state.copyWith(
      message: 'Member details saved',
      createdMemberTempPassword: saved.tempPassword,
    ));
  }

  Future<void> _onActivationChanged(TeamMemberActivationChanged event, Emitter<AdminTeamState> emit) async {
    await _setTeamMemberActiveUseCase(event.memberId, event.isActive);
    add(const AdminTeamLoaded());
    emit(state.copyWith(message: 'Member status updated'));
  }

  Future<void> _onAssignmentRequested(LeadAssignmentRequested event, Emitter<AdminTeamState> emit) async {
    await _assignLeadUseCase(
      leadId: event.leadId,
      teamMemberId: event.teamMemberId,
      assignedBy: event.assignedBy,
    );
    final assignCandidates = state.members.where((m) => m.id == event.teamMemberId);
    final memberName = assignCandidates.isEmpty ? event.teamMemberId : assignCandidates.first.name;
    final updatedAssignments = Map<String, String>.from(state.leadAssignments)
      ..[event.leadId] = event.teamMemberId;
    emit(state.copyWith(
      leadAssignments: updatedAssignments,
      message: 'Lead assigned to $memberName',
    ));
    add(const AdminTeamLoaded());
  }

  Future<void> _onReassignmentRequested(
    LeadReassignmentRequested event,
    Emitter<AdminTeamState> emit,
  ) async {
    await _reassignLeadUseCase(
      leadId: event.leadId,
      teamMemberId: event.teamMemberId,
      assignedBy: event.assignedBy,
    );
    final reassignCandidates = state.members.where((m) => m.id == event.teamMemberId);
    final memberName = reassignCandidates.isEmpty ? event.teamMemberId : reassignCandidates.first.name;
    final updatedAssignments = Map<String, String>.from(state.leadAssignments)
      ..[event.leadId] = event.teamMemberId;
    emit(state.copyWith(
      leadAssignments: updatedAssignments,
      message: 'Lead reassigned to $memberName',
    ));
    add(const AdminTeamLoaded());
  }

  Future<void> _onSupportTicketUpdated(
    AdminSupportTicketUpdated event,
    Emitter<AdminTeamState> emit,
  ) async {
    await _updateAdminSupportTicketUseCase(
      ticketId: event.ticketId,
      status: event.status,
      actor: event.actor,
      message: event.message,
    );
    add(const AdminTeamLoaded());
    emit(state.copyWith(message: 'Support ticket updated'));
  }

  Future<void> _onTicketSelected(
    TicketSelected event,
    Emitter<AdminTeamState> emit,
  ) async {
    try {
      final ticket = await _getAdminTicketByIdUseCase(event.ticketId);
      emit(state.copyWith(selectedTicket: ticket));
    } catch (_) {}
  }

  Future<void> _onTicketUpdateAdded(
    TicketUpdateAdded event,
    Emitter<AdminTeamState> emit,
  ) async {
    final ticket = await _addAdminTicketUpdateUseCase(
      event.ticketId,
      event.message,
      isInternal: event.isInternal,
    );
    emit(state.copyWith(selectedTicket: ticket, message: 'Reply sent'));
    add(const AdminTeamLoaded());
  }

  Future<void> _onTicketEscalated(
    TicketEscalated event,
    Emitter<AdminTeamState> emit,
  ) async {
    final ticket = await _escalateAdminTicketUseCase(event.ticketId, event.reason);
    emit(state.copyWith(selectedTicket: ticket, message: 'Ticket escalated'));
    add(const AdminTeamLoaded());
  }

  Future<void> _onTicketAssigned(
    TicketAssigned event,
    Emitter<AdminTeamState> emit,
  ) async {
    final ticket = await _assignTicketUseCase(event.ticketId, event.assignedTo);
    emit(state.copyWith(selectedTicket: ticket, message: 'Ticket assigned'));
    add(const AdminTeamLoaded());
  }
}
