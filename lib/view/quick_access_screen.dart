import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/colors.dart';

class QuickAccessScreen extends StatefulWidget {
  const QuickAccessScreen({super.key});

  @override
  State<QuickAccessScreen> createState() => _QuickAccessScreenState();
}

class _QuickAccessScreenState extends State<QuickAccessScreen> {
  // Data item navigasi dengan path asset lokal
  final List<QuickAccessItem> quickAccessItems = [
    QuickAccessItem(
      name: "E-Course Del",
      link: "https://ecourse.del.ac.id/",
      imageUrl: "lib/assets/pictures/ecourse.png",
    ),
    QuickAccessItem(
      name: "Campus Information System (CIS)",
      link: "https://cis.del.ac.id/",
      imageUrl: "lib/assets/pictures/cis.jpeg",
    ),
    QuickAccessItem(
      name: "Zimbra Del",
      link: "https://students.del.ac.id/",
      imageUrl: "lib/assets/pictures/zimbra.png",
    ),
  ];

  // Fungsi untuk membuka browser eksternal
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quick Access"),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LineAwesomeIcons.angle_left_solid, color: Colors.white),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'DIN_Next_Rounded',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/pictures/background-pattern.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quickAccessItems.length,
          itemBuilder: (context, index) {
            final item = quickAccessItems[index];
            return Container(
              // PERBAIKAN: Menggunakan EdgeInsets.only untuk bottom margin
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => _launchURL(item.link),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Wadah gambar yang fleksibel agar logo terlihat semua
                      Container(
                        width: 80,
                        height: 50,
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          item.imageUrl,
                          // FIT CONTAIN: Agar gambar tidak terpotong dan terlihat utuh
                          fit: BoxFit.contain, 
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Teks Nama Layanan
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: 'DIN_Next_Rounded',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      // Icon indikator link
                      const Icon(
                        LineAwesomeIcons.external_link_alt_solid,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class QuickAccessItem {
  final String name;
  final String link;
  final String imageUrl;

  QuickAccessItem({
    required this.name,
    required this.link,
    required this.imageUrl,
  });
}