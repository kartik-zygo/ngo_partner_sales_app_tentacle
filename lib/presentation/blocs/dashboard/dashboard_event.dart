part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardLoaded extends DashboardEvent {
  const DashboardLoaded(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

class DashboardRevenueToggled extends DashboardEvent {
  const DashboardRevenueToggled(this.showMonthly);

  final bool showMonthly;

  @override
  List<Object?> get props => [showMonthly];
}
