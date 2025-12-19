import 'package:flutter/material.dart';
import '../../model/course.dart';
import '../../utils/colors.dart';

class ProgressCard extends StatelessWidget {
  final Course? lastestCourse;
  final VoidCallback onTap;

  const ProgressCard({super.key, this.lastestCourse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Progress', 
              style: TextStyle(color: AppColors.primaryColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
            const SizedBox(height: 12),
            lastestCourse == null
                ? const Center(child: Text('Start a course to see progress!'))
                : Row(
                    children: [
                      CircularProgressIndicator(
                        value: (lastestCourse!.progress ?? 0) / 100,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 16),
                      Text(lastestCourse!.courseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}