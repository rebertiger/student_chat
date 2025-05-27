import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';
// Import error handling utilities if needed (e.g., for Either type)

// Abstract interface for the Auth Repository
abstract class AuthRepository {
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? university,
    String? department,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<void> deleteUser();
}

// Implementation of the Auth Repository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  // final NetworkInfo networkInfo; // Optional: Inject network connectivity checker

  AuthRepositoryImpl({
    required this.remoteDataSource,
    // required this.networkInfo,
  });

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? university,
    String? department,
  }) async {
    // Optional: Check network connectivity first
    // if (await networkInfo.isConnected) {
    try {
      final userModel = await remoteDataSource.register(
        email: email,
        password: password,
        fullName: fullName,
        university: university,
        department: department,
      );
      // In a more complex app, you might map UserModel to a domain User entity here
      return userModel;
    } on ServerException catch (e) {
      // Re-throw or handle specific server exceptions
      // Could wrap in a custom Failure type using Either package
      throw ServerException(message: e.message);
    }
    // } else {
    //   // Handle no network connection
    //   throw NetworkException(); // Define a custom NetworkException
    // }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Optional: Check network connectivity first
    // if (await networkInfo.isConnected) {
    try {
      final userModel = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Log the token to debug (remove in production)
      print('Token received: ${userModel.token}');

      return userModel;
    } on ServerException catch (e) {
      throw ServerException(message: e.message);
    }
    // } else {
    //   throw NetworkException();
    // }
  }

  @override
  Future<void> deleteUser() async {
    try {
      await remoteDataSource.deleteUser();
    } on ServerException catch (e) {
      throw ServerException(message: e.message);
    }
  }
}

// Example of NetworkInfo interface (if needed)
// abstract class NetworkInfo {
//   Future<bool> get isConnected;
// }

// Example of NetworkException (if needed)
// class NetworkException implements Exception {}
