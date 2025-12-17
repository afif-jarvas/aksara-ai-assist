import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class MusicGeminiService {
  // Pastikan API Key sudah benar
  static const String _apiKey = 'AIzaSyDxx4h_9bJsW2Z08MeeJYM-niNrOtbUqoA';
  
  late final GenerativeModel _model;

  MusicGeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: _apiKey,
      // SETTING PENTING: Agar AI tidak terlalu sensitif (bisa bahas mantan/galau)
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
  }

  Future<Map<String, dynamic>> generateSong(String topic, String genre, String mood, String language) async {
    try {
      // Prompt dinamis sesuai bahasa user
      final promptText = """
        Bertindaklah sebagai penulis lagu profesional. Ciptakan lagu orisinal.
        Topik: "$topic"
        Genre: $genre
        Mood: $mood
        Bahasa Lirik: $language (Sesuaikan dengan bahasa ini)

        Berikan respon HANYA dalam format JSON MURNI tanpa markdown (```json). 
        Jangan ada teks pembuka atau penutup.
        Struktur JSON wajib:
        {
          "title": "Judul Lagu",
          "style": "Deskripsi gaya musik singkat",
          "lyrics": [
            {"section": "Verse 1", "text": "Baris lirik...", "chord": "C"},
            {"section": "Chorus", "text": "Baris lirik...", "chord": "Am"}
          ],
          "trivia": "Satu fakta menarik tentang komposisi ini"
        }
      """;

      final response = await _model.generateContent([Content.text(promptText)]);
      final text = response.text;
      
      if (text == null || text.isEmpty) throw Exception("Empty response");

      // --- PEMBERSIH JSON CERDAS ---
      // Mencari kurung kurawal pertama { dan terakhir }
      // Ini mengatasi masalah jika AI membalas: "Tentu, ini JSON nya: { ... }"
      final int startIndex = text.indexOf('{');
      final int endIndex = text.lastIndexOf('}');

      if (startIndex == -1 || endIndex == -1) {
        throw Exception("Format JSON tidak ditemukan dalam respon AI");
      }

      final cleanJson = text.substring(startIndex, endIndex + 1);
      return jsonDecode(cleanJson);

    } catch (e) {
      print("Music AI Error: $e");
      return {
        'error': true,
        'message': e.toString()
      };
    }
  }
}