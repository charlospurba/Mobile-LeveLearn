import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'stat_item.dart';
import '../../utils/colors.dart';

class CourseStat extends StatelessWidget {
  final int count;
  const CourseStat({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return StatItem(
      icon: LineAwesomeIcons.user_check_solid,
      label: 'Courses',
      value: '$count',
      iconColor: AppColors.accentColor,
    );
  }
}