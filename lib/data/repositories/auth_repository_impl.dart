import '../../core/services/secure_storage_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage);

  final RemoteDataSource _remote;
  final SecureStorageService _storage;

  @override
  Future<AppUser?> getCurrentSession() async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;
    try {
      return await _remote.getMe();
    } catch (_) {
      await _storage.clearTokens();
      return null;
    }
  }

  @override
  Future<AppUser> login({required String email, required String password}) async {
    final data = await _remote.loginRaw(email, password);
    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    final userMap = data['user'] as Map<String, dynamic>;
    final roles = (userMap['roles'] as List? ?? ['SALES']).cast<String>();
    final isAdmin = roles.contains('ADMIN');
    return AppUser(
      id: userMap['id'] as String,
      name: userMap['email'] as String? ?? '',
      email: userMap['email'] as String? ?? '',
      role: isAdmin ? AppRole.admin : AppRole.sales,
    );
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    await _remote.logout(refreshToken ?? '');
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _remote.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<String> deleteAccount({required String password, String? reason}) async {
    final message = await _remote.deleteAccount(password: password, reason: reason);
    // The server has already revoked every session; drop the dead tokens.
    await _storage.clearTokens();
    return message;
  }
}
