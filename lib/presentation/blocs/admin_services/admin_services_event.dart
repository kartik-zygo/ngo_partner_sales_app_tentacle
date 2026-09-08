part of 'admin_services_bloc.dart';

sealed class AdminServicesEvent extends Equatable {
  const AdminServicesEvent();

  @override
  List<Object?> get props => [];
}

class AdminServicesLoaded extends AdminServicesEvent {
  const AdminServicesLoaded();
}

class AdminServicesFilterChanged extends AdminServicesEvent {
  const AdminServicesFilterChanged({
    this.search,
    this.selectedCategory,
    this.includeInactive,
  });

  final String? search;
  final String? selectedCategory;
  final bool? includeInactive;

  @override
  List<Object?> get props => [search, selectedCategory, includeInactive];
}

class ServicePackageSaved extends AdminServicesEvent {
  const ServicePackageSaved(this.servicePackage);

  final ServicePackage servicePackage;

  @override
  List<Object?> get props => [servicePackage];
}

class ServicePackageToggled extends AdminServicesEvent {
  const ServicePackageToggled({required this.id, required this.isActive});

  final String id;
  final bool isActive;

  @override
  List<Object?> get props => [id, isActive];
}

class ServicePackageDeleted extends AdminServicesEvent {
  const ServicePackageDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class ApprovalDecisionRequested extends AdminServicesEvent {
  const ApprovalDecisionRequested({required this.id, required this.status});

  final String id;
  final ApprovalStatus status;

  @override
  List<Object?> get props => [id, status];
}
