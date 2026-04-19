import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:app/global_var.dart';
import 'package:app/model/chapter.dart';
import 'package:app/service/badge_service.dart';
import 'package:app/service/course_service.dart';
import 'package:app/service/user_chapter_service.dart';
import 'package:app/service/user_course_service.dart';
import 'package:app/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/badge.dart';
import '../model/course.dart';
import '../model/user.dart';
import '../model/user_course.dart';
import '../utils/colors.dart';
import 'chapter_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final int id;
  const CourseDetailScreen({super.key, required this.id});

  @override
  State<CourseDetailScreen> createState() => _CourseDetail();
}

class _CourseDetail extends State<CourseDetailScreen> {
  Course? courseDetail;
  List<Chapter> listChapter = [];
  late SharedPreferences pref;
  int idCourse = 0;
  int idUser = 0;
  bool isLoading = true;
  UserCourse? uc;
  Student? user;
  List<BadgeModel>? listBadge;
  String userType = "Disruptors";

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    try {
      pref = await SharedPreferences.getInstance();
      idCourse = widget.id != 0 ? widget.id : (pref.getInt('lastestSelectedCourse') ?? 0);
      idUser = pref.getInt('userId') ?? 0;

      if (idUser != 0) {
        final fetchedUser = await UserService.getUserById(idUser);
        user = fetchedUser;
        
        await fetchAdaptiveProfile(idUser);

        if (idCourse != 0) {
          final results = await Future.wait([
            CourseService.getCourse(idCourse),
            UserCourseService.getUserCourse(idUser, idCourse),
            BadgeService.getBadgeListCourseByCourseId(idCourse),
            CourseService.getChapterByCourse(idCourse),
          ]);

          courseDetail = results[0] as Course?;
          uc = results[1] as UserCourse?;
          listBadge = results[2] as List<BadgeModel>?;
          
          final chapters = results[3] as List<Chapter>;
          listChapter = await getStatusChapter(chapters);
        }
      }
    } catch (e) {
      debugPrint("Error loading course details: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchAdaptiveProfile(int id) async {
    final String url = "${GlobalVar.baseUrl}/api/user/adaptive/$id";
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            userType = data['currentCluster'] ?? "Disruptors";
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal sinkron cluster: $e");
    }
  }

  Future<List<Chapter>> getStatusChapter(List<Chapter> list) async {
    await Future.wait(list.map((chapter) async {
      chapter.status = await UserChapterService.getChapterStatus(idUser, chapter.id);
    }));
    list.sort((a, b) => a.level.compareTo(b.level));
    return list;
  }

  Future<void> updateStatus(int index) async {
    if (listChapter[index].status == null) return;
    final result = await UserChapterService.updateChapterStatus(
        listChapter[index].status!.id, listChapter[index].status!);
    if (mounted) {
      setState(() {
        listChapter[index].status = result;
      });
    }
  }

