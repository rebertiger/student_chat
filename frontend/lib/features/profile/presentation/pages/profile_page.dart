import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart'; // Import GetIt
import '../cubit/profile_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Create ProfileCubit using GetIt
      create: (_) => sl<ProfileCubit>()..loadProfile(),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _universityController;
  late TextEditingController _departmentController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers - they will be updated by the BlocBuilder
    _usernameController = TextEditingController();
    _universityController = TextEditingController();
    _departmentController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileCubit>().updateProfile(
            username: _usernameController.text,
            university: _universityController.text,
            department: _departmentController.text,
            bio: _bioController.text,
            // Profile picture update needs separate handling (e.g., file picker)
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          } else if (state is ProfileUpdateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update Error: ${state.message}')),
            );
          } else if (state is ProfileUpdateSuccess) {
            // Or listen for ProfileLoaded after update
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileLoaded) {
            // Update controllers only if the state data is different
            // This prevents cursor jumping during typing
            if (_usernameController.text != state.username) {
              _usernameController.text = state.username;
            }
            if (_universityController.text != state.university) {
              _universityController.text = state.university;
            }
            if (_departmentController.text != state.department) {
              _departmentController.text = state.department;
            }
            if (_bioController.text != (state.bio ?? '')) {
              _bioController.text = state.bio ?? '';
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  // Use ListView for scrollability
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: state.profilePictureUrl != null
                                ? NetworkImage(state.profilePictureUrl!)
                                : null,
                            child: state.profilePictureUrl == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: () {
                                // TODO: Implement profile picture update logic
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Profile picture update not implemented yet.')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _universityController,
                      decoration:
                          const InputDecoration(labelText: 'University'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your university';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _departmentController,
                      decoration:
                          const InputDecoration(labelText: 'Department'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your department';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed:
                          (state is ProfileUpdating) ? null : _saveProfile,
                      child: (state is ProfileUpdating)
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is ProfileError) {
            return Center(
                child: Text('Failed to load profile: ${state.message}'));
          } else {
            // Handle other states like ProfileUpdating, ProfileUpdateError if needed
            // Or just show the loaded state during update
            return const Center(child: Text('An unexpected error occurred.'));
          }
        },
      ),
    );
  }
}
