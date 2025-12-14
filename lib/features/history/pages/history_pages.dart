import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/activity_provider.dart';
import '../../../core/localization_service.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  /// Helper untuk translasi yang aman (fallback ke key jika null)
  String _safeTr(WidgetRef ref, String key, String fallback) {
    final translated = tr(ref, key);
    if (translated == null || translated == key) {
      return fallback;
    }
    return translated;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activityProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLocaleCode = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background transparan
      appBar: AppBar(
        title: Text(
          _safeTr(ref, 'history', 'Riwayat'), 
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (activities.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.delete_sweep_rounded, 
                color: isDark ? Colors.redAccent : Colors.red,
              ),
              tooltip: _safeTr(ref, 'clear_history', 'Hapus Semua'),
              onPressed: () => _showClearDialog(context, ref, isDark),
            ),
        ],
      ),
      
      body: activities.isEmpty
          ? _buildEmptyState(context, isDark, ref)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final item = activities[index];
                return _buildHistoryItem(context, item, isDark, ref, index, currentLocaleCode)
                    .animate(delay: (50 * index).ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: 0.2, curve: Curves.easeOut);
              },
            ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context, 
    ActivityItem item, 
    bool isDark, 
    WidgetRef ref, 
    int index,
    String localeCode
  ) {
    // Glassmorphism effect colors
    final bgColor = isDark 
        ? Colors.white.withOpacity(0.05) 
        : Colors.white.withOpacity(0.6);
    final borderColor = isDark 
        ? Colors.white.withOpacity(0.1) 
        : Colors.white.withOpacity(0.4);

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(activityProvider.notifier).removeAt(index);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          title: Text(
            // Gunakan _safeTr agar jika key hilang, tetap ada teks default
            _safeTr(ref, item.titleKey, item.titleKey), 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                _safeTr(ref, item.descKey, "Aktivitas baru"), 
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, 
                    size: 12, 
                    color: isDark ? Colors.white38 : Colors.grey
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(item.timestamp, locale: localeCode),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.blue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_toggle_off_rounded,
              size: 80,
              color: isDark ? Colors.white24 : Colors.blue.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _safeTr(ref, 'no_history', "Belum ada riwayat"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _safeTr(ref, 'start_explore', "Mulai gunakan fitur AI sekarang!"),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).scale(),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          // Judul Dialog diterjemahkan
          _safeTr(ref, 'clear_history', "Hapus Riwayat?"), 
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          // Konten Dialog diterjemahkan
          _safeTr(ref, 'clear_history_confirm', "Semua catatan aktivitas Anda akan dihapus permanen."),
          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            // Tombol Batal diterjemahkan
            child: Text(tr(ref, 'cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ref.read(activityProvider.notifier).clearHistory();
              Navigator.pop(context);
            },
            // Tombol Hapus diterjemahkan
            child: Text(tr(ref, 'delete')),
          ),
        ],
      ),
    );
  }
}