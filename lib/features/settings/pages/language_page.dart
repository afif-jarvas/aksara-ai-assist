import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization_service.dart'; // Sesuaikan path ini jika merah

class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ambil Theme Data dari context (ini yang mengatur Light/Dark mode)
    final theme = Theme.of(context);
    
    // 2. Ambil Locale saat ini dari Riverpod Provider
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      // KUNCI PERBAIKAN: Paksa background mengikuti theme.scaffoldBackgroundColor
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Menggunakan fungsi tr() dari localization_service.dart untuk judul
        title: Text(
          tr(ref, 'language'), 
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        // Pastikan AppBar transparan/putih sesuai theme
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        // Icon back button mengikuti theme
        iconTheme: theme.iconTheme,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Opsi Bahasa Indonesia
          _buildLanguageOption(
            context,
            ref,
            title: "Bahasa Indonesia",
            flagEmoji: "🇮🇩",
            languageCode: 'id',
            isSelected: currentLocale.languageCode == 'id',
          ),
          const SizedBox(height: 16),
          
          // Opsi English
          _buildLanguageOption(
            context,
            ref,
            title: "English",
            flagEmoji: "🇺🇸",
            languageCode: 'en',
            isSelected: currentLocale.languageCode == 'en',
          ),
          
          const SizedBox(height: 16),

          // Opsi Chinese (Sesuai Localization Service Anda)
          _buildLanguageOption(
            context,
            ref,
            title: "中文 (Chinese)",
            flagEmoji: "🇨🇳",
            languageCode: 'zh',
            isSelected: currentLocale.languageCode == 'zh',
          ),

           const SizedBox(height: 16),

          // Opsi Japanese (Sesuai Localization Service Anda)
          _buildLanguageOption(
            context,
            ref,
            title: "日本語 (Japanese)",
            flagEmoji: "🇯🇵",
            languageCode: 'ja',
            isSelected: currentLocale.languageCode == 'ja',
          ),

           const SizedBox(height: 16),

          // Opsi Korean (Sesuai Localization Service Anda)
          _buildLanguageOption(
            context,
            ref,
            title: "한국어 (Korean)",
            flagEmoji: "🇰🇷",
            languageCode: 'ko',
            isSelected: currentLocale.languageCode == 'ko',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String flagEmoji,
    required String languageCode,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        // UPDATE STATE RIVERPOD
        ref.read(localeProvider.notifier).state = Locale(languageCode);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          // Logic Warna: Gunakan cardColor dari AppTheme (0xFFF5F5F5 saat Light)
          color: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : theme.cardColor, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.dividerColor.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Text(
              flagEmoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  // Text otomatis hitam/putih mengikuti theme
                  color: theme.textTheme.bodyLarge?.color, 
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor,
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}