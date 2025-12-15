class UserCourse {
  int id;
  int userId;
  int courseId;
  int progress;
  int currentChapter;
  bool isCompleted;
  DateTime enrolledAt;

  UserCourse({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.progress,
    required this.currentChapter,
    required this.isCompleted,
    required this.enrolledAt,
  });

  factory UserCourse.fromJson(Map<String, dynamic> json) {
    return UserCourse(
      id: json['id'],
      userId: json['userId'],
      courseId: json['courseId'],
      progress: json['progress'],
      currentChapter: json['currentChapter'],
      isCompleted: json['isCompleted'],
      enrolledAt: DateTime.parse(json['enrolledAt']),
    );
  }
}