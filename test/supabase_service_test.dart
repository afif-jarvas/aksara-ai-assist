import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class EdgeFunctionService {
  static String? _baseUrl;
  static String? _anonKey;

  // Inisialisasi (Dipanggil di main.dart)
  static void initialize(String url, String anonKey) {
    _baseUrl = url;
    _anonKey = anonKey;
  }

  // --- GETTERS (INI YANG HILANG & BIKIN ERROR) ---
  // Menambahkan kembali agar file test bisa membaca URL & Key
  static String get baseUrl => _baseUrl ?? '';
  static String get anonKey => _anonKey ?? '';

  // --- FUNGSI UTAMA ---
  static Future<Map<String, dynamic>> callFunction(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    // 1. Ambil Token User Terbaru (PENTING UNTUK FIX 401)
    final session = Supabase.instance.client.auth.currentSession;
    final userToken = session?.accessToken;

    if (_baseUrl == null || _anonKey == null) {
      throw Exception("Service belum diinisialisasi. Cek main.dart.");
    }

    final url = '$_baseUrl/functions/v1/$functionName';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          // Kirim Token User jika login, atau Anon Key jika tamu
          'Authorization': 'Bearer ${userToken ?? _anonKey}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Edge Function Error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- HELPER METHODS (WAJIB ADA AGAR FITUR LAIN TIDAK ERROR) ---

  // 1. Chatbot AI (Gemini)
  static Future<Map<String, dynamic>> aiChat({
    required String message,
    String mode = 'general',
    String? userId,
  }) async {
    return await callFunction('ai_chat', {
      'message': message,
      'mode': mode,
      'user_id': userId ?? 'anon',
    });
  }

  // 2. Face Matching
  static Future<Map<String, dynamic>> faceMatch({
    required List<double> embedding,
  }) async {
    return await callFunction('face_match', {
      'embedding': embedding,
    });
  }

  // 3. OCR Enhancement
  static Future<Map<String, dynamic>> ocrEnhance({
    required String imageUrl,
    required String imageId,
  }) async {
    return await callFunction('ocr_enhance', {
      'image_url': imageUrl,
      'image_id': imageId,
    });
  }

  // 4. QR Recovery
  static Future<Map<String, dynamic>> qrRecovery({
    required String imageUrl,
  }) async {
    return await callFunction('qr_recovery', {
      'image_url': imageUrl,
    });
  }
}
