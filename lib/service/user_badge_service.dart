import 'package:app/model/user_badge.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../global_var.dart';

class UserBadgeService {
  static String get _apiPath => "${GlobalVar.baseUrl}/api";

  // --- FUNGSI BARU: Untuk menyimpan/klaim badge baru ke user ---
  static Future<void> createUserBadge({required int userId, required int badgeId}) async {
    try {
      final response = await http.post(
        // Sesuaikan dengan route API Anda di backend (biasanya /api/userbadge)
        Uri.parse('$_apiPath/userbadge'), 
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({
          'userId': userId,
          'badgeId': badgeId,
          'isPurchased': false, // Selalu false di awal karena didapat sebagai reward
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(">>> [BADGE SYSTEM] SUCCESS: Badge ID $badgeId berhasil disimpan ke User ID $userId!");
      } else {
        throw Exception("Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      debugPrint(">>> [BADGE SYSTEM] ERROR Gagal menyimpan badge: $e");
    }
  }

  // --- FUNGSI LAMA ---
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