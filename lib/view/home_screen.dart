import 'dart:async';
import 'package:app/model/user.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/course.dart';
import '../model/user_badge.dart';
import '../service/badge_service.dart';
import '../service/course_service.dart';
import '../service/user_service.dart';
import '../utils/colors.dart';
import 'login_screen.dart';

// IMPORT KOMPONEN GAMIFICATION
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
      // Sinkronisasi tampilan streak awal dari data user
      if (user != null) {
        setState(() => streakDays = user!.streak);
      }
    });
    getEnrolledCourse();
  }

  // --- LOGIKA STREAK TERBARU (SINKRON DB) ---
  Future<void> handleStreakInteraction() async {
    if (user == null) return;

    pref = await SharedPreferences.getInstance();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    
    int currentStreak = user!.streak;
    DateTime? lastInteractionDate = user!.lastInteraction;

    if (lastInteractionDate != null) {
      DateTime lastDate = DateTime(
          lastInteractionDate.year, 
          lastInteractionDate.month, 
          lastInteractionDate.day
      );
      final int difference = today.difference(lastDate).inDays;

      if (difference == 0) {
        // Sudah interaksi hari ini
        return; 
      } else if (difference == 1) {
        // Hari baru berurutan
        currentStreak++;
      } else {
        // Bolos > 1 hari, reset
        currentStreak = 1;
      }
    } else {
      // Interaksi pertama
      currentStreak = 1;
    }

    // Update UI & Object
    setState(() {
      streakDays = currentStreak;
      user!.streak = currentStreak;
      user!.lastInteraction = now;
    });

    // Simpan ke DB
    try {
      await UserService.updateUser(user!);
      debugPrint("Streak synced to database: $currentStreak");
    } catch (e) {
      debugPrint("Database sync failed: $e");
    }
  }

  Future<void> getEnrolledCourse() async {
    pref = await SharedPreferences.getInstance();
    int? id = pref.getInt('userId');
    if (id != null) {
      try {
        final result = await CourseService.getEnrolledCourse(id).timeout(const Duration(seconds: 10));
        final fetchedUser = await UserService.getUserById(id).timeout(const Duration(seconds: 10));
        
        allCourses = result;
        user = fetchedUser;

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

        setState(() {
          lastestCourse = foundCourse;
          streakDays = user?.streak ?? 0; // Sync streak dari data API
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
    pref.clear();
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
                : RefreshIndicator(
                    onRefresh: getEnrolledCourse,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          _buildProfileHeader(),
                          _buildStatsDashboard(),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  BadgeStat(count: userBadges?.length ?? 0),
                  CourseStat(count: allCourses.length),
                  RankStat(rank: rank, total: list.length),
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
                      // TRIGGER STREAK SAAT MEMBUKA COURSE
                      await handleStreakInteraction(); 
                      
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