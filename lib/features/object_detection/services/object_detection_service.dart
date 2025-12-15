import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ObjectDetectionService {
  late ObjectDetector _objectDetector;
  late ImageLabeler _imageLabeler;
  bool _isBusy = false;

  ObjectDetectionService() {
    // 1. DETEKTOR REAL-TIME (Kotak Hijau)
    // Mode Stream agar cepat, hanya untuk tracking posisi
    final objectOptions = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: objectOptions);

    // 2. DETEKTOR DETAIL (Untuk Tombol Capture)
    // Gunakan ImageLabeler agar bisa mendeteksi "Mouse", "Mask", "Fan".
    // Threshold 0.5 (50%) agar lebih sensitif mendeteksi benda kecil.
    final labelerOptions = ImageLabelerOptions(confidenceThreshold: 0.5); 
    _imageLabeler = ImageLabeler(options: labelerOptions);
  }

  // --- Fungsi Stream (Cepat, untuk UI Kamera) ---
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

  // --- Fungsi Capture (Detail, untuk Modal List) ---
  Future<List<String>> analyzeImageLabels(CameraImage image, int sensorOrientation) async {
    final inputImage = _inputImageFromCameraImage(image, sensorOrientation);
    if (inputImage == null) return [];

    try {
      // ImageLabeler memberikan list benda detail (Laptop, Mouse, Fan)
      final labels = await _imageLabeler.processImage(inputImage);
      
      // Ambil teks labelnya saja
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