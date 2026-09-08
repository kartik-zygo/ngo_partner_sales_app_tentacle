import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/client_case.dart';
import '../../../domain/entities/collaboration_opportunity.dart';
import '../../../domain/entities/cross_app_notification_event.dart';
import '../../../domain/entities/follow_up_task.dart';
import '../../../domain/entities/lead.dart';
import '../../../domain/entities/support_call_request.dart';
import '../../../domain/entities/support_ticket.dart';
import '../../../domain/entities/user_action_payload.dart';
import '../../../domain/usecases/sales_usecases.dart';

part 'leads_event.dart';
part 'leads_state.dart';

class LeadsBloc extends Bloc<LeadsEvent, LeadsState> {
  LeadsBloc({
    required GetLeadsUseCase getLeadsUseCase,
    required UpsertLeadUseCase upsertLeadUseCase,
    required DeleteLeadUseCase deleteLeadUseCase,
    required UpdateLeadStatusUseCase updateLeadStatusUseCase,
    required AddLeadNoteUseCase addLeadNoteUseCase,
    required GetClientCasesUseCase getClientCasesUseCase,
    required CreateClientCaseUseCase createClientCaseUseCase,
    required AddTaskUseCase addTaskUseCase,
    required CreateLeadFromUserActionUseCase createLeadFromUserActionUseCase,
    required SyncCaseStatusUseCase syncCaseStatusUseCase,
    required RequestCaseDocumentsUseCase requestCaseDocumentsUseCase,
    required MarkDocumentsResubmittedUseCase markDocumentsResubmittedUseCase,
    required PushUserNotificationEventUseCase pushUserNotificationEventUseCase,
    required GetQueuedUserNotificationEventsUseCase getQueuedUserNotificationEventsUseCase,
    required GetSupportTicketsUseCase getSupportTicketsUseCase,
    required GetTicketByIdUseCase getTicketByIdUseCase,
    required UpdateSupportTicketUseCase updateSupportTicketUseCase,
    required AddTicketUpdateUseCase addTicketUpdateUseCase,
    required EscalateTicketUseCase escalateTicketUseCase,
    required GetSupportCallsUseCase getSupportCallsUseCase,
    required UpdateSupportCallStatusUseCase updateSupportCallStatusUseCase,
    required GetCollaborationOpportunitiesUseCase getCollaborationOpportunitiesUseCase,
  })  : _getLeadsUseCase = getLeadsUseCase,
        _upsertLeadUseCase = upsertLeadUseCase,
        _deleteLeadUseCase = deleteLeadUseCase,
        _updateLeadStatusUseCase = updateLeadStatusUseCase,
        _addLeadNoteUseCase = addLeadNoteUseCase,
        _getClientCasesUseCase = getClientCasesUseCase,
        _createClientCaseUseCase = createClientCaseUseCase,
        _addTaskUseCase = addTaskUseCase,
        _createLeadFromUserActionUseCase = createLeadFromUserActionUseCase,
        _syncCaseStatusUseCase = syncCaseStatusUseCase,
        _requestCaseDocumentsUseCase = requestCaseDocumentsUseCase,
        _markDocumentsResubmittedUseCase = markDocumentsResubmittedUseCase,
        _pushUserNotificationEventUseCase = pushUserNotificationEventUseCase,
        _getQueuedUserNotificationEventsUseCase = getQueuedUserNotificationEventsUseCase,
        _getSupportTicketsUseCase = getSupportTicketsUseCase,
        _getTicketByIdUseCase = getTicketByIdUseCase,
        _updateSupportTicketUseCase = updateSupportTicketUseCase,
        _addTicketUpdateUseCase = addTicketUpdateUseCase,
        _escalateTicketUseCase = escalateTicketUseCase,
        _getSupportCallsUseCase = getSupportCallsUseCase,
        _updateSupportCallStatusUseCase = updateSupportCallStatusUseCase,
        _getCollaborationOpportunitiesUseCase = getCollaborationOpportunitiesUseCase,
        super(const LeadsState()) {
    on<LeadsLoaded>(_onLoaded);
    on<LeadSearchChanged>(_onSearchChanged);
    on<LeadFilterChanged>(_onFilterChanged);
    on<LeadSourceFilterChanged>(_onSourceFilterChanged);
    on<LeadSortToggled>(_onSortToggled);
    on<LeadSaved>(_onLeadSaved);
    on<LeadDeleted>(_onLeadDeleted);
    on<LeadStatusUpdated>(_onLeadStatusUpdated);
    on<LeadNoteAdded>(_onLeadNoteAdded);
    on<LeadFollowUpScheduled>(_onFollowUpScheduled);
    on<ClientCaseSubmitted>(_onClientCaseSubmitted);
    on<LeadSelected>(_onLeadSelected);
    on<UserActionReceived>(_onUserActionReceived);
    on<LeadCreatedFromUserAction>(_onLeadCreatedFromUserAction);
    on<CaseStatusSynced>(_onCaseStatusSynced);
    on<DocumentRequested>(_onDocumentRequested);
    on<DocumentResubmitted>(_onDocumentResubmitted);
    on<UserNotificationQueued>(_onUserNotificationQueued);
    on<SupportTicketUpdated>(_onSupportTicketUpdated);
    on<TicketSelected>(_onTicketSelected);
    on<TicketUpdateAdded>(_onTicketUpdateAdded);
    on<TicketEscalated>(_onTicketEscalated);
    on<SupportCallUpdated>(_onSupportCallUpdated);
  }

