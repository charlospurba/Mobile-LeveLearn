import 'dart:convert';
import 'package:app/model/badge.dart';
import 'package:app/model/user_badge.dart';
import 'package:http/http.dart' as http;
import '../global_var.dart';

class BadgeService {
  // Helper konsistensi API prefix
  static String get _apiPath => "${GlobalVar.baseUrl}/api";

  static Future<List<BadgeModel>> getBadgeListCourseByCourseId(int courseId) async {
    try {
      final response = await http.get(Uri.parse('$_apiPath/course/$courseId/badges'))
          .timeout(const Duration(seconds: 10));

      // Mencegah error jika server balas HTML (404)
      if (response.body.startsWith('<!DOCTYPE html>')) {
        print("Error: Backend mengembalikan HTML 404 untuk Badge Course");
        return [];
      }

      final List<dynamic> result = jsonDecode(response.body);
      return result.map((q) => BadgeModel.fromJson(q)).toList();
    } catch (e) {
      print("Badge Service Error (Course): $e");
      return [];
    }
  }

  static Future<void> createUserBadgeByChapterId(int userId, int badgeId) async {
    try {
      Map<String, dynamic> request = {
        "userId": userId,
        "badgeId": badgeId,
        "isPurchased": false
      };
      final response = await http.post(
        Uri.parse('$_apiPath/userbadge'), 
        headers: {
          'Content-type' : 'application/json; charset=utf-8',
          'Accept': 'application/json',
        }, 
        body: jsonEncode(request)
      ).timeout(const Duration(seconds: 10));

      final result = jsonDecode(response.body);
      print("DEBUG CREATE BADGE: ${result['message']}");
    } catch (e) {
      print("Error creating user badge: $e");
    }
  }

  static Future<List<UserBadge>> getUserBadgeListByUserId(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_apiPath/user/$userId/badges'))
          .timeout(const Duration(seconds: 10));

      if (response.body.startsWith('<!DOCTYPE html>')) {
        print("Error: Backend mengembalikan HTML 404 untuk User Badge");
        return [];
      }

      final dynamic decodedResponse = jsonDecode(response.body);
      if (decodedResponse is List) {
        return decodedResponse.map((json) => UserBadge.fromJson(json)).toList();
      } 
      return [];
    } catch (e) {
      print("Badge Service Error (User): $e");
      return [];
    }
  }

  static Future<BadgeModel> getBadgeById(int badgeId) async {
    try {
      final response = await http.get(Uri.parse('$_apiPath/badge/$badgeId'))
          .timeout(const Duration(seconds: 10));
      
      final result = jsonDecode(response.body);
      if (result == null) throw Exception("Badge not found");

      return BadgeModel.fromJson(result);
    } catch (e) {
      throw Exception("Error fetching badge: ${e.toString()}");
    }
  }
}