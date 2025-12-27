import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  bool tapped = false;
  int correctAnswer = 0;
  int point = 0;
  Assessment? question;
  bool isCalculating = true;

  @override
  void initState() {
    super.initState();
    getAssessment(widget.status.chapterId);
  }

  void getAssessment(int id) async {
    try {
      final resultAssessment = await ChapterService.getAssessmentByChapterId(id);
      if (mounted) {
        setState(() {
          question = resultAssessment;
        });
      }
    } catch (e) {
      debugPrint("Error fetching assessment: $e");
      if (mounted) setState(() => isCalculating = false);
    }
  }

  Future<double> checkEssay(String reference, String answer) async {
    try {
      // Menambahkan timeout agar tidak nunggu terlalu lama jika server lambat
      double similarity = await ChapterService.checkSimiliarity(reference, answer)
          .timeout(const Duration(seconds: 5));
      return similarity;
    } catch (e) {
      debugPrint("Essay check error: $e");
      return 0.0;
    }
  }

  Future<bool> _calculateResults() async {
    if (question == null || widget.status.assessmentAnswer == null) return false;

    tapped = true;
    int tempCorrect = 0;
    double rangeScore = 100 / (question!.questions.length > 0 ? question!.questions.length : 1);

    // Loop untuk memetakan jawaban lama ke model pertanyaan
    for (int i = 0; i < widget.status.assessmentAnswer.length; i++) {
      if (i >= question!.questions.length) break;

      var q = question!.questions[i];
      q.selectedAnswer = widget.status.assessmentAnswer[i];

      if (q.type != 'EY') {
        // Pilihan Ganda / True False
        bool isNowCorrect = q.selectedAnswer.trim().toLowerCase() ==
            q.correctedAnswer.trim().toLowerCase();

        q.isCorrect = isNowCorrect;
        if (isNowCorrect) {
          q.score = rangeScore.ceil();
          tempCorrect++;
        }
      } else {
        // Essay - Membutuhkan pengecekan similarity ulang untuk review
        double similarity = await checkEssay(q.correctedAnswer, q.selectedAnswer);
        
        q.isCorrect = similarity > 0.5;
        if (q.isCorrect) {
          q.score = (rangeScore * similarity).ceil();
          tempCorrect++;
        }
      }
    }

    if (mounted) {
      setState(() {
        correctAnswer = tempCorrect;
        point = widget.status.assessmentGrade; // Ambil dari status yang sudah tersimpan
        isCalculating = false;
      });
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (question == null) {
      return _loadingState("Memuat Pertanyaan...");
    }

    return FutureBuilder<bool>(
      future: _calculateResults(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingState("Menghitung Hasil...");
        } else if (snapshot.hasError || snapshot.data == false) {
          return _emptyState("Gagal memproses data assessment.");
        } else {
          return _buildMainContent();
        }
      },
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/pictures/background-pattern.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          _buildHeaderCard(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: question!.questions.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _buildQuestionReview(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        color: AppColors.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Review Assessment',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'DIN_Next_Rounded'),
              ),
              const Divider(color: Colors.white54),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _headerStat("Benar", "$correctAnswer / ${question!.questions.length}"),
                  _headerStat("Skor Akhir", "$point / 100"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuestionReview(int index) {
    final q = question!.questions[index];
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: q.isCorrect ? Colors.green.shade400 : Colors.red.shade400,
            width: 1.5),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: q.isCorrect ? Colors.green : Colors.red,
          child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(
          q.question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text("Skor: ${q.score}", 
          style: TextStyle(color: q.isCorrect ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _reviewRow("Jawaban Anda:", q.selectedAnswer, q.isCorrect ? Colors.black : Colors.red),
                const SizedBox(height: 4),
                _reviewRow("Kunci Jawaban:", q.correctedAnswer, Colors.green),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value.isEmpty ? "(Kosong)" : value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _loadingState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(fontFamily: 'DIN_Next_Rounded')),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Text(msg, style: const TextStyle(color: Colors.grey)),
    );
  }
}