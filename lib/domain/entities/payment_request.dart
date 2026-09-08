import 'package:equatable/equatable.dart';

enum PaymentMethod {
  upi,
  bankTransfer,
  neft,
  imps,
  cash,
  cheque,
  other;

  String get apiValue {
    switch (this) {
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.neft:
        return 'neft';
      case PaymentMethod.imps:
        return 'imps';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.cheque:
        return 'cheque';
      case PaymentMethod.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.neft:
        return 'NEFT';
      case PaymentMethod.imps:
        return 'IMPS';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  static PaymentMethod fromApi(String? value) {
    switch (value) {
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'neft':
        return PaymentMethod.neft;
      case 'imps':
        return PaymentMethod.imps;
      case 'cash':
        return PaymentMethod.cash;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'other':
        return PaymentMethod.other;
      case 'upi':
      default:
        return PaymentMethod.upi;
    }
  }
}

enum PaymentRequestStatus {
  pending,
  approved,
  rejected;

  String get apiValue => name;

  String get label {
    switch (this) {
      case PaymentRequestStatus.pending:
        return 'Pending';
      case PaymentRequestStatus.approved:
        return 'Approved';
      case PaymentRequestStatus.rejected:
        return 'Rejected';
    }
  }

  static PaymentRequestStatus fromApi(String? value) {
    switch (value) {
      case 'approved':
        return PaymentRequestStatus.approved;
      case 'rejected':
        return PaymentRequestStatus.rejected;
      case 'pending':
      default:
        return PaymentRequestStatus.pending;
    }
  }
}

class PaymentRequest extends Equatable {
  const PaymentRequest({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.amountClaimed,
    this.orderAmount,
    this.amountMatchesOrder = true,
    this.paidAt,
    this.payerName,
    this.payerNote,
    this.proofUrl,
    required this.status,
    this.orderStatus,
    this.serviceName,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.reviewedBy,
    this.reviewerEmail,
    this.reviewNotes,
    this.reviewedAt,
    this.createdAt,
  });

  final String id;
  final String orderId;
  final PaymentMethod paymentMethod;
  final String referenceNumber;
  final double amountClaimed;
  final double? orderAmount;
  final bool amountMatchesOrder;
  final DateTime? paidAt;
  final String? payerName;
  final String? payerNote;
  final String? proofUrl;
  final PaymentRequestStatus status;
  final String? orderStatus;
  final String? serviceName;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? reviewedBy;
  final String? reviewerEmail;
  final String? reviewNotes;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  bool get isPending => status == PaymentRequestStatus.pending;
  bool get isApproved => status == PaymentRequestStatus.approved;
  bool get isRejected => status == PaymentRequestStatus.rejected;

  PaymentRequest copyWith({
    PaymentRequestStatus? status,
    String? orderStatus,
    String? reviewedBy,
    String? reviewerEmail,
    String? reviewNotes,
    DateTime? reviewedAt,
  }) {
    return PaymentRequest(
      id: id,
      orderId: orderId,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      amountClaimed: amountClaimed,
      orderAmount: orderAmount,
      amountMatchesOrder: amountMatchesOrder,
      paidAt: paidAt,
      payerName: payerName,
      payerNote: payerNote,
      proofUrl: proofUrl,
      status: status ?? this.status,
      orderStatus: orderStatus ?? this.orderStatus,
      serviceName: serviceName,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewerEmail: reviewerEmail ?? this.reviewerEmail,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, orderId, status, amountClaimed, reviewNotes];
}
