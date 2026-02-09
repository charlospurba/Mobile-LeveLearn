import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class GlobalVar {
  static final GlobalVar _instance = GlobalVar._internal();
  factory GlobalVar() => _instance;
  GlobalVar._internal();

  // IP Laptop Anda (Pastikan HP terhubung ke Wi-Fi yang sama)
  static const String serverIp = '10.106.207.43';
  static const String port = '7000';

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$port/api';
    return 'http://$serverIp:$port/api';
  }

  // --- VARIABEL YANG TADI HILANG ---
  static String similiarityEssayUrl = 'http://$serverIp:8081/evaluate/'; 

static String formatImageUrl(String? url) {
  const String serverIp = '10.106.207.43';
  if (url == null || url.isEmpty) return "";
  if (url.startsWith('lib/assets/')) return url;
  if (url.contains('localhost')) return url.replaceAll('localhost', serverIp);
  if (!url.startsWith('http')) return 'http://$serverIp:7000$url';
  return url;
}

  static const Color primaryColor = Color.fromARGB(255, 68, 31, 127);
  static const Color secondaryColor = Color.fromARGB(255, 26, 173, 33);
  static const Color accentColor = Color.fromARGB(255, 221, 200, 255);
}

final globalVars = GlobalVar();