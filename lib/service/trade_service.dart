import 'dart:convert';
import 'package:app/global_var.dart';
import 'package:app/model/trade.dart';
import 'package:app/model/user_trade.dart';
import 'package:http/http.dart' as http;

class TradeService {
  static Future<List<TradeModel>> getAllTrades() async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/trade'));
      if (response.statusCode == 200) {
        final List result = jsonDecode(response.body);
        return result.map((json) => TradeModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Gagal mengambil data trade: $e");
    }
  }

  // Fungsi untuk mencatat transaksi ke database
  static Future<bool> createUserTrade(int userId, int tradeId) async {
    try {
      Map<String, dynamic> request = {
        "userId": userId,
        "tradeId": tradeId
      };
      final response = await http.post(
        Uri.parse('${GlobalVar.baseUrl}/usertrade'),
        headers: {
          'Content-type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(request),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error createUserTrade: $e");
      return false;
    }
  }

  static Future<List<UserTrade>> getUserTrade(int userId) async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/usertrade'));
      if (response.statusCode == 200) {
        final List result = jsonDecode(response.body);
        List<UserTrade> allUserTrades = result.map((json) => UserTrade.fromJson(json)).toList();
        // Filter di sisi client sesuai userId
        return allUserTrades.where((ut) => ut.userId == userId).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Error fetching user trades: $e");
    }
  }
}