import 'package:equatable/equatable.dart';

import 'case_document_request.dart';

enum UserCaseStatus {
  submitted,
  filingInProgress,
  underReview,
  resubmitRequired,
  approved,
  rejected,
}

extension UserCaseStatusX on UserCaseStatus {
  String get label {
    switch (this) {
      case UserCaseStatus.submitted:
        return 'Submitted';
      case UserCaseStatus.filingInProgress:
        return 'Filing In Progress';
      case UserCaseStatus.underReview:
        return 'Under Review';
      case UserCaseStatus.resubmitRequired:
        return 'Resubmit Needed';
      case UserCaseStatus.approved:
        return 'Approved';
      case UserCaseStatus.rejected:
        return 'Rejected';
    }
  }
}

class ClientCase extends Equatable {
  const ClientCase({
    required this.id,
    required this.organizationName,
    required this.selectedServiceIds,
    required this.documentChecklist,
    required this.submittedAt,
    required this.createdByUserId,
    this.status = UserCaseStatus.submitted,
    this.userId,
    this.serviceId,
    this.serviceName,
    this.resubmitReason,
    this.rejectionReason,
    this.documentRequests = const [],
    this.statusHistory = const [],
  });

  final String id;
  final String organizationName;
  final List<String> selectedServiceIds;
  final Map<String, bool> documentChecklist;
  final DateTime submittedAt;
  final String createdByUserId;
  final UserCaseStatus status;
  final String? userId;
  final String? serviceId;
  final String? serviceName;
  final String? resubmitReason;
  final String? rejectionReason;
  final List<CaseDocumentRequest> documentRequests;
  final List<String> statusHistory;

  String get caseId => id;

  ClientCase copyWith({
    String? id,
    String? organizationName,
    List<String>? selectedServiceIds,
    Map<String, bool>? documentChecklist,
    DateTime? submittedAt,
    String? createdByUserId,
    UserCaseStatus? status,
    String? userId,
    String? serviceId,
    String? serviceName,
    String? resubmitReason,
    bool clearResubmitReason = false,
    String? rejectionReason,
    bool clearRejectionReason = false,
    List<CaseDocumentRequest>? documentRequests,
    List<String>? statusHistory,
  }) {
    return ClientCase(
      id: id ?? this.id,
      organizationName: organizationName ?? this.organizationName,
      selectedServiceIds: selectedServiceIds ?? this.selectedServiceIds,
      documentChecklist: documentChecklist ?? this.documentChecklist,
      submittedAt: submittedAt ?? this.submittedAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      resubmitReason: clearResubmitReason ? null : (resubmitReason ?? this.resubmitReason),
      rejectionReason: clearRejectionReason ? null : (rejectionReason ?? this.rejectionReason),
      documentRequests: documentRequests ?? this.documentRequests,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  @override
  List<Object?> get props => [
        id,
        organizationName,
        selectedServiceIds,
        documentChecklist,
        submittedAt,
        createdByUserId,
        status,
        userId,
        serviceId,
        serviceName,
        resubmitReason,
        rejectionReason,
        documentRequests,
        statusHistory,
      ];
}
