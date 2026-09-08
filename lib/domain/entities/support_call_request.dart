import 'package:equatable/equatable.dart';

enum SupportCallType { voice, video }

enum SupportCallStatus { ringing, accepted, rejected, ended }

extension SupportCallTypeX on SupportCallType {
  String get label {
    switch (this) {
      case SupportCallType.voice:
        return 'voice';
      case SupportCallType.video:
        return 'video';
    }
  }
}

extension SupportCallStatusX on SupportCallStatus {
  String get label {
    switch (this) {
      case SupportCallStatus.ringing:
        return 'Incoming';
      case SupportCallStatus.accepted:
        return 'Active';
      case SupportCallStatus.rejected:
        return 'Declined';
      case SupportCallStatus.ended:
        return 'Ended';
    }
  }

  String get apiValue => name;
}

class SupportCallRequest extends Equatable {
  const SupportCallRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.organization,
    required this.targetTeam,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.message,
    this.salesAgentId,
    this.salesAgentName,
  });

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String organization;
  final String targetTeam;
  final SupportCallType type;
  final SupportCallStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? message;
  final String? salesAgentId;
  final String? salesAgentName;

  SupportCallRequest copyWith({
    SupportCallStatus? status,
    DateTime? updatedAt,
    String? salesAgentId,
    String? salesAgentName,
  }) {
    return SupportCallRequest(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      organization: organization,
      targetTeam: targetTeam,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      message: message,
      salesAgentId: salesAgentId ?? this.salesAgentId,
      salesAgentName: salesAgentName ?? this.salesAgentName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userEmail,
        userPhone,
        organization,
        targetTeam,
        type,
        status,
        createdAt,
        updatedAt,
        message,
        salesAgentId,
        salesAgentName,
      ];
}
