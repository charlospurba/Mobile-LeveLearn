import 'dart:async';
import 'package:app/model/user.dart';
import 'package:app/model/user_challenge.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/course.dart';
import '../model/user_badge.dart';
import '../service/badge_service.dart';
import '../service/course_service.dart';
import '../service/user_service.dart';
import '../utils/colors.dart';
import 'login_screen.dart';

// IMPORT KOMPONEN GAMIFIKASI
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

  @override
  void initState() {
    super.initState();
    _initialLoad(); // Memicu pengecekan streak harian otomatis saat aplikasi dibuka
  }

  // Fungsi muat data awal dan sinkronisasi streak otomatis
  Future<void> _initialLoad() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    await getUserFromSharedPreference();
    
    if (idUser != 0) {
      // 1. Jalankan sinkronisasi streak ke backend
      await handleStreakInteraction(); 
      
      // 2. Muat data pendukung secara paralel untuk performa
      await Future.wait([
        getAllUser(),
        getEnrolledCourse(),
        fetchChallenges(),
      ]);
    }
    
    if (mounted) setState(() => isLoading = false);
  }

  // Mengambil data tantangan harian dari database
  Future<void> fetchChallenges() async {
    if (idUser == 0) return;
    try {
      final result = await UserService.getUserChallenges(idUser);
      if (mounted) {
        setState(() {
          myChallenges = result;
        });
      }
    } catch (e) {
      debugPrint("Gagal load challenges: $e");
    }
  }

  // Logika pemicu streak yang divalidasi oleh backend
  Future<void> handleStreakInteraction() async {
    if (idUser == 0) return;

    try {
      // Ambil data user terbaru
      final currentUser = await UserService.getUserById(idUser);
      
      // Kirim ke backend untuk hitung penambahan/reset streak berdasarkan tanggal
      final updatedUser = await UserService.updateUser(currentUser); 
      
      if (mounted) {
        setState(() {
          user = updatedUser;
          streakDays = updatedUser.streak;
        });
      }
      debugPrint("Sistem: Streak hari ini adalah ${updatedUser.streak}");
    } catch (e) {
      debugPrint("Gagal sinkron streak: $e");
    }
  }

  Future<void> getEnrolledCourse() async {
    if (idUser == 0) return;
    try {
      final result = await CourseService.getEnrolledCourse(idUser).timeout(const Duration(seconds: 10));
      allCourses = result;

      pref = await SharedPreferences.getInstance();
      final lastId = pref.getInt('lastestSelectedCourse');
      Course? foundCourse;

      if (lastId != null) {
        for (var c in allCourses) {
          if (c.id == lastId) {
            foundCourse = c;
            break;
          }
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
      final result = await UserService.getAllUser().timeout(const Duration(seconds: 10));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            right: 0,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset("lib/assets/vectors/learn.png", width: 200, height: 200),
            ),
          ),
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
                    onRefresh: _initialLoad, // Swipe refresh memicu hitung ulang streak
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          _buildProfileHeader(),
                          _buildStatsDashboard(),
                          
                          // Widget Tantangan Harian
                          ChallengeWidget(
                            challenges: myChallenges,
                            userId: idUser,
                            onTabChange: (index) => widget.updateIndex(index),
                            onRefresh: () {
                              fetchChallenges(); 
                              getUserFromSharedPreference(); 
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
                  StreakStat(days: streakDays), // Menampilkan streak hari aktif secara akurat
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

  // Perbaikan tampilan Explore Courses agar tidak berulang (looping) jika data hanya satu
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
                  viewportFraction: allCourses.length == 1 ? 0.9 : 0.7, // Fokuskan jika hanya 1 kursus
                  enlargeCenterPage: true,
                  enableInfiniteScroll: allCourses.length > 1, // Matikan infinite scroll jika data hanya 1
                  autoPlay: allCourses.length > 1,
                ),
                itemBuilder: (context, index, realIndex) {
                  final course = allCourses[index];
                  return GestureDetector(
                    onTap: () {
                      pref.setInt('lastestSelectedCourse', course.id);
                      if (mounted) {
                        setState(() {
                          lastestCourse = course;
                        });
                      }
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