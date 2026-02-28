import 'package:app/model/onboarding.dart';
import 'package:app/utils/colors.dart';
import 'package:app/view/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingModel> onboardingData = [
    OnboardingModel(
        image: 'lib/assets/vectors/socialshare-primary.png',
        title: 'Extra Time College',
        description:
            'Tingkatkan Pemahaman Kuliahmu, Kapan Saja, Di Mana Saja!'),
    OnboardingModel(
        image: 'lib/assets/vectors/gaming-primary.png',
        title: 'Gamified Learning',
        description: 'Belajar Sambil Bermain, Jadikan Ilmu sebagai Temanmu!'),
    OnboardingModel(
        image: 'lib/assets/vectors/socialinfluencer-primary.png',
        title: 'Levelearn!',
        description: 'Level Up Your Learn! Become Advanced!'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Pattern (Tetap penuh menutupi layar)
          Positioned.fill(
            child: Image.asset(
              'lib/assets/pictures/background-pattern.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. PageView (Diberi padding bawah agar kontennya otomatis naik dan tidak tabrakan dengan tombol)
          Padding(
            padding: const EdgeInsets.only(bottom: 140.0), // Ruang khusus untuk area tombol di bawah
            child: PageView.builder(
              controller: _pageController,
              itemCount: onboardingData.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                return OnboardingPage(model: onboardingData[index]);
              },
            ),
          ),
          
          // 3. Tombol dan Indikator (Ditempatkan terpisah di tumpukan paling atas)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0), // Jarak tombol ke batas bawah HP
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: onboardingData.length,
                      effect: WormEffect(
                        dotColor: Colors.grey,
                        activeDotColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _currentPage < onboardingData.length - 1
                              ? () {
                                  _pageController.nextPage(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.ease,
                                  );
                                }
                              : () async {
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('firstLaunch', false);

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LoginScreen()),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentPage < onboardingData.length - 1
                                ? 'Selanjutnya'
                                : 'Mulai',
                            style: TextStyle(
                              fontFamily: 'DIN_Next_Rounded',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingModel model;

  const OnboardingPage({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder membaca ukuran aktual layar yang tersedia (setelah dikurangi padding bawah 140)
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(), // Mencegah efek scroll mantul yang mengganggu swipe
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight, // Memastikan konten pas, tidak lebih dari layar
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(flex: isLandscape ? 1 : 2),

                  Container(
                    color: Colors.transparent,
                    height: isLandscape ? 80 : 128,
                  ),

                  Image.asset(
                    model.image,
                    height: isLandscape ? screenHeight * 0.25 : null,
                  ),

                  SizedBox(height: 20),

                  Text(
                    model.title,
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DIN_Next_Rounded',
                      color: AppColors.primaryColor,
                      fontSize: isLandscape ? 18 : null,
                    ),
                  ),

                  SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      model.description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontFamily: 'DIN_Next_Rounded',
                        fontSize: isLandscape ? 14 : null,
                      ),
                    ),
                  ),

                  // Spacer bottom asli dikembalikan tanpa pakai SizedBox(150)
                  Spacer(flex: isLandscape ? 2 : 3),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}