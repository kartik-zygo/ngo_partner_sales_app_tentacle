import 'package:equatable/equatable.dart';

import 'payment_request.dart';

enum FulfillmentStatus {
  none,
  processing,
  completed,
  refundInitiated,
  refunded;

  String get label {
    switch (this) {
      case FulfillmentStatus.none:
        return 'Not Actioned';
      case FulfillmentStatus.processing:
        return 'Processing';
      case FulfillmentStatus.completed:
        return 'Completed';
      case FulfillmentStatus.refundInitiated:
        return 'Refund Initiated';
      case FulfillmentStatus.refunded:
        return 'Refunded';
    }
  }

  String get apiValue {
    switch (this) {
      case FulfillmentStatus.none:
        return 'none';
      case FulfillmentStatus.processing:
        return 'processing';
      case FulfillmentStatus.completed:
        return 'completed';
      case FulfillmentStatus.refundInitiated:
        return 'refund_initiated';
      case FulfillmentStatus.refunded:
        return 'refunded';
    }
  }
}

enum OrderPaymentStatus {
  pendingPayment,
  paymentSubmitted,
  paid,
  rejected,
  cancelled,
  expired;

  String get apiValue {
    switch (this) {
      case OrderPaymentStatus.pendingPayment:
        return 'pending_payment';
      case OrderPaymentStatus.paymentSubmitted:
        return 'payment_submitted';
      case OrderPaymentStatus.paid:
        return 'paid';
      case OrderPaymentStatus.rejected:
        return 'rejected';
      case OrderPaymentStatus.cancelled:
        return 'cancelled';
      case OrderPaymentStatus.expired:
        return 'expired';
    }
  }

  String get label {
    switch (this) {
      case OrderPaymentStatus.pendingPayment:
        return 'Awaiting Payment';
      case OrderPaymentStatus.paymentSubmitted:
        return 'Awaiting Approval';
      case OrderPaymentStatus.paid:
        return 'Paid';
      case OrderPaymentStatus.rejected:
        return 'Rejected';
      case OrderPaymentStatus.cancelled:
        return 'Cancelled';
      case OrderPaymentStatus.expired:
        return 'Expired';
    }
  }

  static OrderPaymentStatus fromApi(String? value) {
    switch (value) {
      case 'payment_submitted':
        return OrderPaymentStatus.paymentSubmitted;
      case 'paid':
        return OrderPaymentStatus.paid;
      case 'rejected':
        return OrderPaymentStatus.rejected;
      case 'cancelled':
        return OrderPaymentStatus.cancelled;
      case 'expired':
        return OrderPaymentStatus.expired;
      case 'pending_payment':
      default:
        return OrderPaymentStatus.pendingPayment;
    }
  }
}

class ServiceOrder extends Equatable {
  const ServiceOrder({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.fulfillmentStatus,
    this.adminNotes,
    this.fulfillmentUpdatedBy,
    this.fulfillmentUpdatedAt,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    this.notes,
    this.paidAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.latestPaymentRequestId,
    this.latestPaymentRequestStatus,
    this.paymentRequests = const [],
  });

  final String id;
  final String userId;
  final String serviceId;
  final String serviceName;
  final double amount;
  final String currency;
  final OrderPaymentStatus status;
  final FulfillmentStatus fulfillmentStatus;
  final String? adminNotes;
  final String? fulfillmentUpdatedBy;
  final DateTime? fulfillmentUpdatedAt;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String? notes;
  final DateTime? paidAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? latestPaymentRequestId;
  final PaymentRequestStatus? latestPaymentRequestStatus;
  final List<PaymentRequest> paymentRequests;

  bool get isAwaitingApproval => status == OrderPaymentStatus.paymentSubmitted;
  bool get isPaid => status == OrderPaymentStatus.paid;

  PaymentRequest? get latestPaymentRequest {
    if (paymentRequests.isEmpty) return null;
    if (latestPaymentRequestId != null) {
      for (final request in paymentRequests) {
        if (request.id == latestPaymentRequestId) return request;
      }
    }
    return paymentRequests.first;
  }

  ServiceOrder copyWith({
    String? id,
    String? userId,
    String? serviceId,
    String? serviceName,
    double? amount,
    String? currency,
    OrderPaymentStatus? status,
    FulfillmentStatus? fulfillmentStatus,
    String? adminNotes,
    String? fulfillmentUpdatedBy,
    DateTime? fulfillmentUpdatedAt,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? notes,
    DateTime? paidAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? latestPaymentRequestId,
    PaymentRequestStatus? latestPaymentRequestStatus,
    List<PaymentRequest>? paymentRequests,
  }) {
    return ServiceOrder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      fulfillmentStatus: fulfillmentStatus ?? this.fulfillmentStatus,
      adminNotes: adminNotes ?? this.adminNotes,
      fulfillmentUpdatedBy: fulfillmentUpdatedBy ?? this.fulfillmentUpdatedBy,
      fulfillmentUpdatedAt: fulfillmentUpdatedAt ?? this.fulfillmentUpdatedAt,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      paidAt: paidAt ?? this.paidAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latestPaymentRequestId:
          latestPaymentRequestId ?? this.latestPaymentRequestId,
      latestPaymentRequestStatus:
          latestPaymentRequestStatus ?? this.latestPaymentRequestStatus,
      paymentRequests: paymentRequests ?? this.paymentRequests,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, serviceId, status, fulfillmentStatus, updatedAt];
}
