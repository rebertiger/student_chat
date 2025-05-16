import 'package:dio/dio.dart'; // Import Dio
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// Calls the POST /api/auth/register endpoint.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? university,
    String? department,
  });

  /// Calls the POST /api/auth/login endpoint.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<UserModel> login({
    required String email,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? university,
    String? department,
  }) async {
    try {
      final response = await dioClient.post(
        '/auth/register', // Endpoint path relative to baseUrl
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'university': university,
          'department': department,
        },
      );

      if (response.statusCode == 201) {
        // Assuming the API returns { "message": "...", "user": { ... } }
        return UserModel.fromJson(
            response.data['user'] as Map<String, dynamic>);
      } else {
        // Handle other status codes if necessary, otherwise Dio throws DioException
        throw ServerException(
            message:
                'Registration failed with status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Handle Dio specific errors (network, timeout, response errors)
      final message = e.response?.data['message'] as String? ??
          e.message ??
          'Unknown registration error';
      throw ServerException(message: message);
    } catch (e) {
      // Handle other potential errors
      throw ServerException(
          message: 'An unexpected error occurred during registration.');
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dioClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        // Log the raw response for debugging
        print('Login response: ${response.data}');

        // The API returns { "message": "...", "user": { ... }, "token": "..." }
        final userData = response.data['user'] as Map<String, dynamic>;

        // Add the token to the user data before converting to UserModel
        userData['token'] = response.data['token'] as String?;

        return UserModel.fromJson(userData);
      } else {
        throw ServerException(
            message: 'Login failed with status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] as String? ??
          e.message ??
          'Unknown login error';
      throw ServerException(message: message);
    } catch (e) {
      throw ServerException(
          message: 'An unexpected error occurred during login.');
    }
  }
}

// Define a custom exception for server errors (optional but good practice)
class ServerException implements Exception {
  final String message;
  ServerException({this.message = 'An error occurred during API call.'});
}
