part of 'room_cubit.dart'; // Part of RoomCubit

abstract class RoomState extends Equatable {
  const RoomState();

  @override
  List<Object?> get props => [];
}

// Initial state
class RoomInitial extends RoomState {}

// State while loading rooms
class RoomLoading extends RoomState {}

// State when rooms are successfully loaded
class RoomLoaded extends RoomState {
  final List<RoomModel> rooms;

  const RoomLoaded({required this.rooms});

  @override
  List<Object?> get props => [rooms];
}

// State when creating a room is in progress
class RoomCreating extends RoomState {}

// State when a room is successfully created (might just reload the list)
// Or could include the new room if needed immediately
class RoomCreated extends RoomState {
  final RoomModel newRoom;
  const RoomCreated({required this.newRoom});

  @override
  List<Object?> get props => [newRoom];
}

// State when an error occurs fetching or creating rooms
class RoomError extends RoomState {
  final String message;

  const RoomError({required this.message});

  @override
  List<Object?> get props => [message];
}
