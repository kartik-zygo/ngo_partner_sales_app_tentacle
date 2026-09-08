import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/usecases/auth_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required CheckSessionUseCase checkSessionUseCase,
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
    required SecureStorageService secureStorage,
    required SocketService socketService,
  })  : _checkSessionUseCase = checkSessionUseCase,
        _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _changePasswordUseCase = changePasswordUseCase,
        _secureStorage = secureStorage,
        _socketService = socketService,
        super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthChangePasswordRequested>(_onChangePasswordRequested);
  }

  final CheckSessionUseCase _checkSessionUseCase;
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final SecureStorageService _secureStorage;
  final SocketService _socketService;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final user = await _checkSessionUseCase();
      if (user == null) {
        emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
      } else {
        await _connectSocket();
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      }
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final user = await _loginUseCase(email: event.email, password: event.password);
      await _connectSocket();
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Invalid credentials. Please try again.',
      ));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    _socketService.disconnect();
    await _logoutUseCase();
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null, clearError: true));
  }

  Future<void> _onChangePasswordRequested(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearPasswordChangeError: true));
    try {
      await _changePasswordUseCase(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      _socketService.disconnect();
      await _logoutUseCase();
      emit(state.copyWith(status: AuthStatus.unauthenticated, user: null, clearError: true));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final String msg;
      if (code == 401) {
        msg = 'Current password is incorrect.';
      } else if (code == 400) {
        msg = 'New password must be at least 8 characters.';
      } else {
        msg = 'Failed to change password. Please try again.';
      }
      emit(state.copyWith(status: AuthStatus.authenticated, passwordChangeError: msg));
    } catch (_) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        passwordChangeError: 'Failed to change password. Please try again.',
      ));
    }
  }

  Future<void> _connectSocket() async {
    final token = await _secureStorage.getAccessToken();
    if (token != null) {
      _socketService.connect(token);
    }
  }
}
