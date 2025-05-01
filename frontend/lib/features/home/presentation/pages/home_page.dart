import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart'; // Import GetIt
import '../../../chat/presentation/pages/chat_page.dart'; // Import ChatPage
import '../cubit/room_cubit.dart'; // Import RoomCubit
import 'create_room_page.dart'; // Import CreateRoomPage

// Main screen after login, displaying the list of chat rooms
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide RoomCubit instance
    return BlocProvider(
      create: (_) =>
          sl<RoomCubit>()..loadRooms(), // Create and load rooms initially
      child: const HomeView(),
    );
  }
}

// The actual view that builds based on RoomState
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms'),
        // TODO: Add logout button or profile access actions
        // actions: [ IconButton(onPressed: () { /* Logout logic */ }, icon: Icon(Icons.logout)) ],
      ),
      body: BlocBuilder<RoomCubit, RoomState>(
        builder: (context, state) {
          if (state is RoomLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RoomLoaded) {
            if (state.rooms.isEmpty) {
              return const Center(
                  child: Text('No public rooms available. Create one!'));
            }
            // Display the list of rooms
            return ListView.builder(
              itemCount: state.rooms.length,
              itemBuilder: (context, index) {
                final room = state.rooms[index];
                return ListTile(
                  title: Text(room.roomName),
                  subtitle: Text(
                    'Created by: ${room.creatorName ?? 'Unknown'} ${room.subjectName != null ? '(${room.subjectName})' : ''}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    // Make onTap async
                    // Call joinRoom from the cubit
                    final success =
                        await context.read<RoomCubit>().joinRoom(room.roomId);

                    // Check if the widget is still mounted before navigating or showing snackbar
                    if (!context.mounted) return;

                    if (success) {
                      // Navigate to the ChatPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            roomId: room.roomId,
                            roomName: room.roomName,
                          ),
                        ),
                      );
                    } else {
                      // Error is likely already shown by the Cubit's BlocListener if we add one,
                      // but we can show a specific one here if needed.
                      // ScaffoldMessenger.of(context)
                      //   ..hideCurrentSnackBar()
                      //   ..showSnackBar(const SnackBar(content: Text('Failed to join room.')));
                    }
                  },
                );
              },
            );
          } else if (state is RoomError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading rooms: ${state.message}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => context.read<RoomCubit>().loadRooms(),
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }
          // Initial state or unexpected state
          return const Center(child: Text('Loading rooms...'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to CreateRoomPage using MaterialPageRoute
          // Pass the existing RoomCubit instance using BlocProvider.value
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<RoomCubit>(), // Pass the existing cubit
                child: const CreateRoomPage(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Room',
      ),
    );
  }
}

// Add the import for CreateRoomPage if it's not already there
// (Assuming it might be needed after the change, although it's likely already imported)
// import 'create_room_page.dart';
