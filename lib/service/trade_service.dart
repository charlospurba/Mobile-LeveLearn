import 'dart:convert';
import 'package:app/global_var.dart';
import 'package:app/model/trade.dart';
import 'package:app/model/user_trade.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TradeService {
  // Helper internal untuk jalur API
  static String get _apiPath => "${GlobalVar.baseUrl}/api";

  static Future<List<TradeModel>> getAllTrades() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiPath/trade'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List result = jsonDecode(response.body);
        return result.map((json) => TradeModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error getAllTrades: $e");
      throw Exception("Gagal mengambil data trade: $e");
    }
  }

  static Future<List<TradeModel>> getShopItems() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiPath/trade'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List result = jsonDecode(response.body);
        return result
            .map((json) => TradeModel.fromJson(json))
            .where((t) => t.priceInPoints > 0)
            .toList();
      }
      return [];
    } catch (e) {
      print("Error getShopItems: $e");
      throw Exception("Gagal mengambil data shop: $e");
    }
  }

  static Future<bool> createUserTrade(int userId, int tradeId) async {
    try {
      Map<String, dynamic> request = {
        "userId": userId,
        "tradeId": tradeId
      };
      final response = await http.post(
        Uri.parse('$_apiPath/usertrade'),
        headers: {
          'Content-type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(request),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error createUserTrade: $e");
      return false;
    }
  }

  static Future<bool> buyShopItem(int userId, int tradeId, int price) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiPath/trade/buy'),
        headers: {
          'Content-type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "userId": userId,
          "tradeId": tradeId,
          "price": price
        }),
      ).timeout(const Duration(seconds: 15));
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error buyShopItem: $e");
      return false;
    }
  }

  static Future<List<UserTrade>> getUserTrade(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiPath/usertrade'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List result = jsonDecode(response.body);
        List<UserTrade> allUserTrades = result.map((json) => UserTrade.fromJson(json)).toList();
        return allUserTrades.where((ut) => ut.userId == userId).toList();
      }
      return [];
    } catch (e) {
      print("Error getUserTrade: $e");
      throw Exception("Error fetching user trades: $e");
    }
  }
}