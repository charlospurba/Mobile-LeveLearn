import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global_var.dart'; 

class ActivityService {
  static Future<void> sendLog({
    required int userId,
    required String type,
    required double value,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // PERBAIKAN: Tambahkan /api sebelum /activity/log
      final url = "${GlobalVar.baseUrl}/api/activity/log";
      
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "type": type,
          "value": value,
          "metadata": metadata ?? {},
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Log $type recorded successfully");
      } else {
        print("Failed to record log: ${response.body}");
      }
    } catch (e) {
      print("Error sending log: $e");
    }
  }
}