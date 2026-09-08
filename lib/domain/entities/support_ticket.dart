import 'package:equatable/equatable.dart';

enum SupportTicketStatus { open, inProgress, waitingForUser, resolved, closed }

extension SupportTicketStatusX on SupportTicketStatus {
  String get label {
    switch (this) {
      case SupportTicketStatus.open:
        return 'Open';
      case SupportTicketStatus.inProgress:
        return 'In Progress';
      case SupportTicketStatus.waitingForUser:
        return 'Awaiting Reply';
      case SupportTicketStatus.resolved:
        return 'Resolved';
      case SupportTicketStatus.closed:
        return 'Closed';
    }
  }

  // Matches the API's expected camelCase status strings
  String get apiValue => name;
}

class SupportTicketUpdate extends Equatable {
  const SupportTicketUpdate({
    required this.message,
    required this.by,
    required this.createdAt,
    this.status,
    this.isInternal = false,
  });

  final String message;
  final String by;
  final DateTime createdAt;
  final SupportTicketStatus? status;
  final bool isInternal;

  @override
  List<Object?> get props => [message, by, createdAt, status, isInternal];
}

class SupportTicket extends Equatable {
  const SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.subject,
    required this.description,
    required this.createdAt,
    required this.status,
    this.assignedToSalesId,
    this.isEscalated = false,
    this.updates = const [],
  });

  final String id;
  final String userId;
  final String userName;
  final String subject;
  final String description;
  final DateTime createdAt;
  final SupportTicketStatus status;
  final String? assignedToSalesId;
  final bool isEscalated;
  final List<SupportTicketUpdate> updates;

  SupportTicket copyWith({
    SupportTicketStatus? status,
    String? assignedToSalesId,
    bool? isEscalated,
    List<SupportTicketUpdate>? updates,
  }) {
    return SupportTicket(
      id: id,
      userId: userId,
      userName: userName,
      subject: subject,
      description: description,
      createdAt: createdAt,
      status: status ?? this.status,
      assignedToSalesId: assignedToSalesId ?? this.assignedToSalesId,
      isEscalated: isEscalated ?? this.isEscalated,
      updates: updates ?? this.updates,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        subject,
        description,
        createdAt,
        status,
        assignedToSalesId,
        isEscalated,
        updates,
      ];
}
