import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/face_recognition_service.dart';
import '../../../core/localization_service.dart';
import '../../../core/activity_provider.dart';

class FaceRecognitionPage extends ConsumerStatefulWidget {
  const FaceRecognitionPage({super.key});
  @override
  ConsumerState<FaceRecognitionPage> createState() =>
      _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends ConsumerState<FaceRecognitionPage> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;
  Map<String, dynamic>? _analysisResult; 
  bool _isProcessing = false;

  Future<void> _captureAndAnalyze() async {
    setState(() {
      _isProcessing = true;
      _analysisResult = null;
    });

    try {
      // Ambil Foto dari Kamera
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 500, // Resize agar tidak terlalu besar (hemat kuota & cepat)
        maxHeight: 500,
        imageQuality: 50,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }
      
      setState(() => _imagePath = image.path);
      
      // Kirim ke Service
      final service = ref.read(faceRecognitionServiceProvider.notifier);
      final result = await service.analyzeFace(image);
      
      // Catat History
      ref.read(activityProvider.notifier).addActivity(
        'face_title',
        'face_analyzing',
        Icons.face_retouching_natural, 
        Colors.orange
      );

      // Tampilkan Hasil
      setState(() {
        _analysisResult = result;
        _isProcessing = false;
      });

    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        // Tampilkan Error dengan Rapi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr(ref, 'error')}: $e'), 
            backgroundColor: Colors.red
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Watch Locale agar teks berubah realtime saat ganti bahasa
    ref.watch(localeProvider); 

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tr(ref, 'face_title')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              // --- 1. KOTAK PREVIEW FOTO ---
              Container(
                height: 350,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white24 : Colors.grey[300]!),
                  boxShadow: [
                    if (_imagePath != null)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8)
                      )
                  ]
                ),
                child: _imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.face_retouching_natural_rounded, 
                            size: 80, 
                            color: isDark ? Colors.white24 : Colors.grey[400]
                          ),
                          const SizedBox(height: 10),
                          Text(tr(ref, 'camera'), // Placeholder teks
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500])
                          )
                        ],
                      ),
              ),
              
              const SizedBox(height: 30),

              // --- 2. TOMBOL AKSI ---
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _captureAndAnalyze,
                    icon: _isProcessing 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                      : const Icon(Icons.camera_alt_rounded),
                    label: Text(
                      _isProcessing
                        ? tr(ref, 'face_analyzing') // "Menganalisa..."
                        : tr(ref, 'face_btn_capture'), // "Analisa Wajah"
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: theme.primaryColor.withOpacity(0.4)
                    )
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. KARTU HASIL ---
              if (_analysisResult != null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 5)
                      )
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle
                            ),
                            child: Icon(Icons.analytics_rounded, color: theme.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Text(tr(ref, 'face_result'), // "Hasil Analisa"
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 30, thickness: 1),
                      
                      // Gender
                      _buildInfoRow(
                        Icons.person_outline_rounded, 
                        'face_gender', 
                        _analysisResult!['gender'] ?? '-'
                      ),
                      
                      // Usia
                      _buildInfoRow(
                        Icons.cake_outlined, 
                        'face_age', 
                        _analysisResult!['age_range'] ?? '-'
                      ),
                      
                      // Etnis
                      _buildInfoRow(
                        Icons.public_rounded, 
                        'face_eth', 
                        _analysisResult!['ethnicity'] ?? '-'
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),
          ])),
    );
  }

  // Widget Baris Info
  Widget _buildInfoRow(IconData icon, String labelKey, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Translate Label (Judul)
                Text(tr(ref, labelKey), 
                  style: TextStyle(
                    fontSize: 12, 
                    color: isDark ? Colors.white38 : Colors.grey[600],
                    fontWeight: FontWeight.w500
                  )
                ),
                const SizedBox(height: 4),
                // Tampilkan Value dari Server (Tetap apa adanya)
                Text(value, 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87
                  )
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}