  final GetLeadsUseCase _getLeadsUseCase;
  final UpsertLeadUseCase _upsertLeadUseCase;
  final DeleteLeadUseCase _deleteLeadUseCase;
  final UpdateLeadStatusUseCase _updateLeadStatusUseCase;
  final AddLeadNoteUseCase _addLeadNoteUseCase;
  final GetClientCasesUseCase _getClientCasesUseCase;
  final CreateClientCaseUseCase _createClientCaseUseCase;
  final AddTaskUseCase _addTaskUseCase;
  final CreateLeadFromUserActionUseCase _createLeadFromUserActionUseCase;
  final SyncCaseStatusUseCase _syncCaseStatusUseCase;
  final RequestCaseDocumentsUseCase _requestCaseDocumentsUseCase;
  final MarkDocumentsResubmittedUseCase _markDocumentsResubmittedUseCase;
  final PushUserNotificationEventUseCase _pushUserNotificationEventUseCase;
  final GetQueuedUserNotificationEventsUseCase _getQueuedUserNotificationEventsUseCase;
  final GetSupportTicketsUseCase _getSupportTicketsUseCase;
  final GetTicketByIdUseCase _getTicketByIdUseCase;
  final UpdateSupportTicketUseCase _updateSupportTicketUseCase;
  final AddTicketUpdateUseCase _addTicketUpdateUseCase;
  final EscalateTicketUseCase _escalateTicketUseCase;
  final GetSupportCallsUseCase _getSupportCallsUseCase;
  final UpdateSupportCallStatusUseCase _updateSupportCallStatusUseCase;
  final GetCollaborationOpportunitiesUseCase _getCollaborationOpportunitiesUseCase;

  Future<void> _onLoaded(LeadsLoaded event, Emitter<LeadsState> emit) async {
    emit(state.copyWith(status: LeadsStatus.loading, userId: event.userId, clearMessage: true));
    await _refreshData(emit, event.userId);
  }

  void _onSearchChanged(LeadSearchChanged event, Emitter<LeadsState> emit) {
    emit(state.copyWith(searchQuery: event.query));
    _applyFilters(emit);
  }

  void _onFilterChanged(LeadFilterChanged event, Emitter<LeadsState> emit) {
    emit(state.copyWith(statusFilter: event.status));
    _applyFilters(emit);
  }

  void _onSourceFilterChanged(LeadSourceFilterChanged event, Emitter<LeadsState> emit) {
    emit(state.copyWith(sourceFilter: event.source));
    _applyFilters(emit);
  }

  void _onSortToggled(LeadSortToggled event, Emitter<LeadsState> emit) {
    emit(state.copyWith(sortNewestFirst: event.newestFirst));
    _applyFilters(emit);
  }

