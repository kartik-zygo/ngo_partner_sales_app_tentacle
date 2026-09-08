// import '../../domain/entities/app_notification.dart';
// import '../../domain/entities/app_user.dart';
// import '../../domain/entities/approval_request.dart';
// import '../../domain/entities/assignment_history.dart';
// import '../../domain/entities/client_case.dart';
// import '../../domain/entities/case_document_request.dart';
// import '../../domain/entities/collaboration_opportunity.dart';
// import '../../domain/entities/cross_app_notification_event.dart';
// import '../../domain/entities/dashboard_summary.dart';
// import '../../domain/entities/follow_up_task.dart';
// import '../../domain/entities/lead.dart';
// import '../../domain/entities/revenue_record.dart';
// import '../../domain/entities/service_package.dart';
// import '../../domain/entities/support_call_request.dart';
// import '../../domain/entities/support_ticket.dart';
// import '../../domain/entities/team_member.dart';
// import '../../domain/entities/user_action_payload.dart';
// import '../../domain/usecases/case_status_mapper.dart';
// import 'cross_app_bridge_data_source.dart';

// class MockLocalDataSource {
//   MockLocalDataSource() {
//     _seedConnectivityScenarios();
//   }

//   final CaseStatusMapper _statusMapper = const CaseStatusMapper();
//   final CrossAppBridgeDataSource _bridgeDataSource = CrossAppBridgeDataSource();
//   AppUser? _session;

//   final List<AppUser> _users = const [
//     AppUser(
//       id: 'u_sales_1',
//       name: 'Riya Sharma',
//       email: 'sales1@ngo.com',
//       phone: '+91 98989 10001',
//       role: AppRole.sales,
//       organizationName: 'NGO Partner Sales',
//     ),
//     AppUser(
//       id: 'u_admin_1',
//       name: 'Arjun Patel',
//       email: AppConstants.adminEmail,
//       phone: '+91 98989 10002',
//       role: AppRole.admin,
//       organizationName: 'NGO Partner Admin',
//     ),
//   ];

//   final List<TeamMember> _teamMembers = [
//     const TeamMember(
//       id: 'tm_1',
//       name: 'Riya Sharma',
//       email: 'sales1@ngo.com',
//       region: 'North',
//       activeLeads: 8,
//       wonDeals: 3,
//     ),
//     const TeamMember(
//       id: 'tm_2',
//       name: 'Neha Verma',
//       email: 'sales2@ngo.com',
//       region: 'West',
//       activeLeads: 11,
//       wonDeals: 4,
//     ),
//     const TeamMember(
//       id: 'tm_3',
//       name: 'Imran Khan',
//       email: 'sales3@ngo.com',
//       region: 'South',
//       activeLeads: 6,
//       wonDeals: 2,
//     ),
//   ];

//   final List<ServicePackage> _servicePackages = [
//     const ServicePackage(
//       id: 'svc_1',
//       name: 'NGO Registration',
//       description: '12A, 80G and core statutory setup package.',
//       price: 14500,
//     ),
//     const ServicePackage(
//       id: 'svc_2',
//       name: 'Fundraising Accelerator',
//       description: 'Grant prep, donor kit, outreach strategy.',
//       price: 32000,
//     ),
//     const ServicePackage(
//       id: 'svc_3',
//       name: 'Impact Reporting Suite',
//       description: 'M&E templates, dashboard setup, quarterly reports.',
//       price: 22000,
//       isActive: false,
//     ),
//   ];

//   final List<Lead> _leads = [
//     Lead(
//       id: 'lead_legacy_1',
//       organization: 'HopeBridge Foundation',
//       contactName: 'Anita Rao',
//       phone: '+91 90000 12345',
//       email: 'anita@hopebridge.org',
//       status: LeadStatus.qualified,
//       createdAt: DateTime.now().subtract(const Duration(days: 4)),
//       updatedAt: DateTime.now().subtract(const Duration(days: 1)),
//       source: LeadSource.campaign,
//       assignedToSalesId: 'tm_1',
//       notes: [
//         LeadNote(
//           message: 'Interested in compliance + donor growth package.',
//           createdAt: DateTime.now().subtract(const Duration(days: 3)),
//         ),
//       ],
//       activity: const ['Lead created', 'Intro call completed'],
//       timeline: [
//         LeadActivity(
//           id: 'la_legacy_1',
//           message: 'Lead imported from campaign list',
//           event: ConnectivityEventName.userActionReceived,
//           createdAt: DateTime.now().subtract(const Duration(days: 4)),
//           performedBy: 'System',
//         ),
//       ],
//     ),
//   ];

//   final List<FollowUpTask> _tasks = [
//     FollowUpTask(
//       id: 'task_1',
//       leadId: 'lead_legacy_1',
//       title: 'Send proposal v2',
//       dueDate: DateTime.now(),
//       status: TaskStatus.pending,
//     ),
//   ];

//   final List<ClientCase> _clientCases = [];

