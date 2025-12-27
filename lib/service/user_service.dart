import 'dart:async';
import 'dart:convert';
import 'package:app/model/login.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../model/user_challenge.dart'; 
import '../model/user.dart';
import '../global_var.dart';

class UserService {
  // --- FUNGSI AMBIL DATA USER ---
  
  static Future<List<Student>> getAllUser() async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/user'));
      final result = jsonDecode(response.body);
      List<Student> users = List<Student>.from(
        result.map((user) => Student.fromJson(user)),
      );
      return users;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Student> getUserById(int id) async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/user/$id'));
      final result = jsonDecode(response.body);
      Student users = Student.fromJson(result);
      return users;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- FUNGSI AUTHENTICATION ---

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final uri = Uri.parse('${GlobalVar.baseUrl}/login');
    final request = {'username': username, 'password': password};
    try {
      final response = await http.post(uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: jsonEncode(request)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final login = Login(
          id: result['data']['id'],
          name: result['data']['name'],
          role: result['data']['role'],
          token: result['token'],
        );
        return {'value': login, 'code': 200};
      } else {
        final body = response.body.isNotEmpty ? jsonDecode(response.body) : {'message': 'Empty response'};
        return {'code': response.statusCode, 'message': body['message'] ?? body};
      }
    } catch (e) {
      return {'code': 0, 'message': e.toString()};
    }
  }

  // --- FUNGSI UPDATE PROFIL & STREAK ---

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
          Uri.parse('${GlobalVar.baseUrl}/user/${user.id}'),
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

  // BARU: Fungsi untuk mengirim data kustom ke backend (untuk trigger Challenge Akurat)
  static Future<void> updateUserRaw(int userId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
          Uri.parse('${GlobalVar.baseUrl}/user/$userId'),
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
      Map<String, dynamic> request = {"password": user.password};
      await http.put(Uri.parse('${GlobalVar.baseUrl}/user/${user.id}'),
          headers: {
            'Content-type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(request));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- FUNGSI UPDATE POIN ---

  static Future<Student> updateUserPoints(Student user) async {
    try {
      Map<String, dynamic> request = {"points": user.points};
      final response = await http.put(
          Uri.parse('${GlobalVar.baseUrl}/user/${user.id}'),
          headers: {
            'Content-type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(request));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final userData = result['user'] ?? result['data'] ?? result;
        return Student.fromJson(userData);
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Student> updateUserPointsAndBadge(Student user) async {
    try {
      Map<String, dynamic> request = {
        "points": user.points,
        "badges": user.badges,
      };
      final response = await http.put(
          Uri.parse('${GlobalVar.baseUrl}/user/${user.id}'),
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

  // --- FUNGSI CHALLENGE TRIGGER ---

  static Future<void> triggerChallengeManual(int userId, String type) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVar.baseUrl}/user/trigger-challenge'),
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

  // --- FUNGSI DATA CHALLENGE & REWARD ---

  static Future<List<UserChallenge>> getUserChallenges(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVar.baseUrl}/user/$userId/challenges'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> result = jsonDecode(response.body);
        return result.map((json) => UserChallenge.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> claimChallengeReward(int userId, int userChallengeId) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVar.baseUrl}/user/claim-challenge'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userChallengeId': userChallengeId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- FUNGSI SHOP & AVATAR ---

  static Future<bool> savePurchasedAvatarToDb(int userId, int avatarId) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVar.baseUrl}/user/purchase-avatar'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({
          'user_id': userId,
          'avatar_id': avatarId,
        }),
      );
      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      return false;
    }
  }

  static Future<List<int>> getPurchasedAvatarsFromDb(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVar.baseUrl}/user/$userId/avatars'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        List<dynamic> data = result['data'] ?? []; 
        return data.map((item) => int.parse(item['avatar_id'].toString())).toList();
      }
      return [1];
    } catch (e) {
      return [1];
    }
  }
}