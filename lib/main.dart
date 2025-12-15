import 'package:app/utils/colors.dart';
import 'package:app/view/login_screen.dart';
import 'package:app/view/main_screen.dart';
import 'package:app/view/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Color purple = AppColors.primaryColor;
Color backgroundNavHex = Color(0xFFF3EDF7);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('firstLaunch') ?? true;
  final bool isLoggedIn = await checkLoginStatus();
  // final bool isLoggedIn = true;

  await Supabase.initialize(
      url: "https://kfxaanhuccwjokmkdtho.supabase.co",
      anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmeGFhbmh1Y2N3am9rbWtkdGhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwNDE1MDEsImV4cCI6MjA1NTYxNzUwMX0.icFBLGnPC8eqbxnGuovKNnJ5Frvm_SnFrPDsoFlfNEA"
  );
  runApp(MyApp(isLoggedIn: isLoggedIn, isFirstLaunch: isFirstLaunch));
}

Future<bool> checkLoginStatus() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  return token != null;
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isFirstLaunch;

  const MyApp({super.key, required this.isLoggedIn, required this.isFirstLaunch});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Widget home;
    if (isFirstLaunch) {
      home = OnboardingScreen();
    } else if (isLoggedIn) {
      home = Mainscreen();
    } else {
      home = LoginScreen();
    }

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: home
    );
  }
}