//   final List<ApprovalRequest> _approvals = [
//     ApprovalRequest(
//       id: 'apr_1',
//       title: 'Discount Request - HopeBridge',
//       reason: 'Budget capped by donor cycle.',
//       requestedBy: 'Riya Sharma',
//       amount: 2500,
//       status: ApprovalStatus.pending,
//       createdAt: DateTime.now().subtract(const Duration(hours: 5)),
//     ),
//   ];

//   final List<RevenueRecord> _revenueRecords = List.generate(
//     35,
//     (index) => RevenueRecord(
//       id: 'rev_$index',
//       date: DateTime.now().subtract(Duration(days: index)),
//       amount: 10000 + (index * 850).toDouble(),
//       source: index.isEven ? 'Compliance Package' : 'Fundraising Support',
//     ),
//   );

//   final List<AppNotification> _notifications = [
//     AppNotification(
//       id: 'ntf_sales_1',
//       title: 'Integration Event Received',
//       body: 'A new user app request has been converted into a lead.',
//       createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
//       targetRole: AppRole.sales,
//     ),
//     AppNotification(
//       id: 'ntf_admin_1',
//       title: 'Assignment queue update',
//       body: 'UserApp leads pending assignment increased by 1.',
//       createdAt: DateTime.now().subtract(const Duration(hours: 2)),
//       targetRole: AppRole.admin,
//     ),
//   ];

//   final List<AssignmentHistory> _assignmentHistory = [];
//   final List<CrossAppNotificationEvent> _crossAppEvents = [];
//   final List<SupportTicket> _supportTickets = [];
//   final List<SupportCallRequest> _supportCalls = [];
//   final List<CollaborationOpportunity> _collabOpportunities = [];
//   final List<UserActionPayload> _userActions = [];
//   final List<String> _reportExports = [];

//   Future<T> _simulate<T>(T value) async {
//     await Future<void>.delayed(const Duration(milliseconds: 180));
//     return value;
//   }

//   String _gen(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

//   void _seedConnectivityScenarios() {
//     final scenarioAAction = UserActionPayload(
//       id: 'ua_1',
//       userId: 'ngo_user_1',
//       userName: 'Priya Nair',
//       userEmail: 'priya@greensteps.org',
//       userPhone: '+91 98888 11111',
//       organization: 'GreenSteps Trust',
//       type: UserActionType.servicePurchase,
//       serviceId: 'svc_1',
//       serviceName: 'NGO Registration',
//       createdAt: DateTime.now().subtract(const Duration(hours: 5)),
//       message: 'Purchased via user app checkout.',
//     );
//     _ingestUserAction(scenarioAAction, performedBy: 'UserAppSync');

//     final scenarioBCase = ClientCase(
//       id: 'case_1',
//       organizationName: 'GreenSteps Trust',
//       selectedServiceIds: const ['svc_1'],
//       documentChecklist: {
//         'PAN Card': true,
//         'Registration Certificate': false,
//         'Latest audited statement': false,
//       },
//       submittedAt: DateTime.now().subtract(const Duration(days: 2)),
//       createdByUserId: 'ngo_user_1',
//       userId: 'ngo_user_1',
//       serviceId: 'svc_1',
//       serviceName: 'NGO Registration',
//       status: UserCaseStatus.submitted,
//       statusHistory: const ['submitted by user app'],
//     );
//     _clientCases.add(scenarioBCase);

//     _supportTickets.add(
//       SupportTicket(
//         id: 'ticket_1',
//         userId: 'ngo_user_2',
//         userName: 'Rahul Das',
//         subject: 'Payment verification pending',
//         description: 'Payment completed but case still shows draft.',
//         createdAt: DateTime.now().subtract(const Duration(hours: 9)),
//         status: SupportTicketStatus.open,
//       ),
//     );

//     final collaborationAction = UserActionPayload(
//       id: 'ua_2',
//       userId: 'ngo_user_3',
//       userName: 'Farah Ali',
//       userEmail: 'farah@cityyouth.org',
//       userPhone: '+91 97777 33333',
//       organization: 'City Youth Collective',
//       type: UserActionType.collaborationRequest,
//       serviceId: 'collab_1',
//       serviceName: 'Collaboration Opportunity',
//       createdAt: DateTime.now().subtract(const Duration(hours: 7)),
//       message: 'Looking for strategic partnership on youth livelihoods.',
//     );
//     _ingestUserAction(collaborationAction, performedBy: 'UserAppSync');
//   }

//   Future<AppUser?> getCurrentSession() => _simulate(_session);

//   Future<AppUser> login({required String email, required String password}) async {
//     if (email == 'sales1@ngo.com' && password == 'sales123') {
//       _session = _users.firstWhere((e) => e.role == AppRole.sales);
//       return _simulate(_session!);
//     }
//     if (email == AppConstants.adminEmail && password == AppConstants.adminPassword) {
//       _session = _users.firstWhere((e) => e.role == AppRole.admin);
//       return _simulate(_session!);
//     }
//     throw Exception('Invalid credentials');
//   }

