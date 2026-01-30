import 'package:app/global_var.dart';
import 'package:app/model/chapter.dart';
import 'package:app/main.dart';
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
  State<CourseDetailScreen> createState()  => _CourseDetail();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getCourseDetail();
    getUserFromSharedPreference();
  }

  Future<void> updateStatus(index) async {
    final result = await UserChapterService.updateChapterStatus(listChapter[index].status!.id, listChapter[index].status!);
    setState(() {
      listChapter[index].status = result;
    });
  }

  void getUser(int id) async {
    user = await UserService.getUserById(id);
  }

  void getCourseDetail() async {
    pref = await SharedPreferences.getInstance();
    setState(() {
      idCourse = pref.getInt('lastestSelectedCourse') ?? 0;
    });
    final idUser = pref.getInt('userId');
    if(idUser != null) {
      getUser(idUser);
    }
    if(idCourse != 0){
      final result = await CourseService.getCourse(idCourse);
      setState(() {
        courseDetail = result;
      });
      getChapter(idCourse);
      await getListBadge(idCourse);
    }
  }

  void getUserCourse() async {
    uc = await UserCourseService.getUserCourse(idUser, idCourse);
  }

  void updateUserCourse() async {
    await UserCourseService.updateUserCourse(uc!.id, uc!);
  }

  void getChapter(int id) async {
    setState(() {
      isLoading = true; // Start loading
    });

    final result = await CourseService.getChapterByCourse(id);
    final updatedList = await getStatusChapter(result);

    setState(() {
      listChapter = updatedList;
      isLoading = false; // Stop loading
    });
  }

  Future<void> getListBadge(int courseId) async {
    listBadge = await BadgeService.getBadgeListCourseByCourseId(courseId);
  }

  Future<List<Chapter>> getStatusChapter(List<Chapter> list) async {
    await Future.forEach(list, (Chapter chapter) async {
      chapter.status = await UserChapterService.getChapterStatus(idUser, chapter.id);
    });
    return list;
  }

  void getUserFromSharedPreference() async{
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getInt('userId') ?? 0;
    });
    if (idUser != 0 && idCourse != 0) {
      getUserCourse();
    }
  }

  int idOfBadge(int isCheckpoint) {
    int idbadge = 0;
    switch(isCheckpoint) {
      case 1 : {
        for(BadgeModel i in listBadge!) {
          if(i.type == 'BEGINNER') {
            idbadge = i.id;
          }
        }
      }
      case 2 : {
        for(BadgeModel i in listBadge!) {
          if(i.type == 'INTERMEDIATE') {
            idbadge = i.id;
          }
        }
      }
      case 3 : {
        for(BadgeModel i in listBadge!) {
          if(i.type == 'ADVANCE') {
            idbadge = i.id;
          }
        }
      }
      default : idbadge = 0;
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
        // Global Background
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
                image: AssetImage("lib/assets/learnbg.png"),
                fit: BoxFit.cover,
                opacity: 0.15 
            ),
          ),
        ),
        
        // 1. Consistent Compact Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120, // Compact height
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF441F7F), // Primary Purple (from friends_screen)
                  Color(0xFF3A206C), // Darker Purple (from friends_screen background)
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                )
              ]
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                   // Logo - Top Left (Large)
                  Positioned(
                    top: 10,
                    left: 20,
                    child: Image.asset(
                      "lib/assets/LeveLearn.png",
                      width: 150, // Significantly Larger
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Center Title
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Level',
                            style: TextStyle(
                              fontFamily: 'DIN_Next_Rounded', 
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2) 
                                )
                              ]
                            ),
                          ),
                          // Keep Course Name visible as requested
                          Container(
                            margin: EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              courseDetail?.courseName ?? "Loading...",
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
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

        // 2. Scrollable Content
        idCourse != 0 && courseDetail != null
        ? Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 0, // Hide default AppBar, we use custom header
            automaticallyImplyLeading: false, 
          ),
          body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 130, bottom: 40, left: 20, right: 20), // Start after compact header
              itemCount: listChapter.length,
              itemBuilder: (context, count) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 500 + (count * 150)),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 100 * (1 - value)),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                       // Connector Line
                       if (count < listChapter.length - 1)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: -50,
                            top: 80,
                            child: Center(
                              child: Container(
                                width: 6,
                                decoration: BoxDecoration(
                                  color: Color(0xFFD1C4E9),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: count <= uc!.currentChapter - 1 
                          ? _buildCourseItem(count) 
                          : _buildCourseItemLocked(count),
                      ),
                    ],
                  ),
                );
              },
            ),
        )
        : SizedBox(), // Empty state handled by default
      ],
    );
  }

  Widget _buildCourseItem(int index) {
    final chapter = listChapter[index];
    final isCurrent = index == uc!.currentChapter - 1;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Main Card
          Container(
            margin: EdgeInsets.only(top: 30), // Space for badge
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF4A148C).withOpacity(0.25),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () async {
                  uc?.currentChapter = uc!.currentChapter < chapter.level ? chapter.level : uc!.currentChapter;
                  updateUserCourse();
                  if (!chapter.status!.isStarted){
                    chapter.status?.timeStarted = DateTime.now();
                    chapter.status?.isStarted = true;
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
                      listChapter[result['index']].status = ChapterStatus.fromJson(result['status']);
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF5E2B99), // Slightly lighter than header for cards
                        Color(0xFF441F7F), // Matches Header Primary
                      ],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5)
                  ),
                  child: Stack(
                    children: [
                       // Star Decoration (Background)
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: Opacity(
                          opacity: 0.1,
                          child: Image.asset(
                            'lib/assets/pixels/star.png',
                            width: 180,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatusIcon(chapter.status!.materialDone, Icons.menu_book, "Materi"),
                                SizedBox(width: 15),
                                _buildStatusIcon(chapter.status!.assessmentDone, Icons.task_alt, "Kuis"),
                                SizedBox(width: 15),
                                _buildStatusIcon(chapter.status!.assignmentDone, Icons.assignment, "Tugas"),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              chapter.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                                fontFamily: 'DIN_Next_Rounded',
                                height: 1.3
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20)
                              ),
                              child: Text(
                                chapter.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.9),
                                  fontFamily: 'DIN_Next_Rounded'
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Badge Number Floating centered
           Positioned(
            top: 0,
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 1000),
              tween: Tween<double>(begin: 1.0, end: isCurrent ? 1.1 : 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isCurrent 
                          ? [Color(0xFF00E676), Color(0xFF00C853)] 
                          : [Colors.grey.shade400, Colors.grey.shade600],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isCurrent ? Color(0xFF00E676).withOpacity(0.4) : Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 0,
                          spreadRadius: 3
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "${chapter.level}",
                        style: TextStyle(
                          fontFamily: 'Modak',
                          fontSize: 28,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black26,
                              offset: Offset(1, 2)
                            )
                          ]
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Rocket for Active Level
          if (isCurrent)
            Positioned(
              right: 0,
              bottom: 10,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                tween: Tween<double>(begin: 0, end: 10),
                curve: Curves.easeInOutSine,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value > 5 ? 10 - value : value), // Smooth hover
                    child: child,
                  );
                },
                onEnd: () {},
                child: Image.asset(
                  'lib/assets/rocket.png',
                  width: 60,
                  height: 60,
                ),
              ),
            ),

          // Medals for Checkpoints
          if (listChapter[index].isCheckpoint > 0)
          Positioned(
            top: 40, // Increased top to clear rounded corners and be visibly inside
            right: 16, // Adjusted right
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LineAwesomeIcons.medal_solid,
                size: 32,
                color: chapter.status!.materialDone && chapter.status!.assessmentDone && chapter.status!.assignmentDone
                ? (listChapter[index].isCheckpoint == 1 ? Colors.tealAccent 
                    : listChapter[index].isCheckpoint == 2 ? Colors.blueAccent : Colors.amberAccent)
                : Colors.white24
              ),
            )
          ),

          // Floating Level Badge (Animated if current)
          Positioned(
            top: -40, 
            left: 0,
            right: 0,
            child: Center(
              child: isCurrent 
              ? TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 2),
                  tween: Tween<double>(begin: 0.9, end: 1.1),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: _buildLevelBadge(chapter.level, true),
                    );
                  },
                  onEnd: () {
                    // This creates a crude loop since onEnd isn't easily looped in stateless simplified builder
                    // Ideally use AnimationController, but for simple fix this works or just static
                  },
                )
              : _buildLevelBadge(chapter.level, true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(int level, bool unlocked) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: unlocked 
            ? [Color(0xFF4ADE80), Color(0xFF16A34A)] // Bright Green Gradient
            : [Colors.grey.shade400, Colors.grey.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: unlocked ? Colors.green.withOpacity(0.4) : Colors.black.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            fontSize: 36,
            color: Colors.white,
            fontFamily: 'Modak',
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 2,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseItemLocked(int index) {
    final chapter = listChapter[index];

    return Padding(
      padding: index == listChapter.length - 1 ? EdgeInsets.only(top: 40, bottom: 16) : EdgeInsets.only(top: 40),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: Colors.transparent, // Use Container for styling
              child: Container(
                 decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Color(0xFFF3F4F6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, size: 40, color: Colors.grey.shade400),
                      SizedBox(height: 12),
                      Text(
                        "Selesaikan level sebelumnya!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14, 
                          color: Colors.grey.shade500, 
                          fontFamily: 'DIN_Next_Rounded',
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Level Badge (Grayed out)
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            child: Center(
              child: _buildLevelBadge(chapter.level, false),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Status Icons
  Widget _buildStatusIcon(bool isDone, IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDone ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDone ? Color(0xFFFFD700) : Colors.white38, // Gold if done, faint white if not
          ),
        ),
      ],
    );
  }
}