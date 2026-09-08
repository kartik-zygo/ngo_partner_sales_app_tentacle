import 'package:equatable/equatable.dart';

enum UserActionType {
  serviceInquiry,
  servicePurchase,
  caseSubmitted,
  documentResubmitted,
  supportTicketRaised,
  collaborationRequest,
}

class UserActionPayload extends Equatable {
  const UserActionPayload({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.organization,
    required this.type,
    required this.serviceId,
    required this.serviceName,
    required this.createdAt,
    this.message,
  });

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String organization;
  final UserActionType type;
  final String serviceId;
  final String serviceName;
  final DateTime createdAt;
  final String? message;

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userEmail,
        userPhone,
        organization,
        type,
        serviceId,
        serviceName,
        createdAt,
        message,
      ];
}
