import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ObjectDetectionService {
  late ObjectDetector _objectDetector;
  late ImageLabeler _imageLabeler;
  bool _isBusy = false;

  ObjectDetectionService() {
    // 1. DETEKTOR STREAM (Kotak Hijau)
    // Mode Stream agar cepat, hanya untuk tracking posisi kasar di layar
    final objectOptions = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: objectOptions);

    // 2. DETEKTOR DETAIL (Untuk Tombol Capture & Translate)
    // Menggunakan ImageLabeler karena lebih kaya kosakata (Laptop, Mouse, Fan, dll)
    // Threshold 0.6 (60%) agar hasil yang muncul cukup akurat namun tidak terlalu pelit
    final labelerOptions = ImageLabelerOptions(confidenceThreshold: 0.6); 
    _imageLabeler = ImageLabeler(options: labelerOptions);
  }

  // --- Fungsi Stream (Cepat, untuk UI Kamera / Kotak Hijau) ---
  Future<List<DetectedObject>> processImage(CameraImage image, int sensorOrientation) async {
    if (_isBusy) return [];
    _isBusy = true;

    final inputImage = _inputImageFromCameraImage(image, sensorOrientation);
    if (inputImage == null) {
      _isBusy = false;
      return [];
    }

    try {
      final objects = await _objectDetector.processImage(inputImage);
      _isBusy = false;
      return objects;
    } catch (e) {
      _isBusy = false;
      return [];
    }
  }

  // --- Fungsi Capture (Detail, untuk Translate & Search) ---
  Future<List<String>> analyzeImageLabels(CameraImage image, int sensorOrientation) async {
    final inputImage = _inputImageFromCameraImage(image, sensorOrientation);
    if (inputImage == null) return [];

    try {
      // Proses menggunakan Image Labeler untuk hasil yang lebih spesifik
      final labels = await _imageLabeler.processImage(inputImage);
      
      // Ambil teks labelnya saja (Hasil masih Bahasa Inggris)
      // Contoh output: ['Laptop', 'Computer Keyboard', 'Space bar']
      return labels.map((e) => e.label).toList();
    } catch (e) {
      return [];
    }
  }

  void dispose() {
    _objectDetector.close();
    _imageLabeler.close();
  }

  // --- Helper Konversi Gambar ---
  InputImage? _inputImageFromCameraImage(CameraImage image, int sensorOrientation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final size = Size(image.width.toDouble(), image.height.toDouble());
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;

    final metadata = InputImageMetadata(
      size: size,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }
}