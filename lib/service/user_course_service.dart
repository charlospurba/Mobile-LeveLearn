import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global_var.dart';
import '../model/user_course.dart';

class UserCourseService {
  // Helper internal untuk memastikan route diawali /api secara konsisten
  static String get _apiPath => "${GlobalVar.baseUrl}/api";

  static Future<UserCourse?> getUserCourse(int idUser, int idCourse) async {
    try {
      // PERBAIKAN: Tambahkan /api lewat _apiPath
      final response = await http.get(
        Uri.parse('$_apiPath/usercourse/$idUser/$idCourse'),
      ).timeout(const Duration(seconds: 10));

      final body = response.body;
      
      // Cek jika response bukan JSON (biasanya HTML error)
      if (body.startsWith('<!DOCTYPE html>')) {
        print("Error: Server mengembalikan HTML. Cek route /api/usercourse di backend.");
        return null;
      }

      final result = jsonDecode(body);
      print("DEBUG USERCOURSE: $result");

      if (result is List && result.isNotEmpty) {
        return UserCourse.fromJson(result[0]);
      } else if (result is Map<String, dynamic>) {
        return UserCourse.fromJson(result);
      }
      
      return null;
    } catch (e) {
      print("Error getUserCourse: $e");
      // Mengembalikan null agar aplikasi tidak langsung force close/crash
      return null; 
    }
  }

  static Future<void> updateUserCourse(int id, UserCourse uc) async {
    try {
      Map<String, dynamic> request = {
        "userId": uc.userId,
        "courseId": uc.courseId,
        "progress": uc.progress,
        "currentChapter": uc.currentChapter,
        "isCompleted": uc.isCompleted,
        "enrolledAt": uc.enrolledAt.toIso8601String()
      };

      // PERBAIKAN: Tambahkan /api lewat _apiPath
      final responsePut = await http.put(
        Uri.parse('$_apiPath/usercourse/$id'), 
        headers: {
          'Content-type' : 'application/json; charset=utf-8',
          'Accept': 'application/json',
        }, 
        body: jsonEncode(request)
      ).timeout(const Duration(seconds: 10));

      if (responsePut.statusCode == 200) {
        print("Update UserCourse Successful");
      } else {
        print("Update Failed: ${responsePut.body}");
      }
    } catch (e) {
      print("Error updateUserCourse: $e");
    }
  }
}