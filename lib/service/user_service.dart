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
      final response =
          await http.get(Uri.parse('${GlobalVar.baseUrl}/user/$id'));
      final body = response.body;
      final result = jsonDecode(body);
      Student users = Student.fromJson(result);
      return users;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final uri = Uri.parse('${GlobalVar.baseUrl}/login');
    final request = {'username': username, 'password': password};
    try {
      print('LOGIN -> POST $uri');
      print('Request body: $request');

      final response = await http
          .post(uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
              },
              body: jsonEncode(request))
          .timeout(const Duration(seconds: 10)); // protect against hangs

      print('HTTP ${response.statusCode}');
      print('Response body: ${response.body}');

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
        final body = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Empty response'};
        return {
          'code': response.statusCode,
          'message': body['message'] ?? body
        };
      }
    } on SocketException catch (e) {
      // network-level error (no route to host etc)
      return {'code': 0, 'message': 'Network error: ${e.message}'};
    } on FormatException catch (e) {
      // response was not valid JSON
      return {'code': 0, 'message': 'Response format error: ${e.message}'};
    } on http.ClientException catch (e) {
      return {'code': 0, 'message': 'HTTP client error: ${e.message}'};
    } on TimeoutException {
      return {'code': 0, 'message': 'Request timeout'};
    } catch (e) {
      return {'code': 0, 'message': e.toString()};
    }
  }

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
        "instructorId": user.instructorId,
        "instructorCourses": user.instructorCourses
      };
      final response =
          await http.put(Uri.parse('${GlobalVar.baseUrl}/user/${user.id}'),
              headers: {
                'Content-type': 'application/json; charset=utf-8',
                'Accept': 'application/json',
              },
              body: jsonEncode(request));

      final body = response.body;
      // print(body);
      final result = jsonDecode(body);
      // print(result);
      Student users = Student.fromJson(result['user']);
      return users;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> updatePassword(Student user) async {
    try {
      Map<String, dynamic> request = {
        "password": user.password,
      };
      final response =
          await http.put(Uri.parse('${GlobalVar.baseUrl}/user/${user.id}'),
              headers: {
                'Content-type': 'application/json; charset=utf-8',
                'Accept': 'application/json',
              },
              body: jsonEncode(request));

      // Utilize the response body
      print(response.body); // Debugging purpose
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Student> updateUserPoints(Student user) async {
    try {
      Map<String, dynamic> request = {
        "points": user.points,
      };
      final response =
          await http.put(Uri.parse('${GlobalVar.baseUrl}/user/${user.id}'),
              headers: {
                'Content-type': 'application/json; charset=utf-8',
                'Accept': 'application/json',
              },
              body: jsonEncode(request));

      final body = response.body;
      final result = jsonDecode(body);
      Student users = Student.fromJson(result['user']);
      return users;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Student> updateUserPointsAndBadge(Student user) async {
    try {
      Map<String, dynamic> request = {
        "points": user.points,
      };
      final response =
          await http.put(Uri.parse('${GlobalVar.baseUrl}/user/${user.id}'),
              headers: {
                'Content-type': 'application/json; charset=utf-8',
                'Accept': 'application/json',
              },
              body: jsonEncode(request));

      final body = response.body;
      final result = jsonDecode(body);
      Student users = Student.fromJson(result['user']);
      return users;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> updateUserPhoto(Student user) async {
    try {
      Map<String, dynamic> request = {
        "image": user.image,
      };
      final response =
          await http.put(Uri.parse('${GlobalVar.baseUrl}/user/${user.id}'),
              headers: {
                'Content-type': 'application/json; charset=utf-8',
                'Accept': 'application/json',
              },
              body: jsonEncode(request));

      final body = response.body;
      // print(body);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
