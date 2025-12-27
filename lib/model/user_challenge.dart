class UserChallenge {
  final int id;
  final int currentProgress;
  final bool isCompleted;
  final bool isClaimed;
  final ChallengeDetail challenge;

  UserChallenge({
    required this.id,
    required this.currentProgress,
    required this.isCompleted,
    required this.isClaimed,
    required this.challenge,
  });

  factory UserChallenge.fromJson(Map<String, dynamic> json) {
    return UserChallenge(
      id: json['id'] ?? 0,
      // Gunakan .toInt() atau konversi manual jika backend mengirim double/string
      currentProgress: int.parse(json['currentProgress'].toString()), 
      isCompleted: json['isCompleted'] ?? false,
      isClaimed: json['isClaimed'] ?? false,
      challenge: ChallengeDetail.fromJson(json['challenge'] ?? {}),
    );
  }
}

class ChallengeDetail {
  final String title;
  final String description;
  final int goal;
  final int rewardPoint;

  ChallengeDetail({
    required this.title,
    required this.description,
    required this.goal,
    required this.rewardPoint,
  });

  factory ChallengeDetail.fromJson(Map<String, dynamic> json) {
    return ChallengeDetail(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      goal: int.parse((json['goal'] ?? 0).toString()),
      rewardPoint: int.parse((json['rewardPoint'] ?? 0).toString()),
    );
  }
}