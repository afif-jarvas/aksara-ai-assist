import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // ✅ Pakai library baru ini

// State sederhana
class QRScannerState {
  final bool isProcessing;
  QRScannerState({this.isProcessing = false});
}

// Service LOKAL (Ganti logic ke MobileScanner / ML Kit)
class QRScannerService extends StateNotifier<QRScannerState> {
  QRScannerService() : super(QRScannerState());

  Future<Map<String, dynamic>> recoverQRCode(XFile imageFile) async {
    state = QRScannerState(isProcessing: true);

    try {
      // 1. Setup Controller MobileScanner
      // detectionSpeed: noDuplicates agar tidak membaca ganda
      // returnImage: false agar lebih hemat memori
      final controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        returnImage: false,
      );

      // 2. PROSES SCAN DARI FILE (Solusi Masalah Pencahayaan/Resolusi)
      // Fungsi 'analyzeImage' ini menggunakan Google ML Kit yang sangat pintar.
      // Dia bisa baca QR code meskipun miring, agak gelap, atau resolusi tinggi.
      final BarcodeCapture? capture =
          await controller.analyzeImage(imageFile.path);

      // 3. Matikan controller setelah selesai scan file
      controller.dispose();

      state = QRScannerState(isProcessing: false);

      // 4. Cek Hasil Scan
      if (capture != null && capture.barcodes.isNotEmpty) {
        final Barcode firstBarcode = capture.barcodes.first;

        // Ambil value-nya (rawValue atau displayValue)
        if (firstBarcode.rawValue != null) {
          return {
            'decoded_text': firstBarcode.rawValue,
            'method': 'Scan Galeri (Google ML Kit)',
          };
        }
      }

      // Jika tidak ditemukan barcode sama sekali
      return {
        'error': 'QR Code tidak ditemukan. Pastikan gambar memuat kode QR.'
      };
    } catch (e) {
      state = QRScannerState(isProcessing: false);
      return {'error': 'Gagal memproses gambar: ${e.toString()}'};
    }
  }
}

// Provider
final qRScannerServiceProvider =
    StateNotifierProvider<QRScannerService, QRScannerState>((ref) {
  return QRScannerService();
});
