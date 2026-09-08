part of 'tasks_bloc.dart';

sealed class TasksEvent extends Equatable {
  const TasksEvent();

  @override
  List<Object?> get props => [];
}

class TasksLoaded extends TasksEvent {
  const TasksLoaded({this.userId});

  final String? userId;

  @override
  List<Object?> get props => [userId];
}

class TaskCompleted extends TasksEvent {
  const TaskCompleted(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

class TaskRescheduled extends TasksEvent {
  const TaskRescheduled({required this.taskId, required this.newDate});

  final String taskId;
  final DateTime newDate;

  @override
  List<Object?> get props => [taskId, newDate];
}

class TaskCreated extends TasksEvent {
  const TaskCreated(this.task);

  final FollowUpTask task;

  @override
  List<Object?> get props => [task];
}
