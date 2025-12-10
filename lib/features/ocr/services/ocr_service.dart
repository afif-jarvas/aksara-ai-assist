import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
// Import config untuk Tesseract
import 'package:tesseract_ocr/ocr_engine_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Sesuaikan path import ini dengan struktur project Anda
import '../../../core/edge_function_service.dart';
import '../../../core/supabase_client.dart';

part 'ocr_service.g.dart';

@riverpod
class OCRService extends _$OCRService {
  // Inisialisasi TextRecognizer untuk skrip Latin
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<bool> build() async => true;

  Future<Map<String, dynamic>> processImage(XFile imageFile) async {
    try {
      // 1. OPTIMASI GAMBAR (Resize jika terlalu besar agar OCR lebih cepat)
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) throw Exception("Gagal membaca gambar");

      String imagePathToUse = imageFile.path;

      if (originalImage.width > 800) {
        final img.Image resizedImage =
            img.copyResize(originalImage, width: 800);
        final directory = await getTemporaryDirectory();
        final fileName =
            'ocr_resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File tempFile = File('${directory.path}/$fileName');
        await tempFile.writeAsBytes(img.encodeJpg(resizedImage, quality: 85));
        imagePathToUse = tempFile.path;
      }

      // 2. PROSES OCR UTAMA (Google ML Kit)
      final inputImage = InputImage.fromFilePath(imagePathToUse);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      String finalText = recognizedText.text;

      // 3. FALLBACK (Tesseract) - Opsional
      // Jika ML Kit gagal (kosong), coba gunakan Tesseract
      if (finalText.trim().isEmpty) {
        try {
          finalText = await TesseractOcr.extractText(
            imagePathToUse,
            config: OCRConfig(
              language: 'ind+eng',
              options: {
                "psm": "3",
                "preserve_interword_spaces": "1",
              },
            ),
          );
        } catch (e) {
          print("Tesseract fallback failed: $e");
        }
      }

      if (finalText.trim().isEmpty) {
        return {'mlkit_text': "Tidak ada teks terdeteksi dalam gambar."};
      }

      // 4. AI ENHANCEMENT (Supabase Edge Function)
      // Jika ini gagal (misal tidak ada internet), kita tetap return teks asli (mlkit_text)
      String? enhancedText;
      try {
        final enhancementResult =
            await EdgeFunctionService.callFunction('ai_chat', {
          'message':
              "Rapikan teks hasil OCR berikut (perbaiki typo dan format):\n$finalText",
          'mode': 'general'
        });
        enhancedText = enhancementResult['text'];
      } catch (e) {
        print("AI Enhancement skipped: $e");
        enhancedText =
            "Fitur perapihan AI membutuhkan koneksi internet/setup backend.";
      }

      // Upload history (Fire and forget)
      _uploadToHistory(File(imagePathToUse));

      return {
        'mlkit_text': finalText,
        'enhanced_text': enhancedText,
      };
    } catch (e) {
      print("OCR Error: $e");
      return {'mlkit_text': "Gagal memproses: $e"};
    }
  }

  void _uploadToHistory(File file) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id ?? 'anonymous';
      final fileName = 'ocr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Pastikan bucket 'ocr_images' sudah dibuat di Supabase Storage
      await SupabaseService.client.storage.from('ocr_images').upload(
            '$userId/$fileName',
            file,
            fileOptions: const FileOptions(upsert: false),
          );
    } catch (_) {
      // Ignore upload errors
    }
  }

  // Penting: Tutup resource saat tidak dipakai
  void dispose() {
    _textRecognizer.close();
  }
}
