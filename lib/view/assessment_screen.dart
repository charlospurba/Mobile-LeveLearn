import 'dart:async'; 
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../model/assessment.dart';
import '../model/chapter_status.dart';
import '../model/user.dart';
import '../service/chapter_service.dart';
import '../service/user_chapter_service.dart';
import '../service/user_service.dart';
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
    required this.updateAssessmentFinished
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  bool _assessmentStarted = false;
  bool _assessmentFinished = false;
  bool tapped = false;
  bool assessmentDone = false;
  bool allQuestionsAnswered = false;
  int correctAnswer = 0;
  int point = 0;
  Student? user;
  late ChapterStatus status;
  Assessment? question;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _calculateComplete = false;

  // --- LOGIKA TIMER ---
  Timer? _timer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    status = widget.status;
    user = widget.user;
    // Ambil status awal dari database
    assessmentDone = widget.status.assessmentDone;
    allQuestionsAnswered = widget.status.assessmentDone;
    
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
        setState(() { _secondsRemaining--; });
      } else {
        _timer?.cancel();
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    if (_currentPage < question!.questions.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _executeSubmit();
    }
  }

  void _executeSubmit() {
    _timer?.cancel();
    setState(() {
      tapped = true;
      allQuestionsAnswered = true;
    });
    _showQuizResults();
  }

  void getAssessment(int id) async {
    final resultAssessment = await ChapterService.getAssessmentByChapterId(id);
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

  void _showFinishConfirmation() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Finish Assessment', style: TextStyle(fontFamily: 'DIN_Next_Rounded')),
        content: const Text('Once you submit, you cannot change your answers or retake this assessment.'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _startTimer(); }, child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            onPressed: () {
              Navigator.pop(context);
              _executeSubmit();
            },
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<int> getScore() async {
    int score = 0;
    double rangeScore = 100 / question!.questions.length;
    int tempCorrectAnswer = 0;

    for (int index = 0; index < question!.questions.length; index++) {
      Question i = question!.questions[index];
      if (i.type != 'EY') {
        if (i.selectedAnswer == i.correctedAnswer) {
          question!.questions[index].isCorrect = true;
          question!.questions[index].score = rangeScore.ceil();
          score += rangeScore.ceil();
          tempCorrectAnswer++;
        }
      } else {
        int fullscore = rangeScore.ceil();
        try {
          double similarity = await ChapterService.checkSimiliarity(i.correctedAnswer, i.selectedAnswer);
          int earned = (fullscore * similarity).ceil();
          question!.questions[index].score = earned;
          score += earned;
          if (similarity > 0.5) {
            question!.questions[index].isCorrect = true;
            tempCorrectAnswer++;
          }
        } catch (e) { debugPrint("Score error: $e"); }
      }
    }
    setState(() { correctAnswer = tempCorrectAnswer; });
    return score;
  }

  void _showQuizResults() async {
    setState(() { _assessmentFinished = true; });
    
    int finalScore = await getScore();
    
    setState(() {
      point = finalScore > 100 ? 100 : finalScore;
      _calculateComplete = true;
    });

    if(_calculateComplete) {
      if(!widget.status.assessmentDone && !assessmentDone){
        user!.points = (user!.points ?? 0) + point;
        assessmentDone = true;
        status.assessmentGrade = point;
      }

      if (question!.answers == null) question!.answers = [];
      question!.answers!.clear();
      for (var q in question!.questions) {
        question!.answers!.add(q.selectedAnswer);
      }
      status.assessmentDone = true;
      status.assessmentAnswer = question!.answers!;
      
      // Update DB sebelum memberitahu sistem bahwa assessment sudah selesai total
      await UserService.updateUserPoints(user!);
      status = await UserChapterService.updateChapterStatus(status.id, status);
      
      // Kirim status terbaru ke Parent agar tombol "Mulai" terkunci permanen
      widget.updateStatus(status); 
      widget.updateAssessmentFinished(true);
      widget.updateAssessmentStarted(false);
      widget.updateMaterialLocked(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // PROTEKSI UTAMA: Jika status pengerjaan sudah DONE di DB, langsung tampilkan hasil
    if (widget.status.assessmentDone || _assessmentFinished) {
      return _buildQuizResult();
    }

    if (!_assessmentStarted) {
      return _buildAssessmentInitial();
    }

    return question != null && question!.questions.isNotEmpty
        ? Container(
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('lib/assets/pictures/background-pattern.png'), fit: BoxFit.cover)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(value: (_currentPage + 1) / question!.questions.length, backgroundColor: Colors.grey.shade300, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor)),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(LineAwesomeIcons.clock, color: _secondsRemaining < 10 ? Colors.red : Colors.black54, size: 20),
                          const SizedBox(width: 8),
                          Text("Time Left: $_secondsRemaining s", style: TextStyle(fontWeight: FontWeight.bold, color: _secondsRemaining < 10 ? Colors.red : Colors.black54)),
                      ]),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // User tidak bisa balik soal
                    itemCount: question!.questions.length,
                    onPageChanged: (int page) { setState(() { _currentPage = page; }); _startTimer(); },
                    itemBuilder: (context, count) => Padding(padding: const EdgeInsets.all(20), child: _buildSingleQuestion(count)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(width: double.infinity, child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () => _currentPage < question!.questions.length - 1 ? _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : _showFinishConfirmation(),
                      icon: Icon(_currentPage < question!.questions.length - 1 ? LineAwesomeIcons.arrow_right_solid : LineAwesomeIcons.check_solid, color: Colors.white),
                      label: Text(_currentPage < question!.questions.length - 1 ? 'Next Question' : 'Submit Assessment', style: const TextStyle(color: Colors.white)),
                  )),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _buildAssessmentInitial() {
    return Container(
      decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('lib/assets/pictures/background-pattern.png'), fit: BoxFit.cover)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset('lib/assets/pixels/assessment-pixel.png', height: 80),
              const SizedBox(height: 16),
              const Text('Start Assessment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'DIN_Next_Rounded')),
              const SizedBox(height: 12),
              const Text("30s (Choice) / 60s (Essay)\nOnly one attempt allowed.", textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () { setState(() { _assessmentStarted = true; }); _startTimer(); },
                  icon: const Icon(LineAwesomeIcons.rocket_solid, color: Colors.white),
                  label: const Text('Start Now', style: TextStyle(color: Colors.white)),
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
          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Text("${number + 1}. ${q.question}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          if (q.type == 'EY') 
            Card(color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16), child: TextField(maxLines: 5, decoration: const InputDecoration(hintText: "Type answer here...", border: InputBorder.none),
              onChanged: (val) { setState(() { q.selectedAnswer = val; }); },
            )))
          else if (q.type == 'TF')
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['True', 'False'].map((opt) => ElevatedButton(
              onPressed: () { setState(() { q.selectedAnswer = opt; }); },
              style: ElevatedButton.styleFrom(backgroundColor: q.selectedAnswer == opt ? AppColors.primaryColor : Colors.grey.shade200),
              child: Text(opt, style: TextStyle(color: q.selectedAnswer == opt ? Colors.white : Colors.black)),
            )).toList())
          else 
            Column(children: q.option.map((answer) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: q.selectedAnswer == answer ? AppColors.primaryColor.withOpacity(0.1) : Colors.white,
                  border: Border.all(color: q.selectedAnswer == answer ? AppColors.primaryColor : Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(15)
                ),
                child: RadioListTile<String>(
                  title: Text(answer),
                  value: answer,
                  groupValue: q.selectedAnswer,
                  activeColor: AppColors.primaryColor,
                  onChanged: (val) { setState(() { q.selectedAnswer = val!; }); },
                ),
              );
            }).toList())
      ]),
    );
  }

  // --- TAMPILAN HASIL---
  Widget _buildQuizResult() {
    return Container(
      decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('lib/assets/pictures/background-pattern.png'), fit: BoxFit.cover)),
      child: SingleChildScrollView(
          child: Column(children: [
              const SizedBox(height: 40),
              Card(
                margin: const EdgeInsets.all(16),
                color: AppColors.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Hasil Assessment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 10),
                    Table(
                      columnWidths: const { 0: FlexColumnWidth(1), 1: FlexColumnWidth(2) },
                      children: [
                        TableRow(children: [
                          const Text('Correct', style: TextStyle(color: Colors.white, fontFamily: 'DIN_Next_Rounded')),
                          Text(': $correctAnswer / ${question?.questions.length ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ]),
                        TableRow(children: [
                          const Text('Score', style: TextStyle(color: Colors.white, fontFamily: 'DIN_Next_Rounded')),
                          Text(': ${status.assessmentGrade} / 100', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ]),
                      ],
                    ),
                  ]),
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
    final bool isCorrect = q.selectedAnswer == q.correctedAnswer;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isCorrect ? Colors.green : Colors.red, width: 2)),
      child: ListTile(
        leading: Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red),
        title: Text(q.question),
        subtitle: Text("Your Answer: ${q.selectedAnswer}\nCorrect Answer: ${q.correctedAnswer}"),
      ),
    );
  }

  Widget _emptyState() { return const Center(child: Text("No questions.")); }
}