//   Future<void> logout() async {
//     _session = null;
//     await Future<void>.delayed(const Duration(milliseconds: 120));
//   }

//   Future<SalesDashboardSummary> getSalesDashboardSummary(String userId) async {
//     final assignedLeads = _leads.where((e) => e.assignedToSalesId == userId).length;
//     final todayFollowUps = _tasks.where((e) => _isSameDate(e.dueDate, DateTime.now())).length;
//     final monthlyConversions = _leads.where((e) {
//       final isThisMonth = e.createdAt.month == DateTime.now().month && e.createdAt.year == DateTime.now().year;
//       return e.status == LeadStatus.won && isThisMonth;
//     }).length;
//     final pendingDocuments = _clientCases
//         .where((e) => e.status == UserCaseStatus.resubmitRequired || e.documentChecklist.values.contains(false))
//         .length;

//     return _simulate(
//       SalesDashboardSummary(
//         assignedLeads: assignedLeads,
//         todayFollowUps: todayFollowUps,
//         monthlyConversions: monthlyConversions,
//         pendingDocuments: pendingDocuments,
//         recentActivity: _leads
//             .expand((lead) => lead.activity.take(1))
//             .take(5)
//             .toList(),
//       ),
//     );
//   }

//   Future<AdminDashboardSummary> getAdminDashboardSummary() async {
//     await _syncBridgeData();
//     final pendingApprovals = _approvals.where((e) => e.status == ApprovalStatus.pending).length;
//     final teamPerformance = <String, int>{for (final member in _teamMembers) member.name: member.wonDeals};
//     final weeklyRevenue = List<double>.generate(7, (index) => 22000 + (index * 5500));
//     final monthlyRevenue = List<double>.generate(4, (index) => 74000 + (index * 14500));
//     final metrics = await getIntegrationDashboardMetrics();

//     return _simulate(
//       AdminDashboardSummary(
//         totalTeamRevenue: _revenueRecords.take(20).fold(0, (p, e) => p + e.amount),
//         pipelineValue: _leads.length * 24000,
//         pendingApprovals: pendingApprovals,
//         teamPerformance: teamPerformance,
//         weeklyRevenue: weeklyRevenue,
//         monthlyRevenue: monthlyRevenue,
//         newUserAppLeadsToday: metrics.newUserAppLeadsToday,
//         unassignedUserAppLeads: metrics.unassignedUserAppLeads,
//         casesStuckInResubmitRequired: metrics.casesStuckInResubmitRequired,
//         pendingCollaborationRequests: metrics.pendingCollaborationRequests,
//       ),
//     );
//   }

//   Future<IntegrationDashboardMetrics> getIntegrationDashboardMetrics() async {
//     await _syncBridgeData();
//     final now = DateTime.now();
//     final newUserAppLeadsToday = _leads.where((lead) {
//       return lead.source == LeadSource.userApp && _isSameDate(lead.createdAt, now);
//     }).length;

//     final unassignedUserAppLeads = _leads.where((lead) {
//       return lead.source == LeadSource.userApp && lead.assignedToSalesId == null;
//     }).length;

//     final threshold = now.subtract(const Duration(days: 3));
//     final stuckResubmit = _clientCases.where((clientCase) {
//       return clientCase.status == UserCaseStatus.resubmitRequired &&
//           (clientCase.documentRequests.isNotEmpty &&
//               clientCase.documentRequests.last.requestedAt.isBefore(threshold));
//     }).length;

//     final pendingCollaboration = _collabOpportunities.where((e) => !e.isConvertedToLead).length;

//     return _simulate(
//       IntegrationDashboardMetrics(
//         newUserAppLeadsToday: newUserAppLeadsToday,
//         unassignedUserAppLeads: unassignedUserAppLeads,
//         casesStuckInResubmitRequired: stuckResubmit,
//         pendingCollaborationRequests: pendingCollaboration,
//       ),
//     );
//   }

//   Future<List<Lead>> getLeads({String? assignedToUserId}) async {
//     await _syncBridgeData();
//     final leads = assignedToUserId == null
//         ? _leads
//         : _leads.where((e) => e.assignedToSalesId == assignedToUserId).toList();
//     return _simulate(List<Lead>.from(leads));
//   }

//   Future<Lead> upsertLead(Lead lead) {
//     final index = _leads.indexWhere((e) => e.id == lead.id);
//     if (index == -1) {
//       final created = lead.copyWith(
//         id: _gen('lead'),
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//       );
//       _leads.insert(0, _appendLeadEvent(
//         created,
//         event: ConnectivityEventName.leadCreatedFromUserAction,
//         message: 'Lead created from app',
//         performedBy: _session?.name ?? 'Sales',
//       ));
//       return _simulate(_leads.first);
//     }

//     _leads[index] = _appendLeadEvent(
//       lead.copyWith(updatedAt: DateTime.now()),
//       event: ConnectivityEventName.caseStatusSynced,
//       message: 'Lead details updated',
//       performedBy: _session?.name ?? 'Sales',
//     );
//     return _simulate(_leads[index]);
//   }

