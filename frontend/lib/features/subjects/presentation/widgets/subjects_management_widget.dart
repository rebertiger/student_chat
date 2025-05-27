import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/subjects_cubit.dart';
import '../../domain/entities/subject.dart';

class SubjectsManagementWidget extends StatelessWidget {
  const SubjectsManagementWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubjectsCubit, SubjectsState>(
      builder: (context, state) {
        if (state is SubjectsInitial) {
          context.read<SubjectsCubit>()
            ..loadAllSubjects()
            ..loadUserSubjects();
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
                'Your Subjects',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.userSubjects.map((subject) {
                  return Chip(
                    label: Text(subject.name),
                    onDeleted: () {
                      context
                          .read<SubjectsCubit>()
                          .removeUserSubject(subject.id);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Subject',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.allSubjects
                    .where((subject) => !state.userSubjects
                        .any((userSubject) => userSubject.id == subject.id))
                    .map((subject) {
                  return ActionChip(
                    label: Text(subject.name),
                    onPressed: () {
                      context.read<SubjectsCubit>().addUserSubject(subject.id);
                    },
                  );
                }).toList(),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