  Future<void> _onLeadSaved(LeadSaved event, Emitter<LeadsState> emit) async {
    try {
      await _upsertLeadUseCase(event.lead);
      await _refreshData(emit, state.userId);
      emit(state.copyWith(message: 'Lead saved successfully'));
    } catch (e) {
      emit(state.copyWith(status: LeadsStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLeadDeleted(LeadDeleted event, Emitter<LeadsState> emit) async {
    try {
      await _deleteLeadUseCase(event.leadId);
      await _refreshData(emit, state.userId);
      emit(state.copyWith(message: 'Lead deleted'));
    } catch (e) {
      emit(state.copyWith(status: LeadsStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLeadStatusUpdated(LeadStatusUpdated event, Emitter<LeadsState> emit) async {
    try {
      await _updateLeadStatusUseCase(event.leadId, event.status);
      await _refreshData(emit, state.userId);
      final lead = state.allLeads.where((e) => e.id == event.leadId).firstOrNull;
      if (lead?.userId != null) {
        add(
          UserNotificationQueued(
            CrossAppNotificationEvent(
              id: 'evt_${DateTime.now().microsecondsSinceEpoch}',
              userId: lead!.userId!,
              title: 'Lead status updated',
              body: 'Your request status is now ${event.status.label}.',
              createdAt: DateTime.now(),
              event: ConnectivityEventName.userNotificationQueued,
              leadId: lead.id,
            ),
          ),
        );
      }
      emit(state.copyWith(message: 'Lead status updated'));
    } catch (e) {
      emit(state.copyWith(status: LeadsStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLeadNoteAdded(LeadNoteAdded event, Emitter<LeadsState> emit) async {
    try {
      await _addLeadNoteUseCase(event.leadId, event.note);
      await _refreshData(emit, state.userId);
      emit(state.copyWith(message: 'Note added'));
    } catch (e) {
      emit(state.copyWith(status: LeadsStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onFollowUpScheduled(LeadFollowUpScheduled event, Emitter<LeadsState> emit) async {
    try {
      await _addTaskUseCase(FollowUpTask(
        id: '',
        leadId: event.leadId,
        title: event.title,
        dueDate: event.dueDate,
        status: TaskStatus.pending,
      ));
      emit(state.copyWith(message: 'Follow-up scheduled'));
    } catch (e) {
      emit(state.copyWith(status: LeadsStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onClientCaseSubmitted(ClientCaseSubmitted event, Emitter<LeadsState> emit) async {
    try {
      await _createClientCaseUseCase(event.clientCase);
      await _refreshData(emit, state.userId);
      emit(state.copyWith(message: 'Client case submitted'));
    } catch (e) {
      emit(state.copyWith(status: LeadsStatus.failure, message: e.toString()));
    }
  }

  void _onLeadSelected(LeadSelected event, Emitter<LeadsState> emit) {
    final selected = state.allLeads.where((e) => e.id == event.leadId).firstOrNull;
    emit(state.copyWith(selectedLead: selected));
  }

  Future<void> _onUserActionReceived(UserActionReceived event, Emitter<LeadsState> emit) async {
    final lead = await _createLeadFromUserActionUseCase(event.action);
    add(LeadCreatedFromUserAction(lead));
    await _refreshData(emit, state.userId);
  }

  void _onLeadCreatedFromUserAction(
    LeadCreatedFromUserAction event,
    Emitter<LeadsState> emit,
  ) {
    emit(
      state.copyWith(
        connectivityEvents: [
          'LeadCreatedFromUserAction: ${event.lead.organization}',
          ...state.connectivityEvents,
        ],
        message: 'User action converted to lead',
      ),
    );
  }

  Future<void> _onCaseStatusSynced(CaseStatusSynced event, Emitter<LeadsState> emit) async {
    await _syncCaseStatusUseCase(
      caseId: event.caseId,
      targetStatus: event.targetStatus,
      updatedBy: event.updatedBy,
      reason: event.reason,
    );
    await _refreshData(emit, state.userId);
    emit(
      state.copyWith(
        connectivityEvents: [
          'CaseStatusSynced: ${event.caseId} -> ${event.targetStatus.label}',
          ...state.connectivityEvents,
        ],
        message: 'Case status synchronized',
      ),
    );
  }

  Future<void> _onDocumentRequested(DocumentRequested event, Emitter<LeadsState> emit) async {
    await _requestCaseDocumentsUseCase(
      caseId: event.caseId,
      documents: event.documents,
      reason: event.reason,
      dueDate: event.dueDate,
      requestedBy: event.requestedBy,
    );
    await _refreshData(emit, state.userId);
    emit(
      state.copyWith(
        connectivityEvents: [
          'DocumentRequested: ${event.caseId}',
          ...state.connectivityEvents,
        ],
        message: 'Document request sent to user',
      ),
    );
  }

  Future<void> _onDocumentResubmitted(DocumentResubmitted event, Emitter<LeadsState> emit) async {
    await _markDocumentsResubmittedUseCase(caseId: event.caseId, userId: event.userId);
    await _refreshData(emit, state.userId);
    emit(
      state.copyWith(
        connectivityEvents: [
          'DocumentResubmitted: ${event.caseId}',
          ...state.connectivityEvents,
        ],
        message: 'User document resubmission processed',
      ),
    );
  }

  Future<void> _onUserNotificationQueued(
    UserNotificationQueued event,
    Emitter<LeadsState> emit,
  ) async {
    await _pushUserNotificationEventUseCase(event.event);
    final queued = await _getQueuedUserNotificationEventsUseCase();
    emit(
      state.copyWith(
        queuedNotificationEvents: queued,
        connectivityEvents: [
          'UserNotificationQueued: ${event.event.title}',
          ...state.connectivityEvents,
        ],
      ),
    );
  }

  Future<void> _onSupportTicketUpdated(
    SupportTicketUpdated event,
    Emitter<LeadsState> emit,
  ) async {
    await _updateSupportTicketUseCase(
      ticketId: event.ticketId,
      status: event.status,
      actor: event.actor,
      message: event.message,
    );
    await _refreshData(emit, state.userId);
    emit(state.copyWith(message: 'Support ticket updated'));
  }

  Future<void> _onTicketSelected(
    TicketSelected event,
    Emitter<LeadsState> emit,
  ) async {
    try {
      final ticket = await _getTicketByIdUseCase(event.ticketId);
      emit(state.copyWith(selectedTicket: ticket));
    } catch (e) {
      emit(state.copyWith(status: LeadsStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onTicketUpdateAdded(
    TicketUpdateAdded event,
    Emitter<LeadsState> emit,
  ) async {
    try {
      final ticket = await _addTicketUpdateUseCase(
        event.ticketId,
        event.message,
        isInternal: event.isInternal,
      );
      emit(state.copyWith(
        selectedTicket: ticket,
        message: 'Reply sent',
      ));
      await _refreshData(emit, state.userId);
    } catch (e) {
      emit(state.copyWith(status: LeadsStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onTicketEscalated(
    TicketEscalated event,
    Emitter<LeadsState> emit,
  ) async {
    try {
      final ticket = await _escalateTicketUseCase(event.ticketId, event.reason);
      emit(state.copyWith(
        selectedTicket: ticket,
        message: 'Ticket escalated',
      ));
      await _refreshData(emit, state.userId);
    } catch (e) {
      emit(state.copyWith(status: LeadsStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onSupportCallUpdated(
    SupportCallUpdated event,
    Emitter<LeadsState> emit,
  ) async {
    await _updateSupportCallStatusUseCase(
      callId: event.callId,
      status: event.status,
      actorId: event.actorId,
      actorName: event.actorName,
    );
    await _refreshData(emit, state.userId);
    emit(state.copyWith(message: 'Support call status updated'));
  }

  Future<void> _refreshData(Emitter<LeadsState> emit, String? userId) async {
    try {
      final leads = await _getLeadsUseCase(assignedToUserId: userId);
      final cases = await _getClientCasesUseCase();
      final tickets = await _getSupportTicketsUseCase(assignedToSalesId: userId);
      final calls = await _getSupportCallsUseCase();
      final queued = await _getQueuedUserNotificationEventsUseCase();
      final collab = await _getCollaborationOpportunitiesUseCase();
      emit(
        state.copyWith(
          status: LeadsStatus.success,
          allLeads: leads,
          cases: cases,
          supportTickets: tickets,
          supportCalls: calls,
          queuedNotificationEvents: queued,
          collaborationOpportunities: collab,
        ),
      );
      _applyFilters(emit);
    } catch (e) {
      emit(state.copyWith(status: LeadsStatus.failure, message: e.toString()));
    }
  }

  void _applyFilters(Emitter<LeadsState> emit) {
    final query = state.searchQuery.toLowerCase().trim();
    var leads = state.allLeads.where((lead) {
      final matchesSearch = query.isEmpty ||
          lead.organization.toLowerCase().contains(query) ||
          lead.contactName.toLowerCase().contains(query) ||
          lead.email.toLowerCase().contains(query);
      final matchesStatus = state.statusFilter == null || lead.status == state.statusFilter;
      final matchesSource = state.sourceFilter == null || lead.source == state.sourceFilter;
      return matchesSearch && matchesStatus && matchesSource;
    }).toList();

    leads.sort((a, b) => state.sortNewestFirst
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));

    emit(state.copyWith(visibleLeads: leads));
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
