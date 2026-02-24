import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../model/assessment.dart';
import '../model/chapter_status.dart';
import '../model/user.dart';
import '../service/chapter_service.dart';
import '../service/user_chapter_service.dart';
import '../service/user_service.dart';
import '../service/activity_service.dart';
import '../utils/colors.dart';

class AssessmentScreen extends StatefulWidget {
  final ChapterStatus status;
  final Student user;
  final String userType;
  final Function(bool) updateMaterialLocked;
  final Function(ChapterStatus) updateStatus;
  final Function(bool) updateAssessmentStarted;
  final Function(bool) updateAssessmentFinished;

  const AssessmentScreen({
    super.key,
    required this.status,
    required this.user,
    required this.userType,
    required this.updateMaterialLocked,
    required this.updateStatus,
    required this.updateAssessmentStarted,
    required this.updateAssessmentFinished,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  bool _assessmentStarted = false;
  bool _assessmentFinished = false;
  bool assessmentDone = false;
  int correctAnswer = 0;
  int point = 0;
  Student? user;
  late ChapterStatus status;
  Assessment? question;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _calculateComplete = false;

  Timer? _timer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    status = widget.status;
    user = widget.user;
    assessmentDone = widget.status.assessmentDone;

    if (assessmentDone) {
      point = widget.status.assessmentGrade;
    }

    getAssessment(widget.status.chapterId);
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (question != null && question!.questions.isNotEmpty) {
      // Aturan waktu tetap berbeda untuk Disruptors (Game Element: Time Pressure)
      if (widget.userType == "Disruptors") {
        _secondsRemaining = (question!.questions[_currentPage].type == 'EY') ? 40 : 15;
      } else {
        _secondsRemaining = 999;
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        if (widget.userType == "Disruptors") {
          _handleTimeUp();
        }
      }
    });
  }

  void _handleTimeUp() {
    if (_currentPage < (question?.questions.length ?? 0) - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _executeSubmit();
    }
  }

  void _executeSubmit() {
    _timer?.cancel();
    _showQuizResults();
  }

  void getAssessment(int id) async {
    final resultAssessment = await ChapterService.getAssessmentByChapterId(id);
    
    // DEBUGGING: Cek apakah data teks soal dari Backend memang terpotong
    if (resultAssessment != null && resultAssessment.questions.isNotEmpty) {
      for (int i = 0; i < resultAssessment.questions.length; i++) {
        debugPrint(">>> [DEBUG API] Teks Soal ${i + 1}: ${resultAssessment.questions[i].question} <<<");
      }
    }

    if (mounted) {
      setState(() {
        question = resultAssessment;
        if (assessmentDone && status.assessmentAnswer.isNotEmpty) {
          for (int i = 0; i < question!.questions.length; i++) {
            if (i < status.assessmentAnswer.length) {
              question!.questions[i].selectedAnswer = status.assessmentAnswer[i];
            }
          }
        }
      });
    }
  }