//   Future<void> deleteLead(String id) async {
//     _leads.removeWhere((e) => e.id == id);
//     _tasks.removeWhere((e) => e.leadId == id);
//     await Future<void>.delayed(const Duration(milliseconds: 80));
//   }

//   Future<Lead> updateLeadStatus(String leadId, LeadStatus status, {String actor = 'Sales Team'}) async {
//     final index = _leads.indexWhere((e) => e.id == leadId);
//     final lead = _leads[index];
//     var updated = lead.copyWith(status: status, updatedAt: DateTime.now());
//     updated = _appendLeadEvent(
//       updated,
//       event: ConnectivityEventName.caseStatusSynced,
//       message: 'Status moved to ${status.label}',
//       performedBy: actor,
//     );
//     _leads[index] = updated;

//     final linkedCase = _findCaseForLead(updated);
//     if (linkedCase != null) {
//       final mapped = _statusMapper.mapLeadToUserCaseStatus(status, currentCaseStatus: linkedCase.status);
//       await syncCaseStatus(
//         caseId: linkedCase.id,
//         targetStatus: mapped,
//         updatedBy: actor,
//         reason: status == LeadStatus.lost ? 'Opportunity dropped/invalid.' : null,
//       );

//       if (status == LeadStatus.won && updated.userId != null) {
//         await pushUserNotificationEvent(
//           CrossAppNotificationEvent(
//             id: _gen('evt'),
//             userId: updated.userId!,
//             title: 'Your request is being processed',
//             body: '${updated.serviceName ?? 'Service'} moved to filing.',
//             createdAt: DateTime.now(),
//             event: ConnectivityEventName.userNotificationQueued,
//             caseId: linkedCase.id,
//             leadId: updated.id,
//           ),
//         );
//       }
//     }

//     return _simulate(_leads[index]);
//   }

//   Future<Lead> addLeadNote(String leadId, String note) {
//     final index = _leads.indexWhere((e) => e.id == leadId);
//     final updated = _appendLeadEvent(
//       _leads[index].copyWith(
//         notes: [LeadNote(message: note, createdAt: DateTime.now()), ..._leads[index].notes],
//       ),
//       event: ConnectivityEventName.caseStatusSynced,
//       message: 'New note added',
//       performedBy: _session?.name ?? 'Sales',
//     );
//     _leads[index] = updated;
//     return _simulate(updated);
//   }

//   Future<List<FollowUpTask>> getTasks({String? userId}) {
//     if (userId == null) {
//       return _simulate(List<FollowUpTask>.from(_tasks));
//     }
//     final leadIds = _leads.where((e) => e.assignedToSalesId == userId).map((e) => e.id).toSet();
//     final filtered = _tasks.where((e) => leadIds.contains(e.leadId)).toList();
//     return _simulate(filtered);
//   }

//   Future<FollowUpTask> addTask(FollowUpTask task) {
//     final created = task.copyWith(id: _gen('task'));
//     _tasks.insert(0, created);
//     return _simulate(created);
//   }

//   Future<FollowUpTask> completeTask(String id) {
//     final index = _tasks.indexWhere((e) => e.id == id);
//     final updated = _tasks[index].copyWith(status: TaskStatus.completed);
//     _tasks[index] = updated;
//     return _simulate(updated);
//   }

//   Future<FollowUpTask> rescheduleTask(String id, DateTime newDate) {
//     final index = _tasks.indexWhere((e) => e.id == id);
//     final updated = _tasks[index].copyWith(dueDate: newDate, status: TaskStatus.rescheduled);
//     _tasks[index] = updated;
//     return _simulate(updated);
//   }

//   Future<List<ClientCase>> getClientCases({String? createdByUserId}) {
//     if (createdByUserId == null) {
//       return _simulate(List<ClientCase>.from(_clientCases));
//     }
//     final list = _clientCases
//         .where((e) => e.createdByUserId == createdByUserId || e.userId == createdByUserId)
//         .toList();
//     return _simulate(List<ClientCase>.from(list));
//   }

//   Future<ClientCase> createClientCase(ClientCase clientCase) {
//     final created = clientCase.copyWith(
//       id: _gen('case'),
//       submittedAt: DateTime.now(),
//       status: UserCaseStatus.submitted,
//       statusHistory: [...clientCase.statusHistory, 'submitted by sales'],
//     );
//     _clientCases.insert(0, created);
//     return _simulate(created);
//   }

//   Future<Lead> createLeadFromUserAction(UserActionPayload action) {
//     final lead = _ingestUserAction(action, performedBy: 'UserAppSync');
//     return _simulate(lead);
//   }

//   Lead _ingestUserAction(UserActionPayload action, {required String performedBy}) {
//     final duplicate = _userActions.any((existing) => existing.id == action.id);
//     if (duplicate) {
//       final existingLead = _leads.where((lead) {
//         return lead.userId == action.userId &&
//             lead.serviceId == action.serviceId &&
//             lead.status != LeadStatus.won &&
//             lead.status != LeadStatus.lost;
//       }).firstOrNull;
//       return existingLead ?? _leads.first;
//     }

