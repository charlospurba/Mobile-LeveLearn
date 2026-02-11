import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/global_var.dart';
import 'package:app/model/chapter_status.dart';
import 'package:app/model/user_course.dart';
import 'package:app/utils/colors.dart';
import 'package:app/view/already_finished_assessment.dart';
import 'package:app/view/assessment_screen.dart';
import 'package:app/view/assignment_screen.dart';
import 'package:app/view/material_screen.dart';
import 'package:flutter/material.dart';

import '../model/user.dart';
import 'custom_tab_indicator.dart';

class Chapterscreen extends StatefulWidget {
  final ChapterStatus status;
  final int chapterIndexInList;
  final UserCourse uc;
  final int chLength;
  final Student user;
  final String chapterName;
  final int idBadge;
  final int level;
  
  // FIX: Menambahkan parameter updateProgress agar bisa dipanggil dari CourseDetail
  final Function(bool) updateProgress;

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
    // FIX: Menambahkan ke constructor
    required this.updateProgress,
  });

  @override
  State<Chapterscreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<Chapterscreen> with TickerProviderStateMixin {
  Student? user;
  late TabController _tabController;
  int _currentIndex = 0;
  final List<Widget?> _screens = [null, null, null];
  late ChapterStatus status;
  bool materialComplete = false;
  bool _materialLocked = false;
  bool _assessmentStarted = false;
  bool _assessmentFinished = false;
  String userType = "Disruptors";

  @override
  void initState() {
    materialComplete = widget.status.materialDone;
    status = widget.status;
    user = widget.user;
    super.initState();
    _fetchUserCluster();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _fetchUserCluster() async {
    final String url = "${GlobalVar.baseUrl}/api/user/adaptive/${widget.user.id}";
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => userType = data['currentCluster'] ?? "Disruptors");
      }
    } catch (e) {
      debugPrint("Gagal sinkron cluster di Chapter: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fungsi internal untuk mengupdate UI lokal di dalam tab
  void _localUpdateProgress(bool value) {
    setState(() {
      materialComplete = true;
      _screens[1] = null; // Reset tab Assessment agar build ulang
    });
    
    // Meneruskan ke fungsi progres global (CourseDetail)
    widget.updateProgress(value);
  }

  void updateStatus(ChapterStatus value) {
    setState(() {
      status = value;
    });
  }

  void updateMaterialLocked(bool value) {
    setState(() => _materialLocked = value);
  }

  void updateAssessmentStarted(bool value) {
    setState(() => _assessmentStarted = value);
  }

  void updateAssessmentFinished(bool value) {
    setState(() {
      _assessmentFinished = value;
      _screens[2] = null; // Reset tab Assignment agar build ulang
    });
  }

  Widget _buildPage(int index) {
    if (_screens[index] == null) {
      switch (index) {
        case 0:
          _screens[index] = _materialLocked
              ? _lockedMaterialContent()
              : MaterialScreen(
                  status: widget.status, 
                  chapterName: widget.chapterName, 
                  updateProgress: _localUpdateProgress, 
                  updateStatus: updateStatus,
                );
          break;
        case 1:
          _screens[index] = materialComplete
              ? widget.status.assessmentDone
                  ? AlreadyFinishedAssessmentAssessmentScreen(status: widget.status, user: widget.user)
                  : AssessmentScreen(
                      status: widget.status, 
                      user: widget.user, 
                      userType: userType, 
                      updateMaterialLocked: updateMaterialLocked, 
                      updateStatus: updateStatus, 
                      updateAssessmentFinished: updateAssessmentFinished, 
                      updateAssessmentStarted: updateAssessmentStarted,
                    )
              : _lockedContent();
          break;
        case 2:
          _screens[index] = (widget.status.assessmentDone || _assessmentFinished)
              ? AssignmentScreen(
                  status: status, 
                  user: widget.user, 
                  uc: widget.uc, 
                  level: widget.level, 
                  chLength: widget.chLength, 
                  idBadge: widget.idBadge, 
                  // Meneruskan fungsi update ke Assignment agar saat tugas dikirim, gembok terbuka
                  updateProgress: widget.updateProgress, 
                  updateStatus: updateStatus,
                )
              : _lockedAssignmentContent();
          break;
      }
    }
    return _screens[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_assessmentStarted || _assessmentFinished,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, {'status': status.toJson(), 'index': widget.chapterIndexInList});
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true, // Diubah menjadi true agar ada tombol back manual
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: AppColors.primaryColor,
          title: Text(widget.chapterName, style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'DIN_Next_Rounded')),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Material(
              color: Colors.white,
              child: IgnorePointer(
                ignoring: _assessmentStarted && !_assessmentFinished,
                child: TabBar(
                  controller: _tabController,
                  indicator: CustomTabIndicator(color: AppColors.primaryColor),
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: Colors.grey.shade400,
                  onTap: (index) {
                    setState(() => _currentIndex = index);
                  },
                  tabs: const [Tab(text: 'Material'), Tab(text: 'Assessment'), Tab(text: 'Assignment')],
                ),
              ),
            ),
            Expanded(child: _buildPage(_currentIndex)),
          ],
        ),
      ),
    );
  }

  Widget _lockedContent() => const Center(child: Text("Assessment Terkunci! Selesaikan Material terlebih dahulu."));
  Widget _lockedMaterialContent() => const Center(child: Text("Material Terkunci karena hukuman!"));
  Widget _lockedAssignmentContent() => const Center(child: Text("Assignment Terkunci! Selesaikan Assessment terlebih dahulu."));
}