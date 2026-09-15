import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/socket_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/ui_primitives.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/client_case.dart';
import '../../../domain/entities/cross_app_notification_event.dart';
import '../../../domain/entities/follow_up_task.dart';
import '../../../domain/entities/lead.dart';
import '../../../domain/entities/service_order.dart';
import '../../../domain/entities/support_call_request.dart';
import '../../../domain/entities/support_ticket.dart';
import '../../../injection_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/leads/leads_bloc.dart';
import '../../blocs/notifications/notifications_bloc.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../blocs/payment_approvals/payment_approvals_bloc.dart';
import '../../blocs/quotations/quotations_bloc.dart';
import '../../blocs/tasks/tasks_bloc.dart';
import 'sales_call_session_page.dart';
import '../account/delete_account_page.dart';
import '../community/community_moderation_page.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/payment_approvals_view.dart';
import '../../widgets/quotations_view.dart';
import '../../widgets/role_guard.dart';

class SalesShellPage extends StatefulWidget {
  const SalesShellPage({super.key, required this.user});

  final AppUser user;

  @override
  State<SalesShellPage> createState() => _SalesShellPageState();
}

class _SalesShellPageState extends State<SalesShellPage> {
  int _index = 0;
  bool _incomingDialogOpen = false;

  String get _salesMemberId => widget.user.id == 'u_sales_1' ? 'tm_1' : widget.user.id;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardLoaded(widget.user));
    context.read<LeadsBloc>().add(LeadsLoaded(userId: _salesMemberId));
    context.read<TasksBloc>().add(TasksLoaded(userId: _salesMemberId));
    context.read<NotificationsBloc>().add(const NotificationsLoaded(AppRole.sales));
    context.read<OrdersBloc>().add(const OrdersLoaded(status: 'paid', fulfillmentStatus: 'none'));
    context
        .read<PaymentApprovalsBloc>()
        .add(const PaymentApprovalsLoaded(status: 'pending'));
    // Reps work their own queue; `me` resolves server-side.
    context.read<QuotationsBloc>().add(const QuotationsLoaded(assignedTo: 'me'));
    _subscribeSocketCallEvents();
  }

  @override
  void dispose() {
    _unsubscribeSocketCallEvents();
    super.dispose();
  }

  void _subscribeSocketCallEvents() {
    final socket = sl<SocketService>();
    socket.onCallIncoming((data) {
      if (!mounted) return;
      _showIncomingCallDialog(_callFromSocket(data));
    });
    socket.onCallCancelled((data) {
      if (!mounted || !_incomingDialogOpen) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _incomingDialogOpen = false);
    });
    socket.onPaymentRequestSubmitted((payload) {
      if (!mounted) return;
      context
          .read<PaymentApprovalsBloc>()
          .add(PaymentApprovalSubmissionReceived(payload));
    });
    socket.onQuotationAssigned((payload) {
      if (!mounted) return;
      context.read<QuotationsBloc>().add(QuotationSubmissionReceived(payload));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New query assigned: ${payload['serviceName'] ?? 'a service'}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.salesAccent,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => _jumpTo(1),
          ),
        ),
      );
    });
  }

  void _unsubscribeSocketCallEvents() {
    final socket = sl<SocketService>();
    socket.offCallIncoming();
    socket.offCallCancelled();
    socket.offPaymentRequestSubmitted();
    socket.offQuotationAssigned();
  }

  SupportCallRequest _callFromSocket(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>?;
    final profile = user?['profile'] as Map<String, dynamic>?;
    final firstName = profile?['firstName'] as String? ?? '';
    final lastName = profile?['lastName'] as String? ?? '';
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    final displayName = fullName.isNotEmpty
        ? fullName
        : user?['name'] as String?
            ?? user?['email'] as String?
            ?? data['userName'] as String?
            ?? 'Unknown';
    return SupportCallRequest(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: displayName,
      userEmail: user?['email'] as String? ?? '',
      userPhone: profile?['phone'] as String? ?? user?['phone'] as String? ?? '',
      organization: data['organization'] as String? ?? '',
      targetTeam: data['targetTeam'] as String? ?? 'sales',
      type: (data['callType'] as String?) == 'video'
          ? SupportCallType.video
          : SupportCallType.voice,
      status: SupportCallStatus.ringing,
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? '') ?? DateTime.now(),
      message: data['message'] as String?,
    );
  }

  Future<void> _showIncomingCallDialog(SupportCallRequest call) async {
    setState(() => _incomingDialogOpen = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _IncomingCallDialog(
        call: call,
        onAccept: () {
          Navigator.of(context, rootNavigator: true).pop();
          setState(() => _incomingDialogOpen = false);
          context.read<LeadsBloc>().add(SupportCallUpdated(
                callId: call.id,
                status: SupportCallStatus.accepted,
                actorId: widget.user.id,
                actorName: widget.user.name,
              ));
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SalesCallSessionPage(
              call: call.copyWith(status: SupportCallStatus.accepted),
              actorId: widget.user.id,
              actorName: widget.user.name,
              socketService: sl<SocketService>(),
              agoraTokenUseCase: sl(),
            ),
          ));
        },
        onDecline: () {
          Navigator.of(context, rootNavigator: true).pop();
          setState(() => _incomingDialogOpen = false);
          context.read<LeadsBloc>().add(SupportCallUpdated(
                callId: call.id,
                status: SupportCallStatus.rejected,
                actorId: widget.user.id,
                actorName: widget.user.name,
              ));
        },
      ),
    );
    if (mounted) setState(() => _incomingDialogOpen = false);
  }

  static const int _quotationsTabIndex = 1;

  void _jumpTo(int newIndex) {
    setState(() => _index = newIndex);
    if (newIndex == _quotationsTabIndex) {
      context.read<QuotationsBloc>().add(const QuotationInboxSeen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _SalesDashboardTab(onJumpTo: _jumpTo),
      _SalesQuotationsTab(user: widget.user),
      const _LeadsTab(),
      const _TasksTab(),
      _CasesTab(userId: _salesMemberId),
      const _SalesOrdersTab(),
      _SalesProfileTab(user: widget.user),
    ];

    return RoleGuard(
      expectedRole: AppRole.sales,
      currentRole: widget.user.role,
      child: MultiBlocListener(
        listeners: [
          BlocListener<LeadsBloc, LeadsState>(
            listener: (context, state) {
              if (state.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message!),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
          ),
          BlocListener<TasksBloc, TasksState>(
            listener: (context, state) {
              if (state.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message!),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<LeadsBloc, LeadsState>(
          buildWhen: (prev, next) =>
              prev.supportCalls.length != next.supportCalls.length ||
              prev.supportCalls
                      .where((c) => c.status == SupportCallStatus.ringing)
                      .length !=
                  next.supportCalls
                      .where((c) => c.status == SupportCallStatus.ringing)
                      .length,
          builder: (context, leadsState) {
            final ringingCount = leadsState.supportCalls
                .where((c) => c.status == SupportCallStatus.ringing)
                .length;
            return LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 720;
                return Scaffold(
                  body: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF0FAFA),
                          AppColors.salesAccent.withValues(alpha: 0.08),
                          const Color(0xFFF3F7FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Ringing call banner — visible on any tab
                          if (ringingCount > 0)
                            _RingingBanner(
                              count: ringingCount,
                              onTap: () => _jumpTo(4),
                            ),
                          Expanded(
                            child: Row(
                              children: [
                                if (isTablet)
                                  NavigationRail(
                                    selectedIndex: _index,
                                    onDestinationSelected: _jumpTo,
                                    indicatorColor:
                                        AppColors.salesAccent.withValues(alpha: 0.2),
                                    labelType: NavigationRailLabelType.all,
                                    leading: Padding(
                                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                                      child: Text(
                                        'Sales',
                                        style: GoogleFonts.dmSerifDisplay(fontSize: 24),
                                      ),
                                    ),
                                    destinations: [
                                      const NavigationRailDestination(
                                          icon: Icon(Icons.dashboard_outlined),
                                          selectedIcon: Icon(Icons.dashboard_rounded),
                                          label: Text('Dashboard')),
                                      const NavigationRailDestination(
                                          icon: _QuotationBadge(
                                              child: Icon(
                                                  Icons.request_quote_outlined)),
                                          selectedIcon: _QuotationBadge(
                                              child: Icon(
                                                  Icons.request_quote_rounded)),
                                          label: Text('Quotations')),
                                      const NavigationRailDestination(
                                          icon: Icon(Icons.people_outline_rounded),
                                          selectedIcon: Icon(Icons.people_rounded),
                                          label: Text('Leads')),
                                      const NavigationRailDestination(
                                          icon: Icon(Icons.checklist_rtl_outlined),
                                          selectedIcon: Icon(Icons.checklist_rtl_rounded),
                                          label: Text('Tasks')),
                                      NavigationRailDestination(
                                          icon: Badge(
                                            isLabelVisible: ringingCount > 0,
                                            label: Text('$ringingCount'),
                                            child: const Icon(Icons.folder_open_outlined),
                                          ),
                                          selectedIcon: Badge(
                                            isLabelVisible: ringingCount > 0,
                                            label: Text('$ringingCount'),
                                            child: const Icon(Icons.folder_open_rounded),
                                          ),
                                          label: const Text('Cases')),
                                      const NavigationRailDestination(
                                          icon: Icon(Icons.receipt_long_outlined),
                                          selectedIcon: Icon(Icons.receipt_long_rounded),
                                          label: Text('Orders')),
                                      const NavigationRailDestination(
                                          icon: Icon(Icons.person_outline_rounded),
                                          selectedIcon: Icon(Icons.person_rounded),
                                          label: Text('Profile')),
                                    ],
                                  ),
                                Expanded(
                                  child: IndexedStack(index: _index, children: tabs),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  bottomNavigationBar: isTablet
                      ? null
                      : NavigationBar(
                          selectedIndex: _index,
                          onDestinationSelected: _jumpTo,
                          destinations: [
                            const NavigationDestination(
                                icon: Icon(Icons.dashboard_outlined), label: 'Home'),
                            const NavigationDestination(
                                icon: _QuotationBadge(
                                    child: Icon(Icons.request_quote_outlined)),
                                label: 'Quotes'),
                            const NavigationDestination(
                                icon: Icon(Icons.people_outline_rounded), label: 'Leads'),
                            const NavigationDestination(
                                icon: Icon(Icons.checklist_rtl_outlined), label: 'Tasks'),
                            NavigationDestination(
                              icon: Badge(
                                isLabelVisible: ringingCount > 0,
                                label: Text('$ringingCount'),
                                child: const Icon(Icons.folder_open_outlined),
                              ),
                              label: 'Cases',
                            ),
                            const NavigationDestination(
                                icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
                            const NavigationDestination(
                                icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
                          ],
                        ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SalesDashboardTab extends StatelessWidget {
  const _SalesDashboardTab({required this.onJumpTo});

  final ValueChanged<int> onJumpTo;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      accent: AppColors.salesAccent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state.status == DashboardStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.salesSummary == null) {
                return const EmptyStateView(
                  title: 'No dashboard metrics yet',
                  subtitle: 'Try refreshing once leads and tasks are available.',
                );
              }
              final summary = state.salesSummary!;
              return GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 760 ? 4 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  MetricCard(
                    label: 'Assigned Leads',
                    value: summary.assignedLeads.toString(),
                    icon: Icons.group_rounded,
                    color: AppColors.salesAccent,
                  ),
                  MetricCard(
                    label: 'Today Follow-ups',
                    value: summary.todayFollowUps.toString(),
                    icon: Icons.today_rounded,
                    color: AppColors.adminAccent,
                  ),
                  MetricCard(
                    label: 'Conversions This Month',
                    value: summary.monthlyConversions.toString(),
                    icon: Icons.trending_up_rounded,
                    color: AppColors.positive,
                  ),
                  MetricCard(
                    label: 'Pending Documents',
                    value: summary.pendingDocuments.toString(),
                    icon: Icons.description_rounded,
                    color: AppColors.warning,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const SectionTitle(
            title: 'Quick Actions',
            subtitle: 'Jump to the most common tasks',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => onJumpTo(2),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add Lead'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.adminAccent,
                ),
                onPressed: () => onJumpTo(3),
                icon: const Icon(Icons.checklist_rtl_rounded),
                label: const Text('My Tasks'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.salesAccentDeep,
                ),
                onPressed: () => onJumpTo(4),
                icon: const Icon(Icons.folder_copy_rounded),
                label: const Text('Cases & Support'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CommunityModerationPage(),
                  ),
                ),
                icon: const Icon(Icons.forum_rounded),
                label: const Text('Community'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionTitle(
            title: 'Recent Activity',
            subtitle: 'Your latest actions and updates',
          ),
          const SizedBox(height: 10),
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              final items = state.salesSummary?.recentActivity ?? [];
              return GlassCard(
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      StaggerItem(
                        index: i,
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                AppColors.salesAccent.withValues(alpha: 0.18),
                            child: Icon(Icons.bolt_rounded,
                                size: 16, color: AppColors.salesAccentDeep),
                          ),
                          title: Text(items[i]),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Counts `quotation:assigned` events since the rep last opened the tab.
class _QuotationBadge extends StatelessWidget {
  const _QuotationBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuotationsBloc, QuotationsState>(
      buildWhen: (p, c) => p.unseenCount != c.unseenCount,
      builder: (context, state) => Badge(
        isLabelVisible: state.unseenCount > 0,
        label: Text('${state.unseenCount}'),
        child: child,
      ),
    );
  }
}

class _SalesQuotationsTab extends StatelessWidget {
  const _SalesQuotationsTab({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Quotations',
      accent: AppColors.salesAccent,
      child: QuotationsView(
        accent: AppColors.salesAccent,
        // Assigning is ADMIN-only; the server rejects a SALES caller with 403.
        canAssign: false,
        currentUserId: user.id,
      ),
    );
  }
}

class _LeadsTab extends StatefulWidget {
  const _LeadsTab();

  @override
  State<_LeadsTab> createState() => _LeadsTabState();
}

class _LeadsTabState extends State<_LeadsTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Leads',
      accent: AppColors.salesAccent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-add-lead',
        onPressed: () => _showLeadEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Lead'),
      ),
      child: BlocBuilder<LeadsBloc, LeadsState>(
        builder: (context, state) {
          if (state.status == LeadsStatus.loading && state.visibleLeads.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            context.read<LeadsBloc>().add(LeadSearchChanged(value)),
                        decoration: const InputDecoration(
                          hintText: 'Search by organization or contact...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PopupMenuButton<LeadStatus?>(
                      tooltip: 'Filter status',
                      onSelected: (status) =>
                          context.read<LeadsBloc>().add(LeadFilterChanged(status)),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: null, child: Text('All Statuses')),
                        ...LeadStatus.values.map(
                          (status) => PopupMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        ),
                      ],
                      child: const Icon(Icons.filter_alt_rounded),
                    ),
                    IconButton(
                      tooltip: 'Toggle Sort',
                      onPressed: () => context
                          .read<LeadsBloc>()
                          .add(LeadSortToggled(!state.sortNewestFirst)),
                      icon: Icon(
                        state.sortNewestFirst
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('User App Leads'),
                      selected: state.sourceFilter == LeadSource.userApp,
                      onSelected: (selected) {
                        context.read<LeadsBloc>().add(
                              LeadSourceFilterChanged(
                                selected ? LeadSource.userApp : null,
                              ),
                            );
                      },
                    ),
                    if (state.sourceFilter != null)
                      ActionChip(
                        label: const Text('Clear Source Filter'),
                        onPressed: () =>
                            context.read<LeadsBloc>().add(const LeadSourceFilterChanged(null)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: state.visibleLeads.isEmpty
                    ? const EmptyStateView(
                        title: 'No leads found',
                        subtitle: 'Try changing search/filter or add a new lead.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.visibleLeads.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final lead = state.visibleLeads[index];
                          return StaggerItem(
                            index: index,
                            child: GlassCard(
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(lead.organization),
                                    subtitle: Text(
                                      '${lead.contactName} • ${lead.email}'
                                      '${lead.serviceName == null ? '' : '\nService: ${lead.serviceName}'}',
                                    ),
                                    isThreeLine: lead.serviceName != null,
                                    trailing: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        StatusPill(
                                          label: lead.status.label,
                                          color: _leadColor(lead.status),
                                        ),
                                        const SizedBox(height: 6),
                                        _LeadSourceBadge(source: lead.source),
                                        // Set when the lead came in through a
                                        // client's quotation request.
                                        if (lead.quotationReference != null &&
                                            lead.quotationReference!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            lead.quotationReference!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _showLeadEditor(context, lead: lead),
                                        icon: const Icon(Icons.edit_rounded),
                                        label: const Text('Edit'),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => _LeadDetailPage(leadId: lead.id),
                                          ),
                                        ),
                                        icon: const Icon(Icons.open_in_new_rounded),
                                        label: const Text('Details'),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () => context
                                            .read<LeadsBloc>()
                                            .add(LeadDeleted(lead.id)),
                                        icon: const Icon(Icons.delete_outline_rounded),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showLeadEditor(BuildContext context, {Lead? lead}) async {
    final org = TextEditingController(text: lead?.organization ?? '');
    final contact = TextEditingController(text: lead?.contactName ?? '');
    final phone = TextEditingController(text: lead?.phone ?? '');
    final email = TextEditingController(text: lead?.email ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lead == null ? 'Add Lead' : 'Edit Lead'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: org, decoration: const InputDecoration(labelText: 'Organization')),
              const SizedBox(height: 10),
              TextField(controller: contact, decoration: const InputDecoration(labelText: 'Contact Name')),
              const SizedBox(height: 10),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 10),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (result != true) {
      return;
    }

    final existing = lead;
    final updated = Lead(
      id: existing?.id ?? '',
      organization: org.text.trim(),
      contactName: contact.text.trim(),
      phone: phone.text.trim(),
      email: email.text.trim(),
      status: existing?.status ?? LeadStatus.newLead,
      createdAt: existing?.createdAt ?? DateTime.now(),
      assignedToUserId: existing?.assignedToUserId,
      notes: existing?.notes ?? const [],
      activity: existing?.activity ?? const [],
    );

    if (!context.mounted) {
      return;
    }
    context.read<LeadsBloc>().add(LeadSaved(updated));
  }

  Color _leadColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return AppColors.muted;
      case LeadStatus.contacted:
        return AppColors.adminAccent;
      case LeadStatus.qualified:
        return AppColors.salesAccent;
      case LeadStatus.proposalSent:
        return AppColors.warning;
      case LeadStatus.won:
        return AppColors.positive;
      case LeadStatus.lost:
        return AppColors.danger;
    }
  }
}

class _LeadDetailPage extends StatefulWidget {
  const _LeadDetailPage({required this.leadId});

  final String leadId;

  @override
  State<_LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<_LeadDetailPage> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Lead Detail',
      child: BlocBuilder<LeadsBloc, LeadsState>(
        builder: (context, state) {
          final lead = state.allLeads.firstWhere((e) => e.id == widget.leadId);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lead.organization,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('${lead.contactName} • ${lead.phone}'),
                    Text(lead.email),
                    if (lead.quotationReference != null &&
                        lead.quotationReference!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.request_quote_outlined,
                              size: 14, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Text(
                            'Quotation ${lead.quotationReference}',
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ],
                    if (lead.assignedToName != null &&
                        lead.assignedToName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_pin_rounded,
                              size: 14, color: AppColors.positive),
                          const SizedBox(width: 6),
                          Text(
                            'Assigned to ${lead.assignedToName}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.positive,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: LeadStatus.values
                          .map(
                            (status) => ChoiceChip(
                              label: Text(status.label),
                              selected: lead.status == status,
                              onSelected: (_) => context.read<LeadsBloc>().add(
                                    LeadStatusUpdated(leadId: lead.id, status: status),
                                  ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              if (lead.userId != null || lead.userAppContext.isNotEmpty) ...[
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User App Context', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.account_circle_outlined),
                        title: Text(lead.userName ?? lead.contactName),
                        subtitle: Text(
                          '${lead.userEmail ?? lead.email} • ${lead.userPhone ?? lead.phone}',
                        ),
                      ),
                      if (lead.serviceName != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.miscellaneous_services_outlined),
                          title: Text(lead.serviceName!),
                          subtitle: Text('Source: ${lead.source.label}'),
                        ),
                      if (lead.userAppContext.isNotEmpty)
                        ...lead.userAppContext.take(4).map(
                              (entry) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: const Icon(Icons.subdirectory_arrow_right_rounded),
                                title: Text(entry),
                              ),
                            ),
                      if (state.queuedNotificationEvents
                          .where((event) => event.leadId == lead.id)
                          .isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Queued user updates: ${state.queuedNotificationEvents.where((event) => event.leadId == lead.id).length}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.adminAccent),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes Timeline', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (lead.notes.isEmpty)
                      const Text('No notes added yet.')
                    else
                      for (final note in lead.notes)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.note_alt_outlined),
                          title: Text(note.message),
                          subtitle: Text(AppDateUtils.full.format(note.createdAt)),
                        ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Add a note...',
                        suffixIcon: IconButton(
                          onPressed: () {
                            if (_noteController.text.trim().isEmpty) {
                              return;
                            }
                            context.read<LeadsBloc>().add(
                                  LeadNoteAdded(
                                    leadId: lead.id,
                                    note: _noteController.text.trim(),
                                  ),
                                );
                            _noteController.clear();
                          },
                          icon: const Icon(Icons.send_rounded),
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
                    Text('Activity History', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final log in lead.activity)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.timeline_rounded),
                        title: Text(log),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (date == null || !context.mounted) {
                          return;
                        }
                        context.read<LeadsBloc>().add(
                              LeadFollowUpScheduled(
                                leadId: lead.id,
                                title: 'Follow up with ${lead.organization}',
                                dueDate: date,
                              ),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Follow-up scheduled')),
                        );
                      },
                      icon: const Icon(Icons.event_available_rounded),
                      label: const Text('Schedule Follow-up'),
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

class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Tasks',
      accent: AppColors.salesAccent,
      child: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) {
          if (state.status == TasksStatus.loading && state.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.tasks.isEmpty) {
            return const EmptyStateView(
              title: 'No follow-ups scheduled',
              subtitle:
                  'Open a lead, scroll to the Activity section, and tap "Schedule Follow-up" to add one here.',
            );
          }

          final grouped = <String, List<FollowUpTask>>{};
          for (final task in state.tasks) {
            final key = AppDateUtils.weekday.format(task.dueDate);
            grouped.putIfAbsent(key, () => []).add(task);
          }

          final entries = grouped.entries.toList()
            ..sort((a, b) => a.value.first.dueDate.compareTo(b.value.first.dueDate));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, sectionIndex) {
              final section = entries[sectionIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.key, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      for (final task in section.value)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(task.title),
                          subtitle: Text(task.status.label),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                tooltip: 'Complete',
                                onPressed: () => context
                                    .read<TasksBloc>()
                                    .add(TaskCompleted(task.id)),
                                icon: const Icon(Icons.check_circle_outline_rounded),
                              ),
                              IconButton(
                                tooltip: 'Reschedule',
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime.now(),
                                    lastDate:
                                        DateTime.now().add(const Duration(days: 365)),
                                    initialDate: task.dueDate,
                                  );
                                  if (date == null || !context.mounted) {
                                    return;
                                  }
                                  context
                                      .read<TasksBloc>()
                                      .add(TaskRescheduled(taskId: task.id, newDate: date));
                                },
                                icon: const Icon(Icons.calendar_month_rounded),
                              ),
                            ],
                          ),
                        ),
                    ],
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

class _CasesTab extends StatelessWidget {
  const _CasesTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cases & Support',
      accent: AppColors.salesAccent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-new-case',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _CaseWizardPage(userId: userId),
          ),
        ),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Case'),
      ),
      child: BlocBuilder<LeadsBloc, LeadsState>(
        builder: (context, state) {
          final ringingCalls = state.supportCalls
              .where((c) => c.status == SupportCallStatus.ringing)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionTitle(
                title: 'Support Calls',
                subtitle: ringingCalls.isNotEmpty
                    ? '${ringingCalls.length} incoming — answer now'
                    : 'Incoming voice & video calls from users',
              ),
              const SizedBox(height: 8),
              if (state.supportCalls.isEmpty)
                const EmptyStateView(
                  title: 'No active calls',
                  subtitle: 'Voice and video call requests from users will appear here.',
                )
              else
                ...state.supportCalls.map(
                  (call) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: call.status == SupportCallStatus.ringing
                                  ? AppColors.danger.withValues(alpha: 0.14)
                                  : AppColors.adminAccent.withValues(alpha: 0.14),
                              child: Icon(
                                call.type == SupportCallType.video
                                    ? Icons.videocam_rounded
                                    : Icons.call_rounded,
                                color: call.status == SupportCallStatus.ringing
                                    ? AppColors.danger
                                    : AppColors.adminAccent,
                              ),
                            ),
                            title: Text(
                              call.userName.isNotEmpty ? call.userName : 'Unknown Caller',
                            ),
                            subtitle: Text(
                              '${call.type == SupportCallType.video ? 'Video' : 'Voice'} call'
                              '${call.organization.isNotEmpty ? ' • ${call.organization}' : ''}'
                              '\n${call.userPhone.isNotEmpty ? call.userPhone : call.userEmail}',
                            ),
                            isThreeLine: true,
                            trailing: StatusPill(
                              label: call.status.label,
                              color: _supportCallStatusColor(call.status),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (call.status == SupportCallStatus.ringing)
                                FilledButton.icon(
                                  onPressed: () {
                                    context.read<LeadsBloc>().add(
                                          SupportCallUpdated(
                                            callId: call.id,
                                            status: SupportCallStatus.accepted,
                                            actorId: userId,
                                            actorName: 'Sales Team',
                                          ),
                                        );
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SalesCallSessionPage(
                                          call: call,
                                          actorId: userId,
                                          actorName: 'Sales Team',
                                          socketService: sl<SocketService>(),
                                          agoraTokenUseCase: sl(),
                                        ),
                                      ),
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.positive,
                                  ),
                                  icon: const Icon(Icons.call_rounded),
                                  label: const Text('Answer'),
                                ),
                              if (call.status == SupportCallStatus.ringing)
                                OutlinedButton.icon(
                                  onPressed: () => context.read<LeadsBloc>().add(
                                        SupportCallUpdated(
                                          callId: call.id,
                                          status: SupportCallStatus.rejected,
                                          actorId: userId,
                                          actorName: 'Sales Team',
                                        ),
                                      ),
                                  icon: const Icon(Icons.call_end_rounded),
                                  label: const Text('Decline'),
                                ),
                              if (call.status == SupportCallStatus.accepted)
                                FilledButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SalesCallSessionPage(
                                        call: call,
                                        actorId: userId,
                                        actorName: 'Sales Team',
                                        socketService: sl<SocketService>(),
                                        agoraTokenUseCase: sl(),
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.call_rounded),
                                  label: const Text('Rejoin'),
                                ),
                              if (call.status == SupportCallStatus.accepted)
                                OutlinedButton.icon(
                                  onPressed: () => context.read<LeadsBloc>().add(
                                        SupportCallUpdated(
                                          callId: call.id,
                                          status: SupportCallStatus.ended,
                                          actorId: userId,
                                          actorName: 'Sales Team',
                                        ),
                                      ),
                                  icon: const Icon(Icons.stop_circle_outlined),
                                  label: const Text('End Call'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const SectionTitle(
                title: 'Support Tickets',
                subtitle: 'Text-based support requests assigned to you by admin',
              ),
              const SizedBox(height: 8),
              if (state.supportTickets.isEmpty)
                const EmptyStateView(
                  title: 'No tickets assigned',
                  subtitle: 'When admin assigns support tickets to you, they will appear here.',
                )
              else
                ...state.supportTickets.map(
                  (ticket) => Padding(
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
                              color: _supportStatusColor(ticket.status),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => context.read<LeadsBloc>().add(
                                      SupportTicketUpdated(
                                        ticketId: ticket.id,
                                        status: SupportTicketStatus.inProgress,
                                        actor: 'Sales Team',
                                        message: 'Picked by sales',
                                      ),
                                    ),
                                child: const Text('Work On It'),
                              ),
                              OutlinedButton(
                                onPressed: () => context.read<LeadsBloc>().add(
                                      SupportTicketUpdated(
                                        ticketId: ticket.id,
                                        status: SupportTicketStatus.waitingForUser,
                                        actor: 'Sales Team',
                                        message: 'Waiting for user confirmation',
                                      ),
                                    ),
                                child: const Text('Awaiting Reply'),
                              ),
                              FilledButton(
                                onPressed: () => context.read<LeadsBloc>().add(
                                      SupportTicketUpdated(
                                        ticketId: ticket.id,
                                        status: SupportTicketStatus.resolved,
                                        actor: 'Sales Team',
                                        message: 'Issue resolved',
                                      ),
                                    ),
                                child: const Text('Mark Resolved'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const SectionTitle(
                title: 'Onboarding Cases',
                subtitle: 'Track client document submission and review progress',
              ),
              const SizedBox(height: 8),
              if (state.cases.isEmpty)
                const EmptyStateView(
                  title: 'No cases yet',
                  subtitle: 'Tap "New Case" to start onboarding a client.',
                )
              else
                ...state.cases.map(
                  (clientCase) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.folder_shared_rounded),
                            title: Text(clientCase.organizationName),
                            subtitle: Text(
                              'Services: ${clientCase.selectedServiceIds.length} • '
                              '${AppDateUtils.full.format(clientCase.submittedAt)}',
                            ),
                            trailing: StatusPill(
                              label: clientCase.status.label,
                              color: AppColors.adminAccent,
                            ),
                          ),
                          if (clientCase.documentRequests.isNotEmpty)
                            Text(
                              'Latest doc request: Round ${clientCase.documentRequests.first.round}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.warning),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showDocumentRequestDialog(context, clientCase),
                                icon: const Icon(Icons.description_outlined),
                                label: const Text('Request Docs'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () => context.read<LeadsBloc>().add(
                                      CaseStatusSynced(
                                        caseId: clientCase.id,
                                        targetStatus: UserCaseStatus.approved,
                                        updatedBy: 'Sales Team',
                                      ),
                                    ),
                                icon: const Icon(Icons.verified_rounded),
                                label: const Text('Mark Review Complete'),
                              ),
                              FilledButton.icon(
                                onPressed: clientCase.userId == null
                                    ? null
                                    : () {
                                        context.read<LeadsBloc>().add(
                                              UserNotificationQueued(
                                                CrossAppNotificationEvent(
                                                  id: 'evt_${DateTime.now().microsecondsSinceEpoch}',
                                                  userId: clientCase.userId!,
                                                  title: 'Case update from sales team',
                                                  body:
                                                      'Your case ${clientCase.organizationName} is ${clientCase.status.label}.',
                                                  createdAt: DateTime.now(),
                                                  event: ConnectivityEventName.userNotificationQueued,
                                                  caseId: clientCase.id,
                                                ),
                                              ),
                                            );
                                      },
                                icon: const Icon(Icons.campaign_outlined),
                                label: const Text('Send Update'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDocumentRequestDialog(BuildContext context, ClientCase clientCase) async {
    final docsController = TextEditingController(
      text: 'Registration Certificate, Latest audited statement',
    );
    final reasonController = TextEditingController(
      text: 'Please provide clearer supporting documents for verification.',
    );
    DateTime? dueDate;

    final send = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Additional Documents'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: docsController,
                  decoration: const InputDecoration(
                    labelText: 'Documents (comma separated)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 3)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 45)),
                    );
                    if (date == null) {
                      return;
                    }
                    setState(() => dueDate = date);
                  },
                  icon: const Icon(Icons.event_note_rounded),
                  label: Text(
                    dueDate == null
                        ? 'Set Due Date (Optional)'
                        : 'Due: ${AppDateUtils.full.format(dueDate!)}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );

    if (send != true || !context.mounted) {
      return;
    }

    final docs = docsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one document.')),
      );
      return;
    }

    context.read<LeadsBloc>().add(
          DocumentRequested(
            caseId: clientCase.id,
            documents: docs,
            reason: reasonController.text.trim(),
            dueDate: dueDate,
            requestedBy: 'Sales Team',
          ),
        );
  }

  Color _supportStatusColor(SupportTicketStatus status) {
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

  Color _supportCallStatusColor(SupportCallStatus status) {
    switch (status) {
      case SupportCallStatus.ringing:
        return AppColors.warning;
      case SupportCallStatus.accepted:
        return AppColors.positive;
      case SupportCallStatus.rejected:
        return AppColors.danger;
      case SupportCallStatus.ended:
        return AppColors.muted;
    }
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

class _RingingBanner extends StatelessWidget {
  const _RingingBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.danger,
        child: Row(
          children: [
            const Icon(Icons.call_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                count == 1
                    ? 'Incoming call — tap to answer'
                    : '$count incoming calls — tap to view',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _IncomingCallDialog extends StatelessWidget {
  const _IncomingCallDialog({
    required this.call,
    required this.onAccept,
    required this.onDecline,
  });

  final SupportCallRequest call;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final isVideo = call.type == SupportCallType.video;
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.salesAccent.withValues(alpha: 0.24),
            child: Text(
              call.userName.isNotEmpty ? call.userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            call.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Incoming ${isVideo ? 'video' : 'voice'} call',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallActionButton(
                icon: Icons.call_end_rounded,
                color: AppColors.danger,
                label: 'Decline',
                onTap: onDecline,
              ),
              _CallActionButton(
                icon: Icons.call_rounded,
                color: AppColors.positive,
                label: 'Accept',
                onTap: onAccept,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _CaseWizardPage extends StatefulWidget {
  const _CaseWizardPage({required this.userId});

  final String userId;

  @override
  State<_CaseWizardPage> createState() => _CaseWizardPageState();
}

class _CaseWizardPageState extends State<_CaseWizardPage> {
  final _orgController = TextEditingController();
  final _contactController = TextEditingController();

  int _step = 0;
  final List<String> _services = [];
  final Map<String, bool> _docs = {
    'PAN Card': false,
    'Registration Certificate': false,
    'Board Resolution': false,
    'Address Proof': false,
  };

  @override
  void dispose() {
    _orgController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'New Client Case',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Stepper(
            physics: const NeverScrollableScrollPhysics(),
            currentStep: _step,
            onStepCancel: _step == 0 ? null : () => setState(() => _step--),
            onStepContinue: () {
              if (_step < 3) {
                setState(() => _step++);
                return;
              }
              final clientCase = ClientCase(
                id: '',
                organizationName: _orgController.text.trim(),
                selectedServiceIds: _services,
                documentChecklist: _docs,
                submittedAt: DateTime.now(),
                createdByUserId: widget.userId,
              );
              context.read<LeadsBloc>().add(ClientCaseSubmitted(clientCase));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Case submitted successfully')),
              );
              Navigator.of(context).pop();
            },
            steps: [
              Step(
                title: const Text('Basic Organization Details'),
                content: Column(
                  children: [
                    TextField(
                      controller: _orgController,
                      decoration: const InputDecoration(labelText: 'Organization Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _contactController,
                      decoration: const InputDecoration(labelText: 'Primary Contact'),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Service / Package Selection'),
                content: Column(
                  children: [
                    for (final option in const [
                      'Registration Essentials',
                      'Fundraising Accelerator',
                      'Impact Reporting Suite',
                    ])
                      CheckboxListTile(
                        value: _services.contains(option),
                        title: Text(option),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _services.add(option);
                            } else {
                              _services.remove(option);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              Step(
                title: const Text('Document Checklist'),
                content: Column(
                  children: _docs.entries
                      .map(
                        (entry) => SwitchListTile(
                          value: entry.value,
                          title: Text(entry.key),
                          subtitle: const Text('Marked as uploaded'),
                          onChanged: (value) {
                            setState(() {
                              _docs[entry.key] = value;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              Step(
                title: const Text('Review + Submit'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Organization: ${_orgController.text}'),
                    Text('Contact: ${_contactController.text}'),
                    Text('Selected services: ${_services.join(', ')}'),
                    Text('Uploaded docs: ${_docs.values.where((e) => e).length}/${_docs.length}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Orders and their payment approvals only settle business that was already
/// in flight at the quotation cutover. Nothing new lands here.
class _LegacyOrdersNotice extends StatelessWidget {
  const _LegacyOrdersNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.history_rounded, size: 16, color: AppColors.warning),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Legacy — orders placed before the quotation cutover. New '
                'business comes in through Quotations.',
                style: TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesOrdersTab extends StatefulWidget {
  const _SalesOrdersTab();

  @override
  State<_SalesOrdersTab> createState() => _SalesOrdersTabState();
}

class _SalesOrdersTabState extends State<_SalesOrdersTab>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String? _statusFilter = 'paid';
  String? _fulfillmentFilter = 'none';
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
      title: 'Legacy orders',
      accent: AppColors.salesAccent,
      child: Column(
        children: [
          const _LegacyOrdersNotice(),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.salesAccent,
            indicatorColor: AppColors.salesAccent,
            unselectedLabelColor: AppColors.muted,
            tabs: const [
              Tab(text: 'Orders'),
              Tab(text: 'Payment Approvals'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(),
                const PaymentApprovalsView(
                  accent: AppColors.salesAccent,
                  canDecide: false,
                ),
              ],
            ),
          ),
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
              behavior: SnackBarBehavior.floating,
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
                      _SalesOrderFilter(
                        label: 'New (Paid)',
                        selected: _statusFilter == 'paid' && _fulfillmentFilter == 'none',
                        onTap: () => setState(() {
                          _statusFilter = 'paid';
                          _fulfillmentFilter = 'none';
                          _applyFilter();
                        }),
                      ),
                      const SizedBox(width: 6),
                      _SalesOrderFilter(
                        label: 'Processing',
                        selected: _fulfillmentFilter == 'processing',
                        onTap: () => setState(() {
                          _statusFilter = 'paid';
                          _fulfillmentFilter = 'processing';
                          _applyFilter();
                        }),
                      ),
                      const SizedBox(width: 6),
                      _SalesOrderFilter(
                        label: 'Completed',
                        selected: _fulfillmentFilter == 'completed',
                        onTap: () => setState(() {
                          _statusFilter = 'paid';
                          _fulfillmentFilter = 'completed';
                          _applyFilter();
                        }),
                      ),
                      const SizedBox(width: 6),
                      _SalesOrderFilter(
                        label: 'Awaiting Approval',
                        selected: _statusFilter == 'payment_submitted',
                        onTap: () => setState(() {
                          _statusFilter = 'payment_submitted';
                          _fulfillmentFilter = null;
                          _applyFilter();
                        }),
                      ),
                      const SizedBox(width: 6),
                      _SalesOrderFilter(
                        label: 'All',
                        selected: _statusFilter == null,
                        onTap: () => setState(() {
                          _statusFilter = null;
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
                if (state.status == OrdersStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.orders.isEmpty) {
                  return const EmptyStateView(
                    title: 'No orders found',
                    subtitle: 'Paid orders requiring action will appear here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: state.orders.length,
                  itemBuilder: (context, index) {
                    final order = state.orders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SalesOrderCard(order: order),
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

class _SalesOrderFilter extends StatelessWidget {
  const _SalesOrderFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
              ? AppColors.salesAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.salesAccent : Colors.grey.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.salesAccent : null,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
        ),
      ),
    );
  }
}

class _SalesOrderCard extends StatelessWidget {
  const _SalesOrderCard({required this.order});

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
              backgroundColor: AppColors.salesAccent.withValues(alpha: 0.15),
              child: const Icon(Icons.receipt_long_rounded, size: 20),
            ),
            title: Text(order.serviceName,
                style: Theme.of(context).textTheme.titleSmall),
            subtitle: Text('${order.customerName} • ${order.customerEmail}'),
            trailing: Text(
              '₹${order.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: [
              StatusPill(
                label: order.status == OrderPaymentStatus.paid
                    ? order.fulfillmentStatus.label
                    : order.status.label,
                color: order.status == OrderPaymentStatus.paid
                    ? _fulfillmentColor(order.fulfillmentStatus)
                    : _orderStatusColor(order.status),
              ),
              const Spacer(),
              if (order.status == OrderPaymentStatus.paid)
                TextButton(
                  onPressed: () => _showFulfillmentDialog(context, order),
                  child: const Text('Update'),
                ),
              TextButton(
                onPressed: () => _showDetail(context, order),
                child: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _fulfillmentColor(FulfillmentStatus s) {
    switch (s) {
      case FulfillmentStatus.completed:
        return AppColors.positive;
      case FulfillmentStatus.processing:
        return AppColors.salesAccent;
      case FulfillmentStatus.refundInitiated:
      case FulfillmentStatus.refunded:
        return AppColors.warning;
      case FulfillmentStatus.none:
        return AppColors.muted;
    }
  }

  Color _orderStatusColor(OrderPaymentStatus s) {
    switch (s) {
      case OrderPaymentStatus.paid:
        return AppColors.positive;
      case OrderPaymentStatus.rejected:
        return AppColors.danger;
      case OrderPaymentStatus.cancelled:
      case OrderPaymentStatus.expired:
        return AppColors.muted;
      case OrderPaymentStatus.paymentSubmitted:
        return AppColors.salesAccent;
      case OrderPaymentStatus.pendingPayment:
        return AppColors.warning;
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
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
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

  void _showDetail(BuildContext context, ServiceOrder order) {
    context.read<OrdersBloc>().add(OrderDetailRequested(order.id));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<OrdersBloc>(),
        child: _SalesOrderDetailSheet(orderId: order.id, initialOrder: order),
      ),
    );
  }
}

class _SalesOrderDetailSheet extends StatelessWidget {
  const _SalesOrderDetailSheet({required this.orderId, required this.initialOrder});

  final String orderId;
  final ServiceOrder initialOrder;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
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
              const SizedBox(height: 12),
              _SalesDetailRow('Service', order.serviceName),
              _SalesDetailRow('Amount', '₹${order.amount.toStringAsFixed(0)}'),
              _SalesDetailRow('Status', order.status.label),
              _SalesDetailRow('Fulfillment', order.fulfillmentStatus.label),
              const Divider(height: 24),
              Text('Customer', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _SalesDetailRow('Name', order.customerName),
              _SalesDetailRow('Email', order.customerEmail),
              if (order.customerPhone != null)
                _SalesDetailRow('Phone', order.customerPhone!),
              if (order.notes != null && order.notes!.isNotEmpty)
                _SalesDetailRow('Notes', order.notes!),
              if (order.adminNotes != null && order.adminNotes!.isNotEmpty) ...[
                const Divider(height: 24),
                _SalesDetailRow('Admin Notes', order.adminNotes!),
              ],
              if (order.paymentRequests.isNotEmpty) ...[
                const Divider(height: 24),
                ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                      'Payment Requests (${order.paymentRequests.length})'),
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
                              '${r.amountMatchesOrder ? '' : ' (amount mismatch)'}',
                            ),
                            trailing: StatusPill(
                              label: r.status.label,
                              color: statusColor(r.status),
                            ),
                            onTap: () => showPaymentRequestSheet(
                              context,
                              request: r,
                              accent: AppColors.salesAccent,
                              canDecide: false,
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

class _SalesDetailRow extends StatelessWidget {
  const _SalesDetailRow(this.label, this.value);

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
            width: 110,
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

class _SalesProfileTab extends StatelessWidget {
  const _SalesProfileTab({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profile',
      accent: AppColors.salesAccent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              children: [
                const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
                const SizedBox(height: 10),
                Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                Text(user.email),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.salesAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Sales Team',
                    style: TextStyle(
                      color: AppColors.salesAccentDeep,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                ),
              ],
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
          const GlassCard(child: DeleteAccountTile()),
          const SizedBox(height: 12),
          const SectionTitle(
            title: 'Notifications',
            subtitle: 'Updates and alerts for your account',
          ),
          const SizedBox(height: 10),
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
                  children: [
                    for (final notification in state.notifications)
                      ListTile(
                        leading: Icon(
                          notification.isRead
                              ? Icons.mark_email_read_outlined
                              : Icons.notifications_active_rounded,
                        ),
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
                  ],
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
