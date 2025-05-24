import 'package:equatable/equatable.dart';

class SubjectModel extends Equatable {
  final int id;
  final String name;
  final String? description;

  const SubjectModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['subject_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_id': id,
      'name': name,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, name, description];
}
