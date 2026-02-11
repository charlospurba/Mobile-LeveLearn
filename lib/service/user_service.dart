import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../model/login.dart';
import '../model/user_challenge.dart'; 
import '../model/user.dart';
import '../global_var.dart';

class UserService {
  // Helper agar semua URL otomatis menggunakan prefix /api secara konsisten
  // Merujuk ke GlobalVar.baseUrl (http://10.107.253.43:7000)
  static String get _apiPath => "${GlobalVar.baseUrl}/api";

  // --- FUNGSI AUTHENTICATION ---

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final uri = Uri.parse('$_apiPath/login');
    final request = {'username': username, 'password': password};
    
    try {
      print("LOG: Mencoba POST login ke $uri");
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(request)
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final loginData = Login(
          id: result['data']['id'],
          name: result['data']['name'],
          role: result['data']['role'],
          token: result['token'],
        );
        return {'value': loginData, 'code': 200};
      } else {
        final body = response.body.isNotEmpty ? jsonDecode(response.body) : {'message': 'Gagal masuk'};
        return {'code': response.statusCode, 'message': body['message'] ?? 'Login Gagal'};
      }
    } catch (e) {
      print("DETAIL ERROR LOGIN: $e");
      return {
        'code': 0, 
        'message': "Timeout/Koneksi Gagal. Pastikan Laptop & HP satu WiFi dan Firewall Laptop mati."
      };
    }
  }

  // --- FUNGSI AMBIL DATA USER ---

  static Future<List<Student>> getAllUser() async {
    try {
      final response = await http.get(Uri.parse('$_apiPath/user'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List result = jsonDecode(response.body);
        return result.map((user) => Student.fromJson(user)).toList();
      }
      throw Exception("Gagal mengambil data: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error getAllUser: $e");
    }
  }

  static Future<Student> getUserById(int id) async {
    try {
      final response = await http.get(Uri.parse('$_apiPath/user/$id'))
          .timeout(const Duration(seconds: 10));
      final result = jsonDecode(response.body);
      return Student.fromJson(result);
    } catch (e) {
      throw Exception("Error getUserById: $e");
    }
  }

  // --- FUNGSI UPDATE PROFIL, STREAK & PASSWORD ---

  static Future<Student> updateUser(Student user) async {
    try {
      Map<String, dynamic> request = {
        "name": user.name,
        "username": user.username,
        "role": user.role,
        "studentId": user.studentId,
        "points": user.points,
        "totalCourses": user.totalCourses,
        "badges": user.badges,
        "image": user.image,
        "streak": user.streak,
        "lastInteraction": user.lastInteraction?.toIso8601String(),
        "instructorId": user.instructorId,
        "instructorCourses": user.instructorCourses
      };
      
      final response = await http.put(
        Uri.parse('$_apiPath/user/${user.id}'),
        headers: {
          'Content-type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(request)
      ).timeout(const Duration(seconds: 10));

      final result = jsonDecode(response.body);
      final userData = result['user'] ?? result['data'] ?? result;
      return Student.fromJson(userData);
    } catch (e) {
      throw Exception("Error updateUser: $e");
    }
  }

  static Future<void> updateUserRaw(int userId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
          Uri.parse('$_apiPath/user/$userId'),
          headers: {
            'Content-type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(data));
      print('DEBUG UPDATE RAW: ${response.body}');
    } catch (e) {
      print('Error updateUserRaw: $e');
    }
  }

  static Future<void> updatePassword(Student user) async {
    try {
      await http.put(
        Uri.parse('$_apiPath/user/${user.id}'),
        headers: {'Content-type': 'application/json'},
        body: jsonEncode({"password": user.password})
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception("Gagal update password: $e");
    }
  }

  // --- FUNGSI UPDATE POIN & BADGE ---

  static Future<Student> updateUserPoints(Student user) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiPath/user/${user.id}'),
        headers: {'Content-type': 'application/json'},
        body: jsonEncode({"points": user.points})
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final userData = result['user'] ?? result['data'] ?? result;
        return Student.fromJson(userData);
      }
      throw Exception("Server error saat update poin");
    } catch (e) {
      throw Exception("Error updatePoints: $e");
    }
  }

  static Future<Student> updateUserPointsAndBadge(Student user) async {
    try {
      Map<String, dynamic> request = {
        "points": user.points,
        "badges": user.badges,
      };
      final response = await http.put(
          Uri.parse('$_apiPath/user/${user.id}'),
          headers: {
            'Content-type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(request));

      final result = jsonDecode(response.body);
      return Student.fromJson(result['user'] ?? result['data'] ?? result);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- FUNGSI CHALLENGE ---

  static Future<List<UserChallenge>> getUserChallenges(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiPath/user/$userId/challenges'),
        headers: {'Accept': 'application/json'}
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List result = jsonDecode(response.body);
        return result.map((json) => UserChallenge.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching challenges: $e");
      return [];
    }
  }

  static Future<void> triggerChallengeManual(int userId, String type) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiPath/user/trigger-challenge'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({
          'userId': userId,
          'type': type,
        }),
      );
      print('DEBUG TRIGGER CHALLENGE: ${response.body}');
    } catch (e) {
      print('Error triggerChallengeManual: $e');
    }
  }

  static Future<void> triggerChallenge(int userId, String type) async {
    return triggerChallengeManual(userId, type);
  }

  static Future<bool> claimChallengeReward(int userId, int userChallengeId) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiPath/user/claim-challenge'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userChallengeId': userChallengeId,
        })
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- FUNGSI SHOP & AVATAR ---

  static Future<bool> savePurchasedAvatarToDb(int userId, int avatarId) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiPath/user/purchase-avatar'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({
          'user_id': userId,
          'avatar_id': avatarId,
        })
      ).timeout(const Duration(seconds: 10));
      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      return false;
    }
  }

  static Future<List<int>> getPurchasedAvatarsFromDb(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiPath/user/$userId/avatars'),
        headers: {'Accept': 'application/json'}
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        List data = result['data'] ?? []; 
        return data.map((item) => int.parse(item['avatar_id'].toString())).toList();
      }
      return [1];
    } catch (e) {
      return [1];
    }
  }
}