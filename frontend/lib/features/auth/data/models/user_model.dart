import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int userId;
  final String fullName;
  final String email;
  final String? university;
  final String? department;
  final DateTime createdAt;
  final String? token; // Auth token'ı saklamak için

  const UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.university,
    this.department,
    required this.createdAt,
    this.token, // Auth token'ı constructor'a ekle
  });

  // Factory constructor to create a UserModel from JSON data (API response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      university: json['university'] as String?,
      department: json['department'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      token: json['token'] as String?, // JSON'dan token'ı al
    );
  }

  // Method to convert UserModel instance to JSON (less common for models, but can be useful)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'university': university,
      'department': department,
      'created_at': createdAt.toIso8601String(),
      'token': token, // Token'ı JSON'a ekle
    };
  }

  @override
  List<Object?> get props => [
        userId,
        fullName,
        email,
        university,
        department,
        createdAt,
        token, // Token'ı props listesine ekle
      ];
}