  void _showFinishConfirmation() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kirim Jawaban?',
            style: TextStyle(fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.bold)),
        content: const Text('Anda tidak dapat mengubah jawaban setelah ini dikirim.'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startTimer();
              },
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(context);
              _executeSubmit();
            },
            child: const Text('Ya, Kirim', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQuizResults() async {
    if (_calculateComplete) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int tempCorrect = 0;
    double totalScoreCalculated = 0;
    double rangeScore = 100 / (question?.questions.length ?? 1);

    for (int index = 0; index < (question?.questions.length ?? 0); index++) {
      Question q = question!.questions[index];
      String userAns = q.selectedAnswer.toString().trim().toLowerCase();
      String correctAns = q.correctedAnswer.toString().trim().toLowerCase();

      if (userAns == correctAns) {
        tempCorrect++;
        totalScoreCalculated += rangeScore;
        question!.questions[index].isCorrect = true;
      }
    }

    int finalScore = totalScoreCalculated.round();
    if (finalScore > 100) finalScore = 100;

    try {
      ActivityService.sendLog(userId: user!.id, type: 'QUIZ_SCORE', value: finalScore.toDouble());

      user!.points = (user!.points ?? 0) + finalScore;
      status.assessmentDone = true;
      status.assessmentGrade = finalScore;
      status.assessmentAnswer = question!.questions.map((q) => q.selectedAnswer).toList();

      await Future.wait([
        UserService.updateUserPoints(user!),
        UserChapterService.updateChapterStatus(status.id, status),
      ]);

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          point = finalScore;
          correctAnswer = tempCorrect;
          _calculateComplete = true;
          _assessmentFinished = true;
        });
        widget.updateStatus(status);
        widget.updateAssessmentFinished(true);
        widget.updateAssessmentStarted(false);
        widget.updateMaterialLocked(false);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint(">>> ERROR SINKRONISASI: $e <<<");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status.assessmentDone || _assessmentFinished) {
      return _buildQuizResult();
    }

    if (!_assessmentStarted) {
      return _buildAssessmentInitial();
    }

    bool isDisruptor = widget.userType == "Disruptors";
    int totalQuestions = question?.questions.length ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('lib/assets/pictures/background-pattern.png'),
                fit: BoxFit.cover)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                        minHeight: 10,
                        value: (_currentPage + 1) / (totalQuestions > 0 ? totalQuestions : 1),
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor)),
                  ),
                  const SizedBox(height: 12),
                  if (isDisruptor)
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(LineAwesomeIcons.clock,
                          color: _secondsRemaining < 10 ? Colors.red : Colors.black54,
                          size: 24),
                      const SizedBox(width: 8),
                      Text("$_secondsRemaining DETIK",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _secondsRemaining < 10 ? Colors.red : Colors.black87)),
                    ]),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalQuestions,
                onPageChanged: (int page) {
                  if (mounted) setState(() => _currentPage = page);
                  _startTimer();
                },
                itemBuilder: (context, count) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: _buildSingleQuestion(count)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 10, 30, 50),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      elevation: 4,
                      shadowColor: AppColors.primaryColor.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  onPressed: () => _currentPage < totalQuestions - 1
                      ? _pageController.nextPage(
                          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                      : _showFinishConfirmation(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage < totalQuestions - 1
                            ? 'LANJUT KE SOAL ${_currentPage + 2}'
                            : 'KIRIM JAWABAN SEKARANG',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DIN_Next_Rounded'),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        _currentPage < totalQuestions - 1
                            ? LineAwesomeIcons.arrow_right_solid
                            : LineAwesomeIcons.check_circle,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentInitial() {
    bool isDisruptor = widget.userType == "Disruptors";
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset('lib/assets/pixels/assessment-pixel.png', height: 100),
          const SizedBox(height: 24),
          const Text('Siap Memulai?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
          const SizedBox(height: 12),
          Text(
              isDisruptor
                  ? "Waktu Anda sangat terbatas!"
                  : "Uji pemahaman Anda untuk membuka chapter berikutnya.",
              textAlign: TextAlign.center,
              style: TextStyle(color: isDisruptor ? Colors.red : Colors.black87, fontWeight: isDisruptor ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              onPressed: () {
                setState(() => _assessmentStarted = true);
                _startTimer();
              },
              icon: const Icon(LineAwesomeIcons.rocket_solid, color: Colors.white),
              label: const Text('MULAI SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSingleQuestion(int number) {
    final q = question!.questions[number];
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
          child: Text(
            "Soal ${number + 1}:\n${q.question}",
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.5),
            softWrap: true, // PERBAIKAN: Memastikan teks otomatis turun baris
            overflow: TextOverflow.visible, // PERBAIKAN: Memastikan teks tidak disembunyikan
          ),
        ),
        const SizedBox(height: 25),
        if (q.type == 'EY')
          TextField(
            maxLines: 5,
            decoration: InputDecoration(
                hintText: "Ketik jawaban di sini...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
            onChanged: (val) => q.selectedAnswer = val,
          )
        else
          ...q.option.map((answer) {
            bool isSelected = q.selectedAnswer == answer;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryColor.withOpacity(0.05) : Colors.white,
                  border: Border.all(color: isSelected ? AppColors.primaryColor : Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(15)),
              child: RadioListTile<String>(
                title: Text(answer, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                value: answer,
                groupValue: q.selectedAnswer,
                activeColor: AppColors.primaryColor,
                onChanged: (val) {
                  if (mounted) setState(() => q.selectedAnswer = val!);
                },
              ),
            );
          }).toList()
      ]),
    );
  }

  Widget _buildQuizResult() {
    return SingleChildScrollView(
      child: Column(children: [
        const SizedBox(height: 60),
        const Icon(LineAwesomeIcons.trophy_solid, size: 80, color: Colors.amber),
        const SizedBox(height: 20),
        const Text("Assessment Selesai!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Card(
          margin: const EdgeInsets.all(25),
          color: AppColors.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(children: [
              const Text("SKOR ANDA", style: TextStyle(color: Colors.white70, fontSize: 16)),
              Text("${status.assessmentGrade}", style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              Text("Benar: $correctAnswer / ${question?.questions.length ?? 0}", style: const TextStyle(color: Colors.white, fontSize: 18)),
            ]),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text("Review jawaban Anda di bawah ini:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        if (question != null)
          ...List.generate(question!.questions.length, (i) => _buildReviewCard(i)),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _buildReviewCard(int number) {
    final q = question!.questions[number];
    final bool isCorrect = q.selectedAnswer.toString().trim().toLowerCase() == q.correctedAnswer.toString().trim().toLowerCase();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isCorrect ? Colors.green : Colors.red, width: 2)),
      child: ListTile(
        leading: Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red),
        title: Text(q.question, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Jawaban Anda: ${q.selectedAnswer}", style: TextStyle(color: isCorrect ? Colors.green.shade700 : Colors.red.shade700)),
              if (!isCorrect)
                Text("Kunci Jawaban: ${q.correctedAnswer}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}