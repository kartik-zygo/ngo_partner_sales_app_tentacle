part of 'notifications_bloc.dart';

enum NotificationStatus { initial, loading, success }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.role,
  });

  final NotificationStatus status;
  final List<AppNotification> notifications;
  final AppRole? role;

  NotificationsState copyWith({
    NotificationStatus? status,
    List<AppNotification>? notifications,
    AppRole? role,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [status, notifications, role];
}
