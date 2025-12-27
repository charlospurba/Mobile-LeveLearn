import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../model/chapter_status.dart';
import '../model/learning_material.dart';
import '../service/chapter_service.dart';
import '../service/user_chapter_service.dart';
import '../service/user_service.dart';
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

  @override
  void initState() {
    status = widget.status;
    showDialogMaterialOnce = widget.status.materialDone;
    progressValue = widget.status.materialDone ? 1.0 : 0;
    
    getMaterial(widget.status.chapterId);
    
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(updateProgressMaterial);
  }

  @override
  void dispose() {
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

  // Fungsi untuk memantau scroll user
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

      // Menampilkan dialog sukses
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCompletionDialog(context, "Yeay! Kamu berhasil menyelesaikan Materi. Ayo lanjutkan ke bagian Assessment.", false, false);
      });

      // TRIGGER SINKRONISASI KE BACKEND
      _triggerMaterialChallenge();
    } else {
      setState(() {
        progressValue = currentProgressValue <= progressValue ? progressValue : currentProgressValue;
      });
    }
  }

  // FUNGSI KRUSIAL: Menghubungkan aksi scroll ke sistem Challenge
  void _triggerMaterialChallenge() async {
    try {
      // 1. Update status lokal
      status.materialDone = true;
      
      // 2. Beritahu Parent ChapterScreen agar UI Assessment terbuka
      widget.updateProgress(true);
      widget.updateStatus(status);

      // 3. Simpan status material ke tabel user_chapters
      await UserChapterService.updateChapterStatus(status.id, status);

      // 4. TRIGGER CHALLENGE: Beritahu backend untuk menambah progres 'COMPLETE_CHAPTER'
      // Ini akan menambah progres tantangan seperti "Baca 1 Materi" (ID 101) atau "Selesaikan 2 Materi" (ID 105)
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
                    const SizedBox(height: 50), // Ruang ekstra di bawah agar scroll bisa mentok
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