import '../entities/client_case.dart';
import '../entities/lead.dart';

class CaseStatusMapper {
  const CaseStatusMapper();

  LeadStatus mapUserCaseToLeadStatus(
    UserCaseStatus caseStatus, {
    LeadStatus? currentLeadStatus,
  }) {
    switch (caseStatus) {
      case UserCaseStatus.submitted:
        return currentLeadStatus == LeadStatus.contacted ||
                currentLeadStatus == LeadStatus.qualified
            ? LeadStatus.qualified
            : LeadStatus.newLead;
      case UserCaseStatus.filingInProgress:
        return LeadStatus.won;
      case UserCaseStatus.underReview:
        return LeadStatus.qualified;
      case UserCaseStatus.resubmitRequired:
        return LeadStatus.contacted;
      case UserCaseStatus.approved:
        return LeadStatus.won;
      case UserCaseStatus.rejected:
        return LeadStatus.lost;
    }
  }

  UserCaseStatus mapLeadToUserCaseStatus(
    LeadStatus leadStatus, {
    UserCaseStatus? currentCaseStatus,
  }) {
    switch (leadStatus) {
      case LeadStatus.newLead:
      case LeadStatus.contacted:
      case LeadStatus.qualified:
      case LeadStatus.proposalSent:
        return currentCaseStatus ?? UserCaseStatus.submitted;
      case LeadStatus.won:
        return UserCaseStatus.filingInProgress;
      case LeadStatus.lost:
        return UserCaseStatus.rejected;
    }
  }
}
