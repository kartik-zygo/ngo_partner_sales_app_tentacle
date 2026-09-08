part of 'admin_reports_bloc.dart';

enum AdminReportsStatus { initial, loading, success, failure }

class AdminReportsState extends Equatable {
  const AdminReportsState({
    this.status = AdminReportsStatus.initial,
    required this.fromDate,
    required this.toDate,
    this.records = const [],
    this.exportHistory = const [],
    this.permissionToggles = const {},
    this.message,
    this.errorMessage,
  });

  final AdminReportsStatus status;
  final DateTime fromDate;
  final DateTime toDate;
  final List<RevenueRecord> records;
  final List<String> exportHistory;
  final Map<String, bool> permissionToggles;
  final String? message;
  final String? errorMessage;

  AdminReportsState copyWith({
    AdminReportsStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    List<RevenueRecord>? records,
    List<String>? exportHistory,
    Map<String, bool>? permissionToggles,
    String? message,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminReportsState(
      status: status ?? this.status,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      records: records ?? this.records,
      exportHistory: exportHistory ?? this.exportHistory,
      permissionToggles: permissionToggles ?? this.permissionToggles,
      message: message ?? this.message,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        fromDate,
        toDate,
        records,
        exportHistory,
        permissionToggles,
        message,
        errorMessage,
      ];
}
