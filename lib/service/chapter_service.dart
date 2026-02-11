import 'dart:convert';
import 'package:app/global_var.dart';
import 'package:app/model/assignment.dart';
import 'package:http/http.dart' as http;
import '../model/assessment.dart';
import '../model/chapter.dart';
import '../model/learning_material.dart';

class ChapterService {
  // Helper internal untuk memastikan route diawali /api secara konsisten
  static String get _apiPath => "${GlobalVar.baseUrl}/api";

  static Future<LearningMaterial> getMaterialByChapterId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiPath/chapter/$id/materials'),
      ).timeout(const Duration(seconds: 15));
      
      final body = response.body;
      
      // Proteksi jika server mengirim error HTML
      if (body.startsWith('<!DOCTYPE html>')) {
        throw Exception("Server Error: Route /api/chapter/$id/materials tidak ditemukan.");
      }
      
      final result = jsonDecode(body);
      return LearningMaterial(
        id: result['id'],
        chapterId: result['chapterId'],
        name: result['name'],
        content: result['content'],
        createdAt: DateTime.parse(result['createdAt']),
        updatedAt: DateTime.parse(result['updatedAt']),
      );
    } catch (e) {
      print("Error getMaterialByChapterId: $e");
      throw Exception(e.toString());
    }
  }

  static Future<Assessment> getAssessmentByChapterId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiPath/chapter/$id/assessments'),
      ).timeout(const Duration(seconds: 20)); // Durasi lebih lama untuk data soal yang besar
      
      final body = response.body;
      if (body.startsWith('<!DOCTYPE html>')) {
        throw Exception("Server Error: Route /api/chapter/$id/assessments tidak ditemukan.");
      }

      final result = jsonDecode(body);
      if (result == null || (result is List && result.isEmpty)) {
        throw Exception("No assessments found for this chapter");
      }

      // Mendukung response jika berbentuk List atau Map langsung
      final data = (result is List) ? result[0] : result;

      final List<dynamic> decodeQuestion = jsonDecode(data['questions']);
      List<Question> questions = decodeQuestion.map((q) => Question(
        question: q['question'],
        option: List<String>.from(q['options']),
        correctedAnswer: q['answer'],
        type: q['type']
      )).toList();

      final List<String>? decodedAnswers = data['answers'] != null
          ? List<String>.from(jsonDecode(data['answers']))
          : null;

      return Assessment(
        id: data['id'],
        chapterId: data['chapterId'],
        instruction: data['instruction'],
        questions: questions,
        answers: decodedAnswers,
        createdAt: DateTime.parse(data['createdAt']),
        updatedAt: DateTime.parse(data['updatedAt']),
      );
    } catch (e) {
      print("Error getAssessmentByChapterId: $e");
      throw Exception("Error fetching assessment: ${e.toString()}");
    }
  }

  static Future<Assignment> getAssignmentByChapterId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiPath/chapter/$id/assignments'),
      ).timeout(const Duration(seconds: 15));
      
      final body = response.body;
      if (body.startsWith('<!DOCTYPE html>')) {
        throw Exception("Server Error: Route /api/chapter/$id/assignments tidak ditemukan.");
      }

      final result = jsonDecode(body);
      if (result == null || (result is List && result.isEmpty)) {
        throw Exception("No assignment found");
      }

      final data = (result is List) ? result[0] : result;
      return Assignment.fromJson(data);
    } catch (e) {
      print("Error getAssignmentByChapterId: $e");
      throw Exception("Error fetching assignment: ${e.toString()}");
    }
  }

  static Future<Chapter> getChapterById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiPath/chapter/$id'),
      ).timeout(const Duration(seconds: 10));
      
      final body = response.body;
      if (body.startsWith('<!DOCTYPE html>')) {
        throw Exception("Server Error: Route /api/chapter/$id tidak ditemukan.");
      }

      final result = jsonDecode(body);
      return Chapter.fromJson(result);
    } catch (e) {
      print("Error getChapterById: $e");
      throw Exception("Error fetching chapter: ${e.toString()}");
    }
  }

  static Future<double> checkSimiliarity(String reference, String answer) async {
    Map<String, dynamic> request = {
      'reference': reference,
      'essay': answer
    };
    try {
      // Menggunakan URL khusus AI Flask (Port 8081)
      final response = await http.post(
        Uri.parse(GlobalVar.similiarityEssayUrl), 
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        }, 
        body: jsonEncode(request)
      ).timeout(const Duration(seconds: 45)); // AI butuh waktu lebih lama untuk memproses
      
      final result = jsonDecode(response.body);
      return (result['similarity_score'] as num).toDouble();
    } catch (e) {
      print("Error checkSimiliarity: $e");
      throw Exception("Error get Response Essay Similarity: ${e.toString()}");
    }
  }
}