import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'stat_item.dart';
import '../../utils/colors.dart';

class BadgeStat extends StatelessWidget {
  final int count;
  const BadgeStat({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return StatItem(
      icon: LineAwesomeIcons.medal_solid,
      label: 'Badges',
      value: '$count',
      iconColor: AppColors.accentColor,
    );
  }
}