import '../entities/cross_app_notification_event.dart';
import '../entities/lead.dart';
import '../repositories/sales_repository.dart';

class PushUserNotificationEventUseCase {
  PushUserNotificationEventUseCase(this._repository);

  final SalesRepository _repository;

  Future<CrossAppNotificationEvent> call(CrossAppNotificationEvent event) {
    return _repository.pushUserNotificationEvent(event);
  }
}

class GetQueuedUserNotificationEventsUseCase {
  GetQueuedUserNotificationEventsUseCase(this._repository);

  final SalesRepository _repository;

  Future<List<CrossAppNotificationEvent>> call() {
    return _repository.getQueuedUserNotificationEvents();
  }
}

class NotificationBridgeService {
  NotificationBridgeService(this._pushUseCase);

  final PushUserNotificationEventUseCase _pushUseCase;

  Future<CrossAppNotificationEvent> queueLeadProgressUpdate({
    required String userId,
    required String leadId,
    required String title,
    required String body,
    String? caseId,
  }) {
    return _pushUseCase(
      CrossAppNotificationEvent(
        id: 'evt_${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        event: ConnectivityEventName.userNotificationQueued,
        caseId: caseId,
        leadId: leadId,
      ),
    );
  }
}
