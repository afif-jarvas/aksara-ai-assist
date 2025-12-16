import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/edge_function_service.dart';

class FaceRecognitionService extends StateNotifier<AsyncValue<void>> {
  FaceRecognitionService() : super(const AsyncData(null));

  // --- KODE LAMA (TIDAK SAYA UBAH) ---
  Future<Map<String, dynamic>> analyzeFace(XFile image) async {
    state = const AsyncLoading();
    try {
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Memanggil 'face_scan_final' sesuai kode asli Anda
      final result = await EdgeFunctionService.callFunction('face_scan_final', {
        'image': base64Image,
      });
      
      state = const AsyncData(null);
      return result;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  // --- KODE LAMA (TIDAK SAYA UBAH) ---
  // Tetap cek 'gender' sesuai logika asli Anda untuk menjaga kompatibilitas
  Future<bool> loginWithFace(XFile image) async {
    try {
      final result = await analyzeFace(image);
      return result.containsKey('gender');
    } catch (e) {
      return false;
    }
  }

  // --- PENAMBAHAN METODE BARU (Safe Additions) ---
  // Method ini WAJIB ditambahkan agar FaceEnrollmentPage tidak error
  
  Future<List<double>?> processImage(XFile image, int rotation) async {
    try {
      // Kita gunakan fungsi analyzeFace yang sudah ada
      final result = await analyzeFace(image);
      
      // Cek apakah API mengembalikan embedding (vektor wajah)
      if (result.containsKey('embedding')) {
        // Konversi dynamic list ke List<double> dengan aman
        return (result['embedding'] as List).map((e) => (e as num).toDouble()).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Method ini WAJIB ditambahkan untuk menyimpan data wajah
  Future<bool> registerFace(List<List<double>> embeddings) async {
    state = const AsyncLoading();
    try {
      await EdgeFunctionService.callFunction('face_register', {
        'embeddings': embeddings,
      });
      
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final faceRecognitionServiceProvider =
    StateNotifierProvider<FaceRecognitionService, AsyncValue<void>>((ref) {
  return FaceRecognitionService();
});