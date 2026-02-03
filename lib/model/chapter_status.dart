import 'dart:convert';

class ChapterStatus {
  int id;
  int userId;
  int chapterId;
  bool isCompleted;
  bool isStarted;
  bool materialDone;
  bool assessmentDone;
  bool assignmentDone;
  List<String> assessmentAnswer;
  int assessmentGrade;
  String? submission;
  DateTime timeStarted;
  DateTime timeFinished;
  int assignmentScore;
  String assignmentFeedback;
  DateTime createdAt;
  DateTime updatedAt;

  ChapterStatus({
    required this.id,
    required this.userId,
    required this.chapterId,
    required this.isCompleted,
    required this.isStarted,
    required this.materialDone,
    required this.assessmentDone,
    required this.assignmentDone,
    required this.assessmentAnswer,
    required this.assessmentGrade,
    this.submission,
    required this.timeStarted,
    required this.timeFinished,
    required this.assignmentScore,
    required this.assignmentFeedback,
    required this.createdAt,
    required this.updatedAt
  });

  factory ChapterStatus.fromJson(Map<String, dynamic> json) {
    // Helper untuk menangani list jawaban baik dari string JSON maupun list langsung
    List<String> parseAnswers(dynamic answers) {
      if (answers == null) return [];
      if (answers is String) {
        try {
          return (jsonDecode(answers) as List).map((e) => e.toString()).toList();
        } catch (_) {
          return [];
        }
      }
      if (answers is List) {
        return answers.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ChapterStatus(
      id: json['id'],
      userId: json['userId'],
      chapterId: json['chapterId'],
      isStarted: json['isStarted'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      materialDone: json['materialDone'] ?? false,
      assessmentDone: json['assessmentDone'] ?? false,
      assignmentDone: json['assignmentDone'] ?? false,
      assessmentAnswer: parseAnswers(json['assessmentAnswer']),
      assessmentGrade: json['assessmentGrade'] ?? 0,
      submission: json['submission'],
      timeStarted: DateTime.parse(json['timeStarted'] ?? DateTime.now().toIso8601String()),
      timeFinished: DateTime.parse(json['timeFinished'] ?? DateTime.now().toIso8601String()),
      assignmentScore: json['assignmentScore'] ?? 0,
      assignmentFeedback: json['assignmentFeedback'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'chapterId': chapterId,
      'isCompleted': isCompleted,
      'isStarted': isStarted,
      'materialDone': materialDone,
      'assessmentDone': assessmentDone,
      'assignmentDone': assignmentDone,
      'assessmentAnswer': jsonEncode(assessmentAnswer), // Encode ke string JSON untuk DB
      'assessmentGrade': assessmentGrade,
      'submission': submission,
      'timeStarted': timeStarted.toUtc().toIso8601String(),
      'timeFinished': timeFinished.toUtc().toIso8601String(),
      'assignmentScore': assignmentScore,
      'assignmentFeedback': assignmentFeedback,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}