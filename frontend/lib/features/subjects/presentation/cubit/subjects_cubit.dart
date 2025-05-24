import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subjects_repository.dart';

// Events
abstract class SubjectsEvent extends Equatable {
  const SubjectsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllSubjects extends SubjectsEvent {}

class LoadUserSubjects extends SubjectsEvent {}

class AddUserSubject extends SubjectsEvent {
  final int subjectId;

  const AddUserSubject(this.subjectId);

  @override
  List<Object?> get props => [subjectId];
}

class RemoveUserSubject extends SubjectsEvent {
  final int subjectId;

  const RemoveUserSubject(this.subjectId);

  @override
  List<Object?> get props => [subjectId];
}

// States
abstract class SubjectsState extends Equatable {
  const SubjectsState();

  @override
  List<Object?> get props => [];
}

class SubjectsInitial extends SubjectsState {}

class SubjectsLoading extends SubjectsState {}

class SubjectsLoaded extends SubjectsState {
  final List<Subject> allSubjects;
  final List<Subject> userSubjects;

  const SubjectsLoaded({
    required this.allSubjects,
    required this.userSubjects,
  });

  @override
  List<Object?> get props => [allSubjects, userSubjects];
}

class SubjectsError extends SubjectsState {
  final String message;

  const SubjectsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class SubjectsCubit extends Cubit<SubjectsState> {
  final SubjectsRepository repository;

  SubjectsCubit({required this.repository}) : super(SubjectsInitial());

  Future<void> loadAllSubjects() async {
    emit(SubjectsLoading());
    final result = await repository.getAllSubjects();
    result.fold(
      (failure) => emit(SubjectsError('Failed to load subjects')),
      (subjects) {
        if (state is SubjectsLoaded) {
          final currentState = state as SubjectsLoaded;
          emit(SubjectsLoaded(
            allSubjects: subjects,
            userSubjects: currentState.userSubjects,
          ));
        } else {
          emit(SubjectsLoaded(
            allSubjects: subjects,
            userSubjects: const [],
          ));
        }
      },
    );
  }

  Future<void> loadUserSubjects() async {
    emit(SubjectsLoading());
    final result = await repository.getUserSubjects();
    result.fold(
      (failure) => emit(SubjectsError('Failed to load user subjects')),
      (subjects) {
        if (state is SubjectsLoaded) {
          final currentState = state as SubjectsLoaded;
          emit(SubjectsLoaded(
            allSubjects: currentState.allSubjects,
            userSubjects: subjects,
          ));
        } else {
          emit(SubjectsLoaded(
            allSubjects: const [],
            userSubjects: subjects,
          ));
        }
      },
    );
  }

  Future<void> addUserSubject(int subjectId) async {
    final result = await repository.addUserSubject(subjectId);
    result.fold(
      (failure) => emit(SubjectsError('Failed to add subject')),
      (_) => loadUserSubjects(),
    );
  }

  Future<void> removeUserSubject(int subjectId) async {
    final result = await repository.removeUserSubject(subjectId);
    result.fold(
      (failure) => emit(SubjectsError('Failed to remove subject')),
      (_) => loadUserSubjects(),
    );
  }
}
