import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/global_var.dart';
import 'package:app/model/chapter.dart';
import 'package:app/model/user_badge.dart';
import 'package:app/service/badge_service.dart';
import 'package:app/service/chapter_service.dart';
import 'package:app/service/user_service.dart';
import 'package:app/view/about_app.dart';
import 'package:app/view/quick_access_screen.dart';
import 'package:app/view/trade_screen.dart';
import 'package:app/view/update_profile_screeen.dart';
import 'package:app/view/avatar_frame_painter.dart'; 
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/badge.dart';
import '../model/course.dart';
import '../model/user.dart';
import '../service/course_service.dart';
import '../utils/colors.dart';
import 'login_screen.dart';

import 'package:app/view/gamification/badge_stat.dart';
import 'package:app/view/gamification/course_stat.dart';
import 'package:app/view/gamification/rank_stat.dart';
import 'package:app/view/gamification/streak_stat.dart';
import 'package:app/view/gamification/total_points.dart';

class AvatarModel {
  final int id;
  final String imageUrl;
  final int price;
  AvatarModel({required this.id, required this.imageUrl, required this.price});
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  late SharedPreferences prefs;
  Student? user;
  bool isLoading = true;
  List<Student> list = [];
  int rank = 0;
  List<UserBadge>? userBadges = [];
  List<Course>? allCourses;
  int streakDays = 0;

  String userType = "Disruptors"; 
  String? currentFrameDesignId; 
  final String apiBaseUrl = "http://10.106.207.43:7000/api"; 
  final String serverIp = "10.106.207.43";

