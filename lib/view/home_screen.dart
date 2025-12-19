import 'dart:async';
import 'package:app/model/user.dart';
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

// IMPORT KOMPONEN DARI FOLDER GAMIFICATION
import 'package:app/view/gamification/badge_stat.dart';
import 'package:app/view/gamification/course_stat.dart';
import 'package:app/view/gamification/rank_stat.dart';
import 'package:app/view/gamification/streak_stat.dart';
import 'package:app/view/gamification/total_points.dart';
import 'package:app/view/gamification/progress_card.dart';
import 'package:app/view/gamification/leaderboard_list.dart';

class Homescreen extends StatefulWidget {
  final Function(int) updateIndex;
  const Homescreen({super.key, required this.updateIndex});

  @override
  State<Homescreen> createState() => _HomeState();
}

class _HomeState extends State<Homescreen> {
  List<Course> allCourses = [];
  List<Student> list = [];
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
    getUserFromSharedPreference().then((_) {
      getAllUser();
      updateStreak();
    });
    getEnrolledCourse();
  }

  // Logika Streak harian
  Future<void> updateStreak() async {
    pref = await SharedPreferences.getInstance();
    final String? lastLoginDateString = pref.getString('lastLoginDate');
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    if (lastLoginDateString == null) {
      await pref.setString('lastLoginDate', today.toIso8601String());
      await pref.setInt('streakDays', 1);
      setState(() => streakDays = 1);
      return;
    }

    final DateTime lastLoginDate = DateTime.parse(lastLoginDateString);
    final Duration difference = today.difference(lastLoginDate);

    if (difference.inDays == 0) {
      setState(() => streakDays = pref.getInt('streakDays') ?? 0);
    } else if (difference.inDays == 1) {
      final currentStreak = (pref.getInt('streakDays') ?? 0) + 1;
      await pref.setInt('streakDays', currentStreak);
      await pref.setString('lastLoginDate', today.toIso8601String());
      setState(() => streakDays = currentStreak);
    } else {
      await pref.setInt('streakDays', 1);
      await pref.setString('lastLoginDate', today.toIso8601String());
      setState(() => streakDays = 1);
    }
  }

  Future<void> getEnrolledCourse() async {
    pref = await SharedPreferences.getInstance();
    int? id = pref.getInt('userId');
    if (id != null) {
      try {
        final result = await CourseService.getEnrolledCourse(id).timeout(const Duration(seconds: 10));
        final fetchedUser = await UserService.getUserById(id).timeout(const Duration(seconds: 10));
        
        // Simpan data ke state
        allCourses = result;
        user = fetchedUser;

        // --- LOGIKA PERBAIKAN PROGRESS ---
        final lastId = pref.getInt('lastestSelectedCourse');
        Course? foundCourse;

        if (lastId != null) {
          // Cari course yang ID-nya sesuai dengan yang tersimpan terakhir kali
          for (var c in allCourses) {
            if (c.id == lastId) {
              foundCourse = c;
              break;
            }
          }
        }

        // FALLBACK: Jika tidak ada ID tersimpan, otomatis ambil course pertama
        if (foundCourse == null && allCourses.isNotEmpty) {
          foundCourse = allCourses.first;
          // Simpan ID ini secara permanen agar saat buka app lagi tidak null
          await pref.setInt('lastestSelectedCourse', foundCourse.id);
        }

        setState(() {
          lastestCourse = foundCourse;
          isLoading = false;
        });
      } catch (e) {
        setState(() => isLoading = false);
        debugPrint("Error: $e");
      }
    }
  }

  void getAllUser() async {
    try {
      final result = await UserService.getAllUser().timeout(const Duration(seconds: 10));
      setState(() {
        list = result.where((u) => u.role == 'STUDENT').toList();
        list.sort((a, b) => (b.points ?? 0).compareTo(a.points ?? 0));
      });

      if (idUser == 0) return;
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == idUser) {
          setState(() => rank = i + 1);
          break;
        }
      }
    } catch (e) {
      debugPrint('Leaderboard Error: $e');
    }
  }

  Future<void> getUserFromSharedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIdUser = prefs.getInt('userId');
    if (storedIdUser != null) {
      final fetchedUser = await UserService.getUserById(storedIdUser);
      setState(() {
        idUser = storedIdUser;
        name = prefs.getString('name') ?? '';
        user = fetchedUser;
      });
      getUserBadges(storedIdUser);
    } else {
      logout();
    }
  }

  Future<void> getUserBadges(int userId) async {
    final result = await BadgeService.getUserBadgeListByUserId(userId);
    setState(() => userBadges = result);
  }

  void logout() async {
    pref = await SharedPreferences.getInstance();
    pref.remove('userId');
    pref.remove('name');
    pref.remove('role');
    pref.remove('token');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
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
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        _buildProfileHeader(),
                        _buildStatsDashboard(),
                        // My Progress Card
                        ProgressCard(
                          lastestCourse: lastestCourse,
                          onTap: () => widget.updateIndex(2),
                        ),
                        _buildExploreSection(),
                        // Leaderboard Section
                        LeaderboardList(students: list),
                        const SizedBox(height: 30),
                      ],
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
                options: CarouselOptions(height: 180, viewportFraction: 0.7, enlargeCenterPage: true),
                itemBuilder: (context, index, realIndex) {
                  final course = allCourses[index];
                  return GestureDetector(
                    onTap: () async {
                      // Simpan ID yang dipilih ke SharedPreferences
                      await pref.setInt('lastestSelectedCourse', course.id);
                      setState(() {
                        lastestCourse = course;
                      });
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