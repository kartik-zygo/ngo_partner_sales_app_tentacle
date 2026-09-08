import 'package:equatable/equatable.dart';

import 'lead.dart';

class CrossAppNotificationEvent extends Equatable {
  const CrossAppNotificationEvent({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.event,
    this.caseId,
    this.leadId,
    this.isDelivered = false,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final ConnectivityEventName event;
  final String? caseId;
  final String? leadId;
  final bool isDelivered;

  CrossAppNotificationEvent copyWith({bool? isDelivered}) {
    return CrossAppNotificationEvent(
      id: id,
      userId: userId,
      title: title,
      body: body,
      createdAt: createdAt,
      event: event,
      caseId: caseId,
      leadId: leadId,
      isDelivered: isDelivered ?? this.isDelivered,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        body,
        createdAt,
        event,
        caseId,
        leadId,
        isDelivered,
      ];
}
