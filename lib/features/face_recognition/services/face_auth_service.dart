import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FaceAuthService {
  late FaceDetector _faceDetector;
  Interpreter? _interpreter;
  bool _isBusy = false;

  FaceAuthService() {
    _initialize();
  }

  void _initialize() async {
    // Setting deteksi wajah akurasi tinggi
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      landmarkMode: FaceLandmarkMode.all,
      classificationMode: FaceClassificationMode.all,
    );
    _faceDetector = FaceDetector(options: options);
    
    try {
      // Load model MobileFaceNet untuk pengenalan wajah
      _interpreter = await Interpreter.fromAsset('assets/models/face_recognition.tflite');
    } catch (e) {
      print('Warning: TFLite model not found. Using Mock Data for UI Testing.');
    }
  }

  // --- 1. PROSES GAMBAR DARI KAMERA MENJADI EMBEDDING (ANGKA) ---
  Future<List<double>?> processImage(CameraImage image, int rotation) async {
    if (_isBusy) return null;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image, rotation);
      if (inputImage == null) return null;

      final faces = await _faceDetector.processImage(inputImage);
      
      // Harus ada wajah terdeteksi
      if (faces.isEmpty) return null;
      final face = faces.first;

      // TODO: Di implementasi nyata, lakukan cropping wajah & resize ke 112x112
      // lalu masukkan ke _interpreter.run().
      
      // MOCK DATA (Agar kode jalan lancar di HP Anda sekarang)
      // Simulasi array embedding 192 dimensi
      await Future.delayed(const Duration(milliseconds: 100)); // Simulasi proses berat
      return List.generate(192, (index) => Random().nextDouble());

    } catch (e) {
      return null;
    } finally {
      _isBusy = false;
    }
  }

  // --- 2. REGISTER WAJAH (ENROLLMENT 10x) ---
  // Menyimpan rata-rata embedding ke Firebase Firestore
  Future<bool> registerFace(List<List<double>> samples) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || samples.isEmpty) return false;

    // Hitung Rata-rata (Averaging) untuk akurasi tinggi
    List<double> avgEmbedding = List.filled(192, 0.0);
    for (var sample in samples) {
      for (int i = 0; i < 192; i++) {
        avgEmbedding[i] += sample[i];
      }
    }
    for (int i = 0; i < 192; i++) {
      avgEmbedding[i] /= samples.length;
    }

    try {
      // Simpan ke Firestore di collection 'users'
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'face_embedding': avgEmbedding,
        'has_face_id': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print("Firestore Error: $e");
      return false;
    }
  }

  // --- 3. VERIFIKASI WAJAH (LOGIN) ---
  // Membandingkan wajah kamera dengan data di Firestore
  Future<bool> verifyFace(List<double> newEmbedding) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      if (!doc.exists || !doc.data()!.containsKey('face_embedding')) {
        return false; // Belum setup Face ID
      }

      final List<dynamic> storedData = doc.data()!['face_embedding'];
      final List<double> storedEmbedding = storedData.cast<double>();

      // Hitung Jarak Euclidean (Semakin kecil = semakin mirip)
      double distance = 0.0;
      for (int i = 0; i < newEmbedding.length; i++) {
        distance += pow((newEmbedding[i] - storedEmbedding[i]), 2);
      }
      distance = sqrt(distance);

      print("Jarak Kemiripan: $distance");
      
      // Threshold (Batas toleransi)
      // < 1.0 biasanya dianggap orang yang sama untuk MobileFaceNet
      // Karena ini Mock Data, kita return true dulu agar Anda bisa tes flow Login
      return true; 
      // return distance < 1.0; (Gunakan ini nanti jika model TFLite sudah aktif)

    } catch (e) {
      return false;
    }
  }

  // --- HELPER ---
  InputImage? _inputImageFromCameraImage(CameraImage image, int rotation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    final allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final size = Size(image.width.toDouble(), image.height.toDouble());
    final meta = InputImageMetadata(
      size: size,
      rotation: InputImageRotationValue.fromRawValue(rotation) ?? InputImageRotation.rotation0deg,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );
    return InputImage.fromBytes(bytes: bytes, metadata: meta);
  }
  
  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
  }
}