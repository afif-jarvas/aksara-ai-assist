import 'dart:io'; // Tambahan untuk File
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart'; // Tambahan untuk Galeri
import '../../../core/localization_service.dart';

class QRScannerPage extends ConsumerStatefulWidget {
  const QRScannerPage({super.key});

  @override
  ConsumerState<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends ConsumerState<QRScannerPage> with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  bool _isScanning = true; 
  Barcode? _result;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  // --- LOGIC: PROSES HASIL SCAN (Dari Kamera atau Galeri) ---
  void _handleBarcode(Barcode barcode) {
    if (barcode.rawValue != null) {
      setState(() {
        _isScanning = false;
        _result = barcode;
      });
      
      // Stop kamera agar hemat resource saat modal muncul
      _controller.stop();
      
      // Tampilkan Modal Hasil
      _showResultModal(barcode.rawValue!);
    }
  }

  // --- EVENT: DETEKSI LIVE CAMERA ---
  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      _handleBarcode(barcode);
      break; // Ambil 1 saja
    }
  }

  // --- EVENT: AMBIL DARI GALERI ---
  Future<void> _pickImageFromGallery() async {
    // 1. Pick Image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // 2. Stop Scanning sementara (biar gak bentrok)
    setState(() => _isScanning = false);

    try {
      // 3. Analisa Gambar dengan Mobile Scanner
      final BarcodeCapture? capture = await _controller.analyzeImage(image.path);

      if (capture != null && capture.barcodes.isNotEmpty) {
        // Jika ketemu, proses sama seperti scan kamera
        _handleBarcode(capture.barcodes.first);
      } else {
        // Jika gagal/tidak ada QR
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(ref, 'qr_fail')), // "Gagal membaca QR / Tidak ditemukan"
              backgroundColor: Colors.redAccent,
            ),
          );
          // Resume scanning
          setState(() => _isScanning = true);
        }
      }
    } catch (e) {
      debugPrint("Error analyzing image: $e");
      if (mounted) {
        setState(() => _isScanning = true);
      }
    }
  }

  // --- UI MODAL HASIL ---
  void _showResultModal(String code) {
    final isDark = ref.read(themeProvider) == ThemeMode.dark;
    final bool isUrl = Uri.tryParse(code)?.hasAbsolutePath ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50, height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5), 
                  borderRadius: BorderRadius.circular(10)
                ),
              ),
            ),
            const SizedBox(height: 25),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUrl ? Colors.blueAccent.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUrl ? Icons.link : Icons.text_fields, 
                    color: isUrl ? Colors.blueAccent : Colors.orangeAccent, 
                    size: 30
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(ref, 'qr_result_found'), 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87
                      ),
                    ),
                    Text(
                      isUrl ? tr(ref, 'qr_type_link') : tr(ref, 'qr_type_text'), 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, 
                        color: Colors.grey
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12)
              ),
              child: SelectableText(
                code,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 14, 
                  color: isDark ? Colors.white70 : Colors.black87
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr(ref, 'qr_copied')))
                        );
                      },
                      icon: const Icon(Icons.copy, size: 20),
                      label: Text(tr(ref, 'qr_btn_copy')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),

                if (isUrl)
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchURL(code),
                        icon: const Icon(Icons.open_in_new, size: 20, color: Colors.white),
                        label: Text(tr(ref, 'qr_btn_open'), style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ).whenComplete(() {
      setState(() {
        _isScanning = true;
        _result = null;
      });
      _controller.start();
    });
  }

  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr(ref, 'qr_invalid_url')))
          );
        }
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
      width: 280,
      height: 280,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Scanner View
          MobileScanner(
            controller: _controller,
            scanWindow: scanWindow,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(child: Text("Camera Error: $error", style: const TextStyle(color: Colors.white)));
            },
          ),

          // 2. Overlay
          CustomPaint(
            painter: ScannerOverlayPainter(scanWindow),
            child: Container(),
          ),

          // 3. Header
          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                GlassmorphicContainer(
                  width: 200, height: 45,
                  borderRadius: 25, blur: 10, alignment: Alignment.center,
                  border: 1,
                  linearGradient: LinearGradient(colors: [Colors.black54, Colors.black26]),
                  borderGradient: LinearGradient(colors: [Colors.white24, Colors.white10]),
                  child: Text(
                    tr(ref, 'qr_page_title'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          // 4. Instruksi & Controls (Flash + Gallery)
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tr(ref, 'qr_hint_box'),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 30),
                
                // --- BARIS TOMBOL: Flash & Gallery ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // TOMBOL FLASH
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _controller,
                      builder: (context, state, child) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24)
                          ),
                          child: IconButton(
                            iconSize: 32,
                            color: isTorchOn ? Colors.amber : Colors.white,
                            icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
                            onPressed: () => _controller.toggleTorch(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(width: 40), // Jarak antar tombol

                    // TOMBOL GALERI
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24)
                      ),
                      child: IconButton(
                        iconSize: 32,
                        color: Colors.white,
                        icon: const Icon(Icons.image_search_rounded),
                        onPressed: _pickImageFromGallery, // Panggil fungsi galeri
                      ),
                    ),
                  ],
                ),
                // Label Tombol
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60, 
                      child: Text(tr(ref, 'qr_flash'), textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12))
                    ),
                    const SizedBox(width: 40),
                    SizedBox(
                      width: 60, 
                      child: Text(tr(ref, 'gallery'), textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12))
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- PAINTER UNTUK OVERLAY KOTAK ---
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlayPainter(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(20)));

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6) 
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut; 

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black.withOpacity(0.5));
    canvas.drawPath(cutoutPath, backgroundPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(20)), borderPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}