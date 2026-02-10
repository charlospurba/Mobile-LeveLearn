import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../model/assessment.dart';
import '../model/chapter_status.dart';
import '../model/user.dart';
import '../service/chapter_service.dart';
import '../utils/colors.dart';

class AlreadyFinishedAssessmentAssessmentScreen extends StatefulWidget {
  final ChapterStatus status;
  final Student user;

  const AlreadyFinishedAssessmentAssessmentScreen({
    super.key,
    required this.status,
    required this.user,
  });

  @override
  State<AlreadyFinishedAssessmentAssessmentScreen> createState() =>
      _AlreadyFinishedAssessmentAssessmentScreenState();
}

class _AlreadyFinishedAssessmentAssessmentScreenState
    extends State<AlreadyFinishedAssessmentAssessmentScreen> {
  Assessment? question;
  bool isLoading = true;
  int correctAnswerCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAndPrepareData();
  }

  Future<void> _loadAndPrepareData() async {
    try {
      final result = await ChapterService.getAssessmentByChapterId(widget.status.chapterId);
      if (mounted && result != null) {
        int tempCorrect = 0;
        for (int i = 0; i < result.questions.length; i++) {
          if (i < widget.status.assessmentAnswer.length) {
            String userAns = widget.status.assessmentAnswer[i];
            result.questions[i].selectedAnswer = userAns;
            if (userAns.trim().toLowerCase() == result.questions[i].correctedAnswer.trim().toLowerCase()) {
              result.questions[i].isCorrect = true;
              tempCorrect++;
            } else {
              result.questions[i].isCorrect = false;
            }
          }
        }
        setState(() {
          question = result;
          correctAnswerCount = tempCorrect;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // 1. Background Pattern Dasar
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset('lib/assets/pictures/background-pattern.png', fit: BoxFit.cover),
            ),
          ),
          
          // 2. Konten Utama (Header & List Soal)
          Column(
            children: [
              _buildStickyHeader(),
              Expanded(
                child: ListView.builder(
                  // Padding bawah 140 agar soal terakhir tidak tertutup panel tombol
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 140), 
                  itemCount: question?.questions.length ?? 0,
                  itemBuilder: (context, index) => _buildHistoryCard(index),
                ),
              ),
            ],
          ),

          // 3. EFEK GRADIENT FADE (Batas halus agar soal "menghilang" saat di-scroll ke bawah)
          Positioned(
            bottom: 110, // Posisi tepat di atas panel putih
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF8F9FE).withOpacity(0.0),
                    const Color(0xFFF8F9FE).withOpacity(1.0),
                  ],
                ),
              ),
            ),
          ),

          // 4. PANEL TOMBOL BAWAH (Floating Panel dengan Border)
          _buildFloatingBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          const Text("HASIL ASSESSMENT", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1.5, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("${widget.status.assessmentGrade}", 
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: AppColors.primaryColor, fontFamily: 'Modak')),
              const Text(" / 100", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black26)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
            child: Text("Benar $correctAnswerCount dari ${question?.questions.length} Soal",
                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(int index) {
    final q = question!.questions[index];
    final bool isCorrect = q.isCorrect ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCorrect ? Colors.green.shade100 : Colors.red.shade100, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorrect ? LineAwesomeIcons.check_circle : LineAwesomeIcons.times_circle,
              color: isCorrect ? Colors.green : Colors.red, size: 24,
            ),
          ),
          title: Text("Soal ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text(q.question, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 20),
                  Text(q.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 15),
                  _buildAnswerBox("Jawaban Anda", q.selectedAnswer, isCorrect ? Colors.green : Colors.red),
                  if (!isCorrect) ...[
                    const SizedBox(height: 10),
                    _buildAnswerBox("Jawaban Benar", q.correctedAnswer, Colors.green),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerBox(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value.isEmpty ? "-" : value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(25, 15, 25, 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)), // Garis pemisah tegas
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryColor, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  backgroundColor: AppColors.primaryColor.withOpacity(0.02),
                ),
                onPressed: () => Navigator.pop(context),
                icon: Icon(LineAwesomeIcons.arrow_left_solid, color: AppColors.primaryColor, size: 18),
                label: Text("KEMBALI KE MATERI", 
                  style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}