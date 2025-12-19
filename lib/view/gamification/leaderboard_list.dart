import 'package:flutter/material.dart';
import '../../model/user.dart';
import '../../utils/colors.dart';

class LeaderboardList extends StatelessWidget {
  final List<Student> students;
  const LeaderboardList({super.key, required this.students});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leaderboard', style: TextStyle(color: AppColors.primaryColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
          const SizedBox(height: 16),
          if (students.isEmpty)
            const Center(child: Text('No rank data available'))
          else
            ...List.generate(students.length > 5 ? 5 : students.length, (index) {
              final student = students[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accentColor,
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
                  subtitle: Text(student.studentId ?? ''),
                  trailing: Text('${student.points} Pts', style: const TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold)),
                ),
              );
            }),
        ],
      ),
    );
  }
}