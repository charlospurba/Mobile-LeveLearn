import 'dart:convert';
import 'package:app/model/badge.dart';
import 'package:app/model/user_badge.dart';
import 'package:http/http.dart' as http;
import '../global_var.dart';

class BadgeService {
  static Future<List<BadgeModel>> getBadgeListCourseByCourseId(int courseId) async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/course/$courseId/badges'));
      // Deklarasi explisit List agar tidak dianggap Map oleh compiler JS
      final List<dynamic> result = jsonDecode(response.body);
      
      return result.map((q) => BadgeModel.fromJson(q)).toList();
    } catch (e) {
      throw Exception("Error fetching badges: ${e.toString()}");
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
        Uri.parse('${GlobalVar.baseUrl}/userbadge'), 
        headers: {
          'Content-type' : 'application/json; charset=utf-8',
          'Accept': 'application/json',
        }, 
        body: jsonEncode(request)
      );

      final result = jsonDecode(response.body);
      print(result['message']);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<List<UserBadge>> getUserBadgeListByUserId(int userId) async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/user/$userId/badges'));
      final dynamic decodedResponse = jsonDecode(response.body);

      // Cek apakah response berupa List
      if (decodedResponse is List) {
        return decodedResponse.map((json) => UserBadge.fromJson(json)).toList();
      } else {
        // Jika backend mengirim data kosong dalam bentuk objek {} atau null
        return [];
      }
    } catch (e) {
      print("Badge Service Error: $e");
      return []; // Kembalikan list kosong daripada melempar error agar profil tetap bisa terbuka
    }
  }

  static Future<BadgeModel> getBadgeById(int badgeId) async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/badge/$badgeId'));
      final result = jsonDecode(response.body);

      if (result == null) {
        throw Exception("Badge not found");
      }

      return BadgeModel.fromJson(result);
    } catch (e) {
      throw Exception("Error fetching badge: ${e.toString()}");
    }
  }
}