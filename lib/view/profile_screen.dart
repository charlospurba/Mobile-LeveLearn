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
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/badge.dart';
import '../model/course.dart';
import '../model/user.dart';
import '../service/course_service.dart';
import '../utils/colors.dart';
import 'login_screen.dart';

// IMPORT KOMPONEN GAMIFIKASI MODULAR
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
  Course? course;
  Chapter? chapter;
  List<Course>? allCourses;
  int streakDays = 0;

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
    getUserData();
    super.initState();
  }

  Future<void> getUserData() async {
    prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('userId');

    if (idUser != null) {
      Student fetchedUser = await UserService.getUserById(idUser);
      if (mounted) {
        setState(() {
          user = fetchedUser;
          streakDays = fetchedUser.streak;
        });
      }
      getUserBadges(idUser);
      getAllUser();
      getEnrolledCourse(idUser);
    }
  }

  Future<void> getAllUser() async {
    final result = await UserService.getAllUser();
    if (mounted) {
      setState(() {
        list = result.where((u) => u.role == 'STUDENT').toList();
        list.sort((a, b) => (b.points ?? 0).compareTo(a.points ?? 0));
      });
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == user?.id) {
          setState(() => rank = i + 1);
          break;
        }
      }
    }
  }

  Future<void> getEnrolledCourse(int userId) async {
    final result = await CourseService.getEnrolledCourse(userId);
    if (mounted) setState(() => allCourses = result);
  }

  Future<void> getUserBadges(int userId) async {
    final result = await BadgeService.getUserBadgeListByUserId(userId);
    if (mounted) {
      setState(() {
        // FILTER: Kunci utama agar sinkron dengan Avatar
        userBadges = result.where((b) => !b.isPurchased).toList();
        isLoading = false;
      });
    }
  }

  void logout() async {
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : Scaffold(
            appBar: AppBar(
              backgroundColor: GlobalVar.primaryColor,
              automaticallyImplyLeading: false,
              elevation: 0,
              title: const Text("Profile",
                  style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
            ),
            body: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage('lib/assets/pictures/background-pattern.png'),
                          fit: BoxFit.cover)),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 10),
                      _buildMyBadgesSection(),
                      _buildMenuSection(),
                      const SizedBox(height: 20),
                      _buildLogoutButton(),
                      const SizedBox(height: 30),
                    ],
                  ),
                )
              ],
            ));
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      color: GlobalVar.primaryColor,
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          _buildAvatarStack(),
          const SizedBox(height: 10),
          Text(user?.name ?? "",
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold,
                  fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
          Text(user?.studentId ?? "",
              style: const TextStyle(fontFamily: 'DIN_Next_Rounded', color: GlobalVar.accentColor)),
          const SizedBox(height: 25),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withAlpha(25), 
              borderRadius: BorderRadius.circular(25.0),
              border: Border.all(color: Colors.white.withAlpha(50)),
            ),
            child: Column(
              children: [
                DefaultTextStyle(
                  style: const TextStyle(color: Colors.white, fontFamily: 'DIN_Next_Rounded'),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      iconTheme: const IconThemeData(color: Colors.white),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Statistik Badge mengambil dari list yang sudah difilter
                        BadgeStat(count: userBadges?.length ?? 0),
                        CourseStat(count: allCourses?.length ?? 0),
                        RankStat(rank: rank, total: list.length),
                        StreakStat(days: streakDays),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white24),
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: const TextTheme(
                      bodyMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  ),
                  child: TotalPoints(points: user?.points ?? 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    return Stack(
      children: [
        SizedBox(
          width: 120, height: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: user?.image != null && user?.image != ""
                ? (user!.image!.startsWith('lib/assets/')
                    ? Image.asset(user!.image!, fit: BoxFit.cover)
                    : Image.network(user!.image!, fit: BoxFit.cover, 
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.person, size: 100, color: Colors.white)))
                : const Icon(Icons.person, size: 100, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdateProfile(user: user!, availableAvatars: availableAvatars)),
              );
              if (result == true) getUserData();
            },
            child: Container(
              width: 35, height: 35,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: GlobalVar.secondaryColor),
              child: const Icon(LineAwesomeIcons.pencil_alt_solid, color: Colors.white, size: 20),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildMyBadgesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withAlpha(50), spreadRadius: 2, blurRadius: 5)],
      ),
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
                    itemCount: userBadges?.length,
                    itemBuilder: (context, index) {
                      final badge = userBadges![index].badge;
                      if (badge == null) return const SizedBox();
                      
                      // PERBAIKAN: Bersihkan URL double slash agar gambar tidak error
                      String fixUrl = badge.image ?? "";
                      if (fixUrl.contains("badges//")) {
                        fixUrl = fixUrl.replaceAll("badges//", "badges/");
                      }

                      return GestureDetector(
                        onTap: () => _showBadgeDetails(context, badge),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: fixUrl != ''
                                ? Image.network(
                                    fixUrl, 
                                    width: 60, height: 60, fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Image.asset('lib/assets/pictures/icon.png', width: 60, height: 60),
                                  )
                                : Image.asset('lib/assets/pictures/icon.png', width: 60, height: 60, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  )
                : const Center(child: Text('No badges earned yet', style: TextStyle(fontFamily: 'DIN_Next_Rounded'))),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          ProfileMenuWidget(title: "Trades", icon: LineAwesomeIcons.coins_solid, onPress: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TradeScreen(user: user!)))),
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
        child: ElevatedButton(
            onPressed: logout,
            style: ElevatedButton.styleFrom(backgroundColor: GlobalVar.primaryColor, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 15)),
            child: const Text("Log Out", style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white))),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, BadgeModel badge) async {
    Course resCourse = await CourseService.getCourse(badge.courseId);
    Chapter resChapter = await ChapterService.getChapterById(badge.chapterId);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: badge.image != null ? Image.network(badge.image!, fit: BoxFit.cover) : Image.asset('lib/assets/pictures/icon.png'),
            ),
            const SizedBox(height: 16),
            Text(badge.name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded', color: AppColors.primaryColor, fontSize: 18)),
            Text('(${badge.type})', style: const TextStyle(fontFamily: 'DIN_Next_Rounded')),
            const SizedBox(height: 8),
            Text('Earned by completing ${resCourse.courseName} up to chapter ${resChapter.name}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'DIN_Next_Rounded')),
          ],
        ),
        actions: [
          SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor), onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Colors.white)))),
        ],
      ),
    );
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
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: AppColors.primaryColor.withAlpha(25)),
        child: Icon(icon, color: AppColors.primaryColor),
      ),
      title: Text(title, style: TextStyle(color: textColor, fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.w600)),
      trailing: endIcon ? const Icon(LineAwesomeIcons.angle_right_solid, size: 18.0, color: Colors.grey) : null,
    );
  }
}