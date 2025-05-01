import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/room_cubit.dart'; // Import RoomCubit

// Page for creating a new chat room
class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  bool _isPublic = true; // Default to public room

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  void _createRoom() {
    if (_formKey.currentState!.validate()) {
      // Access the cubit (provided by the route/parent) and call createRoom
      context.read<RoomCubit>().createRoom(
            roomName: _roomNameController.text.trim(),
            isPublic: _isPublic,
            // subjectId can be added later if needed
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Room')),
      body: BlocListener<RoomCubit, RoomState>(
        // Listen for state changes to handle navigation or errors
        listener: (context, state) {
          if (state is RoomError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('Creation Failed: ${state.message}')),
              );
          } else if (state is RoomLoaded) {
            // Assuming creation success triggers reload -> RoomLoaded
            // Check if the widget is still mounted before popping
            if (mounted) {
              Navigator.of(context)
                  .pop(); // Go back to HomePage after successful creation
            }
          }
          // We might need a specific RoomCreated state if we want immediate feedback
          // before the list reloads, but popping on RoomLoaded (after reload) works too.
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _roomNameController,
                  decoration: const InputDecoration(labelText: 'Room Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a room name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Public Room'),
                  value: _isPublic,
                  onChanged: (bool value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
                const SizedBox(height: 32),
                // Show loading indicator if the state is RoomLoading
                BlocBuilder<RoomCubit, RoomState>(
                  builder: (context, state) {
                    if (state is RoomLoading) {
                      // Or a specific RoomCreating state
                      return const CircularProgressIndicator();
                    }
                    return ElevatedButton(
                      onPressed: _createRoom,
                      child: const Text('Create Room'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
