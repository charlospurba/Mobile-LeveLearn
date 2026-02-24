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

  // --- FUNGSI INI WAJIB ADA AGAR PASSWORD DIKIRIM KE BACKEND ---
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    
    data['id'] = id;
    data['username'] = username;
    data['name'] = name;
    data['role'] = role;
    data['streak'] = streak;
    
    // Pastikan password masuk payload HANYA jika form diisi
    if (password.isNotEmpty) {
      data['password'] = password;
    }

    if (studentId != null) data['studentId'] = studentId;
    if (points != null) data['points'] = points;
    if (totalCourses != null) data['totalCourses'] = totalCourses;
    if (badges != null) data['badges'] = badges;
    if (instructorId != null) data['instructorId'] = instructorId;
    if (instructorCourses != null) data['instructorCourses'] = instructorCourses;
    if (image != null) data['image'] = image;
    if (equippedFrameId != null) data['equippedFrameId'] = equippedFrameId;
    
    if (lastInteraction != null) {
      data['lastInteraction'] = lastInteraction!.toIso8601String();
    }
    
    data['createdAt'] = createdAt.toIso8601String();
    data['updatedAt'] = updatedAt.toIso8601String();

    return data;
  }
}