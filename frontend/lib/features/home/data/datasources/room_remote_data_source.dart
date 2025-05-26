import 'package:dio/dio.dart';
import '../../../../features/auth/data/datasources/auth_remote_data_source.dart'; // For ServerException
import '../models/room_model.dart';

abstract class RoomRemoteDataSource {
  /// Calls the GET /api/rooms endpoint.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<List<RoomModel>> getRooms();

  /// Calls the POST /api/rooms endpoint.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<RoomModel> createRoom({
    required String roomName,
    int? subjectId,
    bool? isPublic,
    int? createdBy,
  });

  /// Calls the POST /api/rooms/:roomId/join endpoint.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<void> joinRoom({required int roomId});
}

class RoomRemoteDataSourceImpl implements RoomRemoteDataSource {
  final Dio dioClient;

  RoomRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<RoomModel>> getRooms() async {
    try {
      final response = await dioClient.get('/rooms');

      if (response.statusCode == 200) {
        final List<dynamic> roomListJson = response.data as List<dynamic>;
        return roomListJson
            .map((json) => RoomModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
            message: 'Failed to fetch rooms: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] as String? ??
          e.message ??
          'Unknown error fetching rooms';
      throw ServerException(message: message);
    } catch (e) {
      throw ServerException(
          message: 'An unexpected error occurred while fetching rooms.');
    }
  }

  @override
  Future<RoomModel> createRoom({
    required String roomName,
    int? subjectId,
    bool? isPublic,
    int? createdBy,
  }) async {
    try {
      final response = await dioClient.post(
        '/rooms',
        data: {
          'room_name': roomName,
          'subject_id': subjectId,
          'is_public': isPublic,
          'created_by': createdBy,
        },
      );

      if (response.statusCode == 201) {
        return RoomModel.fromJson(
            response.data['room'] as Map<String, dynamic>);
      } else {
        throw ServerException(
            message:
                'Room creation failed with status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] as String? ??
          e.message ??
          'Unknown room creation error';
      throw ServerException(message: message);
    } catch (e) {
      throw ServerException(
          message: 'An unexpected error occurred during room creation.');
    }
  }

  @override
  Future<void> joinRoom({required int roomId}) async {
    try {
      final response = await dioClient.post('/rooms/$roomId/join');

      if (response.statusCode != 200) {
        throw ServerException(
            message: 'Failed to join room: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] as String? ??
          e.message ??
          'Unknown error joining room';
      throw ServerException(message: message);
    } catch (e) {
      throw ServerException(
          message: 'An unexpected error occurred while joining room.');
    }
  }
}
