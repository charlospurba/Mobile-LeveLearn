import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../model/chapter_status.dart';
import '../model/learning_material.dart';
import '../service/chapter_service.dart';
import '../service/user_chapter_service.dart';
import '../service/user_service.dart';
import '../service/activity_service.dart'; // IMPORT BARU
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

  // LOG TRIGGER: FREE SPIRITS (Session Duration)
  final Stopwatch _timer = Stopwatch(); 

  @override
  void initState() {
    status = widget.status;
    showDialogMaterialOnce = widget.status.materialDone;
    progressValue = widget.status.materialDone ? 1.0 : 0;
    
    _timer.start(); // Mulai menghitung durasi belajar

    getMaterial(widget.status.chapterId);
    
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(updateProgressMaterial);
  }

  @override
  void dispose() {
    _timer.stop();
    
    // LOG TRIGGER: Kirim durasi membaca materi ke backend dalam satuan detik
    ActivityService.sendLog(
      userId: widget.status.userId, 
      type: 'SESSION_DURATION', 
      value: _timer.elapsed.inSeconds.toDouble(),
      metadata: {"chapterId": widget.status.chapterId}
    );

    _scrollController.removeListener(updateProgressMaterial);
    _scrollController.dispose();
    super.dispose();
  }

  void getMaterial(int id) async {
    final resultMaterial = await ChapterService.getMaterialByChapterId(id);
    if (mounted) {
      setState(() {
        material = resultMaterial;
      });
    }
  }

  void updateProgressMaterial() {
    if (_scrollController.position.maxScrollExtent <= 0) return;

    double currentProgressValue = _scrollController.offset / _scrollController.position.maxScrollExtent;

    if (currentProgressValue < 0.0) {
      currentProgressValue = 0.0;
    } else if (currentProgressValue > 1.0) {
      currentProgressValue = 1.0;
    }

    if (currentProgressValue >= 1.0 && !showDialogMaterialOnce) {
      setState(() {
        progressValue = 1.0;
        showDialogMaterialOnce = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCompletionDialog(context, "Yeay! Kamu berhasil menyelesaikan Materi. Ayo lanjutkan ke bagian Assessment.", false, false);
      });

      _triggerMaterialChallenge();
    } else {
      setState(() {
        progressValue = currentProgressValue <= progressValue ? progressValue : currentProgressValue;
      });
    }
  }

  void _triggerMaterialChallenge() async {
    try {
      status.materialDone = true;
      widget.updateProgress(true);
      widget.updateStatus(status);

      await UserChapterService.updateChapterStatus(status.id, status);
      await UserService.triggerChallengeManual(status.userId, 'COMPLETE_CHAPTER');
      
      debugPrint(">>> Sinyal Challenge Materi Dikirim! <<<");
    } catch (e) {
      debugPrint("Error triggering material challenge: $e");
    }
  }

  void showCompletionDialog(BuildContext context, String message, bool isAssessment, bool isAssignment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Progress Completed!",
            style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: AppColors.primaryColor, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('lib/assets/pixels/check.png', height: 72),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontFamily: 'DIN_Next_Rounded'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (material != null)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/pictures/background-pattern.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildHTMLContent(material!.content),
                    const SizedBox(height: 50), 
                  ],
                ),
              ),
            ),
          )
        else
          _buildEmptyOrLoadingState(),
      ],
    );
  }

  Widget _buildEmptyOrLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/pictures/background-pattern.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: material == null 
          ? const CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('lib/assets/pixels/material-pixel.png', height: 50),
                const SizedBox(height: 16),
                const Text(
                  "Materi belum tersedia",
                  style: TextStyle(fontSize: 16, color: AppColors.primaryColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildHTMLContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: HtmlWidget(
        content,
        textStyle: const TextStyle(fontFamily: 'DIN_Next_Rounded', fontSize: 16),
      ),
    );
  }
}