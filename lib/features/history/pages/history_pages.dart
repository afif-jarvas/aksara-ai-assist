import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/activity_provider.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  // Fungsi Translasi Kode ke Bahasa Manusia
  String _formatTitle(String key) {
    switch (key) {
      case 'ocr_scan': return 'Pemindaian Teks (OCR)';
      case 'object_detection': return 'Deteksi Objek';
      case 'face_recognition': return 'Pengenalan Wajah';
      case 'assist_title': return 'Chatbot Assistant';
      case 'qr_scan': return 'Pemindaian QR Code';
      case 'login': return 'Login Masuk';
      case 'music_generated': return 'Pembuatan Musik AI';
      default: return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatDescription(String key) {
    if (key.contains('assist')) return "Melakukan percakapan dengan asisten pintar";
    if (key.contains('ocr')) return "Mengubah gambar fisik menjadi teks digital";
    if (key.contains('face')) return "Verifikasi atau identifikasi wajah pengguna";
    if (key.contains('object')) return "Menganalisis objek dalam tangkapan kamera";
    if (key.contains('qr')) return "Membaca informasi dari kode QR";
    return "Aktivitas tercatat dalam sistem";
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'ocr_scan': return Icons.document_scanner_rounded;
      case 'object_detection': return Icons.image_search_rounded;
      case 'face_recognition': return Icons.face_retouching_natural_rounded;
      case 'assist_title': return Icons.chat_bubble_outline_rounded;
      case 'qr_scan': return Icons.qr_code_2_rounded;
      default: return Icons.history_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat Aktivitas", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: activities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Belum ada aktivitas", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final item = activities[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: Colors.grey[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIcon(item.titleKey), color: item.color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatTitle(item.titleKey),
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDescription(item.descKey),
                                style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm').format(item.timestamp),
                                style: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}