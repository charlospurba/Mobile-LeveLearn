import 'package:app/model/user_badge.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global_var.dart';

class UserBadgeService {
  static String get _apiPath => "${GlobalVar.baseUrl}/api";

  static Future<UserBadge> updateUserBadgeStatus(int userBadgeId, bool status) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiPath/userbadge/$userBadgeId'), 
        headers: {'Content-type' : 'application/json', 'Accept': 'application/json'}, 
        body: jsonEncode({"isPurchased": status})
      ).timeout(const Duration(seconds: 10));

      final result = jsonDecode(response.body);
      // Mendukung struktur data Prisma yang mengembalikan objek di dalam key
      return UserBadge.fromJson(result['UserBadge'] ?? result['data'] ?? result);
    } catch(e){
      throw Exception("Gagal update badge: $e");
    }
  }
}