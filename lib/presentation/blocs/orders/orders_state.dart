part of 'orders_bloc.dart';

enum OrdersStatus { initial, loading, success, failure }

class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.initial,
    this.orders = const [],
    this.selectedOrder,
    this.filterStatus,
    this.filterFulfillmentStatus,
    this.filterSearch = '',
    this.message,
    this.errorMessage,
  });

  final OrdersStatus status;
  final List<ServiceOrder> orders;
  final ServiceOrder? selectedOrder;
  final String? filterStatus;
  final String? filterFulfillmentStatus;
  final String filterSearch;
  final String? message;
  final String? errorMessage;

  OrdersState copyWith({
    OrdersStatus? status,
    List<ServiceOrder>? orders,
    Object? selectedOrder = _ordSentinel,
    Object? filterStatus = _ordSentinel,
    Object? filterFulfillmentStatus = _ordSentinel,
    String? filterSearch,
    String? message,
    String? errorMessage,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      selectedOrder: selectedOrder == _ordSentinel
          ? this.selectedOrder
          : selectedOrder as ServiceOrder?,
      filterStatus: filterStatus == _ordSentinel
          ? this.filterStatus
          : filterStatus as String?,
      filterFulfillmentStatus: filterFulfillmentStatus == _ordSentinel
          ? this.filterFulfillmentStatus
          : filterFulfillmentStatus as String?,
      filterSearch: filterSearch ?? this.filterSearch,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        selectedOrder,
        filterStatus,
        filterFulfillmentStatus,
        filterSearch,
        message,
        errorMessage,
      ];
}

const _ordSentinel = Object();
