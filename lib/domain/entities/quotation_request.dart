import 'package:equatable/equatable.dart';

import 'lead.dart';

/// Client-facing status of a quotation request. It mirrors the linked lead's
/// [LeadStatus] automatically — the lead is the source of truth, this is the
/// vocabulary the client reads. Move it with `PATCH /quotations/:id/status`,
/// which takes *lead* pipeline values, not these.
enum QuotationStatus {
  submitted,
  assigned,
  contacted,
  qualified,
  quoted,
  closedWon,
  closedLost,
}

extension QuotationStatusX on QuotationStatus {
  String get api {
    switch (this) {
      case QuotationStatus.closedWon:
        return 'closed_won';
      case QuotationStatus.closedLost:
        return 'closed_lost';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case QuotationStatus.submitted:
        return 'Submitted';
      case QuotationStatus.assigned:
        return 'Assigned';
      case QuotationStatus.contacted:
        return 'Contacted';
      case QuotationStatus.qualified:
        return 'In discussion';
      case QuotationStatus.quoted:
        return 'Quotation shared';
      case QuotationStatus.closedWon:
        return 'Won';
      case QuotationStatus.closedLost:
        return 'Lost';
    }
  }

  bool get isClosed =>
      this == QuotationStatus.closedWon || this == QuotationStatus.closedLost;

  static QuotationStatus fromApi(String? raw) {
    switch (raw) {
      case 'assigned':
        return QuotationStatus.assigned;
      case 'contacted':
        return QuotationStatus.contacted;
      case 'qualified':
        return QuotationStatus.qualified;
      case 'quoted':
        return QuotationStatus.quoted;
      case 'closed_won':
        return QuotationStatus.closedWon;
      case 'closed_lost':
        return QuotationStatus.closedLost;
      default:
        return QuotationStatus.submitted;
    }
  }
}

/// The values `PATCH /quotations/:id/status` accepts. `newLead` is where a
/// request starts, never a target, so it is not offered.
const List<LeadStatus> kQuotationPipelineTargets = [
  LeadStatus.contacted,
  LeadStatus.qualified,
  LeadStatus.proposalSent,
  LeadStatus.won,
  LeadStatus.lost,
];

class QuotationNote extends Equatable {
  const QuotationNote({
    required this.content,
    required this.createdAt,
    this.author,
  });

  final String content;
  final DateTime createdAt;
  final String? author;

  @override
  List<Object?> get props => [content, createdAt, author];
}

class QuotationActivity extends Equatable {
  const QuotationActivity({
    required this.message,
    required this.createdAt,
    this.performedBy,
  });

  final String message;
  final DateTime createdAt;
  final String? performedBy;

  @override
  List<Object?> get props => [message, createdAt, performedBy];
}

class QuotationRequest extends Equatable {
  const QuotationRequest({
    required this.id,
    required this.reference,
    required this.contactName,
    required this.status,
    required this.createdAt,
    this.userId,
    this.serviceId,
    this.serviceName = '',
    this.serviceCategory,
    this.leadId,
    this.leadStatus,
    this.contactEmail = '',
    this.contactPhone = '',
    this.organizationName,
    this.message,
    this.statusLabel = '',
    this.assignedTo,
    this.assignedToName,
    this.assignedToEmail,
    this.assignedAt,
    this.closedAt,
    this.source = 'userApp',
    this.notes = const [],
    this.activity = const [],
  });

  final String id;
  final String reference;
  final String? userId;
  final String? serviceId;
  final String serviceName;
  final String? serviceCategory;
  final String? leadId;
  final LeadStatus? leadStatus;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final String? organizationName;
  final String? message;
  final QuotationStatus status;
  final String statusLabel;

  /// Rep user id, or null while the request is still in the admin inbox.
  final String? assignedTo;
  final String? assignedToName;
  final String? assignedToEmail;
  final DateTime? assignedAt;
  final DateTime? closedAt;
  final String source;
  final DateTime createdAt;
  final List<QuotationNote> notes;
  final List<QuotationActivity> activity;

  bool get isUnassigned => assignedTo == null || assignedTo!.isEmpty;
  bool get isClosed => status.isClosed;

  /// The backend leaves `organizationName` null for individuals, so the
  /// contact name stands in.
  String get displayOrganization =>
      (organizationName != null && organizationName!.isNotEmpty)
          ? organizationName!
          : contactName;

  QuotationRequest copyWith({
    QuotationStatus? status,
    String? statusLabel,
    LeadStatus? leadStatus,
    String? assignedTo,
    String? assignedToName,
    String? assignedToEmail,
    DateTime? assignedAt,
    DateTime? closedAt,
    List<QuotationNote>? notes,
    List<QuotationActivity>? activity,
  }) {
    return QuotationRequest(
      id: id,
      reference: reference,
      userId: userId,
      serviceId: serviceId,
      serviceName: serviceName,
      serviceCategory: serviceCategory,
      leadId: leadId,
      leadStatus: leadStatus ?? this.leadStatus,
      contactName: contactName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      organizationName: organizationName,
      message: message,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      assignedAt: assignedAt ?? this.assignedAt,
      closedAt: closedAt ?? this.closedAt,
      source: source,
      createdAt: createdAt,
      notes: notes ?? this.notes,
      activity: activity ?? this.activity,
    );
  }

  @override
  List<Object?> get props => [
        id,
        reference,
        status,
        statusLabel,
        assignedTo,
        assignedToName,
        assignedAt,
        closedAt,
        leadStatus,
        notes,
        activity,
      ];
}

/// A row from `GET /quotations/sales-reps` — the assign sheet's picker.
class SalesRepOption extends Equatable {
  const SalesRepOption({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.openRequests = 0,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;

  /// Live workload, shown next to the name so admins can spread the load.
  final int openRequests;

  @override
  List<Object?> get props => [id, name, email, phone, openRequests];
}

/// `409` from assign or status — someone else moved the request first.
/// The caller should refetch rather than retry blind.
class QuotationConflictException implements Exception {
  const QuotationConflictException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// `422 INVALID_STATUS_TRANSITION` — an illegal jump such as `newLead → won`.
class InvalidStatusTransitionException implements Exception {
  const InvalidStatusTransitionException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// `403` — SALES tried to assign; only ADMIN may.
class QuotationForbiddenException implements Exception {
  const QuotationForbiddenException(this.message);
  final String message;

  @override
  String toString() => message;
}
