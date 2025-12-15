// lib/global_var.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class GlobalVar {
  // Singleton
  static final GlobalVar _instance = GlobalVar._internal();
  factory GlobalVar() => _instance;
  GlobalVar._internal();

  // Example image URL (unchanged)
  static const String imageUrl =
      'https://www.globalcareercounsellor.com/blog/wp-content/uploads/2018/05/Online-Career-Counselling-course.jpg';

  // Compute baseUrl depending on runtime environment.
  // NOTE: this file imports dart:io and so is intended for mobile (Android/iOS).
  // If you need to build for Flutter Web, ask me for a web-safe variant.
  static String get baseUrl {
    // Web (browser) should use localhost
    if (kIsWeb) return 'http://localhost:7000/api';

    // On Android emulator (Android Studio), use 10.0.2.2
    // On iOS simulator, use 127.0.0.1
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:7000/api';
      if (Platform.isIOS) return 'http://127.0.0.1:7000/api';
    } catch (_) {
      // if Platform is not available for some reason, fall back below
    }

    // Fallback: use your machine LAN IP so physical devices can reach it.
    // Replace with your PC's IP on Wi‑Fi (example from your server logs).
    return 'http://192.168.0.118:7000/api';
  }

  // Example other service URL (you can also adapt like baseUrl if needed)
  static String similiarityEssayUrl =
      'http://192.168.1.3:8081/evaluate/'; // adjust if required

  // App colors
  static const Color primaryColor = Color.fromARGB(255, 68, 31, 127);
  static const Color secondaryColor = Color.fromARGB(255, 26, 173, 33);
  static const Color accentColor = Color.fromARGB(255, 221, 200, 255);
}

// Create an instance if you prefer to use it directly
final globalVars = GlobalVar();