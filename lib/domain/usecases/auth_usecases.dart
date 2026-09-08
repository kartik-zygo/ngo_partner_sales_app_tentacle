import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class CheckSessionUseCase {
  CheckSessionUseCase(this._repository);
  final AuthRepository _repository;

  Future<AppUser?> call() => _repository.getCurrentSession();
}

class LoginUseCase {
  LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }
}

class LogoutUseCase {
  LogoutUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}

class ChangePasswordUseCase {
  ChangePasswordUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({required String currentPassword, required String newPassword}) {
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
