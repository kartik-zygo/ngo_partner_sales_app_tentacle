import 'package:equatable/equatable.dart';

enum TaskStatus { pending, completed, rescheduled }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.rescheduled:
        return 'Rescheduled';
    }
  }
}

class FollowUpTask extends Equatable {
  const FollowUpTask({
    required this.id,
    required this.leadId,
    required this.title,
    required this.dueDate,
    required this.status,
  });

  final String id;
  final String leadId;
  final String title;
  final DateTime dueDate;
  final TaskStatus status;

  FollowUpTask copyWith({
    String? id,
    String? leadId,
    String? title,
    DateTime? dueDate,
    TaskStatus? status,
  }) {
    return FollowUpTask(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, leadId, title, dueDate, status];
}
