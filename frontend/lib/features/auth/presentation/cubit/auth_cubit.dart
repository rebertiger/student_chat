import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/user_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_data_source.dart'; // For ServerException

part 'auth_state.dart'; // Include the state definitions

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  final UserService userService;

  AuthCubit({
    required this.authRepository,
    required this.userService,
  }) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(email: email, password: password);
      userService
          .setCurrentUser(user); // Kullanıcı bilgilerini global servise kaydet
      emit(AuthAuthenticated(user));
    } on ServerException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      // Catch any other unexpected errors
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
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
      userService
          .setCurrentUser(user); // Kullanıcı bilgilerini global servise kaydet
      emit(AuthAuthenticated(user));
    } on ServerException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> deleteUser() async {
    emit(AuthDeleting());
    try {
      await authRepository.deleteUser();
      userService.clearCurrentUser();
      emit(AuthDeleted());
    } on ServerException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('An unexpected error occurred'));
    }
  }
}
