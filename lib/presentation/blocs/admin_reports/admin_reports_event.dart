part of 'admin_reports_bloc.dart';

sealed class AdminReportsEvent extends Equatable {
  const AdminReportsEvent();

  @override
  List<Object?> get props => [];
}

class AdminReportsLoaded extends AdminReportsEvent {
  const AdminReportsLoaded();
}

class ReportDateRangeChanged extends AdminReportsEvent {
  const ReportDateRangeChanged({required this.fromDate, required this.toDate});

  final DateTime fromDate;
  final DateTime toDate;

  @override
  List<Object?> get props => [fromDate, toDate];
}

class ReportExportRequested extends AdminReportsEvent {
  const ReportExportRequested();
}

class ReportPermissionToggled extends AdminReportsEvent {
  const ReportPermissionToggled({required this.key, required this.value});

  final String key;
  final bool value;

  @override
  List<Object?> get props => [key, value];
}
