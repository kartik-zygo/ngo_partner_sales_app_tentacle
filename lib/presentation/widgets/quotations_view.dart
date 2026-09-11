import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui_primitives.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/quotation_request.dart';
import '../blocs/quotations/quotations_bloc.dart';

/// The quotation inbox, shared by both shells. Admins get the assign sheet
/// ([canAssign]); the owning rep gets the status control on their own rows.
class QuotationsView extends StatefulWidget {
  const QuotationsView({
    super.key,
    required this.accent,
    required this.canAssign,
    required this.currentUserId,
  });

  final Color accent;

  /// ADMIN only — the server returns 403 for SALES callers.
  final bool canAssign;
  final String currentUserId;

  @override
  State<QuotationsView> createState() => _QuotationsViewState();
}

class _QuotationsViewState extends State<QuotationsView> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  // The badge is cleared by the shell when this tab is actually selected —
  // doing it here would fire on shell build, since the tabs live in an
  // IndexedStack and are all constructed up front.

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Keeps the clear button in step with the field; the request itself waits
    // for the user to stop typing.
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<QuotationsBloc>().add(QuotationsSearchChanged(value.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuotationsBloc, QuotationsState>(
      listenWhen: (prev, curr) =>
          (curr.message != null && prev.message != curr.message) ||
          (curr.errorMessage != null && prev.errorMessage != curr.errorMessage),
      listener: (context, state) {
        final message = state.message ?? state.errorMessage;
        if (message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: state.errorMessage != null
                ? AppColors.danger
                : AppColors.positive,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search reference, name, email, phone, org…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                _OwnerFilterRow(
                  accent: widget.accent,
                  canAssign: widget.canAssign,
                ),
                const SizedBox(height: 8),
                _StatusFilterRow(accent: widget.accent),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<QuotationsBloc, QuotationsState>(
              builder: (context, state) {
                if (state.isLoading && state.quotations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == QuotationsStatus.failure &&
                    state.quotations.isEmpty) {
                  return _FailureView(
                    message: state.errorMessage ?? 'Could not load quotations',
                    onRetry: () => context
                        .read<QuotationsBloc>()
                        .add(const QuotationsLoaded()),
                  );
                }
                if (state.quotations.isEmpty) {
                  return const EmptyStateView(
                    title: 'Inbox is clear',
                    subtitle:
                        'New client queries land here the moment they are submitted.',
                  );
                }
                return RefreshIndicator(
                  color: widget.accent,
                  onRefresh: () async {
                    context
                        .read<QuotationsBloc>()
                        .add(const QuotationsLoaded());
                    await context.read<QuotationsBloc>().stream.firstWhere(
                          (s) => s.status != QuotationsStatus.loading,
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.quotations.length,
                    itemBuilder: (context, index) {
                      final quotation = state.quotations[index];
                      return StaggerItem(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _QuotationCard(
                            quotation: quotation,
                            accent: widget.accent,
                            canAssign: widget.canAssign,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filters ───────────────────────────────────────────────────────────────────
class _OwnerFilterRow extends StatelessWidget {
  const _OwnerFilterRow({required this.accent, required this.canAssign});

  final Color accent;
  final bool canAssign;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuotationsBloc, QuotationsState>(
      buildWhen: (p, c) => p.assignedToFilter != c.assignedToFilter,
      builder: (context, state) {
        final options = <(String?, String)>[
          if (canAssign) ('unassigned', 'Unassigned'),
          ('me', 'My requests'),
          (null, 'All'),
        ];
        return SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: options.map((option) {
              final selected = state.assignedToFilter == option.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(option.$2),
                  selected: selected,
                  selectedColor: accent.withValues(alpha: 0.18),
                  onSelected: (_) =>
                      context.read<QuotationsBloc>().add(
                            QuotationsFilterChanged(
                              assignedTo: option.$1,
                              clearAssignedTo: option.$1 == null,
                            ),
                          ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuotationsBloc, QuotationsState>(
      buildWhen: (p, c) => p.statusFilter != c.statusFilter,
      builder: (context, state) {
        final options = <(String?, String)>[
          (null, 'Any status'),
          ...QuotationStatus.values.map((s) => (s.api, s.label)),
        ];
        return SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: options.map((option) {
              final selected = state.statusFilter == option.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(option.$2),
                  selected: selected,
                  selectedColor: accent.withValues(alpha: 0.18),
                  onSelected: (_) => context.read<QuotationsBloc>().add(
                        QuotationsFilterChanged(
                          status: option.$1,
                          clearStatus: option.$1 == null,
                        ),
                      ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────
Color quotationColor(QuotationStatus status) {
  switch (status) {
    case QuotationStatus.submitted:
      return AppColors.warning;
    case QuotationStatus.assigned:
    case QuotationStatus.contacted:
      return AppColors.adminAccent;
    case QuotationStatus.qualified:
    case QuotationStatus.quoted:
      return AppColors.salesAccentDeep;
    case QuotationStatus.closedWon:
      return AppColors.positive;
    case QuotationStatus.closedLost:
      return AppColors.muted;
  }
}

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({
    required this.quotation,
    required this.accent,
    required this.canAssign,
    required this.currentUserId,
  });

  final QuotationRequest quotation;
  final Color accent;
  final bool canAssign;
  final String currentUserId;

  bool get _ownedByMe => quotation.assignedTo == currentUserId;

  @override
  Widget build(BuildContext context) {
    final color = quotationColor(quotation.status);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => showQuotationDetailSheet(
        context,
        quotation: quotation,
        accent: accent,
        canAssign: canAssign,
        currentUserId: currentUserId,
      ),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quotation.serviceName.isEmpty
                            ? 'Service enquiry'
                            : quotation.serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quotation.displayOrganization,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(label: quotation.status.label, color: color),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  quotation.reference,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM, HH:mm').format(quotation.createdAt),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  quotation.isUnassigned
                      ? Icons.person_off_outlined
                      : Icons.person_pin_rounded,
                  size: 15,
                  color: quotation.isUnassigned ? AppColors.warning : accent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    quotation.isUnassigned
                        ? 'Unassigned'
                        : 'Rep: ${quotation.assignedToName ?? quotation.assignedTo}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: quotation.isUnassigned
                          ? AppColors.warning
                          : AppColors.charcoal,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canAssign && !quotation.isClosed)
                  TextButton.icon(
                    onPressed: () => showAssignSheet(context, quotation),
                    icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                    label: Text(quotation.isUnassigned ? 'Assign' : 'Reassign'),
                  )
                else if (_ownedByMe && !quotation.isClosed)
                  TextButton.icon(
                    onPressed: () => showStatusSheet(context, quotation),
                    icon: const Icon(Icons.timeline_rounded, size: 16),
                    label: const Text('Update'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail sheet ──────────────────────────────────────────────────────────────
void showQuotationDetailSheet(
  BuildContext context, {
  required QuotationRequest quotation,
  required Color accent,
  required bool canAssign,
  required String currentUserId,
}) {
  final bloc = context.read<QuotationsBloc>()
    ..add(QuotationDetailOpened(quotation.id));

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _QuotationDetailSheet(
        fallback: quotation,
        accent: accent,
        canAssign: canAssign,
        currentUserId: currentUserId,
      ),
    ),
  ).whenComplete(() => bloc.add(const QuotationDetailClosed()));
}

class _QuotationDetailSheet extends StatelessWidget {
  const _QuotationDetailSheet({
    required this.fallback,
    required this.accent,
    required this.canAssign,
    required this.currentUserId,
  });

  final QuotationRequest fallback;
  final Color accent;
  final bool canAssign;
  final String currentUserId;

  Future<void> _launch(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.scheme}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return BlocBuilder<QuotationsBloc, QuotationsState>(
          builder: (context, state) {
            final quotation = state.selected ?? fallback;
            final color = quotationColor(quotation.status);
            final ownedByMe = quotation.assignedTo == currentUserId;

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (state.isDetailLoading)
                    const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quotation.serviceName.isEmpty
                                        ? 'Service enquiry'
                                        : quotation.serviceName,
                                    style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(
                                          text: quotation.reference));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            '${quotation.reference} copied'),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          quotation.reference,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Icon(Icons.copy_rounded,
                                            size: 13, color: AppColors.muted),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusPill(
                                label: quotation.status.label, color: color),
                          ],
                        ),
                        if (quotation.statusLabel.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.visibility_outlined,
                                    size: 15, color: AppColors.muted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Client sees: ${quotation.statusLabel}',
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),

                        // ── Contact row ─────────────────────────────────
                        const _SheetHeading('Contact'),
                        const SizedBox(height: 8),
                        GlassCard(
                          child: Column(
                            children: [
                              _DetailLine(
                                  label: 'Name', value: quotation.contactName),
                              _DetailLine(
                                label: 'Organisation',
                                value: quotation.organizationName ?? '—',
                              ),
                              _DetailLine(
                                  label: 'Email',
                                  value: quotation.contactEmail.isEmpty
                                      ? '—'
                                      : quotation.contactEmail),
                              _DetailLine(
                                  label: 'Phone',
                                  value: quotation.contactPhone.isEmpty
                                      ? '—'
                                      : quotation.contactPhone),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: quotation.contactPhone.isEmpty
                                          ? null
                                          : () => _launch(
                                                context,
                                                Uri(
                                                    scheme: 'tel',
                                                    path:
                                                        quotation.contactPhone),
                                              ),
                                      icon: const Icon(Icons.call, size: 16),
                                      label: const Text('Call'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: quotation.contactEmail.isEmpty
                                          ? null
                                          : () => _launch(
                                                context,
                                                Uri(
                                                    scheme: 'mailto',
                                                    path:
                                                        quotation.contactEmail),
                                              ),
                                      icon: const Icon(Icons.mail_outline,
                                          size: 16),
                                      label: const Text('Email'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── Form snapshot ───────────────────────────────
                        const _SheetHeading('What they asked for'),
                        const SizedBox(height: 8),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quotation.message?.isNotEmpty == true
                                    ? quotation.message!
                                    : 'No message left with the request.',
                                style: const TextStyle(fontSize: 13.5),
                              ),
                              const SizedBox(height: 12),
                              _DetailLine(
                                label: 'Category',
                                value: quotation.serviceCategory ?? '—',
                              ),
                              _DetailLine(
                                  label: 'Source', value: quotation.source),
                              _DetailLine(
                                label: 'Submitted',
                                value: DateFormat('dd MMM yyyy, HH:mm')
                                    .format(quotation.createdAt),
                              ),
                              _DetailLine(
                                label: 'Assigned',
                                value: quotation.assignedAt == null
                                    ? 'Not yet'
                                    : '${quotation.assignedToName ?? 'Rep'} · '
                                        '${DateFormat('dd MMM, HH:mm').format(quotation.assignedAt!)}',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── Notes ───────────────────────────────────────
                        const _SheetHeading('Notes'),
                        const SizedBox(height: 8),
                        if (quotation.notes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text('No notes yet.',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.muted)),
                          )
                        else
                          ...quotation.notes.map(
                            (note) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(note.content,
                                        style: const TextStyle(fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (note.author != null) note.author!,
                                        DateFormat('dd MMM, HH:mm')
                                            .format(note.createdAt),
                                      ].join(' · '),
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: state.isMutating
                              ? null
                              : () => _promptNote(context, quotation.id),
                          icon: const Icon(Icons.note_add_outlined, size: 16),
                          label: const Text('Add note'),
                        ),

                        const SizedBox(height: 18),

                        // ── Activity ────────────────────────────────────
                        const _SheetHeading('Activity'),
                        const SizedBox(height: 8),
                        if (quotation.activity.isEmpty)
                          const Text('Nothing recorded yet.',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.muted))
                        else
                          ...quotation.activity.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 5),
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(entry.message,
                                            style:
                                                const TextStyle(fontSize: 13)),
                                        Text(
                                          [
                                            if (entry.performedBy != null)
                                              entry.performedBy!,
                                            DateFormat('dd MMM, HH:mm')
                                                .format(entry.createdAt),
                                          ].join(' · '),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 22),
                        if (!quotation.isClosed) ...[
                          if (canAssign)
                            FilledButton.icon(
                              onPressed: state.isMutating
                                  ? null
                                  : () => showAssignSheet(context, quotation),
                              icon: const Icon(Icons.assignment_ind_outlined),
                              label: Text(quotation.isUnassigned
                                  ? 'Assign to a rep'
                                  : 'Reassign'),
                            ),
                          if (canAssign) const SizedBox(height: 8),
                          if (ownedByMe || canAssign)
                            OutlinedButton.icon(
                              onPressed: state.isMutating
                                  ? null
                                  : () => showStatusSheet(context, quotation),
                              icon: const Icon(Icons.timeline_rounded),
                              label: const Text('Update status'),
                            )
                          else
                            const Text(
                              'Only the assigned rep can move this request.',
                              style: TextStyle(
                                  fontSize: 12.5, color: AppColors.muted),
                            ),
                        ] else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              quotation.status == QuotationStatus.closedWon
                                  ? 'Won — a case has been opened for this client.'
                                  : 'Closed as lost.',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _promptNote(BuildContext context, String id) async {
  final bloc = context.read<QuotationsBloc>();
  final controller = TextEditingController();
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add note'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'What happened on the call?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Save'),
        ),
      ],
    ),
  );

  final content = controller.text.trim();
  controller.dispose();
  if (saved == true && content.isNotEmpty) {
    bloc.add(QuotationNoteAdded(id: id, content: content));
  }
}

// ── Assign sheet ──────────────────────────────────────────────────────────────
void showAssignSheet(BuildContext context, QuotationRequest quotation) {
  final bloc = context.read<QuotationsBloc>()..add(const SalesRepsLoaded());
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _AssignSheet(quotation: quotation),
    ),
  );
}

class _AssignSheet extends StatefulWidget {
  const _AssignSheet({required this.quotation});

  final QuotationRequest quotation;

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  final _noteController = TextEditingController();
  String? _selectedRepId;

  @override
  void initState() {
    super.initState();
    _selectedRepId = widget.quotation.assignedTo;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: BlocBuilder<QuotationsBloc, QuotationsState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.quotation.isUnassigned
                      ? 'Assign ${widget.quotation.reference}'
                      : 'Reassign ${widget.quotation.reference}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Open requests are shown next to each rep so you can spread the load.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                if (state.salesReps.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.salesReps.length,
                      itemBuilder: (context, index) {
                        final rep = state.salesReps[index];
                        return RadioListTile<String>(
                          value: rep.id,
                          groupValue: _selectedRepId,
                          onChanged: (value) =>
                              setState(() => _selectedRepId = value),
                          title: Text(rep.name.isEmpty ? rep.email : rep.name),
                          subtitle: Text(rep.email),
                          secondary: Chip(
                            label: Text('${rep.openRequests} open'),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Briefing note (optional)',
                    hintText: 'Priority client — call today.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (_selectedRepId == null || state.isMutating)
                        ? null
                        : () {
                            context.read<QuotationsBloc>().add(
                                  QuotationAssigned(
                                    id: widget.quotation.id,
                                    assignedTo: _selectedRepId!,
                                    note: _noteController.text.trim(),
                                  ),
                                );
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('Assign'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Status sheet ──────────────────────────────────────────────────────────────
void showStatusSheet(BuildContext context, QuotationRequest quotation) {
  final bloc = context.read<QuotationsBloc>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _StatusSheet(quotation: quotation),
    ),
  );
}

class _StatusSheet extends StatefulWidget {
  const _StatusSheet({required this.quotation});

  final QuotationRequest quotation;

  @override
  State<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<_StatusSheet> {
  final _noteController = TextEditingController();
  LeadStatus? _selected;

  /// The API requires a note on `lost` and accepts one everywhere else.
  bool get _noteRequired => _selected == LeadStatus.lost;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: BlocBuilder<QuotationsBloc, QuotationsState>(
          builder: (context, state) {
            final noteEmpty = _noteController.text.trim().isEmpty;
            final blocked =
                _selected == null || state.isMutating || (_noteRequired && noteEmpty);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move ${widget.quotation.reference}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Currently ${widget.quotation.status.label}. Marking won opens a case automatically.',
                  style:
                      const TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: kQuotationPipelineTargets.map((status) {
                    return ChoiceChip(
                      label: Text(status.label),
                      selected: _selected == status,
                      onSelected: (_) => setState(() => _selected = status),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: _noteRequired
                        ? 'Reason (required to mark lost)'
                        : 'Note (optional)',
                    hintText: 'Shared the quote over WhatsApp.',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: blocked
                        ? null
                        : () {
                            context.read<QuotationsBloc>().add(
                                  QuotationStatusUpdated(
                                    id: widget.quotation.id,
                                    status: _selected!,
                                    note: _noteController.text.trim(),
                                  ),
                                );
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('Update status'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Small pieces ──────────────────────────────────────────────────────────────
class _SheetHeading extends StatelessWidget {
  const _SheetHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 44, color: AppColors.muted),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
