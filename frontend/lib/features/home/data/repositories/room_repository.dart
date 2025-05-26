import '../../../../features/auth/data/datasources/auth_remote_data_source.dart'; // For ServerException
import '../datasources/room_remote_data_source.dart';
import '../models/room_model.dart';

// Abstract interface for the Room Repository
abstract class RoomRepository {
  Future<List<RoomModel>> getRooms();
  Future<RoomModel> createRoom({
    required String roomName,
    int? subjectId,
    bool? isPublic,
    int? createdBy,
  });
  Future<void> joinRoom({required int roomId});
}

// Implementation of the Room Repository
class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource remoteDataSource;
  // final NetworkInfo networkInfo; // Optional

  RoomRepositoryImpl({
    required this.remoteDataSource,
    // required this.networkInfo,
  });

  @override
  Future<List<RoomModel>> getRooms() async {
    // Optional: Check network connectivity
    try {
      final roomModels = await remoteDataSource.getRooms();
      // Map to domain entities if needed
      return roomModels;
    } on ServerException catch (e) {
      // Handle or re-throw specific exceptions
      throw ServerException(message: e.message);
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
      final newRoom = await remoteDataSource.createRoom(
        roomName: roomName,
        subjectId: subjectId,
        isPublic: isPublic,
        createdBy: createdBy,
      );
      return newRoom;
    } on ServerException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<void> joinRoom({required int roomId}) async {
    // Optional: Check network connectivity
    try {
      await remoteDataSource.joinRoom(roomId: roomId);
      // No return value needed
    } on ServerException catch (e) {
      // Handle or re-throw specific exceptions
      throw ServerException(message: e.message);
    }
  }
}
