import 'dart:async';
import 'package:app/model/assignment.dart';
import 'package:app/model/chapter_status.dart';
import 'package:app/model/learning_material.dart';
import 'package:app/model/user_course.dart';
import 'package:app/service/chapter_service.dart';
import 'package:app/service/user_chapter_service.dart';
import 'package:app/service/user_service.dart';
import 'package:app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../model/assessment.dart';
import '../model/user.dart';
import 'already_finished_assessment.dart';

class Chapterscreen extends StatefulWidget {
  final ChapterStatus status;
  final int chapterIndexInList;
  final UserCourse uc;
  final int chLength;
  final Student user;
  final String chapterName;
  final int idBadge;
  final int level;

  const Chapterscreen({
    super.key,
    required this.status,
    required this.chapterIndexInList,
    required this.uc,
    required this.chLength,
    required this.user,
    required this.chapterName,
    this.idBadge = 0,
    required this.level,
  });

  @override
  State<Chapterscreen> createState() => _ChapterScreen();
}

class _ChapterScreen extends State<Chapterscreen> with TickerProviderStateMixin {
  Assessment? question;
  Assignment? assignment;
  LearningMaterial? material;
  late final TabController _tabController;
  late ScrollController _scrollController;
  late ChapterStatus status;
  Student? user;
  
  double progressValue = 0.0;
  bool assessmentDone = false;
  int correctAnswer = 0;
  int point = 0;
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _assessmentStarted = false;

  @override
  void initState() {
    status = widget.status;
    user = widget.user;
    assessmentDone = widget.status.assessmentDone;
    progressValue = widget.status.materialDone ? 1.0 : 0;
    
    _fetchInitialData();
    
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _fetchInitialData() async {
    material = await ChapterService.getMaterialByChapterId(widget.status.chapterId);
    question = await ChapterService.getAssessmentByChapterId(widget.status.chapterId);
    assignment = await ChapterService.getAssignmentByChapterId(widget.status.chapterId);
    if (mounted) setState(() {});
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !status.materialDone) {
      setState(() {
        progressValue = 1.0;
        status.materialDone = true;
      });
      UserChapterService.updateChapterStatus(status.id, status);
    }
  }

  // --- FUNGSI KONFIRMASI (YANG TADI ERROR) ---
  void _showFinishConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Finish Assessment?", style: TextStyle(fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.bold)),
        content: const Text("Ensure all questions are answered. You cannot retake this test."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            onPressed: () {
              Navigator.pop(context);
              _processSubmit();
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- PROSES SUBMIT PARALEL & FAST TIMEOUT ---
  Future<void> _processSubmit() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int total = 0;
    int correctCount = 0;
    double rangeScore = 100 / (question?.questions.length ?? 1);
    List<Future<void>> essayTasks = [];

    for (var q in question!.questions) {
      String userAns = q.selectedAnswer.trim().toLowerCase();
      String keyAns = q.correctedAnswer.trim().toLowerCase();

      if (q.type != 'EY') {
        if (userAns == keyAns) {
          q.score = rangeScore.ceil();
          total += q.score;
          q.isCorrect = true;
          correctCount++;
        }
      } else {
        essayTasks.add(
          ChapterService.checkSimiliarity(q.correctedAnswer, q.selectedAnswer)
              .timeout(const Duration(seconds: 2))
              .then((sim) {
            if (sim > 0.5) {
              q.score = (rangeScore * sim).ceil();
              total += q.score;
              q.isCorrect = true;
              correctCount++;
            }
          }).catchError((e) => debugPrint("Essay check failed: $e")),
        );
      }
    }

    if (essayTasks.isNotEmpty) await Future.wait(essayTasks);

    setState(() {
      correctAnswer = correctCount;
      point = total > 100 ? 100 : total;
      user!.points = (user!.points ?? 0) + point;
      status.assessmentDone = true;
      status.assessmentGrade = point;
      status.assessmentAnswer = question!.questions.map((q) => q.selectedAnswer).toList();
    });

    try {
      await Future.wait([
        UserService.updateUserPoints(user!),
        UserChapterService.updateChapterStatus(status.id, status),
      ]);
      UserService.updateUser(user!).catchError((e) => debugPrint("Challenge error: $e"));
      
      if (mounted) {
        Navigator.pop(context); // Tutup loading
        setState(() => assessmentDone = true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Gagal sinkron data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapterName, style: const TextStyle(fontFamily: 'DIN_Next_Rounded')),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryColor,
            indicatorColor: AppColors.primaryColor,
            tabs: const [Tab(text: "Material"), Tab(text: "Assessment"), Tab(text: "Assignment")],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMaterialTab(),
                _buildAssessmentTab(),
                const Center(child: Text("Assignment Section")),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMaterialTab() {
    if (material == null) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: HtmlWidget(material!.content, textStyle: const TextStyle(fontFamily: 'DIN_Next_Rounded')),
    );
  }

  Widget _buildAssessmentTab() {
    if (assessmentDone) {
      return AlreadyFinishedAssessmentAssessmentScreen(status: status, user: user!);
    }
    if (!_assessmentStarted) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(LineAwesomeIcons.play_solid, color: Colors.white),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
          onPressed: () => setState(() => _assessmentStarted = true),
          label: const Text("Start Assessment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: question?.questions.length ?? 0,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final q = question!.questions[index];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Question ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryColor)),
                    const SizedBox(height: 10),
                    Text(q.question, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    if (q.type == 'EY')
                      TextField(
                        maxLines: 4,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Type your answer here..."),
                        onChanged: (v) => q.selectedAnswer = v,
                      )
                    else
                      ...q.option.map((opt) => RadioListTile(
                        title: Text(opt),
                        value: opt,
                        activeColor: AppColors.primaryColor,
                        groupValue: q.selectedAnswer,
                        onChanged: (v) => setState(() => q.selectedAnswer = v!),
                      )),
                  ],
                ),
              );
            },
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            ElevatedButton(
              onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease), 
              child: const Text("Back")
            ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            onPressed: () {
              if (_currentPage < (question?.questions.length ?? 1) - 1) {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
              } else {
                _showFinishConfirmation();
              }
            },
            child: Text(
              _currentPage < (question?.questions.length ?? 1) - 1 ? "Next" : "Finish", 
              style: const TextStyle(color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }
}