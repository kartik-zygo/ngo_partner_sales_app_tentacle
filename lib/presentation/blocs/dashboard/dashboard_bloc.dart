import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/dashboard_summary.dart';
import '../../../domain/usecases/admin_usecases.dart';
import '../../../domain/usecases/sales_usecases.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required GetSalesDashboardUseCase getSalesDashboardUseCase,
    required GetAdminDashboardUseCase getAdminDashboardUseCase,
    required GetIntegrationDashboardMetricsUseCase getIntegrationDashboardMetricsUseCase,
  })  : _getSalesDashboardUseCase = getSalesDashboardUseCase,
        _getAdminDashboardUseCase = getAdminDashboardUseCase,
        _getIntegrationDashboardMetricsUseCase = getIntegrationDashboardMetricsUseCase,
        super(const DashboardState()) {
    on<DashboardLoaded>(_onLoaded);
    on<DashboardRevenueToggled>(_onRevenueToggled);
  }

  final GetSalesDashboardUseCase _getSalesDashboardUseCase;
  final GetAdminDashboardUseCase _getAdminDashboardUseCase;
  final GetIntegrationDashboardMetricsUseCase _getIntegrationDashboardMetricsUseCase;

  Future<void> _onLoaded(DashboardLoaded event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(status: DashboardStatus.loading, clearError: true));
    try {
      if (event.user.role == AppRole.sales) {
        final summary = await _getSalesDashboardUseCase(event.user.id == 'u_sales_1' ? 'tm_1' : event.user.id);
        emit(state.copyWith(status: DashboardStatus.success, salesSummary: summary));
      } else {
        final summary = await _getAdminDashboardUseCase();
        final metrics = await _getIntegrationDashboardMetricsUseCase();
        emit(state.copyWith(
          status: DashboardStatus.success,
          adminSummary: summary,
          integrationMetrics: metrics,
        ));
      }
    } catch (e) {
      emit(state.copyWith(status: DashboardStatus.failure, error: e.toString()));
    }
  }

  void _onRevenueToggled(DashboardRevenueToggled event, Emitter<DashboardState> emit) {
    emit(state.copyWith(showMonthlyRevenue: event.showMonthly));
  }
}
