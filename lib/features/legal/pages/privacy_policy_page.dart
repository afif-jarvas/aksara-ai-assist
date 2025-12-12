import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/localization_service.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black; // Hitam
    final subtitleColor = isDark ? Colors.white70 : Colors.black87; // Abu gelap hampir hitam
    final currentFont = ref.watch(fontFamilyProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          tr(ref, 'privacy'),
          style: GoogleFonts.getFont(currentFont, fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr(ref, 'pp_last_updated'),
                      style: GoogleFonts.sourceCodePro(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            _buildSection(tr(ref, 'pp_1_title'), tr(ref, 'pp_1_content'), textColor, subtitleColor, currentFont),
            _buildSection(tr(ref, 'pp_2_title'), tr(ref, 'pp_2_content'), textColor, subtitleColor, currentFont),
            _buildSection(tr(ref, 'pp_3_title'), tr(ref, 'pp_3_content'), textColor, subtitleColor, currentFont),
            _buildSection(tr(ref, 'pp_4_title'), tr(ref, 'pp_4_content'), textColor, subtitleColor, currentFont),
            _buildSection(tr(ref, 'pp_5_title'), tr(ref, 'pp_5_content'), textColor, subtitleColor, currentFont),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                "© 2025 Aksara AI Team",
                style: GoogleFonts.getFont(currentFont, color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, Color titleColor, Color? contentColor, String font) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.getFont(font,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.getFont(font,
              fontSize: 15,
              color: contentColor,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
          const Divider(height: 30, color: Colors.transparent),
        ],
      ),
    );
  }
}