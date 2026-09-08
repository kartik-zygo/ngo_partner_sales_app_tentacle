part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.passwordChangeError,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
  // Set when PATCH /auth/me/password fails; cleared on new attempt or logout.
  final String? passwordChangeError;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    bool clearError = false,
    String? passwordChangeError,
    bool clearPasswordChangeError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      passwordChangeError: clearPasswordChangeError
          ? null
          : (passwordChangeError ?? this.passwordChangeError),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, passwordChangeError];
}
