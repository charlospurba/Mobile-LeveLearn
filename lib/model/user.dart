class Student {
  final int id;
  String username;
  String password;
  String name;
  final String role;
  String? studentId;
  int? points;
  int? totalCourses;
  int? badges;
  String? instructorId;
  int? instructorCourses;

  int streak; 
  DateTime? lastInteraction;

  String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.role,
    this.studentId,
    this.points,
    this.totalCourses,
    this.badges,
    this.streak = 0,
    this.lastInteraction,
    this.instructorId,
    this.instructorCourses,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'STUDENT',
      studentId: json['studentId'],
      points: json['points'] != null ? int.parse(json['points'].toString()) : 0,
      totalCourses: json['totalCourses'] ?? 0,
      badges: json['badges'] ?? 0,
      streak: json['streak'] != null ? int.parse(json['streak'].toString()) : 0,
      lastInteraction: json['lastInteraction'] != null 
          ? DateTime.parse(json['lastInteraction']) 
          : null,
      image: json['image'],
      instructorId: json['instructorId'],
      instructorCourses: json['instructorCourses'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }
}