//     _userActions.insert(0, action);

//     if (action.type == UserActionType.supportTicketRaised) {
//       _supportTickets.insert(
//         0,
//         SupportTicket(
//           id: _gen('ticket'),
//           userId: action.userId,
//           userName: action.userName,
//           subject: action.serviceName,
//           description: action.message ?? 'Ticket from user app',
//           createdAt: action.createdAt,
//           status: SupportTicketStatus.open,
//         ),
//       );
//     }

//     if (action.type == UserActionType.collaborationRequest) {
//       _collabOpportunities.insert(
//         0,
//         CollaborationOpportunity(
//           id: _gen('collab'),
//           userId: action.userId,
//           ngoName: action.organization,
//           contactName: action.userName,
//           contactEmail: action.userEmail,
//           message: action.message ?? 'Collaboration requested from user app.',
//           createdAt: action.createdAt,
//         ),
//       );
//     }

//     final openLeadIndex = _leads.indexWhere((lead) {
//       final isOpen = lead.status != LeadStatus.won && lead.status != LeadStatus.lost;
//       return isOpen && lead.userId == action.userId && lead.serviceId == action.serviceId;
//     });

//     final isCollaboration = action.type == UserActionType.collaborationRequest;
//     final source = isCollaboration ? LeadSource.collaboration : LeadSource.userApp;

//     if (openLeadIndex != -1) {
//       final existing = _leads[openLeadIndex];
//       final updated = _appendLeadEvent(
//         existing.copyWith(
//           organization: action.organization,
//           contactName: action.userName,
//           phone: action.userPhone,
//           email: action.userEmail,
//           updatedAt: DateTime.now(),
//           source: source,
//           userName: action.userName,
//           userEmail: action.userEmail,
//           userPhone: action.userPhone,
//           userAppContext: [
//             '${action.type.name} - ${action.serviceName}',
//             ...existing.userAppContext,
//           ],
//         ),
//         event: ConnectivityEventName.userActionReceived,
//         message: 'User action attached to existing lead (${action.type.name})',
//         performedBy: performedBy,
//       );
//       _leads[openLeadIndex] = updated;
//       return updated;
//     }

//     final created = Lead(
//       id: _gen('lead'),
//       organization: action.organization,
//       contactName: action.userName,
//       phone: action.userPhone,
//       email: action.userEmail,
//       status: action.type == UserActionType.caseSubmitted ? LeadStatus.qualified : LeadStatus.newLead,
//       createdAt: action.createdAt,
//       updatedAt: action.createdAt,
//       source: source,
//       userId: action.userId,
//       userName: action.userName,
//       userEmail: action.userEmail,
//       userPhone: action.userPhone,
//       serviceId: action.serviceId,
//       serviceName: action.serviceName,
//       assignedToSalesId: null,
//       notes: const [],
//       activity: const [],
//       timeline: const [],
//       userAppContext: [
//         'Origin: ${action.type.name}',
//         if (action.message != null) action.message!,
//       ],
//     );

//     final withEvents = _appendLeadEvent(
//       _appendLeadEvent(
//         created,
//         event: ConnectivityEventName.userActionReceived,
//         message: 'UserActionReceived: ${action.type.name}',
//         performedBy: performedBy,
//       ),
//       event: ConnectivityEventName.leadCreatedFromUserAction,
//       message: 'LeadCreatedFromUserAction for ${action.serviceName}',
//       performedBy: performedBy,
//     );

//     _leads.insert(0, withEvents);

//     if (isCollaboration) {
//       final collabIndex = _collabOpportunities.indexWhere((e) => e.userId == action.userId);
//       if (collabIndex != -1) {
//         _collabOpportunities[collabIndex] =
//             _collabOpportunities[collabIndex].copyWith(isConvertedToLead: true, linkedLeadId: withEvents.id);
//       }
//     }

//     return withEvents;
//   }

//   Future<ClientCase> syncCaseStatus({
//     required String caseId,
//     required UserCaseStatus targetStatus,
//     required String updatedBy,
//     String? reason,
//   }) {
//     final index = _clientCases.indexWhere((e) => e.id == caseId);
//     final current = _clientCases[index];
//     final historyEntry = '${DateTime.now().toIso8601String()} : ${current.status.label} -> ${targetStatus.label} by $updatedBy';
//     final updated = current.copyWith(
//       status: targetStatus,
//       resubmitReason: targetStatus == UserCaseStatus.resubmitRequired ? reason : null,
//       clearResubmitReason: targetStatus != UserCaseStatus.resubmitRequired,
//       rejectionReason: targetStatus == UserCaseStatus.rejected ? reason : null,
//       clearRejectionReason: targetStatus != UserCaseStatus.rejected,
//       statusHistory: [historyEntry, ...current.statusHistory],
//     );
//     _clientCases[index] = updated;
//     return _simulate(updated);
//   }

