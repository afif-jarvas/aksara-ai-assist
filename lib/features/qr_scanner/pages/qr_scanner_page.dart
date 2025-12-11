import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../services/qr_scanner_service.dart';
import '../../../core/localization_service.dart';

class QRScannerPage extends ConsumerStatefulWidget {
  const QRScannerPage({super.key});
  @override
  ConsumerState<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends ConsumerState<QRScannerPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isRecovering = false;
  String? _lastResult;
  bool _isDialogShowing = false;

  void _onScanSuccess(Code? result) {
    if (_isDialogShowing) return;
    if (result != null && result.text != null) {
      if (result.text == _lastResult) return;
      setState(() => _lastResult = result.text);
      _handleSmartResult(result.text!, result.format?.name ?? "QR Code");
    }
  }

  void _handleSmartResult(String code, String type) {
    setState(() => _isDialogShowing = true);
    // ... logic deteksi tipe (QRIS/WA/dll) sama seperti sebelumnya ...
    bool isQRIS =
        code.contains("000201") || code.toLowerCase().contains("qris");
    bool isUrl = (code.startsWith("http") ||
        code.startsWith("www.")); // simplified logic

    showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => _buildSmartSheet(code, type, isQRIS, isUrl))
        .then((_) {
      if (mounted) {
        setState(() {
          _isDialogShowing = false;
          _lastResult = null;
        });
      }
    });
  }

  Widget _buildSmartSheet(String code, String type, bool isQRIS, bool isUrl) {
    String title = tr(ref, 'qr_result');
    String btnLabel = tr(ref, 'qr_copy');
    IconData btnIcon = Icons.copy;

    if (isQRIS) {
      title = "QRIS";
      btnLabel = tr(ref, 'qr_open');
      btnIcon = Icons.payment;
    } else if (isUrl) {
      title = "Link";
      btnLabel = tr(ref, 'qr_open');
      btnIcon = Icons.open_in_browser;
    }

    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      padding: const EdgeInsets.all(24),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text(title,
                style: GoogleFonts.exo2(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12)),
                child: Text(code,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.courierPrime(
                        fontSize: 13, color: Colors.black87))),
            const SizedBox(height: 25),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      Navigator.pop(context);
                      _showSnackBar(tr(ref, 'text_copied'), Colors.green);
                    },
                    icon: Icon(btnIcon, color: Colors.white),
                    label: Text(btnLabel,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))))),
          ]),
    );
  }

  Future<void> _pickImageAndRecover() async {
    setState(() => _isRecovering = true);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final result = await ref
            .read(qRScannerServiceProvider.notifier)
            .recoverQRCode(image);
        if (result.containsKey('decoded_text')) {
          _handleSmartResult(result['decoded_text'], result['method']);
        } else {
          _showSnackBar(result['error'] ?? tr(ref, 'qr_fail'), Colors.red);
        }
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      setState(() => _isRecovering = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
          onTap: onTap,
          child: Column(children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                    color: Colors.white24, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white)),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12))
          ]));

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider); // Listen Language Change
    return Scaffold(
      body: Stack(children: [
        ReaderWidget(
            onScan: _onScanSuccess,
            resolution: ResolutionPreset.high,
            showFlashlight: false,
            showGallery: false,
            showToggleCamera: false,
            cropPercent: 0.7),
        SafeArea(
            child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context))),
                    GlassmorphicContainer(
                        width: 160,
                        height: 40,
                        borderRadius: 20,
                        blur: 10,
                        alignment: Alignment.center,
                        border: 1,
                        linearGradient: LinearGradient(colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.05)
                        ]),
                        borderGradient: LinearGradient(colors: [
                          Colors.white.withOpacity(0.5),
                          Colors.white.withOpacity(0.1)
                        ]),
                        child: Text(tr(ref, 'qr_title'),
                            style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2))),
                    const SizedBox(width: 40)
                  ])),
          const Spacer(),
          Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
              color: Colors.black.withOpacity(0.6),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _actionBtn(Icons.flash_on, tr(ref, 'qr_flash'), () {}),
                    GestureDetector(
                        onTap: _isRecovering ? null : _pickImageAndRecover,
                        child: Column(children: [
                          Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                  color: Colors.purpleAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.purple.withOpacity(0.5),
                                        blurRadius: 15)
                                  ]),
                              child: _isRecovering
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.image_search,
                                      color: Colors.white, size: 28)),
                          const SizedBox(height: 8),
                          Text(tr(ref, 'qr_gallery'),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12))
                        ])),
                    _actionBtn(Icons.history, tr(ref, 'history'), () {})
                  ]))
        ]))
      ]),
    );
  }
}
