abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String role;
  final String? name;
  final String? phone;

  AuthAuthenticated({
    required this.role,
    this.name,
    this.phone
  });
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}