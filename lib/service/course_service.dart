import 'dart:convert';
import 'package:app/model/chapter.dart';
import 'package:http/http.dart' as http;
import '../global_var.dart';
import '../model/course.dart';

class CourseService {
  // Helper internal untuk jalur API
  static String get _apiPath => "${GlobalVar.baseUrl}/api";

  static Future<List<Course>> getEnrolledCourse(int id) async {
    try {
      // PERBAIKAN: Tambahkan /api melalui _apiPath
      final response = await http.get(Uri.parse('$_apiPath/user/$id/courses'))
          .timeout(const Duration(seconds: 10));
          
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return List<Course>.from(result.map((item) => Course.fromJson(item)));
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch(e){
      throw Exception("Gagal memuat kursus: $e");
    }
  }

  static Future<Course> getCourse(int id) async {
    try {
      final response = await http.get(Uri.parse('$_apiPath/course/$id'))
          .timeout(const Duration(seconds: 10));
      final result = jsonDecode(response.body);
      
      return Course(
        id: result['id'],
        courseName: result['name'],
        codeCourse: result['code'],
        description: result['description'],
        image: result['image'] ?? '',
        createdAt: DateTime.parse(result['createdAt']),
        updatedAt: DateTime.parse(result['updatedAt']),
        progress: result['progress'] ?? 0,
      );
    } catch(e){
      throw Exception("Gagal memuat detail kursus: $e");
    }
  }

  static Future<List<Chapter>> getChapterByCourse(int id) async {
    try {
      final response = await http.get(Uri.parse('$_apiPath/course/$id/chapters'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List result = jsonDecode(response.body);
        return result.map((item) => Chapter.fromJson(item)).toList();
      }
      return [];
    } catch(e){
      throw Exception("Gagal memuat chapter: $e");
    }
  }
}