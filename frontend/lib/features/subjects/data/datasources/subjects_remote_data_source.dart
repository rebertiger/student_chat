import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/subject_model.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/user_service.dart';

abstract class SubjectsRemoteDataSource {
  Future<List<SubjectModel>> getAllSubjects();
  Future<List<SubjectModel>> getUserSubjects();
  Future<void> addUserSubject(int subjectId);
  Future<void> removeUserSubject(int subjectId);
}

class SubjectsRemoteDataSourceImpl implements SubjectsRemoteDataSource {
  final http.Client client;
  final UserService userService;
  final String baseUrl;

  SubjectsRemoteDataSourceImpl({
    required this.client,
    required this.userService,
    required this.baseUrl,
  });

  @override
  Future<List<SubjectModel>> getAllSubjects() async {
    final token = userService.getToken();
    if (token == null) throw UnauthorizedException();

    final response = await client.get(
      Uri.parse('$baseUrl/api/subjects'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => SubjectModel.fromJson(json)).toList();
    } else {
      throw ServerException();
    }
  }

  @override
  Future<List<SubjectModel>> getUserSubjects() async {
    final token = userService.getToken();
    if (token == null) throw UnauthorizedException();

    final response = await client.get(
      Uri.parse('$baseUrl/api/subjects/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => SubjectModel.fromJson(json)).toList();
    } else {
      throw ServerException();
    }
  }

  @override
  Future<void> addUserSubject(int subjectId) async {
    final token = userService.getToken();
    if (token == null) throw UnauthorizedException();

    final response = await client.post(
      Uri.parse('$baseUrl/api/subjects/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'subjectId': subjectId}),
    );

    if (response.statusCode != 201) {
      throw ServerException();
    }
  }

  @override
  Future<void> removeUserSubject(int subjectId) async {
    final token = userService.getToken();
    if (token == null) throw UnauthorizedException();

    final response = await client.delete(
      Uri.parse('$baseUrl/api/subjects/user/$subjectId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw ServerException();
    }
  }
}
