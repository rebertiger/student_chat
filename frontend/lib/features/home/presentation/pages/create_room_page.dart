import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/subjects/presentation/widgets/subject_selector_widget.dart';
import '../cubit/room_cubit.dart';
import '../../../subjects/presentation/cubit/subjects_cubit.dart';
import 'package:get_it/get_it.dart';
import '../../../subjects/domain/entities/subject.dart';

class CreateRoomPage extends StatefulWidget {
  final RoomCubit roomCubit;

  const CreateRoomPage({
    super.key,
    required this.roomCubit,
  });

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  bool _isPublic = true;
  Subject? _selectedSubject;

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  void _createRoom() {
    if (_formKey.currentState!.validate()) {
      int? subjectId = _selectedSubject?.id;

      widget.roomCubit.createRoom(
        roomName: _roomNameController.text.trim(),
        isPublic: _isPublic,
        subjectId: subjectId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.roomCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Create Study Room',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.deepPurple,
          elevation: 2,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: BlocListener<RoomCubit, RoomState>(
          listener: (context, state) {
            if (state is RoomError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Creation Failed: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
            } else if (state is RoomLoaded) {
              Navigator.of(context).pop();
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _roomNameController,
                    decoration: const InputDecoration(
                      labelText: 'Room Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.meeting_room),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a room name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Room Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.visibility),
                              const SizedBox(width: 8),
                              const Text(
                                'Room Visibility',
                                style: TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              Switch(
                                value: _isPublic,
                                onChanged: (value) {
                                  setState(() {
                                    _isPublic = value;
                                  });
                                },
                                activeColor: Colors.deepPurple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isPublic
                                ? 'Anyone can join this room'
                                : 'Only invited users can join',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  BlocProvider(
                    create: (_) => GetIt.I<SubjectsCubit>(),
                    child: SubjectSelectorWidget(
                      onSubjectSelected: (subject) {
                        setState(() {
                          _selectedSubject = subject;
                        });
                      },
                      selectedSubject: _selectedSubject,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _createRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create Room',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
