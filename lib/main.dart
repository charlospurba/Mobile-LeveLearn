import 'package:app/utils/colors.dart';
import 'package:app/view/login_screen.dart';
import 'package:app/view/main_screen.dart';
import 'package:app/view/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Color purple = AppColors.primaryColor;
Color backgroundNavHex = const Color(0xFFF3EDF7);

void main() async {
  // 1. Pastikan binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Supabase dengan proteksi Error (Penting untuk Flutter Web)
  try {
    await Supabase.initialize(
      url: "https://hfuwatcoqcitqykvrtbp.supabase.co",
      anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmdXdhdGNvcWNpdHF5a3ZydGJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYyNDYyODEsImV4cCI6MjA4MTgyMjI4MX0.JGgZorny4tj7Zo5G7KfuA30dwpX3F5iL3tvLeJIeW4c",
    );
  } catch (e) {
    debugPrint("Supabase sudah terinisialisasi atau error: $e");
  }

  // 3. Ambil data SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('firstLaunch') ?? true;
  
  // 4. Cek Login Status (Langsung ambil dari prefs yang sudah di-await di atas)
  String? token = prefs.getString('token');
  bool isLoggedIn = token != null;

  runApp(MyApp(isLoggedIn: isLoggedIn, isFirstLaunch: isFirstLaunch));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isFirstLaunch;

  const MyApp({super.key, required this.isLoggedIn, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    // Tentukan layar pertama
    Widget home;
    if (isFirstLaunch) {
      home = const OnboardingScreen();
    } else if (isLoggedIn) {
      home = const Mainscreen();
    } else {
      home = const LoginScreen();
    }

    return MaterialApp(
      title: 'LeveLearn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'DIN_Next_Rounded', // Konsisten dengan gaya UI Anda
      ),
      home: home,
    );
  }
}