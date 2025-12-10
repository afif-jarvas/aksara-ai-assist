import 'package:flutter/material.dart'; // WAJIB ADA
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../services/assistant_service.dart';

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.userAvatarUrl,
  });

  final Message message;
  final String? userAvatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Warna yang lebih modern
    final userBg = const Color(0xFF6C63FF);
    final aiBg = isDark ? const Color(0xFF252525) : Colors.white;
    final aiText = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // AVATAR AI (KIRI)
              if (!isUser) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isDark
                      ? Colors.cyanAccent.withOpacity(0.2)
                      : Colors.purple.withOpacity(0.1),
                  child: Icon(Icons.auto_awesome,
                      size: 16,
                      color: isDark ? Colors.cyanAccent : Colors.deepPurple),
                ),
                const SizedBox(width: 8),
              ],

              // BUBBLE
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                      color: isUser ? userBg : aiBg,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isUser
                            ? const Radius.circular(20)
                            : const Radius.circular(5),
                        bottomRight: isUser
                            ? const Radius.circular(5)
                            : const Radius.circular(20),
                      ),
                      boxShadow: [
                        if (!isDark || isUser)
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: GoogleFonts.plusJakartaSans(
                            color: isUser ? Colors.white : aiText,
                            fontSize: 15,
                            height: 1.5),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(message.timestamp),
                            style: TextStyle(
                                fontSize: 10,
                                color: isUser ? Colors.white70 : Colors.grey),
                          ),
                          if (isUser) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.done_all,
                                size: 12, color: Colors.white70)
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // AVATAR USER (KANAN)
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: (userAvatarUrl != null)
                      ? NetworkImage(userAvatarUrl!)
                      : null,
                  child: (userAvatarUrl == null)
                      ? const Icon(Icons.person, size: 16, color: Colors.white)
                      : null,
                ),
              ],
            ],
          ),

          // ACTION BUTTONS FOR AI
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 5),
              child: Row(
                children: [
                  _actionIcon(Icons.copy_rounded, "Salin", isDark, () {
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Teks disalin"),
                          duration: Duration(seconds: 1)),
                    );
                  }),
                  const SizedBox(width: 15),
                  _actionIcon(Icons.volume_up_rounded, "Baca", isDark, () {
                    ref
                        .read(assistantServiceProvider.notifier)
                        .speak(message.content);
                  }),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _actionIcon(
      IconData icon, String tooltip, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon,
          size: 16, color: isDark ? Colors.grey[600] : Colors.grey[400]),
    );
  }
}
