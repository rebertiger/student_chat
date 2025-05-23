import 'package:equatable/equatable.dart';

class Room extends Equatable {
  final int id;
  final String name;
  final bool isPublic;
  final String? subject;
  final int? participantCount;
  final int? createdBy;
  final String? creatorName;
  final DateTime? createdAt;

  const Room({
    required this.id,
    required this.name,
    required this.isPublic,
    this.subject,
    this.participantCount,
    this.createdBy,
    this.creatorName,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        isPublic,
        subject,
        participantCount,
        createdBy,
        creatorName,
        createdAt,
      ];

  Room copyWith({
    int? id,
    String? name,
    bool? isPublic,
    String? subject,
    int? participantCount,
    int? createdBy,
    String? creatorName,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      isPublic: isPublic ?? this.isPublic,
      subject: subject ?? this.subject,
      participantCount: participantCount ?? this.participantCount,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
