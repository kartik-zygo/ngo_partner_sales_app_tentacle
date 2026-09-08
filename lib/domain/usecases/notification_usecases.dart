import '../entities/app_notification.dart';
import '../entities/app_user.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);
  final NotificationRepository _repository;

  Future<List<AppNotification>> call(AppRole role) {
    return _repository.getNotifications(role);
  }
}

class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this._repository);
  final NotificationRepository _repository;

  Future<AppNotification> call(String id) => _repository.markRead(id);
}
