part of 'orders_bloc.dart';

sealed class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class OrdersLoaded extends OrdersEvent {
  const OrdersLoaded({
    this.status,
    this.fulfillmentStatus,
    this.serviceId,
    this.userId,
    this.search,
    this.from,
    this.to,
    this.page = 1,
  });

  final String? status;
  final String? fulfillmentStatus;
  final String? serviceId;
  final String? userId;
  final String? search;
  final DateTime? from;
  final DateTime? to;
  final int page;

  @override
  List<Object?> get props =>
      [status, fulfillmentStatus, serviceId, userId, search, from, to, page];
}

class OrdersFilterChanged extends OrdersEvent {
  const OrdersFilterChanged({
    this.status,
    this.fulfillmentStatus,
    this.search,
  });

  final String? status;
  final String? fulfillmentStatus;
  final String? search;

  @override
  List<Object?> get props => [status, fulfillmentStatus, search];
}

class OrderDetailRequested extends OrdersEvent {
  const OrderDetailRequested(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class OrderFulfillmentUpdateRequested extends OrdersEvent {
  const OrderFulfillmentUpdateRequested({
    required this.orderId,
    required this.fulfillmentStatus,
    this.adminNotes,
  });

  final String orderId;
  final String fulfillmentStatus;
  final String? adminNotes;

  @override
  List<Object?> get props => [orderId, fulfillmentStatus, adminNotes];
}
