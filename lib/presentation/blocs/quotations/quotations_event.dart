import 'package:equatable/equatable.dart';

import '../../../domain/entities/lead.dart';
import '../../../domain/entities/quotation_request.dart';

abstract class QuotationsEvent extends Equatable {
  const QuotationsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the inbox. `assignedTo` takes a rep's UUID, `me`, or `unassigned`;
/// passing null clears the filter and returns everything the caller may see.
class QuotationsLoaded extends QuotationsEvent {
  const QuotationsLoaded({this.assignedTo, this.status, this.search});

  final String? assignedTo;
  final String? status;
  final String? search;

  @override
  List<Object?> get props => [assignedTo, status, search];
}

class QuotationsFilterChanged extends QuotationsEvent {
  const QuotationsFilterChanged({
    this.assignedTo,
    this.status,
    this.clearAssignedTo = false,
    this.clearStatus = false,
  });

  final String? assignedTo;
  final String? status;

  /// Explicit clears — a null value alone means "leave this filter alone".
  final bool clearAssignedTo;
  final bool clearStatus;

  @override
  List<Object?> get props => [assignedTo, status, clearAssignedTo, clearStatus];
}

class QuotationsSearchChanged extends QuotationsEvent {
  const QuotationsSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

/// Pulls the full record — the list rows carry no notes or activity.
class QuotationDetailOpened extends QuotationsEvent {
  const QuotationDetailOpened(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class QuotationDetailClosed extends QuotationsEvent {
  const QuotationDetailClosed();
}

class QuotationAssigned extends QuotationsEvent {
  const QuotationAssigned({
    required this.id,
    required this.assignedTo,
    this.note,
  });

  final String id;
  final String assignedTo;
  final String? note;

  @override
  List<Object?> get props => [id, assignedTo, note];
}

class QuotationStatusUpdated extends QuotationsEvent {
  const QuotationStatusUpdated({
    required this.id,
    required this.status,
    this.note,
  });

  final String id;
  final LeadStatus status;
  final String? note;

  @override
  List<Object?> get props => [id, status, note];
}

class QuotationNoteAdded extends QuotationsEvent {
  const QuotationNoteAdded({required this.id, required this.content});

  final String id;
  final String content;

  @override
  List<Object?> get props => [id, content];
}

class SalesRepsLoaded extends QuotationsEvent {
  const SalesRepsLoaded();
}

/// A `quotation:submitted` socket event landed — a new request is waiting in
/// the inbox. Carries the raw payload so the badge can name the service.
class QuotationSubmissionReceived extends QuotationsEvent {
  const QuotationSubmissionReceived(this.payload);

  final Map<String, dynamic> payload;

  @override
  List<Object?> get props => [payload];
}

/// Clears the unseen counter once the inbox has actually been looked at.
class QuotationInboxSeen extends QuotationsEvent {
  const QuotationInboxSeen();
}

class QuotationMessageCleared extends QuotationsEvent {
  const QuotationMessageCleared();
}

/// Replaces one row in place after a socket-driven refetch.
class QuotationReplaced extends QuotationsEvent {
  const QuotationReplaced(this.quotation);

  final QuotationRequest quotation;

  @override
  List<Object?> get props => [quotation];
}
