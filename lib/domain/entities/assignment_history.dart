import 'package:equatable/equatable.dart';

class AssignmentHistory extends Equatable {
  const AssignmentHistory({
    required this.id,
    required this.leadId,
    required this.leadOrganization,
    required this.assignedToSalesId,
    required this.assignedToSalesName,
    required this.assignedBy,
    required this.assignedAt,
    this.previousSalesId,
    this.previousSalesName,
  });

  final String id;
  final String leadId;
  final String leadOrganization;
  final String assignedToSalesId;
  final String assignedToSalesName;
  final String assignedBy;
  final DateTime assignedAt;
  final String? previousSalesId;
  final String? previousSalesName;

  @override
  List<Object?> get props => [
        id,
        leadId,
        leadOrganization,
        assignedToSalesId,
        assignedToSalesName,
        assignedBy,
        assignedAt,
        previousSalesId,
        previousSalesName,
      ];
}
