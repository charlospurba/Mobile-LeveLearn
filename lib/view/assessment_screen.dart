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
import '../service/activity_service.dart'; // IMPORT BARU
import '../utils/colors.dart';

class AssessmentScreen extends StatefulWidget {
  final ChapterStatus status;
  final Student user;
  final Function(bool) updateMaterialLocked;
  final Function(ChapterStatus) updateStatus;
  final Function(bool) updateAssessmentStarted;
  final Function(bool) updateAssessmentFinished;

  const AssessmentScreen({
    super.key,
    required this.status,
    required this.user,
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
      _secondsRemaining = (question!.questions[_currentPage].type == 'EY') ? 60 : 30;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _handleTimeUp();
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
        title: const Text('Selesaikan Assessment?',
            style: TextStyle(fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.bold)),
        content: const Text(
            'Setelah dikirim, Anda tidak dapat mengubah jawaban atau mengulang kuis ini.'),
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
            child: const Text('Kirim', style: TextStyle(color: Colors.white)),
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
      // LOG TRIGGER: ACHIEVERS (Quiz Score)
      ActivityService.sendLog(
        userId: user!.id, 
        type: 'QUIZ_SCORE', 
        value: finalScore.toDouble()
      );

      // LOG TRIGGER: DISRUPTORS (Anomaly Patterns - Selesai sangat cepat skor sempurna)
      if (_secondsRemaining > 25 && finalScore == 100) {
        ActivityService.sendLog(
          userId: user!.id, 
          type: 'ANOMALY_PATTERNS', 
          value: 1.0,
          metadata: {"reason": "extremely_fast_completion"}
        );
      }

      user!.points = (user!.points ?? 0) + finalScore;
      status.assessmentDone = true;
      status.assessmentGrade = finalScore;
      status.assessmentAnswer = question!.questions.map((q) => q.selectedAnswer).toList();

      await Future.wait([
        UserService.updateUserPoints(user!),
        UserChapterService.updateChapterStatus(status.id, status),
      ]);

      await UserService.triggerChallengeManual(user!.id, 'FINISH_ASSESSMENT');

      if (finalScore == 100) {
        await UserService.triggerChallengeManual(user!.id, 'PERFECT_SCORE');
      }

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
      debugPrint(">>> GAGAL SINKRONISASI ASSESSMENT: $e <<<");
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

    return question != null && question!.questions.isNotEmpty
        ? Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('lib/assets/pictures/background-pattern.png'),
                    fit: BoxFit.cover)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                          value: (_currentPage + 1) / question!.questions.length,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor)),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(LineAwesomeIcons.clock,
                            color: _secondsRemaining < 10 ? Colors.red : Colors.black54,
                            size: 20),
                        const SizedBox(width: 8),
                        Text("Sisa Waktu: $_secondsRemaining detik",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _secondsRemaining < 10 ? Colors.red : Colors.black54)),
                      ]),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: question!.questions.length,
                    onPageChanged: (int page) {
                      if (mounted) setState(() => _currentPage = page);
                      _startTimer();
                    },
                    itemBuilder: (context, count) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildSingleQuestion(count)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: () => _currentPage < question!.questions.length - 1
                            ? _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut)
                            : _showFinishConfirmation(),
                        icon: Icon(
                            _currentPage < question!.questions.length - 1
                                ? LineAwesomeIcons.arrow_right_solid
                                : LineAwesomeIcons.check_solid,
                            color: Colors.white),
                        label: Text(
                            _currentPage < question!.questions.length - 1
                                ? 'Pertanyaan Berikutnya'
                                : 'Kirim Jawaban',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _buildAssessmentInitial() {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('lib/assets/pictures/background-pattern.png'),
              fit: BoxFit.cover)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset('lib/assets/pixels/assessment-pixel.png', height: 80),
            const SizedBox(height: 16),
            const Text('Mulai Assessment',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'DIN_Next_Rounded')),
            const SizedBox(height: 12),
            const Text("Pilihan Ganda (30 detik) / Essay (60 detik)\nHanya diperbolehkan satu kali percobaan.",
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () {
                    setState(() => _assessmentStarted = true);
                    _startTimer();
                  },
                  icon: const Icon(LineAwesomeIcons.rocket_solid, color: Colors.white),
                  label: const Text('Mulai Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )),
          ]),
        ),
      ),
    );
  }

  Widget _buildSingleQuestion(int number) {
    final q = question!.questions[number];
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Text("${number + 1}. ${q.question}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        if (q.type == 'EY')
          Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    maxLines: 5,
                    decoration: const InputDecoration(
                        hintText: "Ketik jawaban Anda di sini...", border: InputBorder.none),
                    onChanged: (val) {
                      q.selectedAnswer = val;
                    },
                  )))
        else
          Column(
              children: q.option.map((answer) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: q.selectedAnswer == answer
                      ? AppColors.primaryColor.withOpacity(0.1)
                      : Colors.white,
                  border: Border.all(
                      color: q.selectedAnswer == answer
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                      width: 2),
                  borderRadius: BorderRadius.circular(15)),
              child: RadioListTile<String>(
                title: Text(answer),
                value: answer,
                groupValue: q.selectedAnswer,
                activeColor: AppColors.primaryColor,
                onChanged: (val) {
                  if (mounted) setState(() => q.selectedAnswer = val!);
                },
              ),
            );
          }).toList())
      ]),
    );
  }

  Widget _buildQuizResult() {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('lib/assets/pictures/background-pattern.png'),
              fit: BoxFit.cover)),
      child: SingleChildScrollView(
          child: Column(children: [
        const SizedBox(height: 40),
        Card(
          margin: const EdgeInsets.all(16),
          color: AppColors.primaryColor,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Hasil Assessment',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const Divider(color: Colors.white30),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Benar', style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text('$correctAnswer / ${question?.questions.length ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Skor Akhir', style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text('${status.assessmentGrade} / 100',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 22)),
                ],
              ),
            ]),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text("Review Jawaban:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        if (question != null)
          ...List.generate(question!.questions.length, (i) => _buildReviewCard(i)),
        const SizedBox(height: 40),
      ])),
    );
  }

  Widget _buildReviewCard(int number) {
    final q = question!.questions[number];
    final bool isCorrect = q.selectedAnswer.toString().trim().toLowerCase() ==
        q.correctedAnswer.toString().trim().toLowerCase();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isCorrect ? Colors.green : Colors.red, width: 2)),
      child: ListTile(
        leading: Icon(isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? Colors.green : Colors.red),
        title: Text(q.question, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text("Jawaban Anda: ${q.selectedAnswer}\nJawaban Benar: ${q.correctedAnswer}"),
        ),
      ),
    );
  }
}