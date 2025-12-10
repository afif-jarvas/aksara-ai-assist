import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Import Service OCR yang dibuat di atas
import '../services/ocr_service.dart';
// Import Localization (dari file yang Anda upload sebelumnya)
import '../../../core/localization_service.dart';

class OCRPage extends ConsumerStatefulWidget {
  const OCRPage({super.key});
  @override
  ConsumerState<OCRPage> createState() => _OCRPageState();
}

class _OCRPageState extends ConsumerState<OCRPage> {
  final ImagePicker _picker = ImagePicker();
  String? _rawText;
  String? _enhancedText;
  String? _imagePath;
  bool _isProcessing = false;

  Future<void> _pickAndProcessImage(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _rawText = null;
      _enhancedText = null;
    });

    try {
      // 1. Ambil Gambar
      final image = await _picker.pickImage(source: source);
      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      setState(() => _imagePath = image.path);

      // 2. Panggil Service
      final service = ref.read(oCRServiceProvider.notifier);
      final result = await service.processImage(image);

      // 3. Update UI dengan Hasil
      setState(() {
        _rawText = result['mlkit_text'] as String?;
        _enhancedText = result['enhanced_text'] as String?;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch locale agar rebuild saat bahasa ganti
    ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            tr(ref,
                'ocr_title'), // Pastikan key 'ocr_title' ada di localization
            style: GoogleFonts.oswald(color: Colors.black, letterSpacing: 1.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // AREA PREVIEW GAMBAR
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12)),
              child: _imagePath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Icon(Icons.document_scanner_outlined,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text(
                              tr(ref, 'ocr_hint') == 'ocr_hint'
                                  ? 'Ambil foto berisi teks...'
                                  : tr(ref, 'ocr_hint'),
                              style: TextStyle(color: Colors.grey[500])),
                        ])
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          Image.file(File(_imagePath!), fit: BoxFit.contain)),
            ),
          ),

          // AREA HASIL TEKS
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5))
                  ]),
              child: _isProcessing
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black))
                  : SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // HASIL AI (DIRAPIKAN)
                          if (_enhancedText != null) ...[
                            Row(children: [
                              const Icon(Icons.auto_awesome,
                                  color: Colors.purple, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                  tr(ref, 'ocr_enhanced') == 'ocr_enhanced'
                                      ? 'AI Enhanced'
                                      : tr(ref, 'ocr_enhanced'),
                                  style: GoogleFonts.exo2(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple))
                            ]),
                            const SizedBox(height: 10),
                            SelectableText(_enhancedText!,
                                style: GoogleFonts.merriweather(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Colors.black87)),
                            const Divider(height: 30),
                          ],

                          // HASIL MENTAH (RAW OCR)
                          if (_rawText != null) ...[
                            Text(
                                tr(ref, 'ocr_raw') == 'ocr_raw'
                                    ? 'Teks Mentah'
                                    : tr(ref, 'ocr_raw'),
                                style: GoogleFonts.exo2(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                    fontSize: 12)),
                            const SizedBox(height: 5),
                            SelectableText(_rawText!,
                                style: GoogleFonts.courierPrime(
                                    fontSize: 12, color: Colors.grey[700])),
                          ]
                        ])),
            ),
          ),
        ],
      ),

      // TOMBOL AKSI
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Row(children: [
          Expanded(
              child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _pickAndProcessImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, color: Colors.black),
                  label: Text("Galeri",
                      style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0))),
          const SizedBox(width: 15),
          Expanded(
              child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _pickAndProcessImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: Text("Kamera",
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 5))),
        ]),
      ),
    );
  }
}
