import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/revenue_record.dart';
import '../../../domain/usecases/admin_usecases.dart';

part 'admin_reports_event.dart';
part 'admin_reports_state.dart';

class AdminReportsBloc extends Bloc<AdminReportsEvent, AdminReportsState> {
  AdminReportsBloc({
    required GetRevenueRecordsUseCase getRevenueRecordsUseCase,
    required ExportReportUseCase exportReportUseCase,
    required GetReportExportHistoryUseCase getReportExportHistoryUseCase,
  })  : _getRevenueRecordsUseCase = getRevenueRecordsUseCase,
        _exportReportUseCase = exportReportUseCase,
        _getReportExportHistoryUseCase = getReportExportHistoryUseCase,
        super(AdminReportsState(
          fromDate: DateTime.now().subtract(const Duration(days: 30)),
          toDate: DateTime.now(),
          permissionToggles: const {
            'canApproveDiscounts': true,
            'canEditServices': true,
            'canManageTeam': true,
          },
        )) {
    on<AdminReportsLoaded>(_onLoaded);
    on<ReportDateRangeChanged>(_onDateRangeChanged);
    on<ReportExportRequested>(_onExportRequested);
    on<ReportPermissionToggled>(_onPermissionToggled);
  }

  final GetRevenueRecordsUseCase _getRevenueRecordsUseCase;
  final ExportReportUseCase _exportReportUseCase;
  final GetReportExportHistoryUseCase _getReportExportHistoryUseCase;

  Future<void> _onLoaded(AdminReportsLoaded event, Emitter<AdminReportsState> emit) async {
    emit(state.copyWith(status: AdminReportsStatus.loading, clearError: true));
    try {
      final records = await _getRevenueRecordsUseCase(state.fromDate, state.toDate);
      final history = await _getReportExportHistoryUseCase();
      emit(state.copyWith(
        status: AdminReportsStatus.success,
        records: records,
        exportHistory: history,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminReportsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDateRangeChanged(
    ReportDateRangeChanged event,
    Emitter<AdminReportsState> emit,
  ) async {
    emit(state.copyWith(fromDate: event.fromDate, toDate: event.toDate));
    add(const AdminReportsLoaded());
  }

  Future<void> _onExportRequested(
    ReportExportRequested event,
    Emitter<AdminReportsState> emit,
  ) async {
    try {
      final fileName = await _exportReportUseCase(state.fromDate, state.toDate);
      final history = await _getReportExportHistoryUseCase();
      emit(state.copyWith(exportHistory: history, message: 'Exported $fileName'));
    } catch (e) {
      emit(state.copyWith(
        status: AdminReportsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onPermissionToggled(
    ReportPermissionToggled event,
    Emitter<AdminReportsState> emit,
  ) {
    final updated = Map<String, bool>.from(state.permissionToggles);
    updated[event.key] = event.value;
    emit(state.copyWith(permissionToggles: updated, message: 'Permission updated'));
  }
}