//   Future<ClientCase> requestCaseDocuments({
//     required String caseId,
//     required List<String> documents,
//     required String reason,
//     DateTime? dueDate,
//     required String requestedBy,
//   }) async {
//     final index = _clientCases.indexWhere((e) => e.id == caseId);
//     final current = _clientCases[index];
//     final round = current.documentRequests.length + 1;

//     final updatedChecklist = Map<String, bool>.from(current.documentChecklist);
//     for (final document in documents) {
//       updatedChecklist[document] = false;
//     }

//     final request = CaseDocumentRequest(
//       round: round,
//       requestedAt: DateTime.now(),
//       requestedBy: requestedBy,
//       reason: reason,
//       documents: documents,
//       dueDate: dueDate,
//     );

//     final updated = await syncCaseStatus(
//       caseId: caseId,
//       targetStatus: UserCaseStatus.resubmitRequired,
//       updatedBy: requestedBy,
//       reason: reason,
//     );

//     final finalCase = updated.copyWith(
//       documentChecklist: updatedChecklist,
//       documentRequests: [request, ...updated.documentRequests],
//       statusHistory: [
//         '${DateTime.now().toIso8601String()} : DocumentRequested (round $round)',
//         ...updated.statusHistory,
//       ],
//     );

//     _clientCases[index] = finalCase;

//     if (finalCase.userId != null) {
//       await pushUserNotificationEvent(
//         CrossAppNotificationEvent(
//           id: _gen('evt'),
//           userId: finalCase.userId!,
//           title: 'Additional document required',
//           body: reason,
//           createdAt: DateTime.now(),
//           event: ConnectivityEventName.documentRequested,
//           caseId: finalCase.id,
//         ),
//       );
//     }

//     return _simulate(finalCase);
//   }

//   Future<ClientCase> markDocumentsResubmitted({
//     required String caseId,
//     required String userId,
//   }) async {
//     final index = _clientCases.indexWhere((e) => e.id == caseId);
//     final current = _clientCases[index];
//     if (current.documentRequests.isEmpty) {
//       return _simulate(current);
//     }

//     final latest = current.documentRequests.first.copyWith(resubmittedAt: DateTime.now());
//     final requests = [latest, ...current.documentRequests.skip(1)];

//     final checklist = Map<String, bool>.from(current.documentChecklist);
//     for (final doc in latest.documents) {
//       checklist[doc] = true;
//     }

//     final updated = await syncCaseStatus(
//       caseId: caseId,
//       targetStatus: UserCaseStatus.underReview,
//       updatedBy: 'UserApp',
//     );

//     final finalCase = updated.copyWith(
//       documentChecklist: checklist,
//       documentRequests: requests,
//       statusHistory: [
//         '${DateTime.now().toIso8601String()} : DocumentResubmitted (round ${latest.round})',
//         ...updated.statusHistory,
//       ],
//     );
//     _clientCases[index] = finalCase;

//     final lead = _leads.firstWhere(
//       (e) => e.userId == userId && (e.serviceId == finalCase.serviceId || finalCase.serviceId == null),
//       orElse: () => _leads.first,
//     );
//     final leadIndex = _leads.indexWhere((e) => e.id == lead.id);
//     _leads[leadIndex] = _appendLeadEvent(
//       lead,
//       event: ConnectivityEventName.documentResubmitted,
//       message: 'User resubmitted requested documents.',
//       performedBy: 'UserApp',
//     );

//     return _simulate(finalCase);
//   }

//   Future<Lead> assignLead({
//     required String leadId,
//     required String teamMemberId,
//     required String assignedBy,
//     bool isReassignment = false,
//   }) {
//     final member = _teamMembers.firstWhere((e) => e.id == teamMemberId);
//     final index = _leads.indexWhere((e) => e.id == leadId);
//     final previous = _leads[index].assignedToSalesId;
//     final previousName = previous == null
//         ? null
//         : _teamMembers.firstWhere((e) => e.id == previous, orElse: () => _teamMembers.first).name;

//     final updated = _appendLeadEvent(
//       _leads[index].copyWith(assignedToSalesId: teamMemberId, updatedAt: DateTime.now()),
//       event: ConnectivityEventName.leadAssigned,
//       message: '${isReassignment ? 'Reassigned' : 'Assigned'} to ${member.name}',
//       performedBy: assignedBy,
//     );
//     _leads[index] = updated;

//     _assignmentHistory.insert(
//       0,
//       AssignmentHistory(
//         id: _gen('asg'),
//         leadId: leadId,
//         leadOrganization: updated.organization,
//         assignedToSalesId: teamMemberId,
//         assignedToSalesName: member.name,
//         assignedBy: assignedBy,
//         assignedAt: DateTime.now(),
//         previousSalesId: previous,
//         previousSalesName: previousName,
//       ),
//     );

//     return _simulate(updated);
//   }

//   Future<Lead> reassignLead({
//     required String leadId,
//     required String teamMemberId,
//     required String assignedBy,
//   }) {
//     return assignLead(
//       leadId: leadId,
//       teamMemberId: teamMemberId,
//       assignedBy: assignedBy,
//       isReassignment: true,
//     );
//   }

