import 'package:flutter/material.dart'; // WAJIB ADA
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/localization_service.dart';

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput(
      {super.key,
      required this.onSendMessage,
      required this.isLoading,
      required this.onVoicePressed,
      required this.isListening});
  final Function(String) onSendMessage;
  final VoidCallback onVoicePressed;
  final bool isLoading;
  final bool isListening;
  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _textController = TextEditingController();
  bool _hasText = false;
  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() => _hasText = _textController.text.trim().isNotEmpty);
    });
  }

  void _send() {
    if (_textController.text.trim().isNotEmpty) {
      widget.onSendMessage(_textController.text.trim());
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ]),
      child: Row(
        children: [
          GestureDetector(
              onLongPress: widget.onVoicePressed,
              onTap: widget.onVoicePressed,
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: widget.isListening
                          ? Colors.redAccent
                          : (isDark ? Colors.white10 : Colors.grey[100]),
                      shape: BoxShape.circle,
                      boxShadow: widget.isListening
                          ? [
                              BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.5),
                                  blurRadius: 15,
                                  spreadRadius: 2)
                            ]
                          : []),
                  child: Icon(
                          widget.isListening
                              ? Icons.graphic_eq
                              : Icons.mic_rounded,
                          color: widget.isListening
                              ? Colors.white
                              : Colors.grey[600],
                          size: 24)
                      .animate(target: widget.isListening ? 1 : 0)
                      .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.2, 1.2),
                          duration: 600.ms,
                          curve: Curves.easeInOut)
                      .then()
                      .scale(
                          begin: const Offset(1.2, 1.2),
                          end: const Offset(1, 1)))),
          const SizedBox(width: 10),
          Expanded(
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color:
                              isDark ? Colors.transparent : Colors.grey[300]!,
                          width: 1)),
                  child: TextField(
                      controller: _textController,
                      enabled: !widget.isLoading,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                          hintText: widget.isListening
                              ? "Listening..."
                              : (widget.isLoading
                                  ? "Thinking..."
                                  : tr(ref, 'assist_hint')),
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12))))),
          const SizedBox(width: 10),
          GestureDetector(
              onTap: _hasText && !widget.isLoading ? _send : null,
              child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: _hasText
                          ? const Color(0xFF6C63FF)
                          : Colors.transparent,
                      shape: BoxShape.circle),
                  child: Icon(Icons.send_rounded,
                      color: _hasText ? Colors.white : Colors.grey[400],
                      size: 24)))
        ],
      ),
    );
  }
}
