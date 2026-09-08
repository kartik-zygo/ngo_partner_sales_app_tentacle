import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentSession();
  Future<AppUser> login({required String email, required String password});
  Future<void> logout();
  Future<void> changePassword({required String currentPassword, required String newPassword});
}
