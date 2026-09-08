part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, success, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.salesSummary,
    this.adminSummary,
    this.integrationMetrics,
    this.showMonthlyRevenue = false,
    this.error,
  });

  final DashboardStatus status;
  final SalesDashboardSummary? salesSummary;
  final AdminDashboardSummary? adminSummary;
  final IntegrationDashboardMetrics? integrationMetrics;
  final bool showMonthlyRevenue;
  final String? error;

  DashboardState copyWith({
    DashboardStatus? status,
    SalesDashboardSummary? salesSummary,
    AdminDashboardSummary? adminSummary,
    IntegrationDashboardMetrics? integrationMetrics,
    bool? showMonthlyRevenue,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      salesSummary: salesSummary ?? this.salesSummary,
      adminSummary: adminSummary ?? this.adminSummary,
      integrationMetrics: integrationMetrics ?? this.integrationMetrics,
      showMonthlyRevenue: showMonthlyRevenue ?? this.showMonthlyRevenue,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        status,
        salesSummary,
        adminSummary,
        integrationMetrics,
        showMonthlyRevenue,
        error,
      ];
}