  int idOfBadge(int chapterId) {
    if (listBadge == null || listBadge!.isEmpty) return 0;
    try {
      final badge = listBadge!.firstWhere((i) => i.chapterId == chapterId);
      return badge.id;
    } catch (_) { 
      return 0; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: _initialLoad,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("lib/assets/learnbg.png"),
                  fit: BoxFit.cover,
                  opacity: 0.1,
                ),
              ),
            ),
            CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                isLoading
                    ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                    : _buildChapterList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      backgroundColor: const Color(0xFF441F7F),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset("lib/assets/gamification.jpeg", fit: BoxFit.cover),
            Container(color: const Color(0xFF441F7F).withOpacity(0.6)),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text('COURSE PROGRESS',
                      style: TextStyle(fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white, letterSpacing: 1.2)),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(courseDetail?.courseName ?? "Loading...",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'DIN_Next_Rounded', fontSize: 14, color: Colors.white70),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      title: Image.asset("lib/assets/LeveLearn.png", width: 150),
    );
  }

  Widget _buildChapterList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, count) => _buildAnimatedChapterItem(count),
          childCount: listChapter.length,
        ),
      ),
    );
  }

  Widget _buildAnimatedChapterItem(int count) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (count * 50)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          if (count < listChapter.length - 1)
            Positioned(
              left: 0, right: 0, bottom: -50, top: 80,
              child: Center(
                child: Container(
                  width: 4,
                  color: const Color(0xFFD1C4E9),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _decideChapterItem(count),
          ),
        ],
      ),
    );
  }

  Widget _decideChapterItem(int index) {
    if (uc == null) return const SizedBox();
    
    // RULES PROFILE: Achievers, Players, & Free Spirits (Bebas Akses)
    bool isAlwaysUnlocked = (userType == "Players" || userType == "Achievers" || userType == "Free Spirits");
    bool isUnlockedByProgress = index <= uc!.currentChapter - 1;

    if (isAlwaysUnlocked || isUnlockedByProgress) {
      return _buildCourseItem(index);
    } else {
      return _buildCourseItemLocked(index, "Latih kompetensimu di level sebelumnya!");
    }
  }

  Widget _buildCourseItem(int index) {
    final chapter = listChapter[index];
    final isCurrent = uc != null && index == uc!.currentChapter - 1;

    // LOGIKA PERBAIKAN JUDUL: Hanya Achievers & Players yang ada teks "Level X"
    String displayedTitle = chapter.name;
    if (userType == "Achievers" || userType == "Players") {
      displayedTitle = "Level ${chapter.level}: ${chapter.name}";
    }

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF4A148C).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () async {
                  await updateStatus(index);
                  if (!mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Chapterscreen(
                        status: chapter.status!,
                        chapterIndexInList: index,
                        uc: uc!,
                        chLength: listChapter.length,
                        user: user!,
                        chapterName: displayedTitle, // Kirim judul sesuai aturan
                        idBadge: idOfBadge(chapter.id), 
                        level: chapter.level,
                        updateProgress: (val) async => await _initialLoad(),
                      ),
                    ),
                  );
                  if (mounted) _initialLoad();
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(colors: [Color(0xFF5E2B99), Color(0xFF441F7F)]),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatusIcon(chapter.status?.materialDone ?? false, Icons.menu_book),
                            const SizedBox(width: 15),
                            _buildStatusIcon(chapter.status?.assessmentDone ?? false, Icons.task_alt),
                            const SizedBox(width: 15),
                            _buildStatusIcon(chapter.status?.assignmentDone ?? false, Icons.assignment),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayedTitle, 
                          textAlign: TextAlign.center, 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 18, 
                            color: Colors.white, 
                            fontFamily: 'DIN_Next_Rounded'
                          )
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 0, child: _buildLevelCircle(chapter.level, isCurrent)),
          if (isCurrent) Positioned(right: -10, bottom: 10, child: Image.asset('lib/assets/rocket.png', width: 45, height: 45)),
        ],
      ),
    );
  }

  Widget _buildCourseItemLocked(int index, String message) {
    final chapter = listChapter[index];
    
    // Untuk item terkunci (pasti Free Spirits atau Disruptors), jangan pakai teks "Level"
    String displayedTitle = chapter.name;

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24), 
              color: const Color(0xFFF3F4F6), 
              border: Border.all(color: Colors.grey.shade300)
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              child: Column(
                children: [
                  Text(
                    displayedTitle, 
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      fontSize: 16, 
                      color: Colors.grey.shade500, 
                      fontWeight: FontWeight.bold, 
                      fontFamily: 'DIN_Next_Rounded'
                    )
                  ),
                  const SizedBox(height: 10),
                  Icon(Icons.lock_rounded, size: 30, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
          Positioned(top: -30, left: 0, right: 0, child: Center(child: _buildLevelCircle(chapter.level, false))),
        ],
      ),
    );
  }

  Widget _buildLevelCircle(int level, bool isCurrent) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: isCurrent ? [const Color(0xFF00E676), const Color(0xFF00C853)] : [Colors.grey.shade400, Colors.grey.shade600]),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(child: Text("$level", style: const TextStyle(fontFamily: 'Modak', fontSize: 24, color: Colors.white))),
    );
  }

  Widget _buildStatusIcon(bool isDone, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: isDone ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: isDone ? const Color(0xFFFFD700) : Colors.white24),
    );
  }
}