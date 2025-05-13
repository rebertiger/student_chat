import 'package:frontend/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> fetchUserProfile();
  Future<void> updateUserProfile(UserProfile profile);
}