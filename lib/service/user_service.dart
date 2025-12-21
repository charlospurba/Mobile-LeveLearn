import 'dart:async';
import 'dart:convert';
import 'package:app/model/login.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../global_var.dart';
import '../model/user.dart';

class UserService {
  static Future<List<Student>> getAllUser() async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/user'));
      final body = response.body;
      final result = jsonDecode(body);
      List<Student> users = List<Student>.from(
        result.map(
          (user) => Student.fromJson(user),
        ),
      );
      return users;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Student> getUserById(int id) async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/user/$id'));
      final body = response.body;
      final result = jsonDecode(body);
      Student users = Student.fromJson(result);
      return users;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final uri = Uri.parse('${GlobalVar.baseUrl}/login');
    final request = {'username': username, 'password': password};
    try {
      print('LOGIN -> POST $uri');
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

  // --- PERBAIKAN: Memastikan mapping response sesuai dengan struktur 'user' dari backend ---
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
        // --- TAMBAHKAN SINKRONISASI STREAK ---
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
      Student updatedUser = Student.fromJson(result['user'] ?? result['data'] ?? result);
      return updatedUser;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  static Future<void> updatePassword(Student user) async {
    try {
      Map<String, dynamic> request = {
        "password": user.password,
      };
      final response = await http.put(Uri.parse('${GlobalVar.baseUrl}/user/${user.id}'),
          headers: {
            'Content-type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(request));
      print(response.body);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Student> updateUserPoints(Student user) async {
    try {
      Map<String, dynamic> request = {"points": user.points};
      final response = await http.put(Uri.parse('${GlobalVar.baseUrl}/user/${user.id}'),
          headers: {
            'Content-type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(request));

      final result = jsonDecode(response.body);
      Student users = Student.fromJson(result['user'] ?? result['data'] ?? result);
      return users;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Student> updateUserPointsAndBadge(Student user) async {
    try {
      Map<String, dynamic> request = {"points": user.points};
      final response = await http.put(Uri.parse('${GlobalVar.baseUrl}/user/${user.id}'),
          headers: {
            'Content-type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(request));

      final result = jsonDecode(response.body);
      Student users = Student.fromJson(result['user'] ?? result['data'] ?? result);
      return users;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> updateUserPhoto(Student user) async {
    try {
      Map<String, dynamic> request = {"image": user.image};
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

  // ==========================================================
  // FUNGSI BARU UNTUK SINKRONISASI DATABASE (PENYEBAB ERROR BELI AVATAR)
  // ==========================================================

  // 1. Simpan pembelian avatar baru ke tabel database backend
static Future<bool> savePurchasedAvatarToDb(int userId, int avatarId) async {
    try {
      // PERBAIKAN: Gunakan /user/purchase-avatar agar sesuai dengan UserRouter.js
      final url = Uri.parse('${GlobalVar.baseUrl}/user/purchase-avatar');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        // PERBAIKAN: Gunakan snake_case sesuai req.body di UserController.js
        body: jsonEncode({
          'user_id': userId,
          'avatar_id': avatarId,
        }),
      );

      print('DEBUG PURCHASE STATUS: ${response.statusCode}');
      print('DEBUG PURCHASE BODY: ${response.body}');

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print('Error savePurchasedAvatarToDb: $e');
      return false;
    }
  }  
  
  // 2. Ambil daftar avatar yang sudah dimiliki user dari database
 static Future<List<int>> getPurchasedAvatarsFromDb(int userId) async {
    try {
      // PERBAIKAN: Sesuaikan endpoint dengan router backend
      final response = await http.get(
        Uri.parse('${GlobalVar.baseUrl}/user/$userId/avatars'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Mapping data dari format {"data": [{"avatar_id": 1}, ...]}
        List<dynamic> data = result['data'] ?? []; 
        return data.map((item) => int.parse(item['avatar_id'].toString())).toList();
      }
      return [1];
    } catch (e) {
      print('Error getPurchasedAvatarsFromDb: $e');
      return [1];
    }
  }
}