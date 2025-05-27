import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/user_service.dart'; // UserService için import
import '../../../../features/auth/data/datasources/auth_remote_data_source.dart'; // For ServerException
import '../../data/models/room_model.dart';
import '../../data/repositories/room_repository.dart';

part 'room_state.dart'; // Include the state definitions

class RoomCubit extends Cubit<RoomState> {
  final RoomRepository roomRepository;
  final UserService userService;

  RoomCubit({required this.roomRepository, required this.userService})
      : super(RoomInitial());

  // Method to load the list of rooms
  Future<void> loadRooms() async {
    emit(RoomLoading());
    try {
      final rooms = await roomRepository.getRooms();
      emit(RoomLoaded(rooms: rooms));
    } on ServerException catch (e) {
      emit(RoomError(message: e.message));
    } catch (e) {
      emit(RoomError(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  // Method to create a new room
  Future<void> createRoom({
    required String roomName,
    int? subjectId,
    bool? isPublic,
  }) async {
    final currentState = state;
    if (currentState is! RoomLoading) {
      emit(RoomLoading());
    }

    try {
      final currentUser = userService.getCurrentUser();
      final userId = currentUser?.userId;

      final newRoom = await roomRepository.createRoom(
        roomName: roomName,
        subjectId: subjectId,
        isPublic: isPublic,
        createdBy: userId,
      );
      await loadRooms();
    } on ServerException catch (e) {
      emit(RoomError(message: e.message));
    } catch (e) {
      emit(RoomError(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  // Method to join a room
  Future<bool> joinRoom(int roomId) async {
    try {
      await roomRepository.joinRoom(roomId: roomId);
      return true;
    } on ServerException catch (e) {
      emit(RoomError(message: e.message));
      return false;
    } catch (e) {
      emit(RoomError(message: 'An unexpected error occurred: ${e.toString()}'));
      return false;
    }
  }

  // Method to delete a room
  Future<void> deleteRoom({required int roomId}) async {
    final currentState = state;
    if (currentState is! RoomLoading) {
      emit(RoomLoading());
    }

    try {
      await roomRepository.deleteRoom(roomId: roomId);
      await loadRooms(); // Reload the rooms list after deletion
    } on ServerException catch (e) {
      emit(RoomError(message: e.message));
    } catch (e) {
      emit(RoomError(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }
}
