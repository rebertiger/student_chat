import 'package:equatable/equatable.dart';
import '../../../auth/data/models/user_model.dart'; // Assuming creator info might be needed

// Model representing a chat room, mirroring backend structure
class RoomModel extends Equatable {
  final int roomId;
  final String roomName;
  final bool isPublic;
  final DateTime createdAt;
  final int? subjectId; // Optional subject ID
  final String? subjectName; // Optional subject name (from include)
  final int? createdBy; // Optional creator ID
  final String? creatorName; // Optional creator name (from include)

  const RoomModel({
    required this.roomId,
    required this.roomName,
    required this.isPublic,
    required this.createdAt,
    this.subjectId,
    this.subjectName,
    this.createdBy,
    this.creatorName,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely extract nested properties
    T? safeGet<T>(Map<String, dynamic>? obj, String key) {
      return obj != null && obj.containsKey(key) ? obj[key] as T? : null;
    }

    return RoomModel(
      roomId: json['room_id'] as int,
      roomName: json['room_name'] as String,
      isPublic: json['is_public'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      subjectId: json['subject_id'] as int?,
      subjectName:
          safeGet<String>(json['subject'] as Map<String, dynamic>?, 'name'),
      createdBy: json['created_by'] as int?,
      creatorName: safeGet<String>(
          json['creator'] as Map<String, dynamic>?, 'full_name'),
    );
  }

  Map<String, dynamic> toJson() {
    // Primarily used for sending data *to* the backend (e.g., creating a room)
    // The backend expects room_name, subject_id, is_public
    return {
      'room_id': roomId,
      'room_name': roomName,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'subject_id': subjectId,
      'created_by': createdBy,
      // Include nested objects if needed, but usually not for sending simple models
    };
  }

  @override
  List<Object?> get props => [
        roomId,
        roomName,
        isPublic,
        createdAt,
        subjectId,
        subjectName,
        createdBy,
        creatorName,
      ];
}
