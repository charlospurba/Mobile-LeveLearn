// lib/view/gamification/challenge.dart

import 'package:flutter/material.dart';
import '../../model/user_challenge.dart';
import '../../service/user_service.dart';
import '../../utils/colors.dart';

class ChallengeWidget extends StatelessWidget {
  final List<UserChallenge> challenges;
  final int userId;
  final Function(int) onTabChange;
  final VoidCallback onRefresh;

  const ChallengeWidget({
    super.key,
    required this.challenges,
    required this.userId,
    required this.onTabChange,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Quest & Challenge',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
              fontFamily: 'DIN_Next_Rounded',
            ),
          ),
        ),
        SizedBox(
          height: 160, // Sedikit lebih tinggi untuk kenyamanan
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final item = challenges[index];
              return _buildChallengeCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(BuildContext context, UserChallenge item) {
    final bool isDone = item.isCompleted;
    final bool isClaimed = item.isClaimed;

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell( // Memungkinkan klik pada kartu
          onTap: isDone ? null : () => onTabChange(2), // Redirect ke My Course
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDone && !isClaimed ? Colors.orange.withOpacity(0.05) : Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isClaimed ? Icons.check_circle : (isDone ? Icons.card_giftcard : Icons.ads_click),
                      color: isClaimed ? Colors.green : (isDone ? Colors.orange : AppColors.secondaryColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.challenge.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.challenge.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (isDone && !isClaimed)
                  SizedBox(
                    width: double.infinity,
                    height: 35,
                    child: ElevatedButton(
                      onPressed: () => _claimReward(context, item.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text("Klaim ${item.challenge.rewardPoint} Poin", 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                else if (isClaimed)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text("Hadiah Sudah Diklaim", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: item.currentProgress / (item.challenge.goal > 0 ? item.challenge.goal : 1),
                          backgroundColor: Colors.grey[200],
                          color: AppColors.primaryColor,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${item.currentProgress}/${item.challenge.goal}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const Text("Ke Course >", style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _claimReward(BuildContext context, int userChallengeId) async {
    final success = await UserService.claimChallengeReward(userId, userChallengeId);
    if (success) {
      onRefresh();
    }
  }
}