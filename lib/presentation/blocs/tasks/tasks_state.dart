part of 'tasks_bloc.dart';

enum TasksStatus { initial, loading, success, failure }

class TasksState extends Equatable {
  const TasksState({
    this.status = TasksStatus.initial,
    this.userId,
    this.tasks = const [],
    this.message,
  });

  final TasksStatus status;
  final String? userId;
  final List<FollowUpTask> tasks;
  final String? message;

  TasksState copyWith({
    TasksStatus? status,
    String? userId,
    List<FollowUpTask>? tasks,
    String? message,
    bool clearMessage = false,
  }) {
    return TasksState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      tasks: tasks ?? this.tasks,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, userId, tasks, message];
}
