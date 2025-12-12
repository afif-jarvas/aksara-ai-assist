import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../core/activity_provider.dart';
import '../../../core/localization_service.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  String _formatTitle(WidgetRef ref, String key) {
    switch (key) {
      case 'ocr_scan': return tr(ref, 'scan_ocr');
      case 'object_detection': return tr(ref, 'det_obj');
      case 'face_recognition': return tr(ref, 'rec_face');
      case 'assist_title': return tr(ref, 'chat_ai');
      case 'qr_scan': return tr(ref, 'scan_qr');
      case 'login': return tr(ref, 'login_act');
      case 'music_generated': return tr(ref, 'gen_music');
      default: return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatDescription(WidgetRef ref, String key) {
    if (key.contains('assist')) return tr(ref, 'desc_act_assist');
    if (key.contains('ocr')) return tr(ref, 'desc_act_ocr');
    if (key.contains('face')) return tr(ref, 'desc_act_face');
    if (key.contains('object')) return tr(ref, 'desc_act_obj');
    if (key.contains('qr')) return tr(ref, 'desc_act_qr');
    return tr(ref, 'desc_act_default');
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
      backgroundColor: Colors.transparent, // Penting untuk efek glass
      appBar: AppBar(
        title: Text(tr(ref, 'history_title'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: activities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(tr(ref, 'no_history'), style: GoogleFonts.plusJakartaSans(color: Colors.white70)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final item = activities[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    height: 90,
                    borderRadius: 16,
                    blur: 10,
                    alignment: Alignment.center,
                    border: 1,
                    linearGradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderGradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.1)]),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: item.color.withOpacity(0.5), width: 1),
                            ),
                            child: Icon(_getIcon(item.titleKey), color: item.color, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatTitle(ref, item.titleKey),
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDescription(ref, item.descKey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(item.timestamp),
                                style: GoogleFonts.sourceCodePro(color: Colors.white54, fontSize: 10),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}