//   Future<List<TeamMember>> getTeamMembers() => _simulate(List<TeamMember>.from(_teamMembers));

//   Future<TeamMember> upsertTeamMember(TeamMember member) {
//     final index = _teamMembers.indexWhere((e) => e.id == member.id);
//     if (index == -1) {
//       final created = member.copyWith(id: _gen('tm'));
//       _teamMembers.add(created);
//       return _simulate(created);
//     }
//     _teamMembers[index] = member;
//     return _simulate(member);
//   }

//   Future<TeamMember> setTeamMemberActive(String id, bool isActive) {
//     final index = _teamMembers.indexWhere((e) => e.id == id);
//     final updated = _teamMembers[index].copyWith(isActive: isActive);
//     _teamMembers[index] = updated;
//     return _simulate(updated);
//   }

//   Future<List<ServicePackage>> getServicePackages() => _simulate(List<ServicePackage>.from(_servicePackages));

//   Future<ServicePackage> upsertServicePackage(ServicePackage servicePackage) {
//     final index = _servicePackages.indexWhere((e) => e.id == servicePackage.id);
//     if (index == -1) {
//       final created = servicePackage.copyWith(id: _gen('svc'));
//       _servicePackages.add(created);
//       return _simulate(created);
//     }
//     _servicePackages[index] = servicePackage;
//     return _simulate(servicePackage);
//   }

//   Future<ServicePackage> toggleServicePackage(String id, bool isActive) {
//     final index = _servicePackages.indexWhere((e) => e.id == id);
//     final updated = _servicePackages[index].copyWith(isActive: isActive);
//     _servicePackages[index] = updated;
//     return _simulate(updated);
//   }

//   Future<List<ApprovalRequest>> getApprovalRequests() => _simulate(List<ApprovalRequest>.from(_approvals));

//   Future<ApprovalRequest> decideApproval(String id, ApprovalStatus status) {
//     final index = _approvals.indexWhere((e) => e.id == id);
//     final updated = _approvals[index].copyWith(status: status);
//     _approvals[index] = updated;
//     return _simulate(updated);
//   }

//   Future<List<RevenueRecord>> getRevenueRecords(DateTime from, DateTime to) {
//     final records = _revenueRecords.where((e) => !e.date.isBefore(from) && !e.date.isAfter(to)).toList();
//     return _simulate(records);
//   }

//   Future<String> exportReport(DateTime from, DateTime to) {
//     final fileName = 'report_${from.millisecondsSinceEpoch}_${to.millisecondsSinceEpoch}.csv';
//     _reportExports.insert(0, fileName);
//     return _simulate(fileName);
//   }

//   Future<List<String>> getReportExportHistory() => _simulate(List<String>.from(_reportExports));

//   Future<List<String>> getAssignmentHistory() {
//     final history = _assignmentHistory
//         .map((e) => '${e.assignedAt.toIso8601String()} - ${e.leadOrganization} -> ${e.assignedToSalesName} (${e.assignedBy})')
//         .toList();
//     return _simulate(history);
//   }

//   Future<List<AppNotification>> getNotifications(AppRole role) {
//     final list = _notifications.where((e) => e.targetRole == role).toList();
//     return _simulate(list);
//   }

//   Future<AppNotification> markRead(String id) {
//     final index = _notifications.indexWhere((e) => e.id == id);
//     final updated = _notifications[index].copyWith(isRead: true);
//     _notifications[index] = updated;
//     return _simulate(updated);
//   }

//   Future<CrossAppNotificationEvent> pushUserNotificationEvent(CrossAppNotificationEvent event) {
//     _crossAppEvents.insert(0, event);
//     return _simulate(event);
//   }

//   Future<List<CrossAppNotificationEvent>> getQueuedUserNotificationEvents() {
//     return _simulate(List<CrossAppNotificationEvent>.from(_crossAppEvents));
//   }

//   Future<List<SupportTicket>> getSupportTickets({String? assignedToSalesId}) {
//     final tickets = assignedToSalesId == null
//         ? _supportTickets
//         : _supportTickets.where((e) => e.assignedToSalesId == assignedToSalesId).toList();
//     return _simulate(List<SupportTicket>.from(tickets));
//   }

//   Future<List<SupportCallRequest>> getSupportCalls() async {
//     await _syncBridgeData();
//     return _simulate(List<SupportCallRequest>.from(_supportCalls));
//   }

//   Future<SupportCallRequest> updateSupportCallStatus({
//     required String callId,
//     required SupportCallStatus status,
//     required String actorId,
//     required String actorName,
//   }) async {
//     await _syncBridgeData();
//     final index = _supportCalls.indexWhere((item) => item.id == callId);
//     if (index == -1) {
//       throw Exception('Support call not found');
//     }

//     final updated = _supportCalls[index].copyWith(
//       status: status,
//       updatedAt: DateTime.now(),
//       salesAgentId: actorId,
//       salesAgentName: actorName,
//     );
//     _supportCalls[index] = updated;

