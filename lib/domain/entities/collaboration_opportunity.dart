import 'package:equatable/equatable.dart';

class CollaborationOpportunity extends Equatable {
  const CollaborationOpportunity({
    required this.id,
    required this.userId,
    required this.ngoName,
    required this.contactName,
    required this.contactEmail,
    required this.message,
    required this.createdAt,
    this.isConvertedToLead = false,
    this.linkedLeadId,
  });

  final String id;
  final String userId;
  final String ngoName;
  final String contactName;
  final String contactEmail;
  final String message;
  final DateTime createdAt;
  final bool isConvertedToLead;
  final String? linkedLeadId;

  CollaborationOpportunity copyWith({
    bool? isConvertedToLead,
    String? linkedLeadId,
  }) {
    return CollaborationOpportunity(
      id: id,
      userId: userId,
      ngoName: ngoName,
      contactName: contactName,
      contactEmail: contactEmail,
      message: message,
      createdAt: createdAt,
      isConvertedToLead: isConvertedToLead ?? this.isConvertedToLead,
      linkedLeadId: linkedLeadId ?? this.linkedLeadId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        ngoName,
        contactName,
        contactEmail,
        message,
        createdAt,
        isConvertedToLead,
        linkedLeadId,
      ];
}
