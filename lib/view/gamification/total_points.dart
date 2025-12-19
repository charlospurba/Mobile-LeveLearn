import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../utils/colors.dart';

class TotalPoints extends StatelessWidget {
  final int points;
  const TotalPoints({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(LineAwesomeIcons.gem_solid, color: AppColors.accentColor, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Points', style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'DIN_Next_Rounded')),
            Text('$points', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
          ],
        ),
      ],
    );
  }
}