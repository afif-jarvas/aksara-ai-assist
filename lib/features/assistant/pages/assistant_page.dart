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

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider); // Watch language changes
    final assistantAsync = ref.watch(assistantServiceProvider);
    final assistantNotifier = ref.read(assistantServiceProvider.notifier);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final user = Supabase.instance.client.auth.currentUser;
    final String? userAvatar =
        user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'];
    final Color bgColor =
        isDark ? const Color(0xFF0F0C29) : const Color(0xFFF7F7F8);
    final Color textColor = isDark ? Colors.white : Colors.black87;

    ref.listen(assistantServiceProvider, (previous, next) {
      next.whenData((state) {
        if (state.messages.length > (previous?.value?.messages.length ?? 0) ||
            state.isLoading) {
          _scrollToBottom();
        }
      });
    });

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
            onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr(ref, 'assist_title'),
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
          Consumer(builder: (context, ref, _) {
            final state = ref.watch(assistantServiceProvider).valueOrNull;
            final isSpeaking = state?.isSpeaking ?? false;
            return Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: isSpeaking ? Colors.redAccent : Colors.green,
                      shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(isSpeaking ? "Speaking..." : "Online",
                  style: TextStyle(
                      color: isSpeaking ? Colors.redAccent : Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w500))
            ]);
          })
        ]),
        actions: [
          Consumer(builder: (context, ref, _) {
            final state = ref.watch(assistantServiceProvider).valueOrNull;
            final model = state?.activeModel ?? 'flash';
            return Center(
                child: GestureDetector(
                    onTap: () => ref
                        .read(assistantServiceProvider.notifier)
                        .toggleModel(),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                            color: model == 'pro'
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    model == 'pro' ? Colors.amber : Colors.blue,
                                width: 1)),
                        child: Text(model.toUpperCase(),
                            style: TextStyle(
                                color: model == 'pro'
                                    ? Colors.amber[700]
                                    : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 10)))));
          }),
          IconButton(
              icon: Icon(Icons.cleaning_services_rounded,
                  color: Colors.grey[400], size: 20),
              onPressed: () => assistantNotifier.clearHistory()),
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
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.blue.withOpacity(0.05),
                                shape: BoxShape.circle),
                            child: Icon(Icons.chat_bubble_outline_rounded,
                                size: 40,
                                color: isDark ? Colors.white54 : Colors.blue)),
                        const SizedBox(height: 16),
                        Text(tr(ref, 'assist_intro'),
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16)) // FIX Localization
                      ]));
                }
                return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    itemCount:
                        state.messages.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state.isLoading && index == state.messages.length)
                        return TypingIndicator(isDark: isDark);
                      return MessageBubble(
                          message: state.messages[index],
                          userAvatarUrl: userAvatar);
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
