import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/edge_function_service.dart';

class FaceRecognitionService extends StateNotifier<AsyncValue<void>> {
  FaceRecognitionService() : super(const AsyncData(null));

  Future<Map<String, dynamic>> analyzeFace(XFile image) async {
    state = const AsyncLoading();
    try {
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      // --- PERUBAHAN: Panggil 'face_scan_final' ---
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

  Future<bool> loginWithFace(XFile image) async {
    try {
      final result = await analyzeFace(image);
      return result.containsKey('gender');
    } catch (e) {
      return false;
    }
  }
}

final faceRecognitionServiceProvider =
    StateNotifierProvider<FaceRecognitionService, AsyncValue<void>>((ref) {
  return FaceRecognitionService();
});