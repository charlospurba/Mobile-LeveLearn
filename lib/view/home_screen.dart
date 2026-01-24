import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/model/user.dart';
import 'package:app/model/user_challenge.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Service & Utils
import '../model/course.dart';
import '../model/user_badge.dart';
import '../service/badge_service.dart';
import '../service/course_service.dart';
import '../service/user_service.dart';
import '../service/activity_service.dart'; 
import '../utils/colors.dart';
import 'login_screen.dart';

// Import Komponen Gamifikasi
import 'package:app/view/gamification/badge_stat.dart';
import 'package:app/view/gamification/course_stat.dart';
import 'package:app/view/gamification/rank_stat.dart';
import 'package:app/view/gamification/streak_stat.dart';
import 'package:app/view/gamification/total_points.dart';
import 'package:app/view/gamification/progress_card.dart';
import 'package:app/view/gamification/leaderboard_list.dart';
import 'package:app/view/gamification/challenge.dart';

class Homescreen extends StatefulWidget {
  final Function(int) updateIndex;
  const Homescreen({super.key, required this.updateIndex});

  @override
  State<Homescreen> createState() => _HomeState();
}

class _HomeState extends State<Homescreen> {
  // --- STATE VARIABLES ---
  List<Course> allCourses = [];
  List<Student> list = [];
  List<UserChallenge> myChallenges = []; 
  String name = '';
  late SharedPreferences pref;
  Student? user;
  bool isLoading = true;
  Course? lastestCourse;
  int rank = 0;
  int idUser = 0;
  List<UserBadge>? userBadges = [];
  int streakDays = 0;

  // Variabel Profile Adaptif (Hasil Klasifikasi GMM)
  String userType = "Achievers";

  // --- KONFIGURASI NETWORK ---
  // Ganti IP ini dengan IP yang muncul di terminal Node.js Anda (On LAN)
  // Contoh: 192.168.1.15 atau gunakan 10.0.2.2 untuk emulator
  final String apiBaseUrl = "http://10.0.2.2:7000/api";

  @override
  void initState() {
    super.initState();
    _initialLoad(); 
  }

  // --- LOGIC FUNCTIONS ---

  Future<void> _initialLoad() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      await getUserFromSharedPreference();
      
