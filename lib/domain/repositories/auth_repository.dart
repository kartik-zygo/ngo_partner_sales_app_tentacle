import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentSession();
  Future<AppUser> login({required String email, required String password});
  Future<void> logout();
  Future<void> changePassword({required String currentPassword, required String newPassword});

  /// Permanently deletes the signed-in account and returns the server's
  /// confirmation message. Throws [AccountDeletionException] when refused.
  Future<String> deleteAccount({required String password, String? reason});
}

/// A refused account deletion, carrying a message fit to show the user.
class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message);

  final String message;

  @override
  String toString() => message;
}
