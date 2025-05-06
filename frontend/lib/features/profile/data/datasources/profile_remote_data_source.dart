import 'package:dio/dio.dart';
import '../../domain/entities/user_profile.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfile> fetchUserProfile();
  Future<void> updateUserProfile(UserProfile profile);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio dio;

  ProfileRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserProfile> fetchUserProfile() async {
    final response = await dio.get('/profile');
    if (response.statusCode == 200) {
      return UserProfile.fromJson(response.data);
    } else {
      throw Exception('Profil verisi alınamadı');
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    final response = await dio.put('/profile', data: profile.toJson());
    if (response.statusCode != 200) {
      throw Exception('Profil güncellenemedi');
    }
  }
}
