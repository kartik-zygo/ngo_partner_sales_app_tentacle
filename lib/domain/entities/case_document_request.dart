import 'package:equatable/equatable.dart';

class CaseDocumentRequest extends Equatable {
  const CaseDocumentRequest({
    required this.round,
    required this.requestedAt,
    required this.requestedBy,
    required this.reason,
    required this.documents,
    this.dueDate,
    this.resubmittedAt,
  });

  final int round;
  final DateTime requestedAt;
  final String requestedBy;
  final String reason;
  final List<String> documents;
  final DateTime? dueDate;
  final DateTime? resubmittedAt;

  bool get isResubmitted => resubmittedAt != null;

  CaseDocumentRequest copyWith({
    int? round,
    DateTime? requestedAt,
    String? requestedBy,
    String? reason,
    List<String>? documents,
    DateTime? dueDate,
    DateTime? resubmittedAt,
  }) {
    return CaseDocumentRequest(
      round: round ?? this.round,
      requestedAt: requestedAt ?? this.requestedAt,
      requestedBy: requestedBy ?? this.requestedBy,
      reason: reason ?? this.reason,
      documents: documents ?? this.documents,
      dueDate: dueDate ?? this.dueDate,
      resubmittedAt: resubmittedAt ?? this.resubmittedAt,
    );
  }

  @override
  List<Object?> get props => [
        round,
        requestedAt,
        requestedBy,
        reason,
        documents,
        dueDate,
        resubmittedAt,
      ];
}
