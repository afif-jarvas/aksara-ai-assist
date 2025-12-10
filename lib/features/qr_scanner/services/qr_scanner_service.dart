import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import '../../../core/edge_function_service.dart';
import '../../../core/supabase_client.dart';

part 'qr_scanner_service.g.dart';

@riverpod
class QRScannerService extends _$QRScannerService {
  @override
  Future<bool> build() async => true;

  Future<void> processScanResult(Code result) async {}

  Future<Map<String, dynamic>> recoverQRCode(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      if (!await file.exists()) {
        return {'error': "File tidak ditemukan."};
      }

      try {
        final result = await zx.readBarcodeImagePath(
          imageFile,
          DecodeParams(tryHarder: true, format: Format.any),
        );
        if (result.isValid && result.text != null && result.text!.isNotEmpty) {
          return {'decoded_text': result.text, 'method': 'Scan Galeri (Lokal)'};
        }
      } catch (_) {}

      final imageBytes = await imageFile.readAsBytes();
      if (imageBytes.lengthInBytes > 5 * 1024 * 1024)
        return {'error': "Ukuran Max 5MB."};

      final fileName = 'qr_rec_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final userId = SupabaseService.client.auth.currentUser?.id ?? 'anon';

      // PERBAIKAN DI SINI: Menggunakan SupabaseService.client atau Supabase.instance.client
      await SupabaseService.client.storage.from('qr_images').uploadBinary(
            '$userId/$fileName',
            imageBytes,
            fileOptions: const FileOptions(upsert: false),
          );

      final imageUrl = SupabaseService.client.storage
          .from('qr_images')
          .getPublicUrl('$userId/$fileName');

      final aiResult = await EdgeFunctionService.callFunction('ai_chat', {
        'message': """
Peran: Scanner Cerdas.
Tugas: Ekstrak data utama dari gambar ini.

PRIORITAS DETEKSI:
1. **Kode Mesin**: Jika ada QR Code, Barcode, atau QRIS, ambil isinya mentah-mentah.
2. **Instagram Nametag**: Jika ini kartu nama Instagram, cari teks USERNAME-nya.
   -> Outputkan format: https://instagram.com/USERNAME_YANG_DITEMUKAN
3. **Link/URL Tertulis**: Jika tidak ada kode, ambil link yang tertulis.

ATURAN ANTI-HALU:
- ABAIKAN teks promosi.
- HANYA output satu baris data.
- Jika kosong, jawab: GAGAL.
          """,
        'mode': 'general',
        'image_url': imageUrl
      });

      String text = aiResult['text']?.toString().trim() ?? "";

      if (text.isNotEmpty && !text.toUpperCase().contains('GAGAL')) {
        text = text.replaceAll('`', '').trim();
        if (text.startsWith("http")) text = text.replaceAll(" ", "");
        return {'decoded_text': text, 'method': 'AI Recovery (Cloud)'};
      } else {
        return {'error': "AI tidak dapat menemukan data valid."};
      }
    } catch (e) {
      if (e.toString().contains("Bucket not found")) {
        return {'error': "Bucket 'qr_images' belum dibuat di Supabase."};
      }
      return {'error': "Gagal memproses: $e"};
    }
  }
}
