import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/service_order.dart';
import '../../../domain/usecases/admin_usecases.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc({
    required GetOrdersUseCase getOrdersUseCase,
    required GetOrderByIdUseCase getOrderByIdUseCase,
    required UpdateOrderFulfillmentUseCase updateOrderFulfillmentUseCase,
  })  : _getOrdersUseCase = getOrdersUseCase,
        _getOrderByIdUseCase = getOrderByIdUseCase,
        _updateOrderFulfillmentUseCase = updateOrderFulfillmentUseCase,
        super(const OrdersState()) {
    on<OrdersLoaded>(_onLoaded);
    on<OrdersFilterChanged>(_onFilterChanged);
    on<OrderDetailRequested>(_onDetailRequested);
    on<OrderFulfillmentUpdateRequested>(_onFulfillmentUpdateRequested);
  }

  final GetOrdersUseCase _getOrdersUseCase;
  final GetOrderByIdUseCase _getOrderByIdUseCase;
  final UpdateOrderFulfillmentUseCase _updateOrderFulfillmentUseCase;

  Future<void> _onLoaded(OrdersLoaded event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(status: OrdersStatus.loading));
    try {
      final orders = await _getOrdersUseCase(
        status: event.status ?? state.filterStatus,
        fulfillmentStatus: event.fulfillmentStatus ?? state.filterFulfillmentStatus,
        serviceId: event.serviceId,
        userId: event.userId,
        search: event.search ?? (state.filterSearch.isEmpty ? null : state.filterSearch),
        from: event.from,
        to: event.to,
        page: event.page,
      );
      emit(state.copyWith(status: OrdersStatus.success, orders: orders));
    } catch (e) {
      emit(state.copyWith(status: OrdersStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onFilterChanged(
    OrdersFilterChanged event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(
      filterStatus: event.status,
      filterFulfillmentStatus: event.fulfillmentStatus,
      filterSearch: event.search ?? state.filterSearch,
    ));
    add(OrdersLoaded(
      status: event.status,
      fulfillmentStatus: event.fulfillmentStatus,
      search: event.search,
    ));
  }

  Future<void> _onDetailRequested(
    OrderDetailRequested event,
    Emitter<OrdersState> emit,
  ) async {
    emit(state.copyWith(status: OrdersStatus.loading));
    try {
      final order = await _getOrderByIdUseCase(event.orderId);
      emit(state.copyWith(status: OrdersStatus.success, selectedOrder: order));
    } catch (e) {
      emit(state.copyWith(status: OrdersStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onFulfillmentUpdateRequested(
    OrderFulfillmentUpdateRequested event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      final updated = await _updateOrderFulfillmentUseCase(
        event.orderId,
        fulfillmentStatus: event.fulfillmentStatus,
        adminNotes: event.adminNotes,
      );
      final updatedOrders = state.orders
          .map((o) => o.id == updated.id ? updated : o)
          .toList();
      emit(state.copyWith(
        orders: updatedOrders,
        selectedOrder: updated,
        message: 'Fulfillment updated',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
