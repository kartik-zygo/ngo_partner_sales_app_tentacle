import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui_primitives.dart';
import '../../domain/entities/payment_request.dart';
import '../blocs/payment_approvals/payment_approvals_bloc.dart';

class PaymentApprovalsView extends StatefulWidget {
  const PaymentApprovalsView({
    super.key,
    required this.accent,
    required this.canDecide,
  });

  final Color accent;
  final bool canDecide;

  @override
  State<PaymentApprovalsView> createState() => _PaymentApprovalsViewState();
}

class _PaymentApprovalsViewState extends State<PaymentApprovalsView> {
  final _searchController = TextEditingController();
  String _statusFilter = 'pending';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _apply() {
    context.read<PaymentApprovalsBloc>().add(PaymentApprovalsFilterChanged(
          status: _statusFilter,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentApprovalsBloc, PaymentApprovalsState>(
      listenWhen: (prev, curr) =>
          (curr.message != null && prev.message != curr.message) ||
          (curr.errorMessage != null && prev.errorMessage != curr.errorMessage),
      listener: (context, state) {
        final msg = state.message ?? state.errorMessage;
        if (msg == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                state.errorMessage != null ? AppColors.danger : AppColors.positive,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                if (!widget.canDecide) _buildReadOnlyNotice(),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search reference, name, email, phone…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _apply,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _apply(),
                ),
                const SizedBox(height: 8),
                BlocBuilder<PaymentApprovalsBloc, PaymentApprovalsState>(
                  buildWhen: (p, c) => p.pendingCount != c.pendingCount,
                  builder: (context, state) => Row(
                    children: [
                      _statusChip('pending', 'Pending', state.pendingCount),
                      const SizedBox(width: 6),
                      _statusChip('approved', 'Approved', null),
                      const SizedBox(width: 6),
                      _statusChip('rejected', 'Rejected', null),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<PaymentApprovalsBloc, PaymentApprovalsState>(
              builder: (context, state) {
                if (state.status == PaymentApprovalsStatus.loading ||
                    state.status == PaymentApprovalsStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == PaymentApprovalsStatus.failure) {
                  return EmptyStateView(
                    title: 'Could not load payment requests',
                    subtitle: state.errorMessage ??
                        'Check your connection and try again.',
                  );
                }
                if (state.requests.isEmpty) {
                  return EmptyStateView(
                    title: _statusFilter == 'pending'
                        ? 'Nothing waiting for approval'
                        : 'No $_statusFilter payments',
                    subtitle: _statusFilter == 'pending'
                        ? 'Declared payments will land here for verification.'
                        : 'Try a different filter or search term.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _apply(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: state.requests.length,
                    itemBuilder: (context, index) {
                      final request = state.requests[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: StaggerItem(
                          index: index,
                          child: _PaymentRequestCard(
                            request: request,
                            accent: widget.accent,
                            canDecide: widget.canDecide,
                            deciding: state.decidingId == request.id,
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

  Widget _buildReadOnlyNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined,
              size: 16, color: AppColors.warning),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Read-only. Only an admin can approve or reject a payment.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String value, String label, int? count) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        _apply();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? widget.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color:
                selected ? widget.accent : Colors.grey.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? widget.accent : null,
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentRequestCard extends StatelessWidget {
  const _PaymentRequestCard({
    required this.request,
    required this.accent,
    required this.canDecide,
    required this.deciding,
  });

  final PaymentRequest request;
  final Color accent;
  final bool canDecide;
  final bool deciding;

  @override
  Widget build(BuildContext context) {
    final mismatched = !request.amountMatchesOrder;
    final amountColor = mismatched ? AppColors.danger : AppColors.charcoal;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor:
                  statusColor(request.status).withValues(alpha: 0.15),
              child: Icon(
                mismatched
                    ? Icons.warning_amber_rounded
                    : Icons.receipt_long_rounded,
                color: statusColor(request.status),
                size: 20,
              ),
            ),
            title: Text(
              request.customerName ?? 'Customer',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: Text(
              request.serviceName ?? request.orderId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatAmount(request.amountClaimed),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                if (mismatched && request.orderAmount != null)
                  Text(
                    'order ${formatAmount(request.orderAmount!)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.danger),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              StatusPill(
                label: request.paymentMethod.label,
                color: accent,
              ),
              const SizedBox(width: 6),
              StatusPill(
                label: request.status.label,
                color: statusColor(request.status),
              ),
              const Spacer(),
              Text(
                relativeTime(request.createdAt ?? request.paidAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.tag_rounded, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.referenceNumber,
                  style: const TextStyle(
                      fontSize: 12, fontFamily: 'monospace'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: deciding
                    ? null
                    : () => showPaymentRequestSheet(
                          context,
                          request: request,
                          accent: accent,
                          canDecide: canDecide,
                        ),
                child: deciding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Review'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color statusColor(PaymentRequestStatus status) {
  switch (status) {
    case PaymentRequestStatus.approved:
      return AppColors.positive;
    case PaymentRequestStatus.rejected:
      return AppColors.danger;
    case PaymentRequestStatus.pending:
      return AppColors.warning;
  }
}

String formatAmount(double value) =>
    NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(value);

String relativeTime(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('d MMM').format(dt.toLocal());
}

void showPaymentRequestSheet(
  BuildContext context, {
  required PaymentRequest request,
  required Color accent,
  required bool canDecide,
}) {
  final bloc = context.read<PaymentApprovalsBloc>();
  bloc.add(PaymentApprovalDetailRequested(request.id));
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _PaymentRequestSheet(
        requestId: request.id,
        initialRequest: request,
        accent: accent,
        canDecide: canDecide,
      ),
    ),
  );
}

class _PaymentRequestSheet extends StatelessWidget {
  const _PaymentRequestSheet({
    required this.requestId,
    required this.initialRequest,
    required this.accent,
    required this.canDecide,
  });

  final String requestId;
  final PaymentRequest initialRequest;
  final Color accent;
  final bool canDecide;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) =>
          BlocBuilder<PaymentApprovalsBloc, PaymentApprovalsState>(
        builder: (context, state) {
          final request = state.selectedRequest?.id == requestId
              ? state.selectedRequest!
              : initialRequest;
          final deciding = state.decidingId == request.id;

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
              Row(
                children: [
                  Expanded(
                    child: Text('Payment Review',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  StatusPill(
                    label: request.status.label,
                    color: statusColor(request.status),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAmountComparison(context, request),
              const SizedBox(height: 16),
              _buildReferenceRow(context, request),
              const SizedBox(height: 16),
              _SheetSection(
                title: 'Payment',
                children: [
                  _SheetRow('Method', request.paymentMethod.label),
                  if (request.paidAt != null)
                    _SheetRow('Paid at', _fullDate(request.paidAt!)),
                  if (request.createdAt != null)
                    _SheetRow('Declared', _fullDate(request.createdAt!)),
                  if (request.payerName != null &&
                      request.payerName!.isNotEmpty)
                    _SheetRow('Payer', request.payerName!),
                  if (request.payerNote != null &&
                      request.payerNote!.isNotEmpty)
                    _SheetRow('Note', request.payerNote!),
                ],
              ),
              _SheetSection(
                title: 'Customer',
                children: [
                  _SheetRow('Name', request.customerName ?? '—'),
                  _SheetRow('Email', request.customerEmail ?? '—'),
                  if (request.customerPhone != null)
                    _SheetRow('Phone', request.customerPhone!),
                  _SheetRow('Service', request.serviceName ?? '—'),
                  _SheetRow('Order', request.orderId),
                  if (request.orderStatus != null)
                    _SheetRow('Order status', request.orderStatus!),
                ],
              ),
              if (request.reviewNotes != null &&
                  request.reviewNotes!.isNotEmpty)
                _SheetSection(
                  title: 'Review',
                  children: [
                    _SheetRow('Notes', request.reviewNotes!),
                    if (request.reviewerEmail != null)
                      _SheetRow('Reviewed by', request.reviewerEmail!),
                    if (request.reviewedAt != null)
                      _SheetRow('Reviewed at', _fullDate(request.reviewedAt!)),
                  ],
                ),
              if (request.proofUrl != null && request.proofUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Proof', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ProofViewer(url: request.proofUrl!),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      request.proofUrl!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 90,
                        alignment: Alignment.center,
                        color: Colors.grey.withValues(alpha: 0.15),
                        child: const Text('Proof could not be loaded'),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (canDecide && request.isPending)
                _buildDecisionButtons(context, request, deciding)
              else if (!canDecide && request.isPending)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 16, color: AppColors.warning),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Only an admin can approve or reject this payment.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAmountComparison(BuildContext context, PaymentRequest request) {
    final mismatched = !request.amountMatchesOrder;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mismatched
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.positive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (mismatched ? AppColors.danger : AppColors.positive)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Declared',
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    Text(
                      formatAmount(request.amountClaimed),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            mismatched ? AppColors.danger : AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Order total',
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    Text(
                      request.orderAmount != null
                          ? formatAmount(request.orderAmount!)
                          : '—',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (mismatched) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppColors.danger),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The declared amount does not match the order total.',
                    style: TextStyle(fontSize: 12, color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferenceRow(BuildContext context, PaymentRequest request) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reference number',
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
                const SizedBox(height: 2),
                SelectableText(
                  request.referenceNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: request.referenceNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reference copied'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionButtons(
    BuildContext context,
    PaymentRequest request,
    bool deciding,
  ) {
    if (deciding) {
      return const Center(child: CircularProgressIndicator());
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _promptReject(context, request),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _promptApprove(context, request),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Approve'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.positive,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _promptApprove(
      BuildContext context, PaymentRequest request) async {
    final bloc = context.read<PaymentApprovalsBloc>();
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Approve this payment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The order will be marked paid, fulfilment starts and a client '
              'case is created automatically.',
              style: Theme.of(dialogCtx).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Verification notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.positive),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    bloc.add(PaymentApprovalDecisionSubmitted(
      requestId: request.id,
      decision: 'approved',
      reviewNotes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    ));
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _promptReject(
      BuildContext context, PaymentRequest request) async {
    final bloc = context.read<PaymentApprovalsBloc>();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reject this payment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The client sees this reason and can submit a corrected '
                'payment.',
                style: Theme.of(dialogCtx).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: notesController,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Reason (required)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'A reason is required when rejecting'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogCtx, true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    bloc.add(PaymentApprovalDecisionSubmitted(
      requestId: request.id,
      decision: 'rejected',
      reviewNotes: notesController.text.trim(),
    ));
    if (context.mounted) Navigator.pop(context);
  }

  String _fullDate(DateTime dt) =>
      DateFormat('d MMM yyyy, h:mm a').format(dt.toLocal());
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow(this.label, this.value);

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
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ProofViewer extends StatelessWidget {
  const _ProofViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Payment proof'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text(
              'Proof could not be loaded',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
