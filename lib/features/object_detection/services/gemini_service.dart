import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiObjectService {
  // GANTI DENGAN API KEY KAMU DARI GOOGLE AI STUDIO
  static const String _apiKey = 'AIzaSyBUhL6m_IXCYqL67clgCHKkAdUSQiXcT74';
  
  late final GenerativeModel _model;

  GeminiObjectService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Model cepat dan akurat untuk gambar
      apiKey: _apiKey,
    );
  }

  Future<Map<String, String>> analyzeImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      // Prompt Prompt Engineering agar output konsisten
      final prompt = TextPart("""
        Analisis gambar ini. Identifikasi SATU objek utama yang paling dominan dan terlihat jelas.
        Berikan respon HANYA dalam format JSON valid tanpa markdown (```json).
        Format JSON:
        {
          "name": "Nama Objek (Gunakan Bahasa Indonesia yang umum)",
          "description": "Penjelasan singkat, edukatif, dan menarik tentang fungsi objek tersebut (maksimal 2 kalimat, Bahasa Indonesia).",
          "query": "Kata kunci pencarian google yang relevan untuk objek ini"
        }
        Contoh jika gambar kipas:
        {
          "name": "Kipas Angin",
          "description": "Perangkat mekanis yang menghasilkan aliran udara untuk pendinginan atau ventilasi ruangan.",
          "query": "Fungsi dan cara kerja Kipas Angin"
        }
      """);

      final imagePart = DataPart('image/jpeg', imageBytes);
      
      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final text = response.text;
      if (text == null) return {};

      // Bersihkan markdown jika ada (kadang Gemini kasih ```json ... ```)
      final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> data = jsonDecode(cleanJson);
      
      return {
        'name': data['name'] ?? 'Objek Tidak Dikenal',
        'description': data['description'] ?? 'Tidak ada penjelasan tersedia.',
        'query': data['query'] ?? 'Info menarik',
      };

    } catch (e) {
      print("Gemini Error: $e");
      return {
        'name': 'Gagal Analisa',
        'description': 'Terjadi kesalahan saat menghubungkan ke AI. Pastikan internet lancar.',
        'query': 'Error'
      };
    }
  }
}