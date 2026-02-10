import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/colors.dart';
import 'main_screen.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  // Fungsi untuk membuka link eksternal (GitHub)
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka URL: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/pictures/background-pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- HEADER: SLIVER APP BAR ---
            SliverAppBar(
              expandedHeight: 240.0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primaryColor,
              leading: IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Mainscreen(navIndex: 4)),
                  );
                },
                icon: const Icon(LineAwesomeIcons.angle_left_solid, color: Colors.white),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  "About LeveLearn",
                  style: TextStyle(
                    fontFamily: 'DIN_Next_Rounded',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'lib/assets/pictures/about-header.png',
                      fit: BoxFit.cover,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- CONTENT: LIST INFO ---
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),

                // Section 1: Pengenalan LeveLearn
                _buildInfoCard(
                  title: "Visi LeveLearn",
                  content:
                      "LeveLearn adalah platform pembelajaran digital inovatif yang mengintegrasikan elemen gamifikasi untuk mentransformasi cara belajar mahasiswa Informatika. Berawal dari tantangan rendahnya keterlibatan pada e-learning konvensional, LeveLearn menciptakan ekosistem belajar yang adaptif dan memotivasi melalui pengalaman bermain (game-like experience).",
                  icon: LineAwesomeIcons.rocket_solid,
                ),

                // Section 2: Logo Tengah (Hero Animation)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        'lib/assets/pictures/about-logo.png',
                        height: 100,
                      ),
                    ),
                  ),
                ),

                // Section 3: Metodologi Adaptive Gamification
                _buildInfoCard(
                  title: "Adaptive Gamification",
                  content:
                      "Sebagai evolusi dari sistem statis, LeveLearn Versi 2 menerapkan pendekatan Adaptive Gamification. Sistem tidak lagi menggunakan model 'one-size-fits-all', melainkan mampu menyesuaikan elemen gamifikasi secara dinamis mengikuti perubahan preferensi dan pola perilaku pengguna selama proses pembelajaran berlangsung.",
                  icon: LineAwesomeIcons.brain_solid,
                ),

                // Section 4: Hybrid Preference Elicitation & GMM
                _buildInfoCard(
                  title: "Hybrid Elicitation (ML)",
                  content:
                      "Melalui metode Hybrid Preference Elicitation, LeveLearn menggabungkan preferensi eksplisit (survei) dengan preferensi implisit yang dianalisis menggunakan algoritma Gaussian Mixture Model (GMM). Pendekatan Machine Learning ini mengelompokkan interaksi data log pengguna secara real-time untuk penyesuaian elemen gamifikasi yang lebih personal.",
                  icon: LineAwesomeIcons.microchip_solid,
                ),

                // Section 5: Tech Stack
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 30, 24, 15),
                  child: Text(
                    "Teknologi Pengembangan",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DIN_Next_Rounded',
                    ),
                  ),
                ),

                _buildTechStackGrid(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                  child: Text(
                    "Arsitektur sistem dibangun menggunakan Flutter (Mobile), React (Web), dan Node.js Express (Backend). Data dikelola secara tangguh oleh PostgreSQL dengan Supabase Storage, serta didukung Docker untuk standarisasi deployment aplikasi.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ),

                // Button GitHub
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _launchURL('https://github.com/Levelearn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      icon: const Icon(LineAwesomeIcons.github, color: Colors.white, size: 28),
                      label: const Text(
                        "Explore Source Code",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'DIN_Next_Rounded',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),
                const Center(
                  child: Text(
                    "© 2026 LeveLearn • Versi 2.0.0\nAll rights reserved.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                  ),
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildInfoCard({required String title, required String content, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryColor, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'DIN_Next_Rounded',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildTechStackGrid() {
    // Array aset gambar teknologi
    final techIcons = [
      'flutter.png', 'node.png', 'react.png',
      'postgresql.png', 'supabase.png', 'docker.png'
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: techIcons.length,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBFB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset(
              'lib/assets/pictures/${techIcons[index]}',
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}