      if (idUser != 0) {
        // 1. Catat Log Akses (Aksi Player)
        await ActivityService.sendLog(
          userId: idUser, 
          type: 'FREQUENT_ACCESS', 
          value: 1.0
        );

        // 2. Load Data Dasar Secara Berurutan (Mencegah Backend Overload)
        await handleStreakInteraction(); 
        await getAllUser();
        await getEnrolledCourse();
        await fetchChallenges(); 
        
        // 3. Ambil Profil ML (Terakhir karena prosesnya paling berat)
        await fetchAdaptiveProfile(); 
      }
    } catch (e) {
      debugPrint("Error during initial load: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Fungsi Utama: Sinkronisasi dengan GMM ML Service via Node.js
  Future<void> fetchAdaptiveProfile() async {
    final String url = "$apiBaseUrl/user/adaptive/$idUser";
    
    try {
      debugPrint("Fetching Adaptive Profile from: $url");
      
      // Menggunakan timeout 20 detik karena Node.js harus menunggu respon Python
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            userType = data['currentCluster'] ?? "Achievers";
          });
          debugPrint("User Cluster Updated: $userType");
        }
      }
    } on TimeoutException catch (_) {
      debugPrint("Koneksi Timeout: Server terlalu lama merespon ML.");
    } catch (e) {
      debugPrint("Koneksi Gagal: Pastikan Server Aktif & IP Benar ($e)");
    }
  }

  Future<void> fetchChallenges() async {
    if (idUser == 0) return;
    try {
      final result = await UserService.getUserChallenges(idUser);
      if (mounted) setState(() => myChallenges = result);
    } catch (e) {
      debugPrint("Gagal load challenges: $e");
    }
  }

  Future<void> handleStreakInteraction() async {
    if (idUser == 0) return;
    try {
      final currentUser = await UserService.getUserById(idUser);
      final updatedUser = await UserService.updateUser(currentUser); 
      if (mounted) {
        setState(() {
          user = updatedUser;
          streakDays = updatedUser.streak;
        });
      }
    } catch (e) {
      debugPrint("Gagal sinkron streak: $e");
    }
  }

  Future<void> getEnrolledCourse() async {
    if (idUser == 0) return;
    try {
      final result = await CourseService.getEnrolledCourse(idUser);
      allCourses = result;

      pref = await SharedPreferences.getInstance();
      final lastId = pref.getInt('lastestSelectedCourse');
      Course? foundCourse;

      if (lastId != null) {
        for (var c in allCourses) {
          if (c.id == lastId) { foundCourse = c; break; }
        }
      }

      if (foundCourse == null && allCourses.isNotEmpty) {
        foundCourse = allCourses.first;
        await pref.setInt('lastestSelectedCourse', foundCourse.id);
      }

      final badgeResult = await BadgeService.getUserBadgeListByUserId(idUser);

      if (mounted) {
        setState(() {
          lastestCourse = foundCourse;
          userBadges = badgeResult.where((b) => !b.isPurchased).toList();
        });
      }
    } catch (e) {
      debugPrint("Error enrolled course: $e");
    }
  }

  Future<void> getAllUser() async {
    try {
      final result = await UserService.getAllUser();
      if (mounted) {
        setState(() {
          list = result.where((u) => u.role == 'STUDENT').toList();
          list.sort((a, b) => (b.points ?? 0).compareTo(a.points ?? 0));
        });
      }

      if (idUser == 0) return;
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == idUser) {
          if (mounted) setState(() => rank = i + 1);
          break;
        }
      }
    } catch (e) {
      debugPrint('Leaderboard Error: $e');
    }
  }

  Future<void> getUserFromSharedPreference() async {
    pref = await SharedPreferences.getInstance();
    final storedIdUser = pref.getInt('userId');
    if (storedIdUser != null) {
      idUser = storedIdUser;
      name = pref.getString('name') ?? '';
      final fetchedUser = await UserService.getUserById(idUser);
      if (mounted) {
        setState(() {
          user = fetchedUser;
          streakDays = fetchedUser.streak;
        });
      }
    } else {
      logout();
    }
  }

  void logout() async {
    pref = await SharedPreferences.getInstance();
    pref.clear(); 
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundVector(),
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/pictures/background-pattern.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _initialLoad, 
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          _buildProfileHeader(),
                          _buildAdaptiveGreeting(), // Widget Dinamis GMM
                          _buildStatsDashboard(),
                          
                          ChallengeWidget(
                            challenges: myChallenges, 
                            userId: idUser,
                            onTabChange: (index) => widget.updateIndex(index),
                            onRefresh: () {
                              fetchChallenges(); 
                              getUserFromSharedPreference(); 
                              fetchAdaptiveProfile(); 
                            },
                          ),

                          ProgressCard(
                            lastestCourse: lastestCourse,
                            onTap: () => widget.updateIndex(2),
                          ),
                          _buildExploreSection(),
                          LeaderboardList(students: list),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundVector() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Opacity(
        opacity: 0.2,
        child: Image.asset("lib/assets/vectors/learn.png", width: 200, height: 200),
      ),
    );
  }

  // HEADER ADAPTIF: Berubah berdasarkan Cluster GMM
  Widget _buildAdaptiveGreeting() {
    String greeting = "Semangat belajar hari ini!";
    IconData icon = Icons.wb_sunny;
    Color color = AppColors.primaryColor;

    if (userType == "Achievers") {
      greeting = "Siap memecahkan rekor nilai kuis?";
      icon = Icons.emoji_events;
      color = Colors.blue;
    } else if (userType == "Players") {
      greeting = "Ada hadiah baru menantimu!";
      icon = Icons.redeem;
      color = Colors.orange;
    } else if (userType == "Free Spirits") {
      greeting = "Jelajahi materi baru yuk!";
      icon = Icons.explore;
      color = Colors.teal;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                greeting,
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: color, 
                  fontFamily: 'DIN_Next_Rounded'
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hello! Happy Learning', style: TextStyle(color: AppColors.primaryColor, fontFamily: 'DIN_Next_Rounded')),
              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryColor, fontFamily: 'DIN_Next_Rounded')),
            ],
          ),
          GestureDetector(
            onTap: () => widget.updateIndex(4),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[200],
              backgroundImage: user?.image != null && user?.image != "" ? NetworkImage(user!.image!) : null,
              child: user?.image == null || user?.image == "" ? const Icon(Icons.person) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(image: AssetImage('lib/assets/pictures/dashboard.png'), fit: BoxFit.cover),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start, 
                children: [
                  BadgeStat(count: userBadges?.length ?? 0),
                  const SizedBox(width: 24),
                  CourseStat(count: allCourses.length),
                  const SizedBox(width: 24),
                  RankStat(rank: rank, total: list.length),
                  const SizedBox(width: 24),
                  StreakStat(days: streakDays), 
                ],
              ),
              const SizedBox(height: 25),
              TotalPoints(points: user?.points ?? 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Explore Courses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryColor, fontFamily: 'DIN_Next_Rounded')),
        ),
        const SizedBox(height: 10),
        allCourses.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No courses joined yet.")))
            : CarouselSlider.builder(
                itemCount: allCourses.length,
                options: CarouselOptions(
                  height: 180, 
                  viewportFraction: allCourses.length == 1 ? 0.9 : 0.7, 
                  enlargeCenterPage: true,
                  enableInfiniteScroll: allCourses.length > 1, 
                  autoPlay: allCourses.length > 1,
                ),
                itemBuilder: (context, index, realIndex) {
                  final course = allCourses[index];
                  return GestureDetector(
                    onTap: () {
                      pref.setInt('lastestSelectedCourse', course.id);
                      if (mounted) setState(() { lastestCourse = course; });
                      widget.updateIndex(2);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: course.image != "" 
                            ? NetworkImage(course.image) 
                            : const AssetImage('lib/assets/pictures/imk-picture.jpg') as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter, 
                            end: Alignment.bottomCenter, 
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)]
                          ),
                        ),
                        child: Text(course.courseName, 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}