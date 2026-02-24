import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class GlobalVar {
  static final GlobalVar _instance = GlobalVar._internal();
  factory GlobalVar() => _instance;
  GlobalVar._internal();

  // --- IP LAPTOP (WAJIB SAMA DENGAN IPCONFIG) ---
  static const String serverIp = '72.60.198.84';
  static const String port = '7000';

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$port';
    return 'http://$serverIp:$port';
  }

  static String similiarityEssayUrl = 'http://$serverIp:8002/evaluate/'; 

  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    
    // FIX: Jika path lokal, jangan tambahkan host http
    if (url.startsWith('lib/assets/') || url.startsWith('assets/')) {
      return url;
    }
    
    if (url.contains('localhost')) {
      return url.replaceAll('localhost', serverIp);
    }
    
    if (!url.startsWith('http')) {
      return 'http://$serverIp:$port$url';
    }
    return url;
  }

  static const Color primaryColor = Color.fromARGB(255, 68, 31, 127);
  static const Color secondaryColor = Color.fromARGB(255, 26, 173, 33);
  static const Color accentColor = Color.fromARGB(255, 221, 200, 255);
}

final globalVars = GlobalVar();