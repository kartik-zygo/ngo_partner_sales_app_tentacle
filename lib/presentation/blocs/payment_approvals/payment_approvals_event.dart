part of 'payment_approvals_bloc.dart';

sealed class PaymentApprovalsEvent extends Equatable {
  const PaymentApprovalsEvent();

  @override
  List<Object?> get props => [];
}

class PaymentApprovalsLoaded extends PaymentApprovalsEvent {
  const PaymentApprovalsLoaded({
    this.status,
    this.paymentMethod,
    this.search,
    this.page = 1,
  });

  final String? status;
  final String? paymentMethod;
  final String? search;
  final int page;

  @override
  List<Object?> get props => [status, paymentMethod, search, page];
}

class PaymentApprovalsFilterChanged extends PaymentApprovalsEvent {
  const PaymentApprovalsFilterChanged({this.status, this.search});

  final String? status;
  final String? search;

  @override
  List<Object?> get props => [status, search];
}

class PaymentApprovalDetailRequested extends PaymentApprovalsEvent {
  const PaymentApprovalDetailRequested(this.requestId);

  final String requestId;

  @override
  List<Object?> get props => [requestId];
}

class PaymentApprovalDecisionSubmitted extends PaymentApprovalsEvent {
  const PaymentApprovalDecisionSubmitted({
    required this.requestId,
    required this.decision,
    this.reviewNotes,
  });

  final String requestId;
  final String decision;
  final String? reviewNotes;

  @override
  List<Object?> get props => [requestId, decision, reviewNotes];
}

class PaymentApprovalSubmissionReceived extends PaymentApprovalsEvent {
  const PaymentApprovalSubmissionReceived(this.payload);

  final Map<String, dynamic> payload;

  @override
  List<Object?> get props => [payload];
}
