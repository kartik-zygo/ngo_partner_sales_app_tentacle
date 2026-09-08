import 'package:equatable/equatable.dart';

enum LeadSource { userApp, manual, campaign, collaboration }

extension LeadSourceX on LeadSource {
  String get label {
    switch (this) {
      case LeadSource.userApp:
        return 'UserApp';
      case LeadSource.manual:
        return 'Manual';
      case LeadSource.campaign:
        return 'Campaign';
      case LeadSource.collaboration:
        return 'Collaboration';
    }
  }
}

enum ConnectivityEventName {
  userActionReceived,
  leadCreatedFromUserAction,
  leadAssigned,
  caseStatusSynced,
  documentRequested,
  documentResubmitted,
  userNotificationQueued,
}

class LeadActivity extends Equatable {
  const LeadActivity({
    required this.id,
    required this.message,
    required this.event,
    required this.createdAt,
    required this.performedBy,
  });

  final String id;
  final String message;
  final ConnectivityEventName event;
  final DateTime createdAt;
  final String performedBy;

  @override
  List<Object?> get props => [id, message, event, createdAt, performedBy];
}

enum LeadStatus { newLead, contacted, qualified, proposalSent, won, lost }

extension LeadStatusX on LeadStatus {
  String get label {
    switch (this) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.contacted:
        return 'Contacted';
      case LeadStatus.qualified:
        return 'Qualified';
      case LeadStatus.proposalSent:
        return 'Proposal Sent';
      case LeadStatus.won:
        return 'Won';
      case LeadStatus.lost:
        return 'Lost';
    }
  }
}

class LeadNote extends Equatable {
  const LeadNote({required this.message, required this.createdAt});

  final String message;
  final DateTime createdAt;

  @override
  List<Object?> get props => [message, createdAt];
}

class Lead extends Equatable {
  const Lead({
    required this.id,
    required this.organization,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.source = LeadSource.manual,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.serviceId,
    this.serviceName,
    String? assignedToSalesId,
    String? assignedToUserId,
    this.notes = const [],
    this.activity = const [],
    this.timeline = const [],
    this.userAppContext = const [],
  }) : assignedToSalesId = assignedToSalesId ?? assignedToUserId;

  final String id;
  final String organization;
  final String contactName;
  final String phone;
  final String email;
  final LeadStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final LeadSource source;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? serviceId;
  final String? serviceName;
  final String? assignedToSalesId;
  final List<LeadNote> notes;
  final List<String> activity;
  final List<LeadActivity> timeline;
  final List<String> userAppContext;

  String get leadId => id;
  String? get assignedToUserId => assignedToSalesId;

  Lead copyWith({
    String? id,
    String? organization,
    String? contactName,
    String? phone,
    String? email,
    LeadStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    LeadSource? source,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? serviceId,
    String? serviceName,
    String? assignedToSalesId,
    List<LeadNote>? notes,
    List<String>? activity,
    List<LeadActivity>? timeline,
    List<String>? userAppContext,
  }) {
    return Lead(
      id: id ?? this.id,
      organization: organization ?? this.organization,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      assignedToSalesId: assignedToSalesId ?? this.assignedToSalesId,
      notes: notes ?? this.notes,
      activity: activity ?? this.activity,
      timeline: timeline ?? this.timeline,
      userAppContext: userAppContext ?? this.userAppContext,
    );
  }

  @override
  List<Object?> get props => [
        id,
        organization,
        contactName,
        phone,
        email,
        status,
        createdAt,
        updatedAt,
        source,
        userId,
        userName,
        userEmail,
        userPhone,
        serviceId,
        serviceName,
        assignedToSalesId,
        notes,
        activity,
        timeline,
        userAppContext,
      ];
}
