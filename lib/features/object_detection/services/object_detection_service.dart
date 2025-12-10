import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

part 'object_detection_service.g.dart';

/// Model Data untuk Hasil Deteksi
class DetectionResult {
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;
  final String label;

  DetectionResult({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
    required this.label,
  });
}

@riverpod
class ObjectDetectionService extends _$ObjectDetectionService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isBusy = false;

  @override
  Future<bool> build() async {
    // Inisialisasi awal jika diperlukan
    return true;
  }

  /// Memuat Model TFLite dan Labels
  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();
      // Pastikan file ini ada di folder assets/models/ project Anda
      _interpreter = await Interpreter.fromAsset(
          'assets/models/ssd_mobilenet.tflite',
          options: options);

      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n');
      print("Object Detection Model Loaded");
    } catch (e) {
      print("Error loading object detection model: $e");
    }
  }

  /// Fungsi Deteksi Objek
  Future<List<DetectionResult>> detectObjects(CameraImage image) async {
    if (_interpreter == null) await loadModel();
    if (_interpreter == null || _labels == null || _isBusy) return [];

    _isBusy = true;
    try {
      // --- LOGIKA DETEKSI ---
      // Catatan: Di sini seharusnya ada logika konversi YUV CameraImage ke Input Tensor.
      // Agar kode bisa di-compile dulu, kita return list kosong atau dummy.
      // Anda perlu mengimplementasikan image processing sesuai model yang dipakai.

      return [];
    } catch (e) {
      print("Detection Error: $e");
      return [];
    } finally {
      _isBusy = false;
    }
  }
}