  List<AvatarModel> availableAvatars = [
    AvatarModel(id: 1, imageUrl: 'lib/assets/avatars/avatar1.jpeg', price: 0),
    AvatarModel(id: 2, imageUrl: 'lib/assets/avatars/avatar2.jpeg', price: 100),
    AvatarModel(id: 3, imageUrl: 'lib/assets/avatars/avatar3.jpeg', price: 100),
    AvatarModel(id: 4, imageUrl: 'lib/assets/avatars/avatar4.jpeg', price: 100),
    AvatarModel(id: 5, imageUrl: 'lib/assets/avatars/avatar5.jpeg', price: 200),
    AvatarModel(id: 6, imageUrl: 'lib/assets/avatars/avatar6.jpeg', price: 200),
    AvatarModel(id: 7, imageUrl: 'lib/assets/avatars/avatar7.jpeg', price: 250),
    AvatarModel(id: 8, imageUrl: 'lib/assets/avatars/avatar8.jpeg', price: 250),
    AvatarModel(id: 9, imageUrl: 'lib/assets/avatars/avatar9.jpeg', price: 300),
    AvatarModel(id: 10, imageUrl: 'lib/assets/avatars/avatar10.jpeg', price: 300),
    AvatarModel(id: 11, imageUrl: 'lib/assets/avatars/avatar11.jpeg', price: 350),
    AvatarModel(id: 12, imageUrl: 'lib/assets/avatars/avatar12.jpeg', price: 350),
  ];

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  // Helper untuk membersihkan URL
  String formatUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (url.startsWith('lib/assets/')) return url;
    if (url.contains('localhost')) return url.replaceAll('localhost', serverIp);
    if (!url.startsWith('http')) return 'http://$serverIp:7000$url';
    return url;
  }

  Future<void> getUserData() async {
    try {
      prefs = await SharedPreferences.getInstance();
      final idUser = prefs.getInt('userId');

      if (idUser != null) {
        Student fetchedUser = await UserService.getUserById(idUser);
        await fetchAdaptiveProfile(idUser);
        await fetchEquippedFrame(idUser); 

        final results = await Future.wait([
          BadgeService.getUserBadgeListByUserId(idUser),
          UserService.getAllUser(),
          CourseService.getEnrolledCourse(idUser),
        ]);

        if (mounted) {
          setState(() {
            user = fetchedUser;
            streakDays = fetchedUser.streak;
            
            if (results[0] is List<UserBadge>) {
              final List<UserBadge> allBadges = results[0] as List<UserBadge>;
              userBadges = allBadges.where((b) => !b.isPurchased).toList();
            }

            if (results[1] is List<Student>) {
              final List<Student> allUsers = results[1] as List<Student>;
              list = allUsers.where((u) => u.role == 'STUDENT').toList();
              list.sort((a, b) => (b.points ?? 0).compareTo(a.points ?? 0));
            }

            if (results[2] is List<Course>) {
              allCourses = results[2] as List<Course>;
            }

            for (int i = 0; i < list.length; i++) {
              if (list[i].id == user?.id) {
                rank = i + 1;
                break;
              }
            }
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error detail profile screen: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchEquippedFrame(int userId) async {
    try {
      final response = await http.get(Uri.parse("$apiBaseUrl/usertrade/equipped/$userId"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted && data != null && data['trade'] != null) {
          setState(() => currentFrameDesignId = data['trade']['image']?.toString());
        } else {
          setState(() => currentFrameDesignId = null);
        }
      }
    } catch (e) {
      debugPrint("Gagal fetch bingkai: $e");
    }
  }

  Future<void> fetchAdaptiveProfile(int idUser) async {
    final String url = "$apiBaseUrl/user/adaptive/$idUser";
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            userType = data['currentCluster'] ?? "Disruptors";
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal sinkron cluster di Profile: $e");
    }
  }

  void logout() async {
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (user == null) return const Scaffold(body: Center(child: Text("User data not found")));

    bool isDisruptor = userType == "Disruptors";
    bool isPlayer = userType == "Players";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalVar.primaryColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('lib/assets/pictures/background-pattern.png'),
                    fit: BoxFit.cover)),
          ),
          RefreshIndicator(
            onRefresh: getUserData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(isDisruptor, isPlayer),
                  const SizedBox(height: 10),
                  if (!isDisruptor && !isPlayer) _buildMyBadgesSection(),
                  _buildMenuSection(isDisruptor),
                  const SizedBox(height: 20),
                  _buildLogoutButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDisruptor, bool isPlayer) {
    Color labelColor = Colors.red; 
    if (userType == "Achievers") labelColor = Colors.blue;
    if (userType == "Players") labelColor = Colors.orange;
    if (userType == "Free Spirits") labelColor = Colors.teal;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: GlobalVar.primaryColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      padding: const EdgeInsets.only(bottom: 32, top: 20),
      child: Column(
        children: [
          _buildAvatarStack(), 
          const SizedBox(height: 15),
          Text(user?.name ?? "", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: labelColor, borderRadius: BorderRadius.circular(20)),
            child: Text(userType.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 25),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(25.0), border: Border.all(color: Colors.white.withOpacity(0.2))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!isDisruptor && !isPlayer) BadgeStat(count: userBadges?.length ?? 0),
                    CourseStat(count: allCourses?.length ?? 0),
                    RankStat(rank: rank, total: list.length),
                    if (userType != "Disruptors" && userType != "Free Spirits" && userType != "Achievers") StreakStat(days: streakDays),
                  ],
                ),
                if (!isDisruptor) ...[
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white24)),
                  TotalPoints(points: user?.points ?? 0),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    String? imgPath = user?.image;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: imgPath != null && imgPath.isNotEmpty
                ? (imgPath.startsWith('lib/assets/')
                    ? Image.asset(imgPath, fit: BoxFit.cover)
                    : Image.network(formatUrl(imgPath), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, size: 80, color: Colors.white)))
                : const Icon(Icons.person, size: 80, color: Colors.white),
          ),
        ),
        
        if (currentFrameDesignId != null && currentFrameDesignId!.isNotEmpty && currentFrameDesignId != "null")
          IgnorePointer(
            child: SizedBox(
              width: 140, 
              height: 140,
              child: CustomPaint(
                painter: AvatarFramePainter(currentFrameDesignId!),
              ),
            ),
          ),

        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateProfile(user: user!, availableAvatars: availableAvatars)));
              if (result == true) getUserData();
            },
            child: Container(
              width: 35, height: 35,
              decoration: BoxDecoration(shape: BoxShape.circle, color: GlobalVar.secondaryColor, border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(LineAwesomeIcons.pencil_alt_solid, color: Colors.white, size: 18),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildMyBadgesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 2, blurRadius: 10)]),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Badges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: GlobalVar.primaryColor, fontFamily: 'DIN_Next_Rounded')),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: userBadges != null && userBadges!.isNotEmpty
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: userBadges!.length,
                    itemBuilder: (context, index) {
                      final badge = userBadges![index].badge;
                      if (badge == null) return const SizedBox();
                      String fixUrl = formatUrl(badge.image?.replaceAll("badges//", "badges/"));
                      return GestureDetector(
                        onTap: () => _showBadgeDetails(context, badge),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: fixUrl.startsWith('lib/assets/') 
                                ? Image.asset(fixUrl, width: 60, height: 60)
                                : Image.network(fixUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Image.asset('lib/assets/pictures/icon.png', width: 60)),
                          ),
                        ),
                      );
                    },
                  )
                : const Center(child: Text('No badges earned yet', style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.grey))),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(bool isDisruptor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        children: [
          if (!isDisruptor) ProfileMenuWidget(title: "Trades", icon: LineAwesomeIcons.coins_solid, onPress: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TradeScreen(user: user!)))),
          ProfileMenuWidget(title: "Update Profile", icon: LineAwesomeIcons.person_booth_solid, onPress: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateProfile(user: user!, availableAvatars: availableAvatars)));
            if (result == true) getUserData();
          }),
          ProfileMenuWidget(title: "Quick Access", icon: LineAwesomeIcons.accessible_icon, onPress: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QuickAccessScreen()))),
          ProfileMenuWidget(title: "About App", icon: LineAwesomeIcons.info_circle_solid, onPress: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutAppScreen()))),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(onPressed: logout, style: ElevatedButton.styleFrom(backgroundColor: GlobalVar.primaryColor, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text("Log Out", style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white))),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, BadgeModel badge) async {
    try {
      Course resCourse = await CourseService.getCourse(badge.courseId);
      Chapter resChapter = await ChapterService.getChapterById(badge.chapterId);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(16), child: badge.image != null 
                  ? (badge.image!.startsWith('lib/assets/') ? Image.asset(badge.image!, height: 100) : Image.network(formatUrl(badge.image!), fit: BoxFit.cover, height: 100))
                  : Image.asset('lib/assets/pictures/icon.png', height: 100)),
              const SizedBox(height: 16),
              Text(badge.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded', color: AppColors.primaryColor, fontSize: 18)),
              Text('(${badge.type})', style: const TextStyle(fontFamily: 'DIN_Next_Rounded')),
              const SizedBox(height: 12),
              Text('Earned by completing ${resCourse.courseName} up to chapter ${resChapter.name}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'DIN_Next_Rounded', fontSize: 13)),
            ],
          ),
          actions: [SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor), onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Colors.white))))],
        ),
      );
    } catch (e) { debugPrint("Error show badge: $e"); }
  }
}

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({super.key, required this.title, required this.icon, required this.onPress, this.endIcon = true, this.textColor});
  final String title;
  final IconData icon;
  final VoidCallback onPress;
  final bool endIcon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPress,
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: AppColors.primaryColor.withOpacity(0.1)), child: Icon(icon, color: AppColors.primaryColor)),
      title: Text(title, style: TextStyle(color: textColor, fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.w600)),
      trailing: endIcon ? const Icon(LineAwesomeIcons.angle_right_solid, size: 18.0, color: Colors.grey) : null,
    );
  }
}