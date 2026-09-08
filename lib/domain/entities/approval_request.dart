import 'package:equatable/equatable.dart';

enum ApprovalStatus { pending, approved, rejected }

extension ApprovalStatusX on ApprovalStatus {
  String get label {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Pending';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
    }
  }
}

class ApprovalRequest extends Equatable {
  const ApprovalRequest({
    required this.id,
    required this.title,
    required this.reason,
    required this.requestedBy,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String reason;
  final String requestedBy;
  final double amount;
  final ApprovalStatus status;
  final DateTime createdAt;

  ApprovalRequest copyWith({
    ApprovalStatus? status,
  }) {
    return ApprovalRequest(
      id: id,
      title: title,
      reason: reason,
      requestedBy: requestedBy,
      amount: amount,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, reason, requestedBy, amount, status, createdAt];
}
