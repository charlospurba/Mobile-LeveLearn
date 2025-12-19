import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'stat_item.dart';
import '../../utils/colors.dart';

class StreakStat extends StatelessWidget {
  final int days;
  const StreakStat({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return StatItem(
      icon: LineAwesomeIcons.fire_solid,
      label: 'Streak',
      value: '$days Days',
      iconColor: AppColors.accentColor,
    );
  }
}