import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/edge_function_service.dart';

class FaceRecognitionService extends StateNotifier<AsyncValue<void>> {
  FaceRecognitionService() : super(const AsyncData(null));

  // Fungsi Utama: Analisa Wajah
  Future<Map<String, dynamic>> analyzeFace(XFile image) async {
    state = const AsyncLoading();
    try {
      // 1. Kompresi Ringan (Opsional tapi disarankan agar upload cepat)
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      // 2. Panggil Edge Function 'face_analyze'
      final result = await EdgeFunctionService.callFunction('face_analyze', {
        'image': base64Image,
      });
      
      state = const AsyncData(null);
      return result;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  // Fungsi Login (Validasi Wajah Sederhana)
  Future<bool> loginWithFace(XFile image) async {
    try {
      final result = await analyzeFace(image);
      // Jika AI berhasil mendeteksi Gender/Umur, berarti wajah valid
      if (result.containsKey('gender') || result.containsKey('age_range')) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final faceRecognitionServiceProvider =
    StateNotifierProvider<FaceRecognitionService, AsyncValue<void>>((ref) {
  return FaceRecognitionService();
});