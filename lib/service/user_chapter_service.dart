import 'dart:convert';
import 'package:app/model/chapter_status.dart';
import 'package:http/http.dart' as http;
import '../global_var.dart';

class UserChapterService {
  // Helper internal untuk memastikan semua route diawali /api secara konsisten
  static String get _apiPath => "${GlobalVar.baseUrl}/api";

  /// Mengambil status belajar user untuk chapter tertentu.
  /// Jika belum ada, maka backend akan membuatkan data baru secara otomatis.
  static Future<ChapterStatus> getChapterStatus(int idUser, int idChapter) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiPath/userchapter/$idUser/$idChapter'),
      ).timeout(const Duration(seconds: 15));

      final body = response.body;

      // Proteksi jika server Express mengembalikan error 404/500 dalam bentuk HTML
      if (body.startsWith('<!DOCTYPE html>')) {
        throw Exception("Backend mengembalikan HTML. Cek route /api/userchapter/:userId/:chapterId");
      }

      final result = jsonDecode(body);
      
      if (result is List && result.isNotEmpty) {
        // Jika data ditemukan, ambil indeks pertama
        return ChapterStatus.fromJson(result[0]);
      } else {
        // Jika data belum ada di DB, buat status chapter baru (Initial State)
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
          // Prisma biasanya membungkus hasil dalam key 'userChapter' atau 'data'
          return ChapterStatus.fromJson(resultPost['userChapter'] ?? resultPost['data'] ?? resultPost);
        } else {
          throw Exception("Gagal menginisialisasi status chapter baru: ${responsePost.statusCode}");
        }
      }
    } catch (e) {
      print("UserChapterService [getChapterStatus] Error: $e");
      throw Exception(e.toString());
    }
  }

  /// Fungsi khusus untuk submit file tugas.
  /// Ini memanggil route backend yang mengolah array submissionHistory (unshift URL baru).
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
      }),
    ).timeout(const Duration(seconds: 20));

    // DEBUG: Cetak status code jika gagal
    if (response.statusCode != 200 && response.statusCode != 201) {
      print("BACKEND REJECTED: ${response.statusCode} - ${response.body}");
      return false;
    }

    return true;
  } catch (e) {
    print("CONNECTION ERROR TO BACKEND: $e");
    return false;
  }
}

  /// Update status chapter secara umum (Progress materi, nilai kuis, dll).
  static Future<ChapterStatus> updateChapterStatus(int id, ChapterStatus statusObj) async {
    try {
      // Menyiapkan data request sesuai format JSON Prisma di Backend
      Map<String, dynamic> request = {
        "isStarted": statusObj.isStarted,
        "isCompleted": statusObj.isCompleted,
        "materialDone": statusObj.materialDone,
        "assessmentDone": statusObj.assessmentDone,
        "assignmentDone": statusObj.assignmentDone,
        // Konversi list ke string JSON agar aman saat diterima Prisma
        "assessmentAnswer": jsonEncode(statusObj.assessmentAnswer),
        "submission": statusObj.submission,
        "submissionHistory": jsonEncode(statusObj.submissionHistory),
        "assessmentGrade": statusObj.assessmentGrade,
        "assignmentScore": statusObj.assignmentScore,
        "assignmentFeedback": statusObj.assignmentFeedback,
        "timeStarted": statusObj.timeStarted.toUtc().toIso8601String(),
        "timeFinished": statusObj.timeFinished.toUtc().toIso8601String(),
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
        throw Exception("Update Gagal dengan status code: ${responsePut.statusCode}");
      }
    } catch (e) {
      print("UserChapterService [updateChapterStatus] Error: $e");
      throw Exception(e.toString());
    }
  }
}