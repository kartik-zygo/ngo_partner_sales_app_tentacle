import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/payment_request.dart';
import '../../../domain/usecases/admin_usecases.dart';

part 'payment_approvals_event.dart';
part 'payment_approvals_state.dart';

class PaymentApprovalsBloc
    extends Bloc<PaymentApprovalsEvent, PaymentApprovalsState> {
  PaymentApprovalsBloc({
    required GetPaymentRequestsUseCase getPaymentRequestsUseCase,
    required GetPaymentRequestByIdUseCase getPaymentRequestByIdUseCase,
    required DecidePaymentRequestUseCase decidePaymentRequestUseCase,
  })  : _getPaymentRequestsUseCase = getPaymentRequestsUseCase,
        _getPaymentRequestByIdUseCase = getPaymentRequestByIdUseCase,
        _decidePaymentRequestUseCase = decidePaymentRequestUseCase,
        super(const PaymentApprovalsState()) {
    on<PaymentApprovalsLoaded>(_onLoaded);
    on<PaymentApprovalsFilterChanged>(_onFilterChanged);
    on<PaymentApprovalDetailRequested>(_onDetailRequested);
    on<PaymentApprovalDecisionSubmitted>(_onDecisionSubmitted);
    on<PaymentApprovalSubmissionReceived>(_onSubmissionReceived);
  }

  final GetPaymentRequestsUseCase _getPaymentRequestsUseCase;
  final GetPaymentRequestByIdUseCase _getPaymentRequestByIdUseCase;
  final DecidePaymentRequestUseCase _decidePaymentRequestUseCase;

  Future<void> _onLoaded(
    PaymentApprovalsLoaded event,
    Emitter<PaymentApprovalsState> emit,
  ) async {
    emit(state.copyWith(status: PaymentApprovalsStatus.loading));
    try {
      final requests = await _getPaymentRequestsUseCase(
        status: event.status ?? state.filterStatus,
        paymentMethod: event.paymentMethod,
        search: event.search ??
            (state.filterSearch.isEmpty ? null : state.filterSearch),
        page: event.page,
      );

      final pendingCount = (event.status ?? state.filterStatus) == 'pending'
          ? requests.where((r) => r.isPending).length
          : state.pendingCount;

      emit(state.copyWith(
        status: PaymentApprovalsStatus.success,
        requests: requests,
        pendingCount: pendingCount,
        hasUnseenSubmission: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PaymentApprovalsStatus.failure,
        errorMessage: _clean(e),
      ));
    }
  }

  Future<void> _onFilterChanged(
    PaymentApprovalsFilterChanged event,
    Emitter<PaymentApprovalsState> emit,
  ) async {
    emit(state.copyWith(
      filterStatus: event.status,
      filterSearch: event.search ?? state.filterSearch,
    ));
    add(PaymentApprovalsLoaded(status: event.status, search: event.search));
  }

  Future<void> _onDetailRequested(
    PaymentApprovalDetailRequested event,
    Emitter<PaymentApprovalsState> emit,
  ) async {
    try {
      final request = await _getPaymentRequestByIdUseCase(event.requestId);
      emit(state.copyWith(selectedRequest: request));
    } catch (e) {
      emit(state.copyWith(errorMessage: _clean(e)));
    }
  }

  Future<void> _onDecisionSubmitted(
    PaymentApprovalDecisionSubmitted event,
    Emitter<PaymentApprovalsState> emit,
  ) async {
    emit(state.copyWith(decidingId: event.requestId));
    try {
      final updated = await _decidePaymentRequestUseCase(
        event.requestId,
        decision: event.decision,
        reviewNotes: event.reviewNotes,
      );

      final remaining = state.filterStatus == 'pending'
          ? state.requests.where((r) => r.id != updated.id).toList()
          : state.requests
              .map((r) => r.id == updated.id ? updated : r)
              .toList();

      emit(state.copyWith(
        requests: remaining,
        selectedRequest: updated,
        pendingCount: remaining.where((r) => r.isPending).length,
        decidingId: null,
        clearDeciding: true,
        message: updated.isApproved
            ? 'Payment approved — the order is now placed'
            : 'Payment rejected — the client can submit again',
      ));
    } catch (e) {
      emit(state.copyWith(
        decidingId: null,
        clearDeciding: true,
        errorMessage: _clean(e),
      ));
    }
  }

  void _onSubmissionReceived(
    PaymentApprovalSubmissionReceived event,
    Emitter<PaymentApprovalsState> emit,
  ) {
    emit(state.copyWith(
      hasUnseenSubmission: true,
      pendingCount: state.pendingCount + 1,
    ));
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}
