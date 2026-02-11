import 'dart:async';
import 'dart:io';
import 'package:app/model/assignment.dart';
import 'package:app/model/chapter_status.dart';
import 'package:app/model/user_course.dart';
import 'package:app/service/chapter_service.dart';
import 'package:app/service/user_chapter_service.dart';
import 'package:app/service/activity_service.dart';
import 'package:app/utils/colors.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/user.dart';

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
  PlatformFile? file;
  bool _isSubmitting = false;

  @override
  void initState() {
    status = widget.status;
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

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal membuka file")),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (file == null) return;
    if (mounted) setState(() => _isSubmitting = true);

    try {
      debugPrint("--- Memulai Proses Submit ---");

      // 1. Log Aktivitas ke Backend
      await ActivityService.sendLog(
        userId: widget.user.id,
        type: 'COMPLETION_RATE',
        value: 1.0,
        metadata: {"chapterId": status.chapterId},
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint("Log aktivitas timeout, lanjut ke upload...");
      });

      // 2. Persiapan Data File
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = file!.extension ?? 'pdf';
      final String filename = 'task_${widget.user.id}_$timestamp.$extension';
      final String storagePath = 'uploads/$filename';
      
      Uint8List bytes = kIsWeb ? file!.bytes! : await File(file!.path!).readAsBytes();

      debugPrint("Uploading ke Supabase: $storagePath...");

      // 3. Upload ke Supabase Storage
      await Supabase.instance.client.storage
          .from('assignment')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'application/$extension',
              upsert: true,
            ),
          ).timeout(const Duration(seconds: 40));

      debugPrint("Upload Supabase Berhasil.");

      // 4. Ambil Public URL
      final String publicUrl = Supabase.instance.client.storage
          .from('assignment')
          .getPublicUrl(storagePath);

      // 5. Sinkronisasi ke Backend Node.js
      bool success = await UserChapterService.submitAssignmentFile(status.id, publicUrl);

      if (success) {
        debugPrint("Backend Sync Berhasil.");
        
        // PERBAIKAN: OPTIMISTIC UPDATE
        // Langsung masukkan URL baru ke list lokal di memori HP agar UI langsung update
        if (mounted) {
          setState(() {
            status.submissionHistory.insert(0, publicUrl); 
            status.assignmentDone = true;
          });
        }

        // PERBAIKAN: JEDA SINKRONISASI
        // Beri waktu 1 detik agar database backend selesai melakukan commit transaksi
        await Future.delayed(const Duration(milliseconds: 1000));

        // 6. RE-FETCH: Ambil status "resmi" terbaru dari DB untuk sinkronisasi final
        final updatedStatus = await UserChapterService.getChapterStatus(widget.user.id, status.chapterId);
        
        if (mounted) {
          setState(() {
            status = updatedStatus;
            file = null;
          });
          widget.updateStatus(status);
          _showSuccessDialog();
        }
      } else {
        throw Exception("Backend gagal menyimpan riwayat pengiriman.");
      }
    } catch (e) {
      debugPrint("CRASH SAAT SUBMIT: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal kirim: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('lib/assets/pictures/background-pattern.png'),
              fit: BoxFit.cover,
              opacity: 0.1)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(color: AppColors.primaryColor),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdminContent(),
                    const SizedBox(height: 25),
                    const Text("Kirim Tugas",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'DIN_Next_Rounded')),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () async {
                              final result = await FilePicker.platform.pickFiles(type: FileType.any);
                              if (result != null) setState(() => file = result.files.first);
                            },
                      child: file == null ? _buildUploadBox() : _buildFilePreview(file!),
                    ),
                    if (file != null && !_isSubmitting) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          onPressed: _handleSubmit,
                          icon: const Icon(LineAwesomeIcons.paper_plane,
                              color: Colors.white),
                          label: const Text("Kirim Pengiriman Baru",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'DIN_Next_Rounded')),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    const Text("Riwayat Pengiriman",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'DIN_Next_Rounded')),
                    const Divider(),
                    _buildHistoryList(),
                    const SizedBox(height: 20),
                    _buildFeedbackSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminContent() {
    if (assignment == null) return const Center(child: CircularProgressIndicator());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HtmlWidget(assignment!.instruction,
            textStyle: const TextStyle(fontFamily: 'DIN_Next_Rounded')),
        if (assignment!.fileUrl != null && assignment!.fileUrl!.isNotEmpty) ...[
          const SizedBox(height: 15),
          InkWell(
            onTap: () => _openUrl(assignment!.fileUrl!),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2))),
              child: const Row(
                children: [
                  Icon(LineAwesomeIcons.file_download_solid, color: Colors.blue),
                  SizedBox(width: 12),
                  Text("Download Lampiran dari Admin",
                      style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildHistoryList() {
    if (status.submissionHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: Text("Belum ada file yang dikirim.",
                style: TextStyle(color: Colors.grey, fontSize: 12))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: status.submissionHistory.length,
      itemBuilder: (context, index) {
        final url = status.submissionHistory[index];
        final fileName = url.split('/').last.split('?').first;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade200)),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
                backgroundColor: AppColors.primaryColor,
                child: Icon(LineAwesomeIcons.file, color: Colors.white, size: 20)),
            title: Text("Pengiriman #${status.submissionHistory.length - index}",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text(fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11)),
            trailing: IconButton(
              icon: const Icon(LineAwesomeIcons.download_solid,
                  color: AppColors.primaryColor),
              onPressed: () => _openUrl(url),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadBox() {
    return DottedBorder(
      color: Colors.grey,
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      child: const SizedBox(
        height: 100,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineAwesomeIcons.file_upload_solid, size: 30, color: Colors.grey),
            SizedBox(height: 8),
            Text("Pilih file tugas Anda",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
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
        child: Row(
          children: [
            const Icon(LineAwesomeIcons.file,
                size: 40, color: AppColors.primaryColor),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text("${(file.size / 1024).toStringAsFixed(2)} KB",
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
                onPressed: () => setState(() => this.file = null),
                icon: const Icon(Icons.close, color: Colors.red))
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Feedback Instruktur",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Divider(),
          Row(
            children: [
              const Text("Skor: ", style: TextStyle(fontSize: 13)),
              Text("${status.assignmentScore}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 5),
          Text(
              status.assignmentFeedback.isEmpty
                  ? "Belum ada feedback dari instruktur."
                  : status.assignmentFeedback,
              style: const TextStyle(
                  fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Berhasil!",
            style: TextStyle(
                fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.bold)),
        content: const Text("Tugas telah dikirim dan tersimpan di riwayat."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("Tutup"))
        ],
      ),
    );
  }
}