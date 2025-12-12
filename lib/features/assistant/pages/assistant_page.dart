import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/assistant_service.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../../../core/localization_service.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../core/activity_provider.dart';

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});
  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  String? _activeAvatarUrl;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initialRefresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchAvatar());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialRefresh() async {
    try {
      await Supabase.instance.client.auth.refreshSession();
    } catch (_) {}
    _fetchAvatar();
  }

  Future<void> _fetchAvatar() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    String? foundUrl;
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data != null) {
        foundUrl = data['avatar_url'] ?? data['avatar'];
      }
    } catch (_) {}

    if (foundUrl == null) {
      foundUrl = user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'];
    }

    if (foundUrl != null && mounted && foundUrl != _activeAvatarUrl) {
      setState(() {
        _activeAvatarUrl = foundUrl;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      });
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(assistantServiceProvider.notifier).sendMessage(text);
    ref.read(activityProvider.notifier).addActivity('assist_title',
        'log_assist_used', Icons.psychology, Colors.deepPurpleAccent);
  }

  // --- UI DIALOGS ---
  void _showRenameDialog(BuildContext context, ChatSession session) {
    final TextEditingController controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ganti Nama Chat"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(assistantServiceProvider.notifier).renameSession(session.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Chat?"),
        content: const Text("Chat ini akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              ref.read(assistantServiceProvider.notifier).deleteSession(sessionId);
              Navigator.pop(context);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final assistantAsync = ref.watch(assistantServiceProvider);
    final assistantNotifier = ref.read(assistantServiceProvider.notifier);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final Color bgColor = isDark ? const Color(0xFF0F0C29) : const Color(0xFFF7F7F8);
    final Color textColor = isDark ? Colors.white : Colors.black87;

    ref.listen(assistantServiceProvider, (previous, next) {
      next.whenData((state) {
        if (state.messages.length > (previous?.value?.messages.length ?? 0) || state.isLoading) {
          _scrollToBottom();
        }
      });
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      // --- DRAWER ---
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.deepPurpleAccent : Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  assistantNotifier.startNewChat();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text("Chat Baru"),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Riwayat Chat", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: assistantAsync.when(
                data: (state) {
                  if (state.historySessions.isEmpty) return Center(child: Text("Belum ada riwayat", style: TextStyle(color: Colors.grey[400], fontSize: 12)));
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: state.historySessions.length,
                    itemBuilder: (context, index) {
                      final session = state.historySessions[index];
                      final isActive = session.id == state.currentSessionId;
                      return ListTile(
                        dense: true,
                        selected: isActive,
                        selectedTileColor: isDark ? Colors.white10 : Colors.blue.withOpacity(0.1),
                        leading: session.isPinned ? const Icon(Icons.push_pin, size: 16, color: Colors.orange) : Icon(Icons.chat_bubble_outline, size: 18, color: isActive ? Colors.blue : Colors.grey),
                        title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isActive ? Colors.blue : textColor, fontSize: 14, fontWeight: session.isPinned ? FontWeight.bold : FontWeight.normal)),
                        onTap: () {
                          assistantNotifier.loadSession(session.id);
                          Navigator.pop(context);
                        },
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
                          onSelected: (value) {
                            if (value == 'rename') _showRenameDialog(context, session);
                            else if (value == 'pin') assistantNotifier.togglePinSession(session.id, session.isPinned);
                            else if (value == 'delete') _showDeleteDialog(context, session.id);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit, size: 16, color: textColor), const SizedBox(width: 8), const Text('Ganti Nama')])),
                            PopupMenuItem(value: 'pin', child: Row(children: [Icon(session.isPinned ? Icons.push_pin_outlined : Icons.push_pin, size: 16, color: textColor), const SizedBox(width: 8), Text(session.isPinned ? 'Lepas Pin' : 'Pin Chat')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr(ref, 'assist_title'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
          Consumer(builder: (context, ref, _) {
            final state = ref.watch(assistantServiceProvider).valueOrNull;
            final isSpeaking = state?.isSpeaking ?? false;
            return Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: isSpeaking ? Colors.redAccent : Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(isSpeaking ? "Speaking..." : "Online", style: TextStyle(color: isSpeaking ? Colors.redAccent : Colors.green, fontSize: 11, fontWeight: FontWeight.w500))
            ]);
          })
        ]),
        actions: [
          // TOMBOL GANTI MODEL (UPDATED)
          Consumer(builder: (context, ref, _) {
            final state = ref.watch(assistantServiceProvider).valueOrNull;
            final model = state?.activeModel ?? 'fast';
            final isExpert = model == 'expert';
            
            return Center(
                child: Tooltip(
                  // Menampilkan Keterangan saat ditahan
                  message: isExpert 
                      ? "Expert: Menganalisis semua lalu memberikan jawaban detail" 
                      : "Fast: Menjawab pertanyaan dengan cepat",
                  triggerMode: TooltipTriggerMode.longPress,
                  child: GestureDetector(
                      onTap: () {
                        assistantNotifier.toggleModel();
                        // Tampilkan info singkat saat di-tap
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(isExpert 
                              ? "Mode Fast: Jawaban cepat (Maks 5s)" 
                              : "Mode Expert: Analisis mendalam (Maks 15s)"),
                          duration: const Duration(seconds: 2),
                          backgroundColor: isExpert ? Colors.blue : Colors.amber[800],
                        ));
                      },
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                              color: isExpert ? Colors.amber.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isExpert ? Colors.amber : Colors.blue, width: 1)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isExpert ? Icons.psychology : Icons.flash_on, 
                                   size: 14, 
                                   color: isExpert ? Colors.amber[700] : Colors.blue),
                              const SizedBox(width: 4),
                              Text(model.toUpperCase(),
                                  style: TextStyle(
                                      color: isExpert ? Colors.amber[700] : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ],
                          ))),
                ));
          }),
          IconButton(icon: Icon(Icons.history_rounded, color: textColor, size: 24), onPressed: () => _scaffoldKey.currentState!.openDrawer()),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: assistantAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (state) {
                if (state.messages.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.blue.withOpacity(0.05), shape: BoxShape.circle), child: Icon(Icons.chat_bubble_outline_rounded, size: 40, color: isDark ? Colors.white54 : Colors.blue)),
                        const SizedBox(height: 16),
                        Text(tr(ref, 'assist_intro'), style: const TextStyle(color: Colors.grey, fontSize: 16))
                      ]));
                }
                return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state.isLoading && index == state.messages.length) return TypingIndicator(isDark: isDark);
                      return MessageBubble(key: ValueKey(_activeAvatarUrl), message: state.messages[index], userAvatarUrl: _activeAvatarUrl);
                    });
              },
            ),
          ),
          ChatInput(
              isLoading: assistantAsync.value?.isLoading ?? false,
              isListening: assistantAsync.value?.isListening ?? false,
              onSendMessage: _sendMessage,
              onVoicePressed: () => assistantNotifier.toggleListening()),
        ],
      ),
    );
  }
}