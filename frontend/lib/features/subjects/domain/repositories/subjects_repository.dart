import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../entities/subject.dart';
import '../../data/datasources/subjects_remote_data_source.dart';

abstract class SubjectsRepository {
  Future<Either<Failure, List<Subject>>> getAllSubjects();
  Future<Either<Failure, List<Subject>>> getUserSubjects();
  Future<Either<Failure, void>> addUserSubject(int subjectId);
  Future<Either<Failure, void>> removeUserSubject(int subjectId);
}

class SubjectsRepositoryImpl implements SubjectsRepository {
  final SubjectsRemoteDataSource remoteDataSource;

  SubjectsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Subject>>> getAllSubjects() async {
    try {
      final subjectModels = await remoteDataSource.getAllSubjects();
      final subjects = subjectModels
          .map((e) =>
              Subject(id: e.id, name: e.name, description: e.description))
          .toList();
      return Right(subjects);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure());
      } else if (e is UnauthorizedException) {
        return Left(UnauthorizedFailure());
      } else {
        return Left(ServerFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<Subject>>> getUserSubjects() async {
    try {
      final subjectModels = await remoteDataSource.getUserSubjects();
      final subjects = subjectModels
          .map((e) =>
              Subject(id: e.id, name: e.name, description: e.description))
          .toList();
      return Right(subjects);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure());
      } else if (e is UnauthorizedException) {
        return Left(UnauthorizedFailure());
      } else {
        return Left(ServerFailure());
      }
    }
  }

  @override
  Future<Either<Failure, void>> addUserSubject(int subjectId) async {
    try {
      await remoteDataSource.addUserSubject(subjectId);
      return const Right(null);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure());
      } else if (e is UnauthorizedException) {
        return Left(UnauthorizedFailure());
      } else {
        return Left(ServerFailure());
      }
    }
  }

  @override
  Future<Either<Failure, void>> removeUserSubject(int subjectId) async {
    try {
      await remoteDataSource.removeUserSubject(subjectId);
      return const Right(null);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure());
      } else if (e is UnauthorizedException) {
        return Left(UnauthorizedFailure());
      } else {
        return Left(ServerFailure());
      }
    }
  }
}
