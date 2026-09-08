import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/widgets/ui_primitives.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/approval_request.dart';
import '../../../domain/entities/collaboration_opportunity.dart';
import '../../../domain/entities/lead.dart';
import '../../../domain/entities/payment_request.dart';
import '../../../domain/entities/service_order.dart';
import '../../../domain/entities/service_package.dart';
import '../../../domain/entities/support_ticket.dart';
import '../../../domain/entities/team_member.dart';
import '../../blocs/admin_reports/admin_reports_bloc.dart';
import '../../blocs/admin_services/admin_services_bloc.dart';
import '../../blocs/admin_team/admin_team_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/notifications/notifications_bloc.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../blocs/payment_approvals/payment_approvals_bloc.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/payment_approvals_view.dart';
import '../community/community_moderation_page.dart';
import '../../widgets/role_guard.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key, required this.user});

  final AppUser user;

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardLoaded(widget.user));
    context.read<AdminTeamBloc>().add(const AdminTeamLoaded());
    context.read<AdminServicesBloc>().add(const AdminServicesLoaded());
    context.read<AdminReportsBloc>().add(const AdminReportsLoaded());
    context.read<NotificationsBloc>().add(const NotificationsLoaded(AppRole.admin));
    context.read<OrdersBloc>().add(const OrdersLoaded());
    context
        .read<PaymentApprovalsBloc>()
        .add(const PaymentApprovalsLoaded(status: 'pending'));
    _subscribeToPaymentSubmissions();
  }

  void _subscribeToPaymentSubmissions() {
    GetIt.instance<SocketService>().onPaymentRequestSubmitted((payload) {
      if (!mounted) return;
      context
          .read<PaymentApprovalsBloc>()
          .add(PaymentApprovalSubmissionReceived(payload));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New payment declared for ${payload['serviceName'] ?? 'an order'}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.warning,
          action: SnackBarAction(
            label: 'Review',
            textColor: Colors.white,
            onPressed: () => setState(() => _index = 4),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    GetIt.instance<SocketService>().offPaymentRequestSubmitted();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _AdminDashboardTab(
        onTabChange: (i) => setState(() => _index = i),
        user: widget.user,
      ),
      const _LeadAssignmentTab(),
      const _TeamManagementTab(),
      const _ServiceCatalogTab(),
      const _AdminOrdersTab(),
      const _ApprovalCenterTab(),
      const _ReportsTab(),
      _AdminSettingsTab(user: widget.user),
    ];

    return RoleGuard(
      expectedRole: AppRole.admin,
      currentRole: widget.user.role,
      child: MultiBlocListener(
        listeners: [
          BlocListener<AdminTeamBloc, AdminTeamState>(
            listenWhen: (prev, curr) =>
                curr.message != null && prev.message != curr.message,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(state.message!),
                    ],
                  ),
                  backgroundColor: AppColors.positive,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          BlocListener<AdminServicesBloc, AdminServicesState>(
            listener: (context, state) {
              if (state.message != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.message!)));
              }
            },
          ),
          BlocListener<AdminReportsBloc, AdminReportsState>(
            listener: (context, state) {
              if (state.message != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.message!)));
              }
            },
          ),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 1000;
            return Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF4F7FF),
                      AppColors.adminAccent.withValues(alpha: 0.15),
                      const Color(0xFFF9FCFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      if (isTablet)
                        NavigationRail(
                          selectedIndex: _index,
                          onDestinationSelected: (value) => setState(() => _index = value),
                          labelType: NavigationRailLabelType.all,
                          indicatorColor: AppColors.adminAccent.withValues(alpha: 0.2),
                          leading: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('Admin',
                                style: GoogleFonts.dmSerifDisplay(fontSize: 26)),
                          ),
                          destinations: const [
                            NavigationRailDestination(
                                icon: Icon(Icons.space_dashboard_outlined),
                                selectedIcon: Icon(Icons.space_dashboard_rounded),
                                label: Text('Dashboard')),
                            NavigationRailDestination(
                                icon: Icon(Icons.assignment_ind_outlined),
                                selectedIcon: Icon(Icons.assignment_ind_rounded),
                                label: Text('Assignments')),
                            NavigationRailDestination(
                                icon: Icon(Icons.group_outlined),
                                selectedIcon: Icon(Icons.group_rounded),
                                label: Text('Team')),
                            NavigationRailDestination(
                                icon: Icon(Icons.design_services_outlined),
                                selectedIcon: Icon(Icons.design_services_rounded),
                                label: Text('Services')),
                            NavigationRailDestination(
                                icon: Icon(Icons.receipt_long_outlined),
                                selectedIcon: Icon(Icons.receipt_long_rounded),
                                label: Text('Payments')),
                            NavigationRailDestination(
                                icon: Icon(Icons.verified_outlined),
                                selectedIcon: Icon(Icons.verified_rounded),
                                label: Text('Approvals')),
                            NavigationRailDestination(
                                icon: Icon(Icons.analytics_outlined),
                                selectedIcon: Icon(Icons.analytics_rounded),
                                label: Text('Reports')),
                            NavigationRailDestination(
                                icon: Icon(Icons.settings_outlined),
                                selectedIcon: Icon(Icons.settings_rounded),
                                label: Text('Settings')),
                          ],
                        ),
                      Expanded(child: IndexedStack(index: _index, children: tabs)),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: isTablet
                  ? null
                  : NavigationBar(
                      selectedIndex: _index,
                      onDestinationSelected: (value) => setState(() => _index = value),
                      destinations: const [
                        NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
                        NavigationDestination(icon: Icon(Icons.assignment_ind), label: 'Assign'),
                        NavigationDestination(icon: Icon(Icons.group), label: 'Team'),
                        NavigationDestination(icon: Icon(Icons.design_services), label: 'Services'),
                        NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Payments'),
                        NavigationDestination(icon: Icon(Icons.verified), label: 'Approval'),
                        NavigationDestination(icon: Icon(Icons.analytics), label: 'Reports'),
                        NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminDashboardTab extends StatelessWidget {
  const _AdminDashboardTab({required this.onTabChange, required this.user});

  final void Function(int) onTabChange;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      accent: AppColors.adminAccent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _WelcomeBanner(user: user),
          const SizedBox(height: 20),
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, dashState) =>
                BlocBuilder<AdminTeamBloc, AdminTeamState>(
              builder: (context, teamState) =>
                  BlocBuilder<AdminServicesBloc, AdminServicesState>(
                builder: (context, servicesState) {
                  if (dashState.status == DashboardStatus.loading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final summary = dashState.adminSummary;
                  final metrics = dashState.integrationMetrics;
                  final currency =
                      NumberFormat.currency(symbol: '₹', decimalDigits: 0);
                  final activeMembers =
                      teamState.members.where((m) => m.isActive).length;
                  final pendingApprovals = servicesState.approvals
                      .where((r) => r.status == ApprovalStatus.pending)
                      .length;
                  final crossAxisCount =
                      MediaQuery.of(context).size.width > 760 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    children: [
                      MetricCard(
                        label: 'Team Revenue',
                        value: summary != null
                            ? currency.format(summary.totalTeamRevenue)
                            : '—',
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.adminAccent,
                      ),
                      MetricCard(
                        label: 'Active Members',
                        value: '$activeMembers',
                        icon: Icons.groups_rounded,
                        color: AppColors.positive,
                      ),
                      MetricCard(
                        label: 'Pending Approvals',
                        value: '$pendingApprovals',
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.warning,
                        subtitle: pendingApprovals > 0 ? 'Needs attention' : null,
                      ),
                      MetricCard(
                        label: 'New Leads Today',
                        value: metrics != null
                            ? '${metrics.newUserAppLeadsToday}'
                            : '—',
                        icon: Icons.person_add_alt_1_rounded,
                        color: AppColors.salesAccent,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              final metrics = state.integrationMetrics;
              if (metrics == null || metrics.unassignedUserAppLeads == 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _AlertBanner(
                  message:
                      '${metrics.unassignedUserAppLeads} lead(s) waiting for assignment',
                  icon: Icons.assignment_late_outlined,
                  color: AppColors.warning,
                  onTap: () => onTabChange(1),
                ),
              );
            },
          ),
          _SectionLabel(
            title: 'Quick Actions',
            icon: Icons.flash_on_rounded,
            color: AppColors.adminAccent,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickActionChip(
                  icon: Icons.assignment_ind_rounded,
                  label: 'Assign Leads',
                  color: AppColors.salesAccent,
                  onTap: () => onTabChange(1),
                ),
                const SizedBox(width: 8),
                _QuickActionChip(
                  icon: Icons.group_rounded,
                  label: 'Manage Team',
                  color: AppColors.positive,
                  onTap: () => onTabChange(2),
                ),
                const SizedBox(width: 8),
                _QuickActionChip(
                  icon: Icons.design_services_rounded,
                  label: 'Services',
                  color: AppColors.adminAccent,
                  onTap: () => onTabChange(3),
                ),
                const SizedBox(width: 8),
                _QuickActionChip(
                  icon: Icons.receipt_long_rounded,
                  label: 'Payments',
                  color: AppColors.warning,
                  onTap: () => onTabChange(4),
                ),
                const SizedBox(width: 8),
                _QuickActionChip(
                  icon: Icons.verified_rounded,
                  label: 'Approvals',
                  color: AppColors.danger,
                  onTap: () => onTabChange(5),
                ),
                const SizedBox(width: 8),
                _QuickActionChip(
                  icon: Icons.analytics_rounded,
                  label: 'Reports',
                  color: AppColors.muted,
                  onTap: () => onTabChange(6),
                ),
                const SizedBox(width: 8),
                _QuickActionChip(
                  icon: Icons.forum_rounded,
                  label: 'Community',
                  color: const Color(0xFF6366F1),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CommunityModerationPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BlocBuilder<AdminTeamBloc, AdminTeamState>(
            builder: (context, state) {
              if (state.assignmentHistory.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    title: 'Recent Activity',
                    icon: Icons.history_rounded,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 12),
                  _RecentActivityFeed(
                    history: state.assignmentHistory.take(5).toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final dateStr = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2455FF), Color(0xFF5B7FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminAccent.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.name,
                  style: GoogleFonts.dmSerifDisplay(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dateStr,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.message,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: color.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityFeed extends StatelessWidget {
  const _RecentActivityFeed({required this.history});

  final List<String> history;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: history.asMap().entries.map((entry) {
          final isLast = entry.key == history.length - 1;
          return Padding(
            padding: EdgeInsets.fromLTRB(
                16, entry.key == 0 ? 14 : 0, 16, isLast ? 14 : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 5),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.adminAccent.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1,
                            color: AppColors.adminAccent.withValues(alpha: 0.12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        entry.value,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppColors.charcoal.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LeadAssignmentTab extends StatelessWidget {
  const _LeadAssignmentTab();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Lead Assignment',
      accent: AppColors.adminAccent,
      child: BlocBuilder<AdminTeamBloc, AdminTeamState>(
        builder: (context, state) {
          if (state.status == AdminTeamStatus.loading && state.leads.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final unassigned = state.leads
              .where((e) =>
                  (state.leadAssignments[e.id] ?? e.assignedToUserId) == null)
              .toList();
          final assigned = state.leads
              .where((e) =>
                  (state.leadAssignments[e.id] ?? e.assignedToUserId) != null)
              .toList();
          final pendingCollaboration =
              state.collaborationOpportunities.where((item) => !item.isConvertedToLead).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionTitle(
                title: 'Unassigned Leads',
                subtitle: 'Pick a team member from the dropdown to assign each lead',
              ),
              const SizedBox(height: 8),
              if (unassigned.isEmpty)
                const EmptyStateView(
                  title: 'All leads assigned',
                  subtitle: 'Every incoming lead has an owner. Great work!',
                )
              else
                ...unassigned.map((lead) => _LeadAssignmentCard(lead: lead, state: state)),
              const SizedBox(height: 14),
              const SectionTitle(
                title: 'Assigned Leads',
                subtitle: 'Change the assigned member by selecting a different name',
              ),
              const SizedBox(height: 8),
              ...assigned.map((lead) => _LeadAssignmentCard(lead: lead, state: state)),
              const SizedBox(height: 14),
              const SectionTitle(
                title: 'Assignment History',
                subtitle: 'Recent lead assignment actions',
              ),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: state.assignmentHistory.isEmpty
                      ? [
                          const ListTile(
                            title: Text('No assignment history yet'),
                          ),
                        ]
                      : state.assignmentHistory
                          .take(8)
                          .map(
                            (entry) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.history_rounded),
                              title: Text(entry),
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 14),
              const SectionTitle(
                title: 'Support Tickets',
                subtitle: 'Assign to a sales member, escalate priority, or close resolved ones',
              ),
              const SizedBox(height: 8),
              if (state.supportTickets.isEmpty)
                const EmptyStateView(
                  title: 'No open tickets',
                  subtitle: 'Support requests from the user app will appear here.',
                )
              else
                ...state.supportTickets.map(
                  (ticket) => _AdminSupportTicketCard(ticket: ticket, state: state),
                ),
              const SizedBox(height: 14),
              SectionTitle(
                title: 'Collaboration Requests',
                subtitle: pendingCollaboration.isEmpty
                    ? 'NGO partnership requests from the user app'
                    : '${pendingCollaboration.length} pending review — convert promising ones to leads',
              ),
              const SizedBox(height: 8),
              if (state.collaborationOpportunities.isEmpty)
                const EmptyStateView(
                  title: 'No collaboration requests',
                  subtitle: 'NGO partnership requests from the user app will appear here.',
                )
              else
                ...state.collaborationOpportunities.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CollaborationOpportunityCard(item: item),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LeadAssignmentCard extends StatelessWidget {
  const _LeadAssignmentCard({required this.lead, required this.state});

  final Lead lead;
  final AdminTeamState state;

  @override
  Widget build(BuildContext context) {
    final activeMembers = state.members.where((member) => member.isActive).toList();
    final activeMemberIds = activeMembers.map((member) => member.id).toSet();
    // Use local cache first since the API doesn't return assignedTo in list responses
    final effectiveAssignedId = state.leadAssignments[lead.id] ?? lead.assignedToSalesId;
    final selectedMemberId = activeMemberIds.contains(effectiveAssignedId)
        ? effectiveAssignedId
        : null;
    final assignedCandidates = selectedMemberId != null
        ? activeMembers.where((m) => m.id == selectedMemberId).toList()
        : <TeamMember>[];
    final assignedMember = assignedCandidates.isEmpty ? null : assignedCandidates.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lead.organization,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('${lead.contactName} • ${lead.status.label}'),
                  if (assignedMember != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_pin_rounded,
                            size: 14, color: AppColors.positive),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned to ${assignedMember.name}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.positive,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _LeadSourceBadge(source: lead.source),
                      _SlaBadge(createdAt: lead.createdAt),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              hint: const Text('Assign'),
              value: selectedMemberId,
              items: activeMembers
                  .map(
                    (member) => DropdownMenuItem(
                      value: member.id,
                      child: Text(member.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                if (effectiveAssignedId == null) {
                  context.read<AdminTeamBloc>().add(
                        LeadAssignmentRequested(
                          leadId: lead.id,
                          teamMemberId: value,
                          assignedBy: 'Admin Console',
                        ),
                      );
                  return;
                }
                context.read<AdminTeamBloc>().add(
                      LeadReassignmentRequested(
                        leadId: lead.id,
                        teamMemberId: value,
                        assignedBy: 'Admin Console',
                      ),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSupportTicketCard extends StatelessWidget {
  const _AdminSupportTicketCard({required this.ticket, required this.state});

  final SupportTicket ticket;
  final AdminTeamState state;

  @override
  Widget build(BuildContext context) {
    final activeMembers = state.members.where((member) => member.isActive).toList();
    final activeMemberIds = activeMembers.map((member) => member.id).toSet();
    final selectedAssigneeId = activeMemberIds.contains(ticket.assignedToSalesId)
        ? ticket.assignedToSalesId
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.support_agent_rounded),
              title: Text(ticket.subject),
              subtitle: Text('${ticket.userName} • ${ticket.description}'),
              trailing: StatusPill(
                label: ticket.status.label,
                color: _ticketColor(ticket.status),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DropdownButton<String>(
                  hint: const Text('Assign to sales'),
                  value: selectedAssigneeId,
                  items: activeMembers
                      .map(
                        (member) => DropdownMenuItem(
                          value: member.id,
                          child: Text(member.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    context.read<AdminTeamBloc>().add(
                          TicketAssigned(
                            ticketId: ticket.id,
                            assignedTo: value,
                          ),
                        );
                  },
                ),
                OutlinedButton.icon(
                  onPressed: ticket.isEscalated
                      ? null
                      : () => context.read<AdminTeamBloc>().add(
                            TicketEscalated(
                              ticketId: ticket.id,
                              reason: 'Ticket escalated by admin',
                            ),
                          ),
                  icon: const Icon(Icons.priority_high_rounded),
                  label: Text(ticket.isEscalated ? 'Escalated' : 'Escalate'),
                ),
                FilledButton.icon(
                  onPressed: ticket.status == SupportTicketStatus.closed
                      ? null
                      : () => context.read<AdminTeamBloc>().add(
                            AdminSupportTicketUpdated(
                              ticketId: ticket.id,
                              status: SupportTicketStatus.closed,
                              actor: 'Admin Console',
                              message: 'Ticket closed by admin',
                            ),
                          ),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _ticketColor(SupportTicketStatus status) {
    switch (status) {
      case SupportTicketStatus.open:
        return AppColors.warning;
      case SupportTicketStatus.inProgress:
        return AppColors.adminAccent;
      case SupportTicketStatus.waitingForUser:
        return AppColors.muted;
      case SupportTicketStatus.resolved:
        return AppColors.positive;
      case SupportTicketStatus.closed:
        return AppColors.danger;
    }
  }
}

class _CollaborationOpportunityCard extends StatelessWidget {
  const _CollaborationOpportunityCard({required this.item});

  final CollaborationOpportunity item;

  @override
  Widget build(BuildContext context) {
    final statusText = item.isConvertedToLead
        ? 'Converted to lead (${item.linkedLeadId ?? 'n/a'})'
        : 'Pending review';
    final statusColor = item.isConvertedToLead ? AppColors.positive : AppColors.warning;

    return GlassCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.handshake_rounded),
        title: Text(item.ngoName),
        subtitle: Text('${item.contactName} • ${item.contactEmail}\n${item.message}'),
        isThreeLine: true,
        trailing: StatusPill(label: statusText, color: statusColor),
      ),
    );
  }
}

class _LeadSourceBadge extends StatelessWidget {
  const _LeadSourceBadge({required this.source});

  final LeadSource source;

  @override
  Widget build(BuildContext context) {
    final color = switch (source) {
      LeadSource.userApp => AppColors.adminAccent,
      LeadSource.manual => AppColors.muted,
      LeadSource.campaign => AppColors.salesAccent,
      LeadSource.collaboration => AppColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        source.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _SlaBadge extends StatelessWidget {
  const _SlaBadge({required this.createdAt});

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(createdAt);
    final label = age.inHours < 24 ? 'SLA ${age.inHours}h' : 'SLA ${age.inDays}d';
    final color = age.inDays >= 2
        ? AppColors.danger
        : age.inHours >= 24
            ? AppColors.warning
            : AppColors.positive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _TeamManagementTab extends StatelessWidget {
  const _TeamManagementTab();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminTeamBloc, AdminTeamState>(
      listenWhen: (prev, curr) =>
          curr.createdMemberTempPassword != null &&
          prev.createdMemberTempPassword != curr.createdMemberTempPassword,
      listener: (context, state) =>
          _showTempPasswordDialog(context, state.createdMemberTempPassword!),
      child: AppScaffold(
        title: 'Team Management',
        accent: AppColors.adminAccent,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab-add-member',
          onPressed: () => _showTeamMemberEditor(context),
          icon: const Icon(Icons.person_add_alt_rounded),
          label: const Text('Add Member'),
        ),
        child: BlocBuilder<AdminTeamBloc, AdminTeamState>(
          builder: (context, state) {
            if (state.members.isEmpty) {
              return const EmptyStateView(
                title: 'No team members',
                subtitle: 'Add your first sales member.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.members.length,
              itemBuilder: (context, index) {
                final member = state.members[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: member.isActive
                            ? AppColors.positive.withValues(alpha: 0.2)
                            : AppColors.muted.withValues(alpha: 0.2),
                        child: Icon(
                          member.isActive ? Icons.person : Icons.person_off,
                          color: member.isActive ? AppColors.positive : AppColors.muted,
                        ),
                      ),
                      title: Text(member.name),
                      subtitle: Text(
                        '${member.email}\n${member.activeLeads} active leads • ${member.wonDeals} wins',
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            onPressed: () => _showTeamMemberEditor(context, member: member),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => context.read<AdminTeamBloc>().add(
                                  TeamMemberActivationChanged(
                                    memberId: member.id,
                                    isActive: !member.isActive,
                                  ),
                                ),
                            icon: Icon(member.isActive
                                ? Icons.block_outlined
                                : Icons.check_circle_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showTeamMemberEditor(BuildContext context, {TeamMember? member}) async {
    final nameParts = (member?.name ?? '').trim().split(' ');
    final firstName = TextEditingController(text: nameParts.isNotEmpty ? nameParts.first : '');
    final lastName = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    final email = TextEditingController(text: member?.email ?? '');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(member == null ? 'Add Member' : 'Edit Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstName,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lastName,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final fullName =
        '${firstName.text.trim()} ${lastName.text.trim()}'.trim();
    final next = TeamMember(
      id: member?.id ?? '',
      name: fullName.isEmpty ? email.text.trim() : fullName,
      email: email.text.trim(),
      region: member?.region ?? '',
      activeLeads: member?.activeLeads ?? 0,
      wonDeals: member?.wonDeals ?? 0,
      isActive: member?.isActive ?? true,
    );
    context.read<AdminTeamBloc>().add(TeamMemberSaved(next));
  }

  void _showTempPasswordDialog(BuildContext context, String tempPassword) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Member Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share this temporary password with the team member. It will not be shown again.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.adminAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.adminAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      tempPassword,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tempPassword));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ServiceCatalogTab extends StatefulWidget {
  const _ServiceCatalogTab();

  @override
  State<_ServiceCatalogTab> createState() => _ServiceCatalogTabState();
}

class _ServiceCatalogTabState extends State<_ServiceCatalogTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminServicesBloc, AdminServicesState>(
      listenWhen: (prev, curr) => curr.errorMessage != null && prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.danger),
          );
        }
      },
      child: AppScaffold(
        title: 'Service Catalog',
        accent: AppColors.adminAccent,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab-add-service',
          onPressed: () => _showServiceEditor(context),
          icon: const Icon(Icons.add_business_rounded),
          label: const Text('Add Service'),
        ),
        child: BlocBuilder<AdminServicesBloc, AdminServicesState>(
          builder: (context, state) {
            return Column(
              children: [
                // Filter bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search services…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<AdminServicesBloc>().add(
                                          const AdminServicesFilterChanged(search: ''),
                                        );
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (v) => context
                            .read<AdminServicesBloc>()
                            .add(AdminServicesFilterChanged(search: v)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: state.selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All categories')),
                                ...state.categories.map(
                                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                                ),
                              ],
                              onChanged: (v) => context
                                  .read<AdminServicesBloc>()
                                  .add(AdminServicesFilterChanged(selectedCategory: v)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Incl. Inactive'),
                            selected: state.includeInactive,
                            onSelected: (v) => context
                                .read<AdminServicesBloc>()
                                .add(AdminServicesFilterChanged(includeInactive: v)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: state.status == AdminServicesStatus.loading
                      ? const Center(child: CircularProgressIndicator())
                      : state.services.isEmpty
                          ? const EmptyStateView(
                              title: 'No services found',
                              subtitle: 'Create your first service package or adjust filters.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                              itemCount: state.services.length,
                              itemBuilder: (context, index) {
                                final service = state.services[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ServiceCard(
                                    service: service,
                                    onEdit: () => _showServiceEditor(context, service: service),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showServiceEditor(BuildContext context, {ServicePackage? service}) async {
    final state = context.read<AdminServicesBloc>().state;
    final name = TextEditingController(text: service?.name ?? '');
    final desc = TextEditingController(text: service?.description ?? '');
    final price = TextEditingController(
      text: service != null && service.price > 0 ? service.price.toStringAsFixed(0) : '',
    );
    String? selectedCategory = service?.category;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setS) => AlertDialog(
          title: Text(service == null ? 'Add Service' : 'Edit Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— None —')),
                    ...state.categories.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (v) => setS(() => selectedCategory = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (₹)',
                    hintText: 'Leave empty = contact for pricing',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: desc,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                Navigator.pop(dialogCtx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (save != true || !context.mounted) return;

    final next = ServicePackage(
      id: service?.id ?? '',
      name: name.text.trim(),
      description: desc.text.trim(),
      category: selectedCategory,
      price: double.tryParse(price.text.trim()) ?? 0,
      isActive: service?.isActive ?? true,
    );
    context.read<AdminServicesBloc>().add(ServicePackageSaved(next));
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onEdit});

  final ServicePackage service;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final priceText = service.price > 0
        ? '₹${service.price.toStringAsFixed(0)}'
        : 'Contact for pricing';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Expanded(child: Text(service.name, style: Theme.of(context).textTheme.titleMedium)),
                if (!service.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Inactive',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.muted)),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service.category != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(service.category!,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.adminAccent)),
                  ),
                if (service.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(service.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(priceText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: service.price > 0 ? AppColors.adminAccent : AppColors.muted,
                      )),
                ),
              ],
            ),
            isThreeLine: true,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Switch(
                value: service.isActive,
                onChanged: (v) => context
                    .read<AdminServicesBloc>()
                    .add(ServicePackageToggled(id: service.id, isActive: v)),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              if (!service.isActive)
                IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: () => _confirmDelete(context, service),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ServicePackage service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Service?'),
        content: Text(
          'Are you sure you want to delete "${service.name}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AdminServicesBloc>().add(ServicePackageDeleted(service.id));
    }
  }
}

class _AdminOrdersTab extends StatefulWidget {
  const _AdminOrdersTab();

  @override
  State<_AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<_AdminOrdersTab>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String? _statusFilter;
  String? _fulfillmentFilter;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    context.read<OrdersBloc>().add(OrdersLoaded(
          status: _statusFilter,
          fulfillmentStatus: _fulfillmentFilter,
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Payments',
      accent: AppColors.adminAccent,
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const PaymentApprovalsView(
                  accent: AppColors.adminAccent,
                  canDecide: true,
                ),
                _buildOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return BlocBuilder<PaymentApprovalsBloc, PaymentApprovalsState>(
      buildWhen: (p, c) =>
          p.pendingCount != c.pendingCount ||
          p.hasUnseenSubmission != c.hasUnseenSubmission,
      builder: (context, state) => TabBar(
        controller: _tabController,
        labelColor: AppColors.adminAccent,
        indicatorColor: AppColors.adminAccent,
        unselectedLabelColor: AppColors.muted,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Approvals'),
                if (state.pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${state.pendingCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Tab(text: 'Orders'),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return BlocListener<OrdersBloc, OrdersState>(
      listenWhen: (prev, curr) =>
          (curr.message != null && prev.message != curr.message) ||
          (curr.errorMessage != null && prev.errorMessage != curr.errorMessage),
      listener: (context, state) {
        final msg = state.message ?? state.errorMessage;
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: state.errorMessage != null ? AppColors.danger : null,
            ),
          );
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, phone…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _applyFilter,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _applyFilter(),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _statusFilter == null && _fulfillmentFilter == null,
                        onTap: () => setState(() {
                          _statusFilter = null;
                          _fulfillmentFilter = null;
                          _applyFilter();
                        }),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Awaiting Payment',
                        selected: _statusFilter == 'pending_payment',
                        onTap: () => setState(() {
                          _statusFilter = 'pending_payment';
                          _fulfillmentFilter = null;
                          _applyFilter();
                        }),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Awaiting Approval',
                        selected: _statusFilter == 'payment_submitted',
                        onTap: () => setState(() {
                          _statusFilter = 'payment_submitted';
                          _fulfillmentFilter = null;
                          _applyFilter();
                        }),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Paid — New',
                        selected: _statusFilter == 'paid' && _fulfillmentFilter == 'none',
                        onTap: () => setState(() {
                          _statusFilter = 'paid';
                          _fulfillmentFilter = 'none';
                          _applyFilter();
                        }),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Processing',
                        selected: _fulfillmentFilter == 'processing',
                        onTap: () => setState(() {
                          _statusFilter = 'paid';
                          _fulfillmentFilter = 'processing';
                          _applyFilter();
                        }),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Completed',
                        selected: _fulfillmentFilter == 'completed',
                        onTap: () => setState(() {
                          _statusFilter = 'paid';
                          _fulfillmentFilter = 'completed';
                          _applyFilter();
                        }),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Rejected',
                        selected: _statusFilter == 'rejected',
                        onTap: () => setState(() {
                          _statusFilter = 'rejected';
                          _fulfillmentFilter = null;
                          _applyFilter();
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<OrdersBloc, OrdersState>(
              builder: (context, state) {
                if (state.status == OrdersStatus.loading ||
                    state.status == OrdersStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == OrdersStatus.failure) {
                  return EmptyStateView(
                    title: 'Failed to load orders',
                    subtitle: state.errorMessage ?? 'Check your connection and try again.',
                  );
                }
                if (state.orders.isEmpty) {
                  return const EmptyStateView(
                    title: 'No orders found',
                    subtitle: 'Customer orders will appear here once received.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: state.orders.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OrderCard(order: state.orders[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.adminAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.adminAccent : Colors.grey.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.adminAccent : null,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: _statusColor(order.status).withValues(alpha: 0.15),
              child: Icon(_statusIcon(order.status), color: _statusColor(order.status), size: 20),
            ),
            title: Text(order.serviceName, style: Theme.of(context).textTheme.titleSmall),
            subtitle: Text('${order.customerName} • ${order.customerEmail}'),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${order.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                StatusPill(
                  label: order.status.label,
                  color: _statusColor(order.status),
                ),
              ],
            ),
          ),
          if (order.status == OrderPaymentStatus.paid)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  StatusPill(
                    label: order.fulfillmentStatus.label,
                    color: _fulfillmentColor(order.fulfillmentStatus),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showFulfillmentDialog(context, order),
                    child: const Text('Update'),
                  ),
                  TextButton(
                    onPressed: () => _showOrderDetail(context, order),
                    child: const Text('Details'),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  if (order.latestPaymentRequestStatus != null)
                    StatusPill(
                      label:
                          'Payment ${order.latestPaymentRequestStatus!.label}',
                      color: _requestColor(order.latestPaymentRequestStatus!),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showOrderDetail(context, order),
                    child: const Text('Details'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(OrderPaymentStatus s) {
    switch (s) {
      case OrderPaymentStatus.paid:
        return AppColors.positive;
      case OrderPaymentStatus.rejected:
        return AppColors.danger;
      case OrderPaymentStatus.cancelled:
      case OrderPaymentStatus.expired:
        return AppColors.muted;
      case OrderPaymentStatus.paymentSubmitted:
        return AppColors.adminAccent;
      case OrderPaymentStatus.pendingPayment:
        return AppColors.warning;
    }
  }

  Color _requestColor(PaymentRequestStatus s) {
    switch (s) {
      case PaymentRequestStatus.approved:
        return AppColors.positive;
      case PaymentRequestStatus.rejected:
        return AppColors.danger;
      case PaymentRequestStatus.pending:
        return AppColors.warning;
    }
  }

  IconData _statusIcon(OrderPaymentStatus s) {
    switch (s) {
      case OrderPaymentStatus.paid:
        return Icons.check_circle_outline;
      case OrderPaymentStatus.rejected:
        return Icons.cancel_outlined;
      case OrderPaymentStatus.paymentSubmitted:
        return Icons.hourglass_top_rounded;
      case OrderPaymentStatus.pendingPayment:
        return Icons.pending_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _fulfillmentColor(FulfillmentStatus s) {
    switch (s) {
      case FulfillmentStatus.completed:
        return AppColors.positive;
      case FulfillmentStatus.processing:
        return AppColors.adminAccent;
      case FulfillmentStatus.refundInitiated:
      case FulfillmentStatus.refunded:
        return AppColors.warning;
      case FulfillmentStatus.none:
        return AppColors.muted;
    }
  }

  void _showFulfillmentDialog(BuildContext context, ServiceOrder order) {
    String selectedStatus = order.fulfillmentStatus.apiValue == 'none'
        ? 'processing'
        : order.fulfillmentStatus.apiValue;
    final notesController = TextEditingController(text: order.adminNotes ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setS) => AlertDialog(
          title: const Text('Update Fulfillment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Fulfillment Status'),
                items: const [
                  DropdownMenuItem(value: 'processing', child: Text('Processing')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'refund_initiated', child: Text('Refund Initiated')),
                  DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                ],
                onChanged: (v) => setS(() => selectedStatus = v!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.read<OrdersBloc>().add(OrderFulfillmentUpdateRequested(
                      orderId: order.id,
                      fulfillmentStatus: selectedStatus,
                      adminNotes: notesController.text.trim().isNotEmpty
                          ? notesController.text.trim()
                          : null,
                    ));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context, ServiceOrder order) {
    context.read<OrdersBloc>().add(OrderDetailRequested(order.id));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<OrdersBloc>(),
        child: _OrderDetailSheet(orderId: order.id, initialOrder: order),
      ),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({required this.orderId, required this.initialOrder});

  final String orderId;
  final ServiceOrder initialOrder;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          final order = state.selectedOrder?.id == orderId
              ? state.selectedOrder!
              : initialOrder;

          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Order Details', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _DetailRow('Service', order.serviceName),
              _DetailRow('Amount', '₹${order.amount.toStringAsFixed(0)} ${order.currency}'),
              _DetailRow('Payment Status', order.status.label),
              if (order.paidAt != null)
                _DetailRow('Paid At', order.paidAt!.toLocal().toString().substring(0, 16)),
              const Divider(height: 24),
              Text('Customer', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _DetailRow('Name', order.customerName),
              _DetailRow('Email', order.customerEmail),
              if (order.customerPhone != null)
                _DetailRow('Phone', order.customerPhone!),
              if (order.notes != null && order.notes!.isNotEmpty)
                _DetailRow('Notes', order.notes!),
              const Divider(height: 24),
              Text('Fulfillment', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _DetailRow('Status', order.fulfillmentStatus.label),
              if (order.adminNotes != null && order.adminNotes!.isNotEmpty)
                _DetailRow('Admin Notes', order.adminNotes!),
              if (order.paymentRequests.isNotEmpty) ...[
                const Divider(height: 24),
                ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                      'Payment Requests (${order.paymentRequests.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  children: order.paymentRequests
                      .map((r) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.receipt_rounded,
                              color: statusColor(r.status),
                            ),
                            title: Text(r.referenceNumber),
                            subtitle: Text(
                              '${r.paymentMethod.label} • ${formatAmount(r.amountClaimed)}'
                              '${r.amountMatchesOrder ? '' : ' (amount mismatch)'}'
                              '${r.reviewNotes != null && r.reviewNotes!.isNotEmpty ? '\n${r.reviewNotes}' : ''}',
                            ),
                            isThreeLine: r.reviewNotes != null &&
                                r.reviewNotes!.isNotEmpty,
                            trailing: StatusPill(
                              label: r.status.label,
                              color: statusColor(r.status),
                            ),
                            onTap: () => showPaymentRequestSheet(
                              context,
                              request: r,
                              accent: AppColors.adminAccent,
                              canDecide: true,
                            ),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ApprovalCenterTab extends StatelessWidget {
  const _ApprovalCenterTab();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Approval Center',
      accent: AppColors.adminAccent,
      child: BlocBuilder<AdminServicesBloc, AdminServicesState>(
        builder: (context, state) {
          final approvals = state.approvals;
          if (approvals.isEmpty) {
            return const EmptyStateView(
              title: 'No approval requests',
              subtitle: 'Everything is already reviewed.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: approvals.length,
            itemBuilder: (context, index) {
              final request = approvals[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(request.title),
                    subtitle: Text(
                      '${request.reason}\nRequested by ${request.requestedBy} • Rs ${request.amount}',
                    ),
                    isThreeLine: true,
                    trailing: request.status == ApprovalStatus.pending
                        ? Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Approve',
                                onPressed: () => context.read<AdminServicesBloc>().add(
                                      ApprovalDecisionRequested(
                                        id: request.id,
                                        status: ApprovalStatus.approved,
                                      ),
                                    ),
                                icon: const Icon(Icons.check_circle_outline_rounded),
                              ),
                              IconButton(
                                tooltip: 'Reject',
                                onPressed: () => context.read<AdminServicesBloc>().add(
                                      ApprovalDecisionRequested(
                                        id: request.id,
                                        status: ApprovalStatus.rejected,
                                      ),
                                    ),
                                icon: const Icon(Icons.cancel_outlined),
                              ),
                            ],
                          )
                        : StatusPill(
                            label: request.status.label,
                            color: request.status == ApprovalStatus.approved
                                ? AppColors.positive
                                : AppColors.danger,
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reports & Analytics',
      accent: AppColors.adminAccent,
      child: BlocBuilder<AdminReportsBloc, AdminReportsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.status == AdminReportsStatus.failure && state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    child: Text(
                      'Failed to load reports: ${state.errorMessage}',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date Range Filters',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: state.fromDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now(),
                              );
                              if (date == null || !context.mounted) {
                                return;
                              }
                              context.read<AdminReportsBloc>().add(
                                    ReportDateRangeChanged(
                                      fromDate: date,
                                      toDate: state.toDate,
                                    ),
                                  );
                            },
                            icon: const Icon(Icons.date_range_rounded),
                            label: Text('From: ${DateFormat('dd MMM').format(state.fromDate)}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: state.toDate,
                                firstDate: state.fromDate,
                                lastDate: DateTime.now().add(const Duration(days: 1)),
                              );
                              if (date == null || !context.mounted) {
                                return;
                              }
                              context.read<AdminReportsBloc>().add(
                                    ReportDateRangeChanged(
                                      fromDate: state.fromDate,
                                      toDate: date,
                                    ),
                                  );
                            },
                            icon: const Icon(Icons.event_available_rounded),
                            label: Text('To: ${DateFormat('dd MMM').format(state.toDate)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<AdminReportsBloc>()
                          .add(const ReportExportRequested()),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Export Report'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue Records', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (state.records.isEmpty)
                      const Text('No records in selected range')
                    else
                      ...state.records.take(10).map(
                            (record) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.attach_money_rounded),
                              title: Text('Rs ${record.amount.toStringAsFixed(0)}'),
                              subtitle: Text(
                                '${DateFormat('dd MMM yyyy').format(record.date)} • ${record.source}',
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Generated Report History',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (state.exportHistory.isEmpty)
                      const Text('No exports generated yet')
                    else
                      ...state.exportHistory.map(
                        (file) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description_outlined),
                          title: Text(file),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminSettingsTab extends StatelessWidget {
  const _AdminSettingsTab({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      accent: AppColors.adminAccent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings_rounded)),
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: FilledButton.icon(
                onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline_rounded),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePasswordDialog(context),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: BlocBuilder<AdminReportsBloc, AdminReportsState>(
              builder: (context, state) {
                final toggles = state.permissionToggles;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Feature Permissions',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Control which features are enabled for your team',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ...toggles.entries.map(
                      (entry) => SwitchListTile(
                        title: Text(entry.key),
                        value: entry.value,
                        onChanged: (value) => context.read<AdminReportsBloc>().add(
                              ReportPermissionToggled(key: entry.key, value: value),
                            ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const SectionTitle(
            title: 'Notifications',
            subtitle: 'Alerts and updates for your admin account',
          ),
          const SizedBox(height: 8),
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state.notifications.isEmpty) {
                return const EmptyStateView(
                  title: 'All caught up',
                  subtitle: 'No new notifications at the moment.',
                );
              }
              return GlassCard(
                child: Column(
                  children: state.notifications
                      .map(
                        (notification) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(notification.title),
                          subtitle: Text(notification.body),
                          trailing: notification.isRead
                              ? null
                              : TextButton(
                                  onPressed: () => context
                                      .read<NotificationsBloc>()
                                      .add(NotificationMarkedRead(notification.id)),
                                  child: const Text('Mark read'),
                                ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPw = TextEditingController();
    final newPw = TextEditingController();
    final confirmPw = TextEditingController();
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return BlocListener<AuthBloc, AuthState>(
            listener: (ctx, state) {
              if (state.status == AuthStatus.unauthenticated) {
                Navigator.pop(dialogCtx);
              } else if (state.passwordChangeError != null) {
                setDialogState(() => localError = state.passwordChangeError);
              }
            },
            child: AlertDialog(
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPw,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      errorText: localError,
                    ),
                    onChanged: (_) {
                      if (localError != null) setDialogState(() => localError = null);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newPw,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPw,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm New Password'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (ctx, state) => FilledButton(
                    onPressed: state.status == AuthStatus.loading
                        ? null
                        : () {
                            if (newPw.text != confirmPw.text) {
                              setDialogState(() => localError = 'Passwords do not match.');
                              return;
                            }
                            if (newPw.text.length < 8) {
                              setDialogState(() =>
                                  localError = 'New password must be at least 8 characters.');
                              return;
                            }
                            ctx.read<AuthBloc>().add(AuthChangePasswordRequested(
                                  currentPassword: currentPw.text,
                                  newPassword: newPw.text,
                                ));
                          },
                    child: state.status == AuthStatus.loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
