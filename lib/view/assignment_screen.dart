import 'dart:async';
import 'dart:io';
import 'package:app/model/assignment.dart';
import 'package:app/model/chapter_status.dart';
import 'package:app/model/user_course.dart';
import 'package:app/service/badge_service.dart';
import 'package:app/service/chapter_service.dart';
import 'package:app/service/user_chapter_service.dart';
import 'package:app/service/user_service.dart';
import 'package:app/service/user_course_service.dart';
import 'package:app/service/activity_service.dart'; // IMPORT BARU
import 'package:app/utils/colors.dart';
import 'package:app/view/main_screen.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/user.dart';
import 'congratulation_screen.dart';

class AssignmentScreen extends StatefulWidget {
  final ChapterStatus status;
  final Student user;
  final UserCourse uc;
  final int level;
  final int idBadge;
  final int chLength;
  final Function(bool) updateProgress;
  final Function(ChapterStatus) updateStatus;

  const AssignmentScreen({
    super.key,
    required this.status,
    required this.user,
    required this.uc,
    required this.level,
    this.idBadge = 0,
    required this.chLength,
    required this.updateProgress,
    required this.updateStatus,
  });

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  late ChapterStatus status;
  Assignment? assignment;
  Student? user;
  late UserCourse uc;
  double downloadProgress = 0.0;
  PlatformFile? file;
  String lastestSubmissionUrl = '';
  bool _isSubmitting = false; 
  int idBadge = 0;
  int chLength = 0;
  bool complete = false;
  bool showDialogAssignmentOnce = false;

  @override
  void initState() {
    status = widget.status;
    user = widget.user;
    uc = widget.uc;
    idBadge = widget.idBadge;
    chLength = widget.chLength;
    complete = status.isCompleted;
    showDialogAssignmentOnce = widget.status.assignmentDone;
    if (status.submission != null && status.submission != '') {
      lastestSubmissionUrl = status.submission!;
    }
    getAssignment(widget.status.chapterId);
    super.initState();
  }

  void getAssignment(int id) async {
    try {
      final resultAssignment = await ChapterService.getAssignmentByChapterId(id);
      if (mounted) setState(() => assignment = resultAssignment);
    } catch (e) {
      debugPrint("Error get assignment: $e");
    }
  }

  Future<void> _handleSubmit() async {
    if (file == null) return;

    setState(() => _isSubmitting = true);

    try {
      // LOG TRIGGER: ACHIEVERS (Completion Rate)
      // Memicu sinyal penyelesaian chapter penuh
      ActivityService.sendLog(
        userId: user!.id, 
        type: 'COMPLETION_RATE', 
        value: 1.0,
        metadata: {"chapterId": status.chapterId}
      );

      Duration difference = status.timeStarted.difference(DateTime.now());
      if (!status.assignmentDone && !complete) {
        user?.points = (user?.points ?? 0) + _calculatePoint(difference.inMinutes.abs());
      }

      if (widget.level == uc.currentChapter) {
        uc.currentChapter++;
        uc.progress = (((uc.currentChapter - 1) / chLength) * 100).toInt();
      }

      if (idBadge != 0) {
        await BadgeService.createUserBadgeByChapterId(user!.id, idBadge);
        user?.badges = (user?.badges ?? 0) + 1;
      }

      final filename = '${file!.name.split('.').first}_${status.userId}_${status.chapterId}_${DateTime.now().millisecondsSinceEpoch}.${file!.extension}';
      final path = 'uploads/$filename';
      
      Uint8List bytes;
      if (kIsWeb) {
        bytes = file!.bytes!;
      } else {
        bytes = await File(file!.path!).readAsBytes();
      }

      await Supabase.instance.client.storage.from('assignment').uploadBinary(
        path, 
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      
      final publicUrl = Supabase.instance.client.storage.from('assignment').getPublicUrl(path);
      
      status.submission = publicUrl;
      status.isCompleted = true;
      status.assignmentDone = true;
      status.timeFinished = DateTime.now();

      await Future.wait([
        UserService.updateUserPointsAndBadge(user!),
        UserCourseService.updateUserCourse(uc.id, uc),
        UserChapterService.updateChapterStatus(status.id, status),
      ]);

      await UserService.triggerChallengeManual(user!.id, 'COMPLETE_CHAPTER');

      if (mounted) {
        widget.updateStatus(status);
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint("Gagal Submit: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengirim tugas: ${e.toString()}"), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false); 
      }
    }
  }

  int _calculatePoint(int mnt) {
    if (mnt <= 120) return 100;
    if (mnt <= 240) return 80;
    return 20;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Berhasil!", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('lib/assets/pixels/check.png', height: 72),
            const SizedBox(height: 16),
            const Text("Tugas berhasil dikumpulkan dan tantangan telah diperbarui.", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Mainscreen(navIndex: 2)),
                  (route) => false,
                );
              },
              child: const Text("Selesai", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('lib/assets/pictures/background-pattern.png'),
              fit: BoxFit.cover)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isSubmitting) const LinearProgressIndicator(color: AppColors.primaryColor),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    assignment == null 
                        ? const CircularProgressIndicator() 
                        : HtmlWidget(assignment!.instruction, textStyle: const TextStyle(fontFamily: 'DIN_Next_Rounded')),
                    const SizedBox(height: 20),
                    
                    GestureDetector(
                      onTap: _isSubmitting ? null : () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom, 
                          allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg']
                        );
                        if (result != null) setState(() => file = result.files.first);
                      },
                      child: file == null ? _buildUploadBox() : _buildFilePreview(file!),
                    ),

                    const SizedBox(height: 20),

                    if (!_isSubmitting && file != null)
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 12)
                              ),
                              onPressed: _handleSubmit,
                              icon: const Icon(LineAwesomeIcons.paper_plane_solid, color: Colors.white),
                              label: const Text("Submit Assignment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => file = null),
                            child: const Text("Hapus Pilihan", style: TextStyle(color: Colors.red)),
                          )
                        ],
                      ),
                      
                    if (_isSubmitting)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),

                    _buildFeedbackSection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadBox() {
    return DottedBorder(
      color: Colors.grey,
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      child: Container(
        height: 150,
        width: double.infinity,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineAwesomeIcons.file_upload_solid, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text("Tap untuk pilih file tugas (PDF/JPG)", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(PlatformFile file) {
    return DottedBorder(
      color: AppColors.primaryColor,
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: Column(
          children: [
            const Icon(LineAwesomeIcons.file_pdf, size: 50, color: AppColors.primaryColor),
            const SizedBox(height: 10),
            Text(file.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("${(file.size / 1024).toStringAsFixed(2)} KB", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border.all(color: Colors.grey.shade300), 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Feedback Instruktur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          Text("Skor: ${status.assignmentScore}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
          const SizedBox(height: 4),
          Text(status.assignmentFeedback.isEmpty ? "Belum ada feedback dari instruktur." : status.assignmentFeedback),
        ],
      ),
    );
  }
}