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
  // Field Baru untuk Riwayat Pengiriman
  List<String> submissionHistory; 
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
    required this.submissionHistory, // Tambahkan ke constructor
    required this.timeStarted,
    required this.timeFinished,
    required this.assignmentScore,
    required this.assignmentFeedback,
    required this.createdAt,
    required this.updatedAt
  });

  factory ChapterStatus.fromJson(Map<String, dynamic> json) {
    // Helper untuk menangani list/array baik dari string JSON maupun list langsung
    List<String> parseJsonList(dynamic data) {
      if (data == null) return [];
      if (data is String) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          return [];
        }
      }
      if (data is List) {
        return data.map((e) => e.toString()).toList();
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
      assessmentAnswer: parseJsonList(json['assessmentAnswer']),
      assessmentGrade: json['assessmentGrade'] ?? 0,
      submission: json['submission'],
      // Parsing riwayat pengiriman dari database
      submissionHistory: parseJsonList(json['submissionHistory']),
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
      'assessmentAnswer': assessmentAnswer, // Biarkan dalam bentuk list untuk diproses Prisma
      'assessmentGrade': assessmentGrade,
      'submission': submission,
      // Mengirim list riwayat kembali ke backend
      'submissionHistory': submissionHistory, 
      'timeStarted': timeStarted.toUtc().toIso8601String(),
      'timeFinished': timeFinished.toUtc().toIso8601String(),
      'assignmentScore': assignmentScore,
      'assignmentFeedback': assignmentFeedback,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}