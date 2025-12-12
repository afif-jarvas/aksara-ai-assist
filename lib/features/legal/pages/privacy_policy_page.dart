import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/localization_service.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    
    // Warna teks yang adaptif
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[800];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(tr(ref, 'privacy'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              "1. Pengumpulan Data",
              "Kami mengumpulkan data yang Anda berikan secara langsung, seperti saat membuat akun, menggunakan fitur pengenalan wajah, atau berinteraksi dengan asisten AI. Data ini digunakan semata-mata untuk meningkatkan pengalaman Anda.",
              textColor, subtitleColor
            ),
            _buildSection(
              "2. Penggunaan Informasi",
              "Informasi Anda digunakan untuk:\n• Menyediakan fitur aplikasi\n• Memproses permintaan Anda\n• Meningkatkan keamanan akun",
              textColor, subtitleColor
            ),
            _buildSection(
              "3. Keamanan Data",
              "Kami menerapkan langkah-langkah keamanan teknis untuk melindungi data Anda dari akses yang tidak sah. Data sensitif seperti biometrik wajah dienkripsi.",
              textColor, subtitleColor
            ),
            _buildSection(
              "4. Hak Pengguna",
              "Anda memiliki hak untuk mengakses, memperbaiki, atau menghapus data pribadi Anda kapan saja melalui pengaturan akun.",
              textColor, subtitleColor
            ),
            const SizedBox(height: 20),
            Text(
              "Terakhir diperbarui: 12 Desember 2025",
              style: GoogleFonts.sourceCodePro(fontSize: 12, color: isDark ? Colors.grey : Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, Color titleColor, Color? contentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: contentColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}