import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/localization_service.dart';
import '../services/assistant_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input.dart';

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final assistantStateAsync = ref.watch(assistantServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.history_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          tr(ref, 'assist_title'),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          assistantStateAsync.when(
            data: (state) {
              final isExpert = state.activeModel == 'expert';
              return Row(
                children: [
                  Text(
                    isExpert ? tr(ref, 'mode_expert') : tr(ref, 'mode_fast'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpert ? Colors.amber : Colors.green,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  Switch(
                    value: isExpert,
                    activeColor: Colors.amber,
                    inactiveThumbColor: Colors.green,
                    onChanged: (val) {
                      ref.read(assistantServiceProvider.notifier).toggleModel();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("${tr(ref, 'mode_switched')} ${val ? tr(ref, 'mode_expert') : tr(ref, 'mode_fast')}"),
                        duration: const Duration(seconds: 1),
                      ));
                    },
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_,__) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: _buildHistoryDrawer(context, ref, assistantStateAsync, isDark),
      body: assistantStateAsync.when(
        data: (state) {
          final messages = state.messages;
          final isLoading = state.isLoading;
          
          return Column(
            children: [
              Expanded(
                child: messages.isEmpty && !isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(tr(ref, 'assist_intro'), style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      reverse: true,
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isLoading && index == 0) return TypingIndicator(isDark: isDark);
                        
                        final adjustedIndex = isLoading ? index - 1 : index;
                        final msgIndex = messages.length - 1 - adjustedIndex;
                        
                        if (msgIndex < 0 || msgIndex >= messages.length) return const SizedBox.shrink();
                        return MessageBubble(message: messages[msgIndex]);
                      },
                    ),
              ),
              ChatInput(
                onSendMessage: (text) => ref.read(assistantServiceProvider.notifier).sendMessage(text),
                isLoading: isLoading,
                isListening: state.isListening,
                onVoicePressed: () => ref.read(assistantServiceProvider.notifier).toggleListening(),
              ),
            ],
          );
        },
        error: (e,s) => Center(child: Text("Error: $e")),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildHistoryDrawer(BuildContext context, WidgetRef ref, AsyncValue<AssistantState> asyncState, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(assistantServiceProvider.notifier).startNewChat();
                    Navigator.pop(context); // Tutup drawer
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Chat Baru"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: asyncState.when(
              data: (state) {
                if (state.historySessions.isEmpty) {
                  return Center(child: Text("Belum ada riwayat", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)));
                }
                return ListView.builder(
                  itemCount: state.historySessions.length,
                  itemBuilder: (context, index) {
                    final session = state.historySessions[index];
                    final isSelected = session.id == state.currentSessionId;
                    
                    return ListTile(
                      tileColor: isSelected ? (isDark ? Colors.white10 : Colors.blue.withOpacity(0.1)) : null,
                      leading: Icon(
                        session.isPinned ? Icons.push_pin : Icons.chat_bubble_outline,
                        color: session.isPinned ? Colors.orange : (isDark ? Colors.white54 : Colors.grey),
                        size: 20,
                      ),
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                      onTap: () {
                        ref.read(assistantServiceProvider.notifier).loadSession(session.id);
                        Navigator.pop(context);
                      },
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: 18, color: isDark ? Colors.white54 : Colors.grey),
                        onSelected: (value) {
                          if (value == 'pin') {
                            ref.read(assistantServiceProvider.notifier).togglePinSession(session.id, session.isPinned);
                          } else if (value == 'delete') {
                            _showDeleteConfirm(context, ref, session.id);
                          } else if (value == 'rename') {
                            _showRenameDialog(context, ref, session.id, session.title);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'pin', child: Text(session.isPinned ? "Lepas Pin" : "Pin Chat")),
                          const PopupMenuItem(value: 'rename', child: Text("Ubah Nama")),
                          const PopupMenuItem(value: 'delete', child: Text("Hapus", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_,__) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Chat?"),
        content: const Text("Riwayat percakapan ini akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              ref.read(assistantServiceProvider.notifier).deleteSession(sessionId);
              Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, String sessionId, String oldTitle) {
    final ctrl = TextEditingController(text: oldTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ubah Nama Chat"),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "Nama baru")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                ref.read(assistantServiceProvider.notifier).renameSession(sessionId, ctrl.text);
              }
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}