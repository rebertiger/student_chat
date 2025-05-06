import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit(this._profileRepository) : super(ProfileInitial());

  Future<void> loadProfile() async {
    try {
      emit(ProfileLoading());
      final profile = await _profileRepository.fetchUserProfile();
      emit(ProfileLoaded(
        username: profile.username,
        university: profile.university,
        department: profile.department,
        profilePictureUrl: profile.profilePictureUrl,
        bio: profile.bio,
      ));
    } catch (e) {
      emit(ProfileError('Profil yüklenemedi: ${e.toString()}'));
    }
  }

  Future<void> updateProfile({
    String? username,
    String? university,
    String? department,
    String? profilePictureUrl,
    String? bio,
  }) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      try {
        emit(ProfileUpdating());
        final updatedProfile = UserProfile(
          username: username ?? currentState.username,
          university: university ?? currentState.university,
          department: department ?? currentState.department,
          profilePictureUrl:
              profilePictureUrl ?? currentState.profilePictureUrl,
          bio: bio ?? currentState.bio,
        );
        await _profileRepository.updateUserProfile(updatedProfile);
        await loadProfile();
      } catch (e) {
        emit(ProfileUpdateError('Profil güncellenemedi: ${e.toString()}'));
        emit(currentState);
      }
    } else {
      emit(const ProfileError('Profil yüklenmeden güncellenemez.'));
    }
  }
}
