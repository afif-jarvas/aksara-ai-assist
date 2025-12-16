import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

// --- IMPORT LOGIC & WIDGETS ---
import '../services/assistant_service.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../../../../core/localization_service.dart';

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isComposing = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    setState(() => _isComposing = false);
    ref.read(assistantServiceProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final assistantState = ref.watch(assistantServiceProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121218) : const Color(0xFFF8F9FE);
    final appBarColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final inputContainerColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final inputFieldColor = isDark ? const Color(0xFF27273A) : const Color(0xFFF1F3F4);

    ref.listen(assistantServiceProvider, (previous, next) {
      if (next.value?.messages.length != previous?.value?.messages.length) {
        Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
      }
    });

    final messages = assistantState.value?.messages ?? [];
    final isLoading = assistantState.value?.isLoading ?? false;
    final isListening = assistantState.value?.isListening ?? false;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black12,
        backgroundColor: appBarColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, 
            color: isDark ? Colors.white70 : Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Hero(
              tag: 'assistant_icon',
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isDark 
                        ? [Colors.blue, Colors.cyanAccent]
                        : [Colors.blue, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                  child: Icon(Icons.auto_awesome, 
                    color: isDark ? Colors.cyanAccent : Colors.blueAccent, 
                    size: 20
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Aksara AI",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6, 
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00C853).withOpacity(0.4), blurRadius: 4)
                        ]
                      )
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Online",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12)
            ),
            child: IconButton(
              icon: Icon(Icons.history_rounded, 
                color: isDark ? Colors.white70 : Colors.black54),
              tooltip: 'Riwayat',
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ],
      ),

      endDrawer: _buildHistoryDrawer(context, ref, assistantState.value, isDark),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: messages.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : ListView.builder(
                        key: const ValueKey('msg_list'),
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: messages.length + (isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10, top: 10, bottom: 20),
                                child: TypingIndicator(isDark: isDark),
                              ),
                            );
                          }
                          final msg = messages[index];
                          return MessageBubble(message: msg);
                        },
                      ),
              ),
            ),
            
            _buildInputArea(context, ref, isListening, isDark, inputContainerColor, inputFieldColor),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      key: const ValueKey('empty_state'),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.blue.withOpacity(0.05),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.blue.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10)
                  )
                ],
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent
                )
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 64,
                color: isDark ? Colors.cyanAccent : Theme.of(context).primaryColor,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 30),
            Text(
              "Halo, Saya Aksara AI",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Saya siap membantu tugas sehari-hari Anda. Tanyakan apa saja!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white54 : Colors.grey[600]
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(
    BuildContext context, 
    WidgetRef ref, 
    bool isListening, 
    bool isDark,
    Color containerColor,
    Color fieldColor
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: containerColor,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)
          )
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -5),
            blurRadius: 20,
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => ref.read(assistantServiceProvider.notifier).toggleListening(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isListening 
                    ? Colors.redAccent 
                    : (isDark ? const Color(0xFF2D2D44) : Colors.grey[100]),
                shape: BoxShape.circle,
                boxShadow: isListening 
                    ? [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 10)] 
                    : null
              ),
              child: Icon(
                isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: isListening ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600]),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: fieldColor, 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent
                )
              ),
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16
                ), 
                maxLines: 5,
                minLines: 1,
                cursorColor: isDark ? Colors.cyanAccent : Colors.blueAccent,
                decoration: InputDecoration(
                  hintText: isListening ? "Mendengarkan..." : tr(ref, 'assist_hint'),
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.grey[400]
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  isDense: true,
                ),
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.trim().isNotEmpty;
                  });
                },
                onSubmitted: _isComposing ? _handleSubmitted : null,
              ),
            ),
          ),
          const SizedBox(width: 12),

          GestureDetector(
            onTap: _isComposing ? () => _handleSubmitted(_textController.text) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: _isComposing 
                    ? LinearGradient(
                        colors: isDark 
                            ? [Colors.cyan, Colors.cyanAccent] 
                            : [Colors.blueAccent, Colors.blue]
                      ) 
                    : null,
                color: _isComposing 
                    ? null 
                    : (isDark ? const Color(0xFF2D2D44) : Colors.grey[200]),
                shape: BoxShape.circle,
                boxShadow: _isComposing 
                    ? [
                        BoxShadow(
                          color: (isDark ? Colors.cyanAccent : Colors.blueAccent).withOpacity(0.4), 
                          blurRadius: 8, 
                          offset: const Offset(0, 4)
                        )
                      ] 
                    : null
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isComposing ? Colors.white : (isDark ? Colors.white24 : Colors.grey[400]),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DRAWER (HISTORY & ACTIONS) ---
  Widget _buildHistoryDrawer(BuildContext context, WidgetRef ref, AssistantState? state, bool isDark) {
    // 1. AMBIL USER DATA (PERBAIKAN)
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    
    // Coba ambil nama dari berbagai kemungkinan key, fallback ke email
    String userName = "Pengguna";
    if (metadata != null) {
      userName = metadata['name'] ?? 
                 metadata['full_name'] ?? 
                 metadata['display_name'] ?? 
                 metadata['user_name'] ??
                 (user?.email != null ? user!.email!.split('@')[0] : "Pengguna");
    } else if (user?.email != null) {
      userName = user!.email!.split('@')[0];
    }

    // Coba ambil avatar
    final avatarUrl = metadata?['avatar_url'] ?? 
                      metadata?['picture'] ?? 
                      metadata?['display_avatar'];
    
    final drawerBg = isDark ? const Color(0xFF161622) : Colors.white;
    final selectedItemColor = isDark ? const Color(0xFF27273A) : Colors.blue.withOpacity(0.1);

    return Drawer(
      backgroundColor: drawerBg,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20, 
              bottom: 24, 
              left: 24, 
              right: 24
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [Colors.blueAccent, Colors.cyanAccent] 
                    : [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)], 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.cyanAccent.withOpacity(0.3) 
                      : const Color(0xFF4A00E0).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8)
                )
              ]
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 2)
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white24,
                    backgroundImage: (avatarUrl != null && avatarUrl.toString().isNotEmpty) 
                        ? NetworkImage(avatarUrl) 
                        : null,
                    child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : "A",
                            style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Halo,",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12
                        ),
                      ),
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18, 
                          color: Colors.white
                        ),
                      ),
                       if (user?.email != null)
                        Text(
                          user!.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.7)
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    ref.read(assistantServiceProvider.notifier).startNewChat();
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text("Percakapan Baru"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.cyanAccent : Theme.of(context).primaryColor,
                  foregroundColor: isDark ? Colors.black87 : Colors.white,
                  elevation: isDark ? 2 : 4,
                  shadowColor: isDark ? Colors.cyanAccent.withOpacity(0.4) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  "RIWAYAT CHAT",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white38 : Colors.grey[500]
                  ),
                ),
                const Expanded(child: Divider(indent: 10)),
              ],
            ),
          ),
          
          Expanded(
            child: (state?.historySessions.isEmpty ?? true)
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, 
                          size: 40, color: isDark ? Colors.white10 : Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(
                          "Belum ada riwayat", 
                          style: TextStyle(color: isDark ? Colors.white30 : Colors.grey)
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state!.historySessions.length,
                    itemBuilder: (context, index) {
                      final session = state.historySessions[index];
                      final isSelected = session.id == state.currentSessionId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? selectedItemColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected && isDark 
                              ? Border.all(color: Colors.cyanAccent.withOpacity(0.3)) 
                              : null
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 0, bottom: 0),
                          // Icon Chat atau Pin
                          leading: Icon(
                            session.isPinned ? Icons.push_pin_rounded : Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: session.isPinned
                                ? (isDark ? Colors.cyanAccent : Colors.orange)
                                : (isSelected 
                                    ? (isDark ? Colors.cyanAccent : Theme.of(context).primaryColor)
                                    : (isDark ? Colors.white38 : Colors.grey)),
                          ),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            timeago.format(session.createdAt, locale: 'id'),
                            style: TextStyle(
                              fontSize: 11, 
                              color: isDark ? Colors.white30 : Colors.grey[500]
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            if (!isSelected) {
                              Future.delayed(const Duration(milliseconds: 250), () {
                                ref.read(assistantServiceProvider.notifier).loadSession(session.id);
                              });
                            }
                          },
                          // Menu Opsi: Rename, Pin, Delete
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, 
                              size: 18, color: isDark ? Colors.white24 : Colors.grey[400]),
                            color: isDark ? const Color(0xFF2D2D44) : Colors.white,
                            onSelected: (value) {
                              if (value == 'pin') {
                                ref.read(assistantServiceProvider.notifier).togglePinSession(session.id, session.isPinned);
                              } else if (value == 'rename') {
                                _showRenameDialog(context, ref, session.id, session.title, isDark);
                              } else if (value == 'delete') {
                                ref.read(assistantServiceProvider.notifier).deleteSession(session.id);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'pin',
                                child: Row(children: [
                                  Icon(session.isPinned ? Icons.push_pin_outlined : Icons.push_pin, 
                                    size: 18, color: isDark ? Colors.white : Colors.black87),
                                  const SizedBox(width: 8),
                                  Text(session.isPinned ? "Lepas Pin" : "Sematkan", 
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'rename',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined, size: 18, color: isDark ? Colors.white : Colors.black87),
                                  const SizedBox(width: 8),
                                  Text("Ganti Nama", 
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Text("Hapus", style: TextStyle(color: Colors.redAccent)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, String sessionId, String oldTitle, bool isDark) {
    final titleController = TextEditingController(text: oldTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        title: Text("Ganti Nama Percakapan", 
          style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: TextField(
          controller: titleController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: "Nama baru...",
            hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey)),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            child: const Text("Simpan"),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                ref.read(assistantServiceProvider.notifier).renameSession(sessionId, titleController.text.trim());
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}