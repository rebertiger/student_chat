import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/subjects_cubit.dart';
import '../../domain/entities/subject.dart';

class SubjectSelectorWidget extends StatelessWidget {
  final Function(Subject) onSubjectSelected;
  final Subject? selectedSubject;

  const SubjectSelectorWidget({
    Key? key,
    required this.onSubjectSelected,
    this.selectedSubject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubjectsCubit, SubjectsState>(
      builder: (context, state) {
        if (state is SubjectsInitial) {
          context.read<SubjectsCubit>().loadAllSubjects();
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SubjectsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SubjectsError) {
          return Center(child: Text(state.message));
        }

        if (state is SubjectsLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Subject',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Subject>(
                value: selectedSubject,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                items: state.allSubjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(subject.name),
                  );
                }).toList(),
                onChanged: (Subject? subject) {
                  if (subject != null) {
                    onSubjectSelected(subject);
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a subject';
                  }
                  return null;
                },
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
