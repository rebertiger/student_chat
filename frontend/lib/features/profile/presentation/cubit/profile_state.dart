part of 'profile_cubit.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final String username;
  final String university;
  final String department;
  final String? profilePictureUrl;
  final String? bio;

  const ProfileLoaded({
    required this.username,
    required this.university,
    required this.department,
    this.profilePictureUrl,
    this.bio,
  });

  @override
  List<Object> get props =>
      [username, university, department, profilePictureUrl ?? '', bio ?? ''];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object> get props => [message];
}

class ProfileUpdating extends ProfileState {}

class ProfileUpdateSuccess extends ProfileState {}

class ProfileUpdateError extends ProfileState {
  final String message;

  const ProfileUpdateError(this.message);

  @override
  List<Object> get props => [message];
}
