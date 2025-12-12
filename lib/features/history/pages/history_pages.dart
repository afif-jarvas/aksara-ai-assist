import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization_service.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Dummy Data untuk testing UI
    final List<Map<String, dynamic>> historyItems = [
      {
        'action': tr(ref, 'log_ocr_title'), // Menggunakan translate key
        'desc': tr(ref, 'log_ocr_desc'),
        'date': '12 Dec 2025, 10:30',
        'icon': Icons.document_scanner,
        'color': Colors.green,
      },
      {
        'action': tr(ref, 'log_face_title'),
        'desc': tr(ref, 'log_face_desc'),
        'date': '11 Dec 2025, 14:15',
        'icon': Icons.face,
        'color': Colors.orange,
      },
      {
        'action': tr(ref, 'log_music_title'),
        'desc': tr(ref, 'log_music_desc'),
        'date': '10 Dec 2025, 09:00',
        'icon': Icons.music_note,
        'color': Colors.purple,
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tr(ref, 'history')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: historyItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    tr(ref, 'no_history'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                final item = historyItems[index];
                return Card(
                  // Menggunakan cardColor yang sudah diset di app_theme.dart (kontras di dark mode)
                  color: theme.cardColor,
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['icon'],
                        color: item['color'],
                      ),
                    ),
                    title: Text(
                      item['action'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        // Warna teks mengikuti onSurface (Hitam di light, Putih di dark)
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['desc'], style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(
                          item['date'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    onTap: () {
                      // Handle tap detail history
                    },
                  ),
                );
              },
            ),
    );
  }
}