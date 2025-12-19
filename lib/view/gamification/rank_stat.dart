import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'stat_item.dart';
import '../../utils/colors.dart';

class RankStat extends StatelessWidget {
  final int rank;
  final int total;
  const RankStat({super.key, required this.rank, required this.total});

  @override
  Widget build(BuildContext context) {
    return StatItem(
      icon: LineAwesomeIcons.trophy_solid,
      label: 'Rank',
      value: '$rank/$total',
      iconColor: AppColors.accentColor,
    );
  }
}