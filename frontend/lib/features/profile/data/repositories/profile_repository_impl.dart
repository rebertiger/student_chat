import 'package:dio/dio.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserProfile> fetchUserProfile() async {
    return await remoteDataSource.fetchUserProfile();
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    await remoteDataSource.updateUserProfile(profile);
  }
}
