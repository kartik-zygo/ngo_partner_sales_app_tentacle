part of 'admin_services_bloc.dart';

enum AdminServicesStatus { initial, loading, success, failure }

class AdminServicesState extends Equatable {
  const AdminServicesState({
    this.status = AdminServicesStatus.initial,
    this.services = const [],
    this.categories = const [],
    this.approvals = const [],
    this.search = '',
    this.selectedCategory,
    this.includeInactive = false,
    this.message,
    this.errorMessage,
  });

  final AdminServicesStatus status;
  final List<ServicePackage> services;
  final List<String> categories;
  final List<ApprovalRequest> approvals;
  final String search;
  final String? selectedCategory;
  final bool includeInactive;
  final String? message;
  final String? errorMessage;

  AdminServicesState copyWith({
    AdminServicesStatus? status,
    List<ServicePackage>? services,
    List<String>? categories,
    List<ApprovalRequest>? approvals,
    String? search,
    Object? selectedCategory = _sentinel,
    bool? includeInactive,
    String? message,
    String? errorMessage,
  }) {
    return AdminServicesState(
      status: status ?? this.status,
      services: services ?? this.services,
      categories: categories ?? this.categories,
      approvals: approvals ?? this.approvals,
      search: search ?? this.search,
      selectedCategory: selectedCategory == _sentinel
          ? this.selectedCategory
          : selectedCategory as String?,
      includeInactive: includeInactive ?? this.includeInactive,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, services, categories, approvals, search, selectedCategory, includeInactive, message, errorMessage];
}

const _sentinel = Object();
