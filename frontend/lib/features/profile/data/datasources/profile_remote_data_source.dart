import 'package:dio/dio.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../features/auth/data/datasources/auth_remote_data_source.dart'; // Import ServerException

abstract class ProfileRemoteDataSource {
  Future<UserProfile> fetchUserProfile();
  Future<void> updateUserProfile(UserProfile profile);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio dio;

  ProfileRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserProfile> fetchUserProfile() async {
    try {
      final response = await dio.get('/profile');

      if (response.statusCode == 200) {
        print('Profile API response: ${response.data}');
        return UserProfile.fromJson(response.data);
      } else {
        throw ServerException(
            message: 'Failed to fetch profile: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] as String? ??
          e.message ??
          'Unknown error fetching profile';

      if (e.response?.statusCode == 401) {
        throw ServerException(message: 'Unauthorized: Please login again');
      }

      throw ServerException(message: message);
    } catch (e) {
      throw ServerException(
          message: 'An unexpected error occurred fetching profile: $e');
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final response = await dio.put('/profile', data: profile.toJson());

      if (response.statusCode != 200) {
        throw ServerException(
            message: 'Failed to update profile: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] as String? ??
          e.message ??
          'Unknown error updating profile';
      throw ServerException(message: message);
    } catch (e) {
      throw ServerException(
          message: 'An unexpected error occurred updating profile: $e');
    }
  }
}
