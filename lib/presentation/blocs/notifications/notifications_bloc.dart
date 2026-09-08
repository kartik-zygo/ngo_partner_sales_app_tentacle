import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/app_notification.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/usecases/notification_usecases.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkNotificationReadUseCase markNotificationReadUseCase,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _markNotificationReadUseCase = markNotificationReadUseCase,
        super(const NotificationsState()) {
    on<NotificationsLoaded>(_onLoaded);
    on<NotificationMarkedRead>(_onMarkedRead);
  }

  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;

  Future<void> _onLoaded(NotificationsLoaded event, Emitter<NotificationsState> emit) async {
    emit(state.copyWith(status: NotificationStatus.loading, role: event.role));
    final list = await _getNotificationsUseCase(event.role);
    emit(state.copyWith(
      status: NotificationStatus.success,
      notifications: list,
      role: event.role,
    ));
  }

  Future<void> _onMarkedRead(NotificationMarkedRead event, Emitter<NotificationsState> emit) async {
    await _markNotificationReadUseCase(event.id);
    if (state.role != null) {
      add(NotificationsLoaded(state.role!));
    }
  }
}
