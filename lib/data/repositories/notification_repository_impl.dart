import '../../domain/entities/app_notification.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote);

  final RemoteDataSource _remote;

  @override
  Future<List<AppNotification>> getNotifications(AppRole role) {
    return _remote.getNotifications(limit: 50);
  }

  @override
  Future<AppNotification> markRead(String id) {
    return _remote.markNotificationRead(id);
  }
}
