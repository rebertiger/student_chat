import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  final int id;
  final String name;
  final String? description;

  const Subject({
    required this.id,
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, description];
}
