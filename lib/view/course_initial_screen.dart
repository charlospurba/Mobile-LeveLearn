import 'package:app/service/badge_service.dart';
import 'package:app/service/user_service.dart'; // Tambahkan import
import 'package:app/utils/colors.dart';
import 'package:app/view/course_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/badge.dart';
import '../model/chapter.dart';
import '../model/course.dart';
import '../service/course_service.dart';

class CourseInitialScreen extends StatefulWidget {
  final int id;
  const CourseInitialScreen({super.key, required this.id});

  @override
  State<CourseInitialScreen> createState() => _CourseInitialScreenState();
}

class _CourseInitialScreenState extends State<CourseInitialScreen> {
  Course? courseDetail;
  int progress = 0;
  List<Chapter> listChapter = [];
  List<BadgeModel>? listBadge;
  int idUser = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInitialData();
  }

  void _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    idUser = prefs.getInt('userId') ?? 0;
    
    getCourseDetail();
    getBadges();
    getChapters();
  }

  void getCourseDetail() async {
    final result = await CourseService.getCourse(widget.id);
    if (mounted) setState(() => courseDetail = result);
  }

  void getBadges() async {
    final result = await BadgeService.getBadgeListCourseByCourseId(widget.id);
    if (mounted) setState(() => listBadge = result);
  }

  void getChapters() async {
    final result = await CourseService.getChapterByCourse(widget.id);
    if (mounted) setState(() => listChapter = result);
  }

  @override
  Widget build(BuildContext context) {
    if (courseDetail == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/pictures/background-pattern.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(child: Text('Mohon Tunggu...', style: TextStyle(fontFamily: 'DIN_Next_Rounded'))),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Course Overview"),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LineAwesomeIcons.angle_left_solid, color: Colors.white)),
        titleTextStyle: const TextStyle(fontFamily: 'DIN_Next_Rounded', fontSize: 24, color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Image.asset('lib/assets/pictures/imk-picture.jpg', width: double.infinity, height: 250, fit: BoxFit.cover),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(courseDetail!.courseName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded', color: AppColors.primaryColor)),
                      const SizedBox(height: 16),
                      const Text('Deskripsi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'DIN_Next_Rounded', color: AppColors.primaryColor)),
                      const SizedBox(height: 8),
                      Text(courseDetail!.description ?? "Tidak ada deskripsi", style: const TextStyle(fontFamily: 'DIN_Next_Rounded')),
                      const SizedBox(height: 16),
                      _buildBadgeRow(),
                      const SizedBox(height: 16),
                      const Text('Daftar Chapter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'DIN_Next_Rounded', color: AppColors.primaryColor)),
                      _buildChapterList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                )
              ],
            ),
          ),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildBadgeRow() {
    if (listBadge == null || listBadge!.isEmpty) return const SizedBox();
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: listBadge!.take(3).map((b) => Column(
            children: [
              Image.network(b.image!, width: 50, height: 50, errorBuilder: (c, e, s) => const Icon(Icons.badge)),
              Text(b.type, style: const TextStyle(fontSize: 10, fontFamily: 'DIN_Next_Rounded')),
            ],
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildChapterList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listChapter.length,
      itemBuilder: (context, index) => Card(
        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: Text('${index + 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
          title: Text(listChapter[index].name, style: const TextStyle(fontFamily: 'DIN_Next_Rounded')),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, minimumSize: const Size(double.infinity, 50)),
          onPressed: () {
            // AKURAT: Trigger tantangan START_COURSE
            UserService.triggerChallengeManual(idUser, 'START_COURSE');
            
            Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(id: widget.id)));
          },
          child: const Text('Kerjakan Course', style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white)),
        ),
      ),
    );
  }
}