import 'dart:convert';
import 'package:app/global_var.dart';
import 'package:app/model/trade.dart';
import 'package:app/model/user_trade.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TradeService {
  // Mengambil semua master data trade/shop
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

  // Mengambil item khusus untuk Tab Shop (yang memiliki harga poin > 0)
  static Future<List<TradeModel>> getShopItems() async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/trade'));
      if (response.statusCode == 200) {
        final List result = jsonDecode(response.body);
        // Filter item yang memiliki harga poin (Shop)
        return result
            .map((json) => TradeModel.fromJson(json))
            .where((t) => t.priceInPoints > 0)
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Gagal mengambil data shop: $e");
    }
  }

  // Mencatat transaksi penukaran Badge (Avatar/Reward)
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
      debugPrint("Error createUserTrade: $e");
      return false;
    }
  }

  // Memproses pembelian item Marketplace dengan Poin
  static Future<bool> buyShopItem(int userId, int tradeId, int price) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVar.baseUrl}/trade/buy'),
        headers: {
          'Content-type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "userId": userId,
          "tradeId": tradeId,
          "price": price
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error buyShopItem: $e");
      return false;
    }
  }

  // Mengambil daftar item yang sudah dimiliki oleh user tertentu
  static Future<List<UserTrade>> getUserTrade(int userId) async {
    try {
      final response = await http.get(Uri.parse('${GlobalVar.baseUrl}/usertrade'));
      if (response.statusCode == 200) {
        final List result = jsonDecode(response.body);
        List<UserTrade> allUserTrades = result.map((json) => UserTrade.fromJson(json)).toList();
        return allUserTrades.where((ut) => ut.userId == userId).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Error fetching user trades: $e");
    }
  }
}