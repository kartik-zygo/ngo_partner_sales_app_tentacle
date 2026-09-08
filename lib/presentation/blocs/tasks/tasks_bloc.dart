import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/follow_up_task.dart';
import '../../../domain/usecases/sales_usecases.dart';

part 'tasks_event.dart';
part 'tasks_state.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc({
    required GetTasksUseCase getTasksUseCase,
    required CompleteTaskUseCase completeTaskUseCase,
    required RescheduleTaskUseCase rescheduleTaskUseCase,
    required AddTaskUseCase addTaskUseCase,
  })  : _getTasksUseCase = getTasksUseCase,
        _completeTaskUseCase = completeTaskUseCase,
        _rescheduleTaskUseCase = rescheduleTaskUseCase,
        _addTaskUseCase = addTaskUseCase,
        super(const TasksState()) {
    on<TasksLoaded>(_onLoaded);
    on<TaskCompleted>(_onCompleted);
    on<TaskRescheduled>(_onRescheduled);
    on<TaskCreated>(_onCreated);
  }

  final GetTasksUseCase _getTasksUseCase;
  final CompleteTaskUseCase _completeTaskUseCase;
  final RescheduleTaskUseCase _rescheduleTaskUseCase;
  final AddTaskUseCase _addTaskUseCase;

  Future<void> _onLoaded(TasksLoaded event, Emitter<TasksState> emit) async {
    emit(state.copyWith(status: TasksStatus.loading, userId: event.userId, clearMessage: true));
    try {
      final tasks = await _getTasksUseCase(userId: event.userId);
      emit(state.copyWith(status: TasksStatus.success, tasks: tasks));
    } catch (e) {
      emit(state.copyWith(status: TasksStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onCompleted(TaskCompleted event, Emitter<TasksState> emit) async {
    await _completeTaskUseCase(event.taskId);
    add(TasksLoaded(userId: state.userId));
    emit(state.copyWith(message: 'Task marked complete'));
  }

  Future<void> _onRescheduled(TaskRescheduled event, Emitter<TasksState> emit) async {
    await _rescheduleTaskUseCase(event.taskId, event.newDate);
    add(TasksLoaded(userId: state.userId));
    emit(state.copyWith(message: 'Task rescheduled'));
  }

  Future<void> _onCreated(TaskCreated event, Emitter<TasksState> emit) async {
    await _addTaskUseCase(event.task);
    add(TasksLoaded(userId: state.userId));
    emit(state.copyWith(message: 'Task created'));
  }
}
