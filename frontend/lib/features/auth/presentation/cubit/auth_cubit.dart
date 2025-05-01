import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_data_source.dart'; // For ServerException

part 'auth_state.dart'; // Include the state definitions

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(email: email, password: password);
      emit(AuthAuthenticated(user: user));
    } on ServerException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      // Catch any other unexpected errors
      emit(AuthError(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? university,
    String? department,
  }) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
        university: university,
        department: department,
      );
      emit(AuthAuthenticated(user: user));
    } on ServerException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }
}
