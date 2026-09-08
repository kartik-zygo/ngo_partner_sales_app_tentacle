import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/approval_request.dart';
import '../../../domain/entities/service_package.dart';
import '../../../domain/usecases/admin_usecases.dart';

part 'admin_services_event.dart';
part 'admin_services_state.dart';

class AdminServicesBloc extends Bloc<AdminServicesEvent, AdminServicesState> {
  AdminServicesBloc({
    required GetServicePackagesUseCase getServicePackagesUseCase,
    required GetServiceCategoriesUseCase getServiceCategoriesUseCase,
    required UpsertServicePackageUseCase upsertServicePackageUseCase,
    required ToggleServicePackageUseCase toggleServicePackageUseCase,
    required DeleteServicePackageUseCase deleteServicePackageUseCase,
    required GetApprovalRequestsUseCase getApprovalRequestsUseCase,
    required DecideApprovalUseCase decideApprovalUseCase,
  })  : _getServicePackagesUseCase = getServicePackagesUseCase,
        _getServiceCategoriesUseCase = getServiceCategoriesUseCase,
        _upsertServicePackageUseCase = upsertServicePackageUseCase,
        _toggleServicePackageUseCase = toggleServicePackageUseCase,
        _deleteServicePackageUseCase = deleteServicePackageUseCase,
        _getApprovalRequestsUseCase = getApprovalRequestsUseCase,
        _decideApprovalUseCase = decideApprovalUseCase,
        super(const AdminServicesState()) {
    on<AdminServicesLoaded>(_onLoaded);
    on<AdminServicesFilterChanged>(_onFilterChanged);
    on<ServicePackageSaved>(_onServiceSaved);
    on<ServicePackageToggled>(_onServiceToggled);
    on<ServicePackageDeleted>(_onServiceDeleted);
    on<ApprovalDecisionRequested>(_onApprovalDecisionRequested);
  }

  final GetServicePackagesUseCase _getServicePackagesUseCase;
  final GetServiceCategoriesUseCase _getServiceCategoriesUseCase;
  final UpsertServicePackageUseCase _upsertServicePackageUseCase;
  final ToggleServicePackageUseCase _toggleServicePackageUseCase;
  final DeleteServicePackageUseCase _deleteServicePackageUseCase;
  final GetApprovalRequestsUseCase _getApprovalRequestsUseCase;
  final DecideApprovalUseCase _decideApprovalUseCase;

  Future<void> _onLoaded(AdminServicesLoaded event, Emitter<AdminServicesState> emit) async {
    emit(state.copyWith(status: AdminServicesStatus.loading));
    try {
      final results = await Future.wait([
        _getServicePackagesUseCase(
          category: state.selectedCategory,
          search: state.search.isEmpty ? null : state.search,
          includeInactive: state.includeInactive,
        ),
        _getServiceCategoriesUseCase(),
        _getApprovalRequestsUseCase(),
      ]);
      emit(state.copyWith(
        status: AdminServicesStatus.success,
        services: results[0] as List<ServicePackage>,
        categories: results[1] as List<String>,
        approvals: results[2] as List<ApprovalRequest>,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminServicesStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFilterChanged(
    AdminServicesFilterChanged event,
    Emitter<AdminServicesState> emit,
  ) async {
    emit(state.copyWith(
      search: event.search ?? state.search,
      selectedCategory: event.selectedCategory,
      includeInactive: event.includeInactive ?? state.includeInactive,
    ));
    add(const AdminServicesLoaded());
  }

  Future<void> _onServiceSaved(ServicePackageSaved event, Emitter<AdminServicesState> emit) async {
    try {
      await _upsertServicePackageUseCase(event.servicePackage);
      emit(state.copyWith(message: 'Service saved'));
      add(const AdminServicesLoaded());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onServiceToggled(
    ServicePackageToggled event,
    Emitter<AdminServicesState> emit,
  ) async {
    try {
      await _toggleServicePackageUseCase(event.id, event.isActive);
      emit(state.copyWith(message: event.isActive ? 'Service activated' : 'Service deactivated'));
      add(const AdminServicesLoaded());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onServiceDeleted(
    ServicePackageDeleted event,
    Emitter<AdminServicesState> emit,
  ) async {
    try {
      await _deleteServicePackageUseCase(event.id);
      emit(state.copyWith(message: 'Service deleted'));
      add(const AdminServicesLoaded());
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Cannot delete: ${e.toString()}'));
    }
  }

  Future<void> _onApprovalDecisionRequested(
    ApprovalDecisionRequested event,
    Emitter<AdminServicesState> emit,
  ) async {
    try {
      await _decideApprovalUseCase(event.id, event.status);
      emit(state.copyWith(message: 'Approval updated'));
      add(const AdminServicesLoaded());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
