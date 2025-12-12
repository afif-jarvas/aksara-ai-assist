import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/localization_service.dart';
import '../services/assistant_service.dart';
import '../models/message.dart';

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Variabel untuk debouncing scroll
  bool _isAutoScrolling = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi Scroll Otomatis yang Halus
  void _scrollToBottom() {
    if (_scrollController.hasClients && !_isAutoScrolling) {
      _isAutoScrolling = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 60, // Tambah offset sedikit
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuad,
          ).then((_) => _isAutoScrolling = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menghubungkan UI dengan Logic di AssistantService
    final assistantState = ref.watch(assistantServiceProvider);
    final notifier = ref.read(assistantServiceProvider.notifier);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Trigger scroll jika ada pesan baru masuk
    ref.listen(assistantServiceProvider, (previous, next) {
      if (next.value != null && (previous?.value?.messages.length ?? 0) < next.value!.messages.length) {
        _scrollToBottom();
      }
    });

    return assistantState.when(
      loading: () => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: Text("Terjadi Kesalahan: $err")),
      ),
      data: (state) {
        // Warna Indikator Mode (Cyan untuk Fast, Emas untuk Expert)
        final modeColor = state.activeModel == 'expert' 
            ? const Color(0xFFFFD700) 
            : const Color(0xFF00E5FF);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          resizeToAvoidBottomInset: true, // Agar input naik saat keyboard muncul
          body: SafeArea(
            child: Column(
              children: [
                // 1. HEADER (Home, Riwayat Dropdown, Settings)
                _buildHeader(context, notifier, state, isDark),

                // 2. MODEL SWITCHER (Fast / Expert)
                _buildModelSelector(context, notifier, state.activeModel, isDark, modeColor),

                // 3. CHAT AREA
                Expanded(
                  child: state.messages.isEmpty
                      ? _buildEmptyState(state.activeModel, isDark)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Tampilkan indikator loading di item terakhir jika sedang berpikir
                            if (index == state.messages.length) {
                              return _buildLoadingIndicator(state.activeModel, modeColor, isDark);
                            }
                            final msg = state.messages[index];
                            return _buildMessageBubble(msg, isDark, modeColor);
                          },
                        ),
                ),

                // 4. INPUT BAR (Text Field & Mic)
                _buildInputBar(context, notifier, state, isDark, modeColor),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET HEADER ---
  Widget _buildHeader(BuildContext context, AssistantService notifier, AssistantState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Home
          IconButton(
            onPressed: () => context.go('/home'),
            icon: Icon(Icons.home_rounded, color: isDark ? Colors.white : Colors.black87),
            tooltip: 'Kembali ke Beranda',
          ),

          // Dropdown Riwayat Chat (Fitur Lengkap)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                elevation: 4,
                tooltip: 'Riwayat Percakapan',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          state.currentSessionId != null 
                              ? (state.historySessions.firstWhere((s) => s.id == state.currentSessionId, orElse: () => ChatSession(id: '', title: 'Chat', createdAt: DateTime.now())).title)
                              : "Riwayat Chat",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.black54),
                    ],
                  ),
                ),
                onSelected: (value) {
                  if (value == 'new_chat') {
                    notifier.startNewChat();
                  } else {
                    notifier.loadSession(value);
                  }
                },
                itemBuilder: (context) {
                  List<PopupMenuEntry<String>> items = [];
                  
                  // Item 1: Chat Baru
                  items.add(const PopupMenuItem(
                    value: 'new_chat',
                    child: Row(children: [
                      Icon(Icons.add_circle_outline, color: Colors.blue),
                      SizedBox(width: 12),
                      Text("Percakapan Baru", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ]),
                  ));
                  items.add(const PopupMenuDivider());

                  // Item 2: List History
                  if (state.historySessions.isEmpty) {
                    items.add(const PopupMenuItem(enabled: false, child: Text("Belum ada riwayat.")));
                  } else {
                    for (var session in state.historySessions) {
                      items.add(PopupMenuItem<String>(
                        value: session.id,
                        child: Row(
                          children: [
                            // Status Pin
                            if (session.isPinned) 
                              const Icon(Icons.push_pin, size: 16, color: Colors.orange)
                            else 
                              const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                            
                            const SizedBox(width: 12),
                            
                            // Judul Chat
                            Expanded(
                              child: Text(
                                session.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: session.id == state.currentSessionId ? FontWeight.bold : FontWeight.normal
                                ),
                              ),
                            ),

                            // Opsi Tambahan (Titik Tiga)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 18),
                              padding: EdgeInsets.zero,
                              tooltip: "Opsi",
                              onSelected: (action) {
                                if (action == 'pin') notifier.togglePinSession(session.id, session.isPinned);
                                if (action == 'rename') _showRenameDialog(context, notifier, session.id, session.title);
                                if (action == 'delete') _showDeleteConfirmDialog(context, notifier, session.id);
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'pin', child: Text(session.isPinned ? "Lepas Pin" : "Sematkan")),
                                const PopupMenuItem(value: 'rename', child: Text("Ganti Nama")),
                                const PopupMenuItem(value: 'delete', child: Text("Hapus", style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                      ));
                    }
                  }
                  return items;
                },
              ),
            ),
          ),

          // Tombol Pengaturan
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: Icon(Icons.settings_rounded, color: isDark ? Colors.white : Colors.black87),
            tooltip: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  // --- WIDGET MODE SELECTOR ---
  Widget _buildModelSelector(BuildContext context, AssistantService notifier, String activeModel, bool isDark, Color color) {
    return GestureDetector(
      onTap: () => _showModelSheet(context, notifier, activeModel, isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 4, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activeModel == 'fast' ? Icons.flash_on_rounded : Icons.psychology_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              activeModel == 'fast' ? "Mode Cepat (Flash)" : "Mode Expert (Pro)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // Bottom Sheet Pilihan Mode
  void _showModelSheet(BuildContext context, AssistantService notifier, String current, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pilih Kecerdasan Aksara", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Sesuaikan mode dengan kebutuhanmu.", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            
            // Opsi Fast
            _modelOptionItem(
              ctx, notifier, 'fast', 
              "Fast (Cepat & Ringkas)", 
              "Respon instan (max 5 detik). Cocok untuk pertanyaan sehari-hari.", 
              const Color(0xFF00E5FF), 
              current == 'fast',
              Icons.flash_on_rounded
            ),
            const SizedBox(height: 12),
            
            // Opsi Expert
            _modelOptionItem(
              ctx, notifier, 'expert', 
              "Expert (Mendalam & Detail)", 
              "Analisis komprehensif (max 15 detik). Cocok untuk tugas rumit.", 
              const Color(0xFFFFD700), 
              current == 'expert',
              Icons.psychology_rounded
            ),
          ],
        ),
      ),
    );
  }

  Widget _modelOptionItem(BuildContext ctx, AssistantService notifier, String id, String title, String desc, Color color, bool selected, IconData icon) {
    return InkWell(
      onTap: () {
        notifier.setModel(id);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : Colors.grey.withOpacity(0.2), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: color),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CHAT AREA ---
  Widget _buildEmptyState(String model, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            model == 'fast' ? Icons.flash_on_rounded : Icons.psychology_rounded,
            size: 80,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
          const SizedBox(height: 20),
          Text(
            model == 'fast' ? "Mode Cepat Siap!" : "Mode Expert Aktif",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tanya apa saja, Aksara siap bantu.",
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildMessageBubble(Message msg, bool isDark, Color accentColor) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isUser 
              ? const Color(0xFF6200EE) 
              : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: SelectableText(
          msg.content,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
    ).animate().fade().slideY(begin: 0.1, duration: 300.ms);
  }

  Widget _buildLoadingIndicator(String model, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 20, top: 10),
      child: Row(
        children: [
          Container(
            width: 35, height: 35,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            model == 'expert' 
                ? "Aksara sedang berpikir mendalam..." 
                : "Aksara sedang mengetik...",
            style: TextStyle(
              fontSize: 12, 
              color: Colors.grey[500],
              fontStyle: FontStyle.italic
            ),
          ).animate().shimmer(duration: 1500.ms),
        ],
      ),
    );
  }

  // --- WIDGET INPUT BAR ---
  Widget _buildInputBar(BuildContext context, AssistantService notifier, AssistantState state, bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Tombol Mic
            InkWell(
              onTap: notifier.toggleListening,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: state.isListening ? Colors.red.withOpacity(0.1) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state.isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: state.isListening ? Colors.red : Colors.grey,
                ),
              ),
            ),
            
            const SizedBox(width: 8),

            // Text Field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.transparent
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Ketik pesan...",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      notifier.sendMessage(val);
                      _textController.clear();
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 8),

            // Tombol Kirim
            GestureDetector(
              onTap: state.isLoading 
                  ? null 
                  : () {
                      if (_textController.text.trim().isNotEmpty) {
                        notifier.sendMessage(_textController.text);
                        _textController.clear();
                      }
                    },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: state.isLoading ? Colors.grey : const Color(0xFF6200EE),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!state.isLoading)
                      BoxShadow(
                        color: const Color(0xFF6200EE).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                  ],
                ),
                child: Icon(
                  Icons.send_rounded, 
                  color: Colors.white, 
                  size: 20
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOGS ---
  void _showRenameDialog(BuildContext context, AssistantService notifier, String sessionId, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Ganti Nama Chat"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Nama baru...",
            filled: true,
            fillColor: Colors.grey.withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              notifier.renameSession(sessionId, controller.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6200EE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, AssistantService notifier, String sessionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Chat?"),
        content: const Text("Riwayat percakapan ini akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              notifier.deleteSession(sessionId);
              Navigator.pop(ctx);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }
  
  ThemeData get theme => Theme.of(context);
}