//     await _bridgeDataSource.updateCallStatus(
//       callId: callId,
//       status: status.label,
//       salesAgentId: actorId,
//       salesAgentName: actorName,
//     );

//     return _simulate(updated);
//   }

//   Future<SupportTicket> updateSupportTicket({
//     required String ticketId,
//     required SupportTicketStatus status,
//     required String actor,
//     String? message,
//     String? assignedToSalesId,
//     bool? escalated,
//   }) {
//     final index = _supportTickets.indexWhere((e) => e.id == ticketId);
//     final ticket = _supportTickets[index];
//     final updateEntry = SupportTicketUpdate(
//       message: message ?? 'Status updated to ${status.label}',
//       by: actor,
//       createdAt: DateTime.now(),
//       status: status,
//     );

//     final updated = ticket.copyWith(
//       status: status,
//       assignedToSalesId: assignedToSalesId ?? ticket.assignedToSalesId,
//       isEscalated: escalated ?? ticket.isEscalated,
//       updates: [updateEntry, ...ticket.updates],
//     );
//     _supportTickets[index] = updated;
//     return _simulate(updated);
//   }

//   Future<List<CollaborationOpportunity>> getCollaborationOpportunities() {
//     return _simulate(List<CollaborationOpportunity>.from(_collabOpportunities));
//   }

//   Future<void> _syncBridgeData() async {
//     await _syncBridgeLeadRequests();
//     await _syncBridgeCalls();
//   }

//   Future<void> _syncBridgeLeadRequests() async {
//     final pendingRequests = await _bridgeDataSource.getPendingLeadRequests();
//     if (pendingRequests.isEmpty) {
//       return;
//     }

//     final processedIds = <String>[];
//     for (final request in pendingRequests) {
//       _ingestUserAction(
//         UserActionPayload(
//           id: request.id,
//           userId: request.userId,
//           userName: request.userName,
//           userEmail: request.userEmail,
//           userPhone: request.userPhone,
//           organization: request.organization,
//           type: UserActionType.serviceInquiry,
//           serviceId: request.serviceId,
//           serviceName: request.serviceName,
//           createdAt: request.createdAt,
//           message: request.message,
//         ),
//         performedBy: 'UserAppBridge',
//       );
//       processedIds.add(request.id);
//     }

//     await _bridgeDataSource.markLeadRequestsProcessed(processedIds);
//   }

//   Future<void> _syncBridgeCalls() async {
//     final calls = await _bridgeDataSource.getSalesCallRequests();
//     if (calls.isEmpty) {
//       return;
//     }

//     for (final call in calls) {
//       final mapped = SupportCallRequest(
//         id: call.id,
//         userId: call.userId,
//         userName: call.userName,
//         userEmail: call.userEmail,
//         userPhone: call.userPhone,
//         organization: call.organization,
//         targetTeam: call.targetTeam,
//         type: call.callType == 'video' ? SupportCallType.video : SupportCallType.voice,
//         status: _mapSupportCallStatus(call.status),
//         createdAt: call.createdAt,
//         updatedAt: call.updatedAt,
//         message: call.message,
//         salesAgentId: call.salesAgentId,
//         salesAgentName: call.salesAgentName,
//       );

//       final index = _supportCalls.indexWhere((item) => item.id == mapped.id);
//       if (index == -1) {
//         _supportCalls.insert(0, mapped);
//       } else {
//         _supportCalls[index] = mapped;
//       }
//     }
//   }

//   SupportCallStatus _mapSupportCallStatus(String raw) {
//     switch (raw) {
//       case 'accepted':
//         return SupportCallStatus.accepted;
//       case 'rejected':
//         return SupportCallStatus.rejected;
//       case 'ended':
//         return SupportCallStatus.ended;
//       default:
//         return SupportCallStatus.ringing;
//     }
//   }

//   Lead _appendLeadEvent(
//     Lead lead, {
//     required ConnectivityEventName event,
//     required String message,
//     required String performedBy,
//   }) {
//     final entry = LeadActivity(
//       id: _gen('act'),
//       message: message,
//       event: event,
//       createdAt: DateTime.now(),
//       performedBy: performedBy,
//     );

//     return lead.copyWith(
//       updatedAt: DateTime.now(),
//       activity: [message, ...lead.activity],
//       timeline: [entry, ...lead.timeline],
//     );
//   }

//   ClientCase? _findCaseForLead(Lead lead) {
//     return _clientCases.where((clientCase) {
//       final userMatched = lead.userId != null && clientCase.userId == lead.userId;
//       final serviceMatched = lead.serviceId == null || clientCase.serviceId == lead.serviceId;
//       return userMatched && serviceMatched;
//     }).firstOrNull;
//   }

//   bool _isSameDate(DateTime a, DateTime b) {
//     return a.year == b.year && a.month == b.month && a.day == b.day;
//   }
// }

// extension<T> on Iterable<T> {
//   T? get firstOrNull => isEmpty ? null : first;
// }
