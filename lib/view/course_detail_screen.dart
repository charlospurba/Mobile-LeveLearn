import 'dart:async';
import 'dart:convert'; // Untuk jsonDecode
import 'package:http/http.dart' as http; // Untuk pemanggilan API

import 'package:app/global_var.dart';
import 'package:app/model/chapter.dart';
import 'package:app/model/chapter_status.dart';
import 'package:app/service/badge_service.dart';
import 'package:app/service/course_service.dart';
import 'package:app/service/user_chapter_service.dart';
import 'package:app/service/user_course_service.dart';
import 'package:app/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
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

  // Variabel pendukung Rules Profile
  String userType = "Disruptors";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initialLoad();
  }

  // ALUR SINKRONISASI: Menjamin data cluster didapat sebelum merender chapter
  Future<void> _initialLoad() async {
    pref = await SharedPreferences.getInstance();
    idCourse = pref.getInt('lastestSelectedCourse') ?? 0;
    idUser = pref.getInt('userId') ?? 0;

    if (idUser != 0) {
      // 1. Ambil data User & Cluster terlebih dahulu
      await getUser(idUser);
      
      // 2. Ambil detail Course & Metadata lainnya
      if (idCourse != 0) {
        courseDetail = await CourseService.getCourse(idCourse);
        uc = await UserCourseService.getUserCourse(idUser, idCourse);
        await getListBadge(idCourse);
        
        // 3. Ambil chapter
        await getChapter(idCourse);
      }
    }
  }

  Future<void> updateStatus(index) async {
    final result = await UserChapterService.updateChapterStatus(
        listChapter[index].status!.id, listChapter[index].status!);
    setState(() {
      listChapter[index].status = result;
    });
  }

  Future<void> getUser(int id) async {
    final fetchedUser = await UserService.getUserById(id);
    if (fetchedUser != null) {
      if (mounted) setState(() => user = fetchedUser);
      // Tunggu hingga sinkronisasi cluster selesai
      await fetchAdaptiveProfile(id);
    }
  }

  Future<void> fetchAdaptiveProfile(int id) async {
    // Gunakan IP laptop aktif Anda: 10.106.207.43
    final String url = "http://10.106.207.43:7000/api/user/adaptive/$id";
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            userType = data['currentCluster'] ?? "Disruptors";
          });
          debugPrint("SYNC SUCCESS: Profile is $userType");
          
          // Force reload chapters untuk memastikan logika open/lock terbaru diterapkan
          if (idCourse != 0) getChapter(idCourse);
        }
      }
    } catch (e) {
      debugPrint("Gagal sinkron cluster: $e");
    }
  }

  Future<void> getChapter(int id) async {
    if (mounted) setState(() => isLoading = true);

    final result = await CourseService.getChapterByCourse(id);
    final updatedList = await getStatusChapter(result);

    if (mounted) {
      setState(() {
        listChapter = updatedList;
        isLoading = false;
      });
    }
  }

  Future<void> getListBadge(int courseId) async {
    listBadge = await BadgeService.getBadgeListCourseByCourseId(courseId);
  }

  Future<List<Chapter>> getStatusChapter(List<Chapter> list) async {
    await Future.forEach(list, (Chapter chapter) async {
      chapter.status =
          await UserChapterService.getChapterStatus(idUser, chapter.id);
    });
    return list;
  }

  void updateUserCourse() async {
    if (uc != null) {
      await UserCourseService.updateUserCourse(uc!.id, uc!);
    }
  }

  int idOfBadge(int isCheckpoint) {
    int idbadge = 0;
    if (listBadge == null) return 0;
    switch (isCheckpoint) {
      case 1:
        for (BadgeModel i in listBadge!) {
          if (i.type == 'BEGINNER') idbadge = i.id;
        }
        break;
      case 2:
        for (BadgeModel i in listBadge!) {
          if (i.type == 'INTERMEDIATE') idbadge = i.id;
        }
        break;
      case 3:
        for (BadgeModel i in listBadge!) {
          if (i.type == 'ADVANCE') idbadge = i.id;
        }
        break;
      default:
        idbadge = 0;
    }
    return idbadge;
  }

  @override
  Widget build(BuildContext context) {
    return _buildDetailCourse();
  }

  Widget _buildDetailCourse() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
                image: AssetImage("lib/assets/learnbg.png"),
                fit: BoxFit.cover,
                opacity: 0.15),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0, height: 120,
          child: Container(
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF441F7F), Color(0xFF3A206C)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 10, left: 20,
                    child: Image.asset(
                      "lib/assets/LeveLearn.png",
                      width: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Course Level',
                            style: TextStyle(
                                fontFamily: 'DIN_Next_Rounded',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                                letterSpacing: 1.2),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              courseDetail?.courseName ?? "Loading...",
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DIN_Next_Rounded',
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        idCourse != 0 && courseDetail != null
            ? Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 0,
                  automaticallyImplyLeading: false,
                ),
                body: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 130, bottom: 40, left: 20, right: 20),
                        itemCount: listChapter.length,
                        itemBuilder: (context, count) {
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 500 + (count * 150)),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 100 * (1 - value)),
                                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                              );
                            },
                            child: Stack(
                              alignment: Alignment.topCenter,
                              clipBehavior: Clip.none,
                              children: [
                                if (count < listChapter.length - 1)
                                  Positioned(
                                    left: 0, right: 0, bottom: -50, top: 80,
                                    child: Center(
                                      child: Container(
                                        width: 6,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1C4E9),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
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
                        },
                      ),
              )
            : const SizedBox(),
      ],
    );
  }

  Widget _decideChapterItem(int index) {
    if (uc == null) return const SizedBox();

    // --- WHITELIST UNTUK FREE SPIRITS, PLAYERS, & ACHIEVERS: TERBUKA TOTAL ---
    // Profil Achievers kini disamakan dengan Players & Free Spirits (Akses terbuka semua)
    if (userType == "Free Spirits" || userType == "Players" || userType == "Achievers") {
      return _buildCourseItem(index);
    }

    // --- LOGIKA UNTUK PROFIL LAIN (DISRUPTORS) ---
    
    // 1. Cek progres level normal berdasarkan urutan database (berlaku untuk Disruptors)
    bool isUnlockedByLevel = index <= uc!.currentChapter - 1;

    // 2. Logika Block Activity (HANYA UNTUK DISRUPTORS)
    bool isStrictlyBlocked = false;
    String blockMessage = "Selesaikan level sebelumnya!";

    if (userType == "Disruptors") {
      if (index > 0) {
        final prevChapterStatus = listChapter[index - 1].status;
        if (prevChapterStatus != null) {
          // Disruptors dikunci jika materi ATAU kuis level sebelumnya belum 100% tuntas
          if (!prevChapterStatus.materialDone || !prevChapterStatus.assessmentDone) {
            isStrictlyBlocked = true;
            blockMessage = "LEVEL TERKUNCI: Selesaikan Materi & Kuis level ${index}!";
          }
        }
      }
    }

    // Tampilkan gembok jika: Level belum sampai (progres normal) ATAU diblokir secara kaku (khusus Disruptor)
    if (!isUnlockedByLevel || isStrictlyBlocked) {
      return _buildCourseItemLocked(index, blockMessage);
    } else {
      return _buildCourseItem(index);
    }
  }

  Widget _buildCourseItem(int index) {
    final chapter = listChapter[index];
    final isCurrent = uc != null && index == uc!.currentChapter - 1;

    // --- LOGIKA JUDUL KHUSUS PLAYERS & ACHIEVERS ---
    // Jika profil Players atau Achievers, tambahkan prefix "Level X - " sebelum nama chapter guna memenuhi kebutuhan visual progres
    String displayTitle = (userType == "Players" || userType == "Achievers") 
        ? "Level ${chapter.level} - ${chapter.name}" 
        : chapter.name;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A148C).withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () async {
                  if (uc != null) {
                    uc!.currentChapter = uc!.currentChapter < chapter.level
                        ? chapter.level
                        : uc!.currentChapter;
                    updateUserCourse();
                  }
                  if (chapter.status != null && !chapter.status!.isStarted) {
                    chapter.status!.timeStarted = DateTime.now();
                    chapter.status!.isStarted = true;
                  }
                  updateStatus(index);

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Chapterscreen(
                        status: chapter.status!,
                        chapterIndexInList: index,
                        uc: uc!,
                        chLength: listChapter.length,
                        user: user!,
                        chapterName: listChapter[index].name,
                        idBadge: idOfBadge(listChapter[index].isCheckpoint),
                        level: listChapter[index].level,
                      ),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      listChapter[result['index']].status =
                          ChapterStatus.fromJson(result['status']);
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5E2B99), Color(0xFF441F7F)],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatusIcon(chapter.status?.materialDone ?? false, Icons.menu_book, "Materi"),
                            const SizedBox(width: 15),
                            _buildStatusIcon(chapter.status?.assessmentDone ?? false, Icons.task_alt, "Kuis"),
                            const SizedBox(width: 15),
                            _buildStatusIcon(chapter.status?.assignmentDone ?? false, Icons.assignment, "Tugas"),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayTitle, // Menggunakan displayTitle (Format Khusus Players & Achievers)
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, fontFamily: 'DIN_Next_Rounded'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCurrent ? [const Color(0xFF00E676), const Color(0xFF00C853)] : [Colors.grey.shade400, Colors.grey.shade600],
                ),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: Text("${chapter.level}", style: const TextStyle(fontFamily: 'Modak', fontSize: 24, color: Colors.white)),
              ),
            ),
          ),
          if (isCurrent)
            Positioned(
              right: 0, bottom: 10,
              child: Image.asset('lib/assets/rocket.png', width: 60, height: 60),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseItemLocked(int index, String message) {
    final chapter = listChapter[index];
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
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              child: Column(
                children: [
                  Icon(Icons.lock_rounded, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  // Teks berwarna MERAH jika aturan kaku Disruptors aktif
                  Text(message, 
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      fontSize: 14, 
                      color: userType == "Disruptors" && message.contains("LEVEL TERKUNCI") ? Colors.red : Colors.grey, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
            ),
          ),
          Positioned(top: -40, left: 0, right: 0, child: Center(child: _buildLevelBadge(chapter.level, false))),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(int level, bool unlocked) {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: unlocked ? [const Color(0xFF4ADE80), const Color(0xFF16A34A)] : [Colors.grey.shade400, Colors.grey.shade600],
        ),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(child: Text('$level', style: const TextStyle(fontSize: 32, color: Colors.white, fontFamily: 'Modak'))),
    );
  }

  Widget _buildStatusIcon(bool isDone, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDone ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: isDone ? const Color(0xFFFFD700) : Colors.white38),
    );
  }
}