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
    // Optionally emit a specific creating state if needed
    // emit(RoomCreating());
    // Keep the current state (e.g., RoomLoaded) while creating in background
    // Or emit RoomLoading() if you want a full screen loader
    final currentState = state; // Keep track of current state if needed
    if (currentState is! RoomLoading) {
      // Avoid emitting loading if already loading
      emit(RoomLoading()); // Or a more specific RoomCreating state
    }

    try {
      // Mevcut kullanıcı bilgilerini al
      final currentUser = userService.getCurrentUser();
      final userId = currentUser?.userId;
      final userFullName = currentUser?.fullName;

      final newRoom = await roomRepository.createRoom(
        roomName: roomName,
        subjectId: subjectId,
        isPublic: isPublic,
        createdBy: userId, // Kullanıcı ID'sini gönder
        creatorName: userFullName, // Kullanıcı adını gönder
      );
      // After successful creation, reload the room list to include the new one
      await loadRooms();
      // Optionally, emit RoomCreated state first if the UI needs the new room details immediately
      // emit(RoomCreated(newRoom: newRoom));
    } on ServerException catch (e) {
      emit(RoomError(message: e.message));
      // If keeping previous state, revert back on error
      // if (currentState is RoomLoaded) emit(currentState);
    } catch (e) {
      emit(RoomError(message: 'An unexpected error occurred: ${e.toString()}'));
      // if (currentState is RoomLoaded) emit(currentState);
    }
  }

  // Method to join a room
  Future<bool> joinRoom(int roomId) async {
    // We might not need specific states for joining, just call repo
    // Optionally emit a 'JoiningRoom' state if feedback is needed
    try {
      await roomRepository.joinRoom(roomId: roomId);
      return true; // Indicate success
    } on ServerException catch (e) {
      // Emit error state or let the caller handle it
      emit(RoomError(
          message:
              'Failed to join room: ${e.message}')); // Or a more specific JoinRoomError state
      return false; // Indicate failure
    } catch (e) {
      emit(RoomError(
          message:
              'An unexpected error occurred while joining room: ${e.toString()}'));
      return false; // Indicate failure
    }
  }
}
