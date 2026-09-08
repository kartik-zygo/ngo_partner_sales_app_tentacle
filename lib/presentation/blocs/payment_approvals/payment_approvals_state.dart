part of 'payment_approvals_bloc.dart';

enum PaymentApprovalsStatus { initial, loading, success, failure }

class PaymentApprovalsState extends Equatable {
  const PaymentApprovalsState({
    this.status = PaymentApprovalsStatus.initial,
    this.requests = const [],
    this.selectedRequest,
    this.filterStatus = 'pending',
    this.filterSearch = '',
    this.pendingCount = 0,
    this.hasUnseenSubmission = false,
    this.decidingId,
    this.message,
    this.errorMessage,
  });

  final PaymentApprovalsStatus status;
  final List<PaymentRequest> requests;
  final PaymentRequest? selectedRequest;
  final String? filterStatus;
  final String filterSearch;
  final int pendingCount;
  final bool hasUnseenSubmission;
  final String? decidingId;
  final String? message;
  final String? errorMessage;

  PaymentApprovalsState copyWith({
    PaymentApprovalsStatus? status,
    List<PaymentRequest>? requests,
    Object? selectedRequest = _paSentinel,
    Object? filterStatus = _paSentinel,
    String? filterSearch,
    int? pendingCount,
    bool? hasUnseenSubmission,
    String? decidingId,
    bool clearDeciding = false,
    String? message,
    String? errorMessage,
  }) {
    return PaymentApprovalsState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      selectedRequest: selectedRequest == _paSentinel
          ? this.selectedRequest
          : selectedRequest as PaymentRequest?,
      filterStatus: filterStatus == _paSentinel
          ? this.filterStatus
          : filterStatus as String?,
      filterSearch: filterSearch ?? this.filterSearch,
      pendingCount: pendingCount ?? this.pendingCount,
      hasUnseenSubmission: hasUnseenSubmission ?? this.hasUnseenSubmission,
      decidingId: clearDeciding ? null : (decidingId ?? this.decidingId),
      message: message,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        requests,
        selectedRequest,
        filterStatus,
        filterSearch,
        pendingCount,
        hasUnseenSubmission,
        decidingId,
        message,
        errorMessage,
      ];
}

const _paSentinel = Object();
