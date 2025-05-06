import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String username;
  final String university;
  final String department;
  final String? profilePictureUrl;
  final String? bio;

  const UserProfile({
    required this.username,
    required this.university,
    required this.department,
    this.profilePictureUrl,
    this.bio,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] ?? '',
      university: json['university'] ?? '',
      department: json['department'] ?? '',
      profilePictureUrl: json['profilePictureUrl'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'university': university,
      'department': department,
      'profilePictureUrl': profilePictureUrl,
      'bio': bio,
    };
  }

  @override
  List<Object?> get props =>
      [username, university, department, profilePictureUrl, bio];
}
