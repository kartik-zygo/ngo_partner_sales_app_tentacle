import '../entities/app_notification.dart';
import '../entities/app_user.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications(AppRole role);
  Future<AppNotification> markRead(String id);
}
