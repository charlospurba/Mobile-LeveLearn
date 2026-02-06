import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:app/model/user.dart';
import 'package:app/model/user_challenge.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/course.dart';
import '../model/user_badge.dart';
import '../service/badge_service.dart';
import '../service/course_service.dart';
import '../service/user_service.dart';
import '../service/activity_service.dart'; 
import '../utils/colors.dart';
import 'login_screen.dart';

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
  String userType = "Disruptors";

  final String apiBaseUrl = "http://10.106.207.43:7000/api";

  @override
  void initState() {
    super.initState();
    _initialLoad(); 
  }

  Future<void> _initialLoad() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      await getUserFromSharedPreference();
      
      if (idUser != 0) {
        await fetchAdaptiveProfile();

        await Future.wait<dynamic>([
          handleStreakInteraction(),
          getAllUser(),
          getEnrolledCourse(),
          fetchChallenges(),
        ]);

        ActivityService.sendLog(
          userId: idUser, 
          type: 'FREQUENT_ACCESS', 
          value: 1.0
        );
      }
    } catch (e) {
      debugPrint("Error loading home data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchAdaptiveProfile() async {
    final String url = "$apiBaseUrl/user/adaptive/$idUser";
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            userType = data['currentCluster'] ?? "Disruptors";
          });
        }
      }
    } catch (e) {
      debugPrint("Adaptive Fetch Failed: $e");
    }
  }

  Future<void> fetchChallenges() async {
    if (idUser == 0) return;
    try {
      final result = await UserService.getUserChallenges(idUser);
      if (mounted) setState(() => myChallenges = result);
    } catch (e) { debugPrint("Challenge error: $e"); }
  }

  Future<void> handleStreakInteraction() async {
    if (idUser == 0) return;
    try {
      final currentUser = await UserService.getUserById(idUser);
      final updatedUser = await UserService.updateUser(currentUser); 
      if (mounted) setState(() { user = updatedUser; streakDays = updatedUser.streak; });
    } catch (e) { debugPrint("Streak error: $e"); }
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
        for (var c in allCourses) { if (c.id == lastId) { foundCourse = c; break; } }
      }
      if (foundCourse == null && allCourses.isNotEmpty) {
        foundCourse = allCourses.first;
        await pref.setInt('lastestSelectedCourse', foundCourse.id);
      }
      final badgeResult = await BadgeService.getUserBadgeListByUserId(idUser);
      if (mounted) setState(() { lastestCourse = foundCourse; userBadges = badgeResult.where((b) => !b.isPurchased).toList(); });
    } catch (e) { debugPrint("Course error: $e"); }
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
        if (list[i].id == idUser) { if (mounted) setState(() => rank = i + 1); break; }
      }
    } catch (e) { debugPrint('Leaderboard error: $e'); }
  }

  Future<void> getUserFromSharedPreference() async {
    pref = await SharedPreferences.getInstance();
    final storedIdUser = pref.getInt('userId');
    if (storedIdUser != null) {
      idUser = storedIdUser;
      name = pref.getString('name') ?? '';
      final fetchedUser = await UserService.getUserById(idUser);
      if (mounted) setState(() { user = fetchedUser; streakDays = fetchedUser.streak; });
    } else { logout(); }
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
    Color clusterColor = Colors.redAccent; 
    IconData clusterIcon = Icons.bolt;

    if (userType == "Achievers") {
      clusterColor = Colors.blue; clusterIcon = Icons.stars;
    } else if (userType == "Players") {
      clusterColor = Colors.orange; clusterIcon = Icons.videogame_asset;
    } else if (userType == "Free Spirits") {
      clusterColor = Colors.teal; clusterIcon = Icons.explore;
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundVector(),
          Container(
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('lib/assets/pictures/background-pattern.png'), fit: BoxFit.cover, opacity: 0.1)),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _initialLoad, 
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          _buildProfileHeader(clusterColor, clusterIcon),
                          _buildAdaptiveGreeting(clusterColor, clusterIcon), 
                          
                          // 1. STATS DASHBOARD
                          _buildStatsDashboard(),

                          // 2. CHALLENGE
                          if (userType == "Achievers" || userType == "Free Spirits")
                            ChallengeWidget(
                              challenges: myChallenges, 
                              userId: idUser,
                              onTabChange: (index) => widget.updateIndex(index),
                              onRefresh: () { _initialLoad(); },
                            ),

                          // 3. PROGRESS CARD
                          if (userType != "Players")
                            ProgressCard(lastestCourse: lastestCourse, onTap: () => widget.updateIndex(2)),

                          _buildExploreSection(),

                          // 4. LEADERBOARD
                          if (userType != "Free Spirits")
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

  Widget _buildProfileHeader(Color clusterColor, IconData clusterIcon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hello! Happy Learning', style: TextStyle(color: AppColors.primaryColor, fontSize: 14, fontFamily: 'DIN_Next_Rounded')),
                Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryColor, fontFamily: 'DIN_Next_Rounded')),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: clusterColor.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(20), 
                    border: Border.all(color: clusterColor.withOpacity(0.5))
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(clusterIcon, size: 14, color: clusterColor),
                      const SizedBox(width: 6),
                      Text(userType.toUpperCase(), style: TextStyle(color: clusterColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5, fontFamily: 'DIN_Next_Rounded')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => widget.updateIndex(4),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]
              ),
              child: CircleAvatar(radius: 30, backgroundColor: Colors.grey[200], backgroundImage: user?.image != null && user?.image != "" ? NetworkImage(user!.image!) : null, child: user?.image == null || user?.image == "" ? const Icon(Icons.person, size: 30) : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveGreeting(Color color, IconData icon) {
    String greeting = "Semangat belajar!";
    if (userType == "Achievers") greeting = "Siap memecahkan rekor nilai kuis?";
    else if (userType == "Players") greeting = "Ada hadiah baru menantimu!";
    else if (userType == "Free Spirits") greeting = "Temukan pengetahuan unik hari ini!";
    else if (userType == "Disruptors") greeting = "Tetap fokus dan raih peringkat teratas!";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: color.withOpacity(0.2))
        ),
        child: Row(
          children: [ 
            Icon(icon, color: color), 
            const SizedBox(width: 12), 
            Expanded(child: Text(greeting, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontFamily: 'DIN_Next_Rounded', fontSize: 15)))
          ]
        ),
      ),
    );
  }

  Widget _buildStatsDashboard() { 
    return Padding(
      padding: const EdgeInsets.all(16.0), 
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20), 
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('lib/assets/pictures/dashboard.png'), fit: BoxFit.cover)), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [ 
                Row(
                  mainAxisAlignment: MainAxisAlignment.start, 
                  children: [
                    if (userType == "Achievers" || userType == "Free Spirits") ...[
                      BadgeStat(count: userBadges?.length ?? 0),
                      const SizedBox(width: 24),
                    ],
                    // MODIFIKASI: CourseStat sekarang muncul juga untuk Players
                    if (userType == "Achievers" || userType == "Free Spirits" || userType == "Disruptors" || userType == "Players") ...[
                      CourseStat(count: allCourses.length),
                      const SizedBox(width: 24),
                    ],
                    if (userType != "Free Spirits") ...[
                      RankStat(rank: rank, total: list.length),
                      const SizedBox(width: 24),
                    ],
                    if (userType == "Players")
                      StreakStat(days: streakDays),
                  ],
                ), 
                const SizedBox(height: 25), 
                if (userType != "Disruptors")
                  TotalPoints(points: user?.points ?? 0)
              ],
            ),
          ),
        ),
      ),
    ); 
  }

  Widget _buildExploreSection() { 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [ 
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Text('Explore Courses', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryColor, fontFamily: 'DIN_Next_Rounded'))), 
        allCourses.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No courses joined yet."))) 
        : CarouselSlider.builder(
            itemCount: allCourses.length, 
            options: CarouselOptions(height: 190, viewportFraction: allCourses.length == 1 ? 0.9 : 0.75, enlargeCenterPage: true, enableInfiniteScroll: allCourses.length > 1, autoPlay: allCourses.length > 1), 
            itemBuilder: (context, index, realIndex) { 
              final course = allCourses[index]; 
              return GestureDetector(
                onTap: () { pref.setInt('lastestSelectedCourse', course.id); setState(() { lastestCourse = course; }); widget.updateIndex(2); }, 
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5), 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                    image: DecorationImage(image: course.image != "" ? NetworkImage(course.image) : const AssetImage('lib/assets/pictures/imk-picture.jpg') as ImageProvider, fit: BoxFit.cover)
                  ), 
                  child: Container(
                    alignment: Alignment.bottomLeft, 
                    padding: const EdgeInsets.all(15), 
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)])), 
                    child: Text(course.courseName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded'))
                  )
                )
              ); 
            }
          )
      ]
    ); 
  }

  Widget _buildBackgroundVector() { return Positioned(bottom: -20, right: -20, child: Opacity(opacity: 0.15, child: Image.asset("lib/assets/vectors/learn.png", width: 220, height: 220))); }
}