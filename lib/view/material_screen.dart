import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../model/chapter_status.dart';
import '../model/learning_material.dart';
import '../service/chapter_service.dart';
import '../service/user_chapter_service.dart';
import '../service/user_service.dart';
import '../service/activity_service.dart'; 
import '../utils/colors.dart';

class MaterialScreen extends StatefulWidget {
  final ChapterStatus status;
  final String chapterName;
  final Function(bool) updateProgress;
  final Function(ChapterStatus) updateStatus;
  
  const MaterialScreen({
    super.key,
    required this.status,
    required this.chapterName,
    required this.updateProgress,
    required this.updateStatus,
  });

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  LearningMaterial? material;
  late ScrollController _scrollController;
  double progressValue = 0.0;
  bool showDialogMaterialOnce = false;
  late ChapterStatus status;
  bool isLoading = true; // Flag Loading
  bool hasError = false; // Flag Error

  // LOG TRIGGER: FREE SPIRITS (Session Duration)
  final Stopwatch _timer = Stopwatch(); 

  @override
  void initState() {
    super.initState();
    status = widget.status;
    showDialogMaterialOnce = widget.status.materialDone;
    progressValue = widget.status.materialDone ? 1.0 : 0;
    
    _timer.start(); 
    _scrollController = ScrollController();
    _scrollController.addListener(updateProgressMaterial);

    getMaterial(widget.status.chapterId);
  }

  @override
  void dispose() {
    _timer.stop();
    
    // Kirim durasi membaca materi ke backend (Fitur Cluster Free Spirits)
    if (_timer.elapsed.inSeconds > 2) { // Hanya kirim jika durasi > 2 detik
        ActivityService.sendLog(
          userId: widget.status.userId, 
          type: 'SESSION_DURATION', 
          value: _timer.elapsed.inSeconds.toDouble(),
          metadata: {"chapterId": widget.status.chapterId}
        ).then((_) => debugPrint("Duration Log Sent")).catchError((e) => debugPrint("Log Error: $e"));
    }

    _scrollController.removeListener(updateProgressMaterial);
    _scrollController.dispose();
    super.dispose();
  }

  void getMaterial(int id) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // Panggil service dengan timeout
      final resultMaterial = await ChapterService.getMaterialByChapterId(id)
          .timeout(const Duration(seconds: 10));
      
      if (mounted) {
        setState(() {
          material = resultMaterial;
          isLoading = false;
          hasError = (resultMaterial == null);
        });
      }
    } catch (e) {
      debugPrint("Error fetching material: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    return Scaffold( // Gunakan Scaffold agar layout lebih stabil
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/pictures/background-pattern.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError || material == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Materi belum tersedia",
              style: TextStyle(fontSize: 16, color: AppColors.primaryColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => getMaterial(widget.status.chapterId),
              child: const Text("Coba Lagi"),
            )
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              widget.chapterName,
              style: const TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: AppColors.primaryColor,
                fontFamily: 'DIN_Next_Rounded'
              ),
            ),
            const Divider(thickness: 1.5),
            const SizedBox(height: 10),
            _buildHTMLContent(material!.content),
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  // LOGIC PROGRESS & DIALOG (Tetap sama dengan perbaikan pemanggilan)
  void updateProgressMaterial() {
    if (_scrollController.position.maxScrollExtent <= 0) return;
    double currentProgressValue = _scrollController.offset / _scrollController.position.maxScrollExtent;
    
    if (currentProgressValue >= 1.0 && !showDialogMaterialOnce) {
      setState(() {
        progressValue = 1.0;
        showDialogMaterialOnce = true;
      });
      _triggerMaterialChallenge();
      showCompletionDialog(context, "Yeay! Kamu berhasil menyelesaikan Materi. Ayo lanjutkan ke bagian Assessment.");
    }
  }

  void _triggerMaterialChallenge() async {
    try {
      status.materialDone = true;
      widget.updateProgress(true);
      widget.updateStatus(status);
      await UserChapterService.updateChapterStatus(status.id, status);
      await UserService.triggerChallengeManual(status.userId, 'COMPLETE_CHAPTER');
    } catch (e) {
      debugPrint("Error progress: $e");
    }
  }

  void showCompletionDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Progress Completed!", textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Sip!"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHTMLContent(String content) {
    return HtmlWidget(
      content,
      textStyle: const TextStyle(fontFamily: 'DIN_Next_Rounded', fontSize: 16, height: 1.5),
    );
  }
}