import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/localization_service.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/animated_background.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    // Warna Kontras
    final Color titleColor = isDark ? Colors.cyanAccent : Colors.blueAccent;
    final Color headingColor = isDark ? Colors.white : Colors.black87;
    final Color bodyColor = isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8);
    final Color cardBg = isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.5);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: headingColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr(ref, 'privacy_title'), // Key: "Kebijakan Privasi"
          style: GoogleFonts.plusJakartaSans(
            color: headingColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: AnimatedBackground(isDark: isDark, child: const SizedBox()),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.cyanAccent.withOpacity(0.1) : Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.cyanAccent.withOpacity(0.3) : Colors.blueAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, size: 32, color: titleColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            tr(ref, 'privacy_subtitle'), // Key: "Kami menjaga privasi Anda"
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Policy Content Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          title: tr(ref, 'privacy_collection_title'), // Key: "Pengumpulan Data"
                          content: tr(ref, 'privacy_collection_content'), // Key: "Kami mengumpulkan..."
                          titleColor: headingColor,
                          bodyColor: bodyColor,
                        ),
                        const Divider(height: 32),
                        _buildSection(
                          title: tr(ref, 'privacy_usage_title'), // Key: "Penggunaan Data"
                          content: tr(ref, 'privacy_usage_content'), // Key: "Data digunakan untuk..."
                          titleColor: headingColor,
                          bodyColor: bodyColor,
                        ),
                        const Divider(height: 32),
                        _buildSection(
                          title: tr(ref, 'privacy_security_title'), // Key: "Keamanan"
                          content: tr(ref, 'privacy_security_content'), // Key: "Kami menggunakan enkripsi..."
                          titleColor: headingColor,
                          bodyColor: bodyColor,
                        ),
                        const Divider(height: 32),
                        _buildSection(
                          title: tr(ref, 'privacy_contact_title'), // Key: "Hubungi Kami"
                          content: tr(ref, 'privacy_contact_content'), // Key: "Jika ada pertanyaan..."
                          titleColor: headingColor,
                          bodyColor: bodyColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color titleColor,
    required Color bodyColor,
  }) {
    return Column(
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
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            height: 1.6,
            color: bodyColor,
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}