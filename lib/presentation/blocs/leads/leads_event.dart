part of 'leads_bloc.dart';

sealed class LeadsEvent extends Equatable {
  const LeadsEvent();

  @override
  List<Object?> get props => [];
}

class LeadsLoaded extends LeadsEvent {
  const LeadsLoaded({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class LeadSearchChanged extends LeadsEvent {
  const LeadSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class LeadFilterChanged extends LeadsEvent {
  const LeadFilterChanged(this.status);

  final LeadStatus? status;

  @override
  List<Object?> get props => [status];
}

class LeadSourceFilterChanged extends LeadsEvent {
  const LeadSourceFilterChanged(this.source);

  final LeadSource? source;

  @override
  List<Object?> get props => [source];
}

class LeadSortToggled extends LeadsEvent {
  const LeadSortToggled(this.newestFirst);

  final bool newestFirst;

  @override
  List<Object?> get props => [newestFirst];
}

class LeadSaved extends LeadsEvent {
  const LeadSaved(this.lead);

  final Lead lead;

  @override
  List<Object?> get props => [lead];
}

class LeadDeleted extends LeadsEvent {
  const LeadDeleted(this.leadId);

  final String leadId;

  @override
  List<Object?> get props => [leadId];
}

class LeadStatusUpdated extends LeadsEvent {
  const LeadStatusUpdated({required this.leadId, required this.status});

  final String leadId;
  final LeadStatus status;

  @override
  List<Object?> get props => [leadId, status];
}

class LeadNoteAdded extends LeadsEvent {
  const LeadNoteAdded({required this.leadId, required this.note});

  final String leadId;
  final String note;

  @override
  List<Object?> get props => [leadId, note];
}

class LeadFollowUpScheduled extends LeadsEvent {
  const LeadFollowUpScheduled({
    required this.leadId,
    required this.title,
    required this.dueDate,
  });

  final String leadId;
  final String title;
  final DateTime dueDate;

  @override
  List<Object?> get props => [leadId, title, dueDate];
}

class ClientCaseSubmitted extends LeadsEvent {
  const ClientCaseSubmitted(this.clientCase);

  final ClientCase clientCase;

  @override
  List<Object?> get props => [clientCase];
}

class LeadSelected extends LeadsEvent {
  const LeadSelected(this.leadId);

  final String leadId;

  @override
  List<Object?> get props => [leadId];
}

class UserActionReceived extends LeadsEvent {
  const UserActionReceived(this.action);

  final UserActionPayload action;

  @override
  List<Object?> get props => [action];
}

class LeadCreatedFromUserAction extends LeadsEvent {
  const LeadCreatedFromUserAction(this.lead);

  final Lead lead;

  @override
  List<Object?> get props => [lead];
}

class CaseStatusSynced extends LeadsEvent {
  const CaseStatusSynced({
    required this.caseId,
    required this.targetStatus,
    required this.updatedBy,
    this.reason,
  });

  final String caseId;
  final UserCaseStatus targetStatus;
  final String updatedBy;
  final String? reason;

  @override
  List<Object?> get props => [caseId, targetStatus, updatedBy, reason];
}

class DocumentRequested extends LeadsEvent {
  const DocumentRequested({
    required this.caseId,
    required this.documents,
    required this.reason,
    this.dueDate,
    required this.requestedBy,
  });

  final String caseId;
  final List<String> documents;
  final String reason;
  final DateTime? dueDate;
  final String requestedBy;

  @override
  List<Object?> get props => [caseId, documents, reason, dueDate, requestedBy];
}

class DocumentResubmitted extends LeadsEvent {
  const DocumentResubmitted({required this.caseId, required this.userId});

  final String caseId;
  final String userId;

  @override
  List<Object?> get props => [caseId, userId];
}

class UserNotificationQueued extends LeadsEvent {
  const UserNotificationQueued(this.event);

  final CrossAppNotificationEvent event;

  @override
  List<Object?> get props => [event];
}

class SupportTicketUpdated extends LeadsEvent {
  const SupportTicketUpdated({
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

class TicketSelected extends LeadsEvent {
  const TicketSelected(this.ticketId);

  final String ticketId;

  @override
  List<Object?> get props => [ticketId];
}

class TicketUpdateAdded extends LeadsEvent {
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

class TicketEscalated extends LeadsEvent {
  const TicketEscalated({required this.ticketId, required this.reason});

  final String ticketId;
  final String reason;

  @override
  List<Object?> get props => [ticketId, reason];
}

class SupportCallUpdated extends LeadsEvent {
  const SupportCallUpdated({
    required this.callId,
    required this.status,
    required this.actorId,
    required this.actorName,
  });

  final String callId;
  final SupportCallStatus status;
  final String actorId;
  final String actorName;

  @override
  List<Object?> get props => [callId, status, actorId, actorName];
}
