import 'dart:convert';
import 'package:app/model/chapter.dart';
import 'package:http/http.dart' as http;

import '../global_var.dart';
import '../model/course.dart';

class CourseService {
  static Future<List<Course>> getEnrolledCourse(int id) async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/user/$id/courses'));
      final body = response.body;
      final result = jsonDecode(body);
      List<Course> courses = List<Course>.from(
        result.map(
              (result) => Course.fromJson(result)
        ),
      );
      return courses;
    } catch(e){
      throw Exception(e.toString());
    }
  }

  static Future<Course> getCourse(int id) async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/course/$id'));
      final result = jsonDecode(response.body);
      
      // PERBAIKAN: Gunakan fromJson agar data progress dan struktur JSON konsisten
      // Jika backend mengembalikan object course langsung tanpa pembungkus 'course':
      return Course(
        id: result['id'],
        courseName: result['name'],
        codeCourse: result['code'],
        description: result['description'],
        image: result['image'] ?? '',
        createdAt: DateTime.parse(result['createdAt']),
        updatedAt: DateTime.parse(result['updatedAt']),
        progress: result['progress'] ?? 0, // Ambil progres asli, jangan dipaksa 0
      );
    } catch(e){
      throw Exception(e.toString());
    }
  }

  static Future<List<Chapter>> getChapterByCourse(int id) async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/course/$id/chapters'));
      final body = response.body;
      final result = jsonDecode(body);
      
      List<Chapter> chapter = List<Chapter>.from(
        result.map(
            (item) => Chapter.fromJson(item)
        )
      );
      return chapter;
    } catch(e){
      throw Exception(e.toString());
    }
  }
}