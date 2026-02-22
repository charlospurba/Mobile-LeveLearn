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

  int? equippedFrameId;

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
    this.equippedFrameId,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    // Fungsi pembantu untuk parsing angka secara aman
    int? parseIntSafely(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return Student(
      id: parseIntSafely(json['id']) ?? 0,
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'STUDENT',
      studentId: json['studentId'],
      points: parseIntSafely(json['points']) ?? 0,
      totalCourses: parseIntSafely(json['totalCourses']) ?? 0,
      badges: parseIntSafely(json['badges']) ?? 0,
      
      // Mengambil dari camelCase atau snake_case sesuai respon database
      equippedFrameId: parseIntSafely(json['equippedFrameId']) ?? parseIntSafely(json['equipped_frame_id']),
      
      streak: parseIntSafely(json['streak']) ?? 0,
      lastInteraction: json['lastInteraction'] != null 
          ? DateTime.parse(json['lastInteraction']) 
          : null,
      image: json['image'],
      instructorId: json['instructorId'],
      instructorCourses: parseIntSafely(json['instructorCourses']),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }
}