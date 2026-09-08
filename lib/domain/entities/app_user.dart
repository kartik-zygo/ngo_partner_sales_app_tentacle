import 'package:equatable/equatable.dart';

enum AppRole { sales, admin }

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.organizationName,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final AppRole role;
  final String? phone;
  final String? organizationName;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, email, role, phone, organizationName, isActive];
}
