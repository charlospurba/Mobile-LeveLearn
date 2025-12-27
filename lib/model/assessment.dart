class Assessment {
  final int id;
  final int chapterId;
  final String instruction;
  final List<Question> questions;
  List<String>? answers;
  final DateTime createdAt;
  final DateTime updatedAt;

  Assessment({
    required this.id,
    required this.chapterId,
    required this.instruction,
    required this.questions,
    this.answers,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'],
      chapterId: json['chapterId'],
      instruction: json['instruction'] ?? '',
      questions: (json['questions'] as List?)
              ?.map((q) => Question.fromJson(q))
              .toList() ?? [],
      answers: json['answers'] != null ? List<String>.from(json['answers']) : [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class Question {
  String question;
  List<String> option;
  String correctedAnswer;
  String type;
  String _selectedAnswer = '';
  bool isCorrect = false;
  int score = 0; 

  Question({
    required this.question,
    required this.option,
    required this.correctedAnswer,
    required this.type,
    this.isCorrect = false,
    this.score = 0,
  });

  String get selectedAnswer => _selectedAnswer;
  set selectedAnswer(String value) => _selectedAnswer = value;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] ?? '',
      option: json['option'] != null ? List<String>.from(json['option']) : [],
      correctedAnswer: json['correctedAnswer'] ?? '',
      type: json['type'] ?? 'MC',
      isCorrect: false,
      score: 0,
    );
  }
}