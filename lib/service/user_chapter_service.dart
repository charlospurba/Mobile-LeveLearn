import 'dart:convert';
import 'package:app/model/chapter_status.dart';
import 'package:http/http.dart' as http;
import '../global_var.dart';

class UserChapterService {
  static String get _apiPath => "${GlobalVar.baseUrl}/api";

  /// Mengambil status belajar user untuk chapter tertentu.
  static Future<ChapterStatus> getChapterStatus(int idUser, int idChapter) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiPath/userchapter/$idUser/$idChapter'),
      ).timeout(const Duration(seconds: 15));

      final body = response.body;

      if (body.startsWith('<!DOCTYPE html>')) {
        throw Exception("Backend mengembalikan HTML. Cek route API.");
      }

      final result = jsonDecode(body);
      
      if (result is List && result.isNotEmpty) {
        return ChapterStatus.fromJson(result[0]);
      } else {
        // Inisialisasi State Baru jika data belum ada
        Map<String, dynamic> request = {
          "userId": idUser,
          "chapterId": idChapter,
          "isCompleted": false,
          "isStarted": false,
          "materialDone": false,
          "assessmentDone": false,
          "assignmentDone": false,
          "assessmentAnswer": "[]",
          "submission": "",
          "submissionHistory": "[]",
          "assessmentGrade": 0,
          "assignmentScore": 0,
          "assignmentFeedback": "",
          "timeStarted": DateTime.now().toUtc().toIso8601String(),
          "timeFinished": DateTime.now().toUtc().toIso8601String()
        };

        final responsePost = await http.post(
          Uri.parse('$_apiPath/userchapter'), 
          headers: {
            'Content-type' : 'application/json; charset=utf-8',
            'Accept': 'application/json',
          }, 
          body: jsonEncode(request)
        ).timeout(const Duration(seconds: 15));

        if (responsePost.statusCode == 201 || responsePost.statusCode == 200) {
          final resultPost = jsonDecode(responsePost.body);
          return ChapterStatus.fromJson(resultPost['userChapter'] ?? resultPost['data'] ?? resultPost);
        } else {
          throw Exception("Gagal inisialisasi status chapter");
        }
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Fungsi khusus untuk submit file tugas.
  /// Diperbarui: Menambahkan fungsionalitas untuk mentrigger update progress otomatis.
  static Future<bool> submitAssignmentFile(int statusId, String fileUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiPath/assignment/submit-file'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'statusId': statusId,
          'fileUrl': fileUrl,
          'isCompleted': true, // Memberitahu backend bahwa langkah ini menyelesaikan tugas
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200 && response.statusCode != 201) {
        print("BACKEND REJECTED: ${response.statusCode}");
        return false;
      }

      return true;
    } catch (e) {
      print("CONNECTION ERROR: $e");
      return false;
    }
  }

  /// Update status chapter secara umum.
  /// PENTING: Untuk Disruptors, backend harus dipicu untuk mengecek kelayakan naik level.
  static Future<ChapterStatus> updateChapterStatus(int id, ChapterStatus statusObj) async {
    try {
      Map<String, dynamic> request = {
        "isStarted": statusObj.isStarted,
        "isCompleted": statusObj.isCompleted,
        "materialDone": statusObj.materialDone,
        "assessmentDone": statusObj.assessmentDone,
        "assignmentDone": statusObj.assignmentDone,
        "assessmentAnswer": jsonEncode(statusObj.assessmentAnswer),
        "submission": statusObj.submission,
        "submissionHistory": jsonEncode(statusObj.submissionHistory),
        "assessmentGrade": statusObj.assessmentGrade,
        "assignmentScore": statusObj.assignmentScore,
        "assignmentFeedback": statusObj.assignmentFeedback,
        "timeStarted": statusObj.timeStarted.toUtc().toIso8601String(),
        "timeFinished": DateTime.now().toUtc().toIso8601String(),
      };

      final responsePut = await http.put(
        Uri.parse('$_apiPath/userchapter/$id'), 
        headers: {
          'Content-type' : 'application/json; charset=utf-8',
          'Accept': 'application/json',
        }, 
        body: jsonEncode(request)
      ).timeout(const Duration(seconds: 15));

      if (responsePut.statusCode == 200) {
        final result = jsonDecode(responsePut.body);
        return ChapterStatus.fromJson(result['data'] ?? result['userChapter'] ?? result);
      } else {
        throw Exception("Update Gagal: ${responsePut.statusCode}");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}