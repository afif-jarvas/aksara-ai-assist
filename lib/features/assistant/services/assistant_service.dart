import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/edge_function_service.dart';
import '../models/message.dart';

part 'assistant_service.g.dart';

class ChatSession {
  final String id;
  final String title;
  final bool isPinned;
  final DateTime createdAt;

  ChatSession({
    required this.id, 
    required this.title, 
    this.isPinned = false, 
    required this.createdAt
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'] ?? 'Percakapan Baru',
      isPinned: json['is_pinned'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AssistantState {
  final List<Message> messages;
  final List<ChatSession> historySessions;
  final String? currentSessionId;
  final bool isListening;
  final bool isLoading;
  final String activeModel; // 'fast' atau 'expert'
  final bool isSpeaking;

  AssistantState({
    this.messages = const [],
    this.historySessions = const [],
    this.currentSessionId,
    this.isListening = false,
    this.isLoading = false,
    this.activeModel = 'fast', 
    this.isSpeaking = false,
  });

  AssistantState copyWith({
    List<Message>? messages,
    List<ChatSession>? historySessions,
    String? currentSessionId,
    bool? isListening,
    bool? isLoading,
    String? activeModel,
    bool? isSpeaking,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      historySessions: historySessions ?? this.historySessions,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isListening: isListening ?? this.isListening,
      isLoading: isLoading ?? this.isLoading,
      activeModel: activeModel ?? this.activeModel,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}

@riverpod
class AssistantService extends _$AssistantService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final _supabase = Supabase.instance.client;
  bool _isInitialized = false;

  @override
  Future<AssistantState> build() async {
    if (!_isInitialized) await _initialize();
    final sessions = await _fetchSessions();
    return AssistantState(historySessions: sessions);
  }

  Future<void> _initialize() async {
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.5);
    
    _flutterTts.setStartHandler(() {
      if (state.hasValue) state = AsyncData(state.value!.copyWith(isSpeaking: true));
    });

    _flutterTts.setCompletionHandler(() {
      if (state.hasValue) state = AsyncData(state.value!.copyWith(isSpeaking: false));
    });

    _flutterTts.setCancelHandler(() {
      if (state.hasValue) state = AsyncData(state.value!.copyWith(isSpeaking: false));
    });

    _isInitialized = true;
  }

  Future<List<ChatSession>> _fetchSessions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('chat_sessions')
          .select()
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);
      
      return (response as List).map((e) => ChatSession.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> loadSession(String sessionId) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);

      final loadedMessages = (response as List).map((data) {
        return Message(
          id: data['id'],
          content: data['content'],
          type: data['is_user'] ? MessageType.user : MessageType.assistant,
          timestamp: DateTime.parse(data['created_at']),
        );
      }).toList();

      state = AsyncData(state.value!.copyWith(
        messages: loadedMessages,
        currentSessionId: sessionId,
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncData(state.value!.copyWith(isLoading: false));
    }
  }

  void startNewChat() {
    stopSpeaking();
    state = AsyncData(state.value!.copyWith(
      messages: [],
      currentSessionId: null,
    ));
  }

  // --- MODEL LOGIC FIX ---

  Future<void> sendMessage(String text, {bool isVoiceInput = false}) async {
    if (text.trim().isEmpty) return;
    stopSpeaking();

    final currentState = state.value ?? AssistantState();
    String? sessionId = currentState.currentSessionId;

    // 1. Buat sesi baru jika null
    if (sessionId == null) {
      try {
        final title = text.length > 30 ? "${text.substring(0, 30)}..." : text;
        final sessionRes = await _supabase.from('chat_sessions').insert({
          'user_id': _supabase.auth.currentUser!.id,
          'title': title,
        }).select().single();
        
        sessionId = sessionRes['id'];
        final updatedSessions = await _fetchSessions();
        state = AsyncData(currentState.copyWith(
          currentSessionId: sessionId,
          historySessions: updatedSessions
        ));
      } catch (e) {
        return; // Gagal membuat sesi
      }
    }

    // 2. Tampilkan pesan user di UI
    final userMsg = Message(
        id: const Uuid().v4(),
        content: text,
        type: MessageType.user,
        timestamp: DateTime.now());

    final newMessages = [...?state.value?.messages, userMsg];
    state = AsyncData(state.value!.copyWith(messages: newMessages, isLoading: true));

    // 3. Simpan pesan user ke DB
    await _supabase.from('chat_messages').insert({
      'session_id': sessionId,
      'content': text,
      'is_user': true,
    });

    try {
      // 4. Siapkan Context
      final historyContext = newMessages.length > 6
          ? newMessages.sublist(newMessages.length - 6)
              .map((m) => "${m.isUser ? 'User' : 'AI'}: ${m.content}").join("\n")
          : "";

      // 5. TIMEOUT & MODEL SELECTION FIX
      // Expert butuh waktu lama, kita beri 60 detik. Fast cukup 15 detik.
      final isExpert = currentState.activeModel == 'expert';
      final timeoutDuration = isExpert 
          ? const Duration(seconds: 60) 
          : const Duration(seconds: 15);

      print("Sending to AI... Model: ${currentState.activeModel}, Timeout: ${timeoutDuration.inSeconds}s");

      // Panggil Edge Function
      final result = await EdgeFunctionService.callFunction('ai_chat', {
        'message': text,
        'mode': 'chat', // mode fungsi
        'context': historyContext,
        'modelType': isExpert ? 'pro' : 'flash' // Pastikan backend menerima 'pro' atau 'flash'
      }).timeout(timeoutDuration, onTimeout: () {
        throw TimeoutException("Respon terlalu lama. Silakan coba lagi.");
      });

      // Handle response
      final replyText = result['text'] ?? result['reply'] ?? "Maaf, terjadi kesalahan format respon.";
      
      final aiMsg = Message(
          id: const Uuid().v4(),
          content: replyText,
          type: MessageType.assistant,
          timestamp: DateTime.now());

      state = AsyncData(state.value!.copyWith(
        messages: [...newMessages, aiMsg], 
        isLoading: false
      ));

      await _supabase.from('chat_messages').insert({
        'session_id': sessionId,
        'content': replyText,
        'is_user': false,
      });

      if (isVoiceInput) speak(replyText);

    } catch (e) {
      String errorText = "Terjadi kesalahan.";
      if (e is TimeoutException) {
        errorText = "Waktu habis (${currentState.activeModel == 'expert' ? '60s' : '15s'}). Koneksi lambat atau model sedang sibuk.";
      } else {
        errorText = "Gagal memproses: ${e.toString()}";
      }

      final errorMsg = Message(
          id: const Uuid().v4(),
          content: errorText,
          type: MessageType.assistant,
          timestamp: DateTime.now());
      
      state = AsyncData(state.value!.copyWith(
        messages: [...newMessages, errorMsg], 
        isLoading: false
      ));
    }
  }

  // Toggle antara Fast & Expert
  void toggleModel() {
    final current = state.value?.activeModel ?? 'fast';
    final newModel = current == 'fast' ? 'expert' : 'fast';
    state = AsyncData(state.value!.copyWith(activeModel: newModel));
  }

  // Placeholder functions for UI actions
  Future<void> deleteSession(String sessionId) async {
    await _supabase.from('chat_sessions').delete().eq('id', sessionId);
    final sessions = await _fetchSessions();
    state = AsyncData(state.value!.copyWith(historySessions: sessions, messages: [], currentSessionId: null));
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    await _supabase.from('chat_sessions').update({'title': newTitle}).eq('id', sessionId);
    state = AsyncData(state.value!.copyWith(historySessions: await _fetchSessions()));
  }

  Future<void> togglePinSession(String sessionId, bool currentStatus) async {
    await _supabase.from('chat_sessions').update({'is_pinned': !currentStatus}).eq('id', sessionId);
    state = AsyncData(state.value!.copyWith(historySessions: await _fetchSessions()));
  }

  Future<void> toggleListening() async {
    final s = state.value ?? AssistantState();
    if (s.isListening) {
      await _speechToText.stop();
      state = AsyncData(s.copyWith(isListening: false));
    } else {
      bool available = await _speechToText.initialize();
      if (available) {
        state = AsyncData(s.copyWith(isListening: true));
        _speechToText.listen(
          onResult: (res) {
            if (res.finalResult) {
              sendMessage(res.recognizedWords, isVoiceInput: true);
              state = AsyncData(state.value!.copyWith(isListening: false));
            }
          },
          localeId: "id_ID"
        );
      }
    }
  }

  Future<void> speak(String text) async => await _flutterTts.speak(text);
  Future<void> stopSpeaking() async => await _flutterTts.stop();
}