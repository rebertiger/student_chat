part of 'auth_cubit.dart'; // Use 'part of' for states related to the cubit

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Initial state before any action is taken
class AuthInitial extends AuthState {}

// State when an authentication operation (login/register) is in progress
class AuthLoading extends AuthState {}

// State when the user is successfully authenticated
class AuthAuthenticated extends AuthState {
  final UserModel user; // Include user data upon successful authentication

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

// State when an authentication operation fails
class AuthError extends AuthState {
  final String message; // Error message to display to the user

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
