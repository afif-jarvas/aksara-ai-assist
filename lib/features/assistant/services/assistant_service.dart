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

// --- MODELS ---

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

// --- SERVICE PROVIDER ---

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
    await _flutterTts.setSpeechRate(0.5); // Kecepatan bicara normal
    
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

  // --- SESSION MANAGEMENT ---

  Future<List<ChatSession>> _fetchSessions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', userId)
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

  Future<void> deleteSession(String sessionId) async {
    await _supabase.from('chat_sessions').delete().eq('id', sessionId);
    final sessions = await _fetchSessions();
    if (state.value?.currentSessionId == sessionId) {
      state = AsyncData(state.value!.copyWith(historySessions: sessions, messages: [], currentSessionId: null));
    } else {
      state = AsyncData(state.value!.copyWith(historySessions: sessions));
    }
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    await _supabase.from('chat_sessions').update({'title': newTitle}).eq('id', sessionId);
    state = AsyncData(state.value!.copyWith(historySessions: await _fetchSessions()));
  }

  Future<void> togglePinSession(String sessionId, bool currentStatus) async {
    await _supabase.from('chat_sessions').update({'is_pinned': !currentStatus}).eq('id', sessionId);
    state = AsyncData(state.value!.copyWith(historySessions: await _fetchSessions()));
  }

  // --- CORE CHAT LOGIC ---

  void setModel(String model) {
    if (model == 'fast' || model == 'expert') {
      state = AsyncData(state.value!.copyWith(activeModel: model));
    }
  }

  Future<void> sendMessage(String text, {bool isVoiceInput = false}) async {
    if (text.trim().isEmpty) return;
    stopSpeaking();

    final currentState = state.value ?? AssistantState();
    String? sessionId = currentState.currentSessionId;

    // 1. Buat Sesi Baru jika belum ada
    if (sessionId == null) {
      try {
        final title = text.length > 30 ? "${text.substring(0, 30)}..." : text;
        final sessionRes = await _supabase.from('chat_sessions').insert({
          'user_id': _supabase.auth.currentUser!.id,
          'title': title,
        }).select().single();
        
        sessionId = sessionRes['id'];
        final updatedSessions = await _fetchSessions();
        // Update state dengan sesi baru
        state = AsyncData(currentState.copyWith(
          currentSessionId: sessionId,
          historySessions: updatedSessions
        ));
      } catch (e) {
        return; // Gagal inisialisasi sesi
      }
    }

    // 2. Tampilkan pesan user ke UI (Optimistic)
    final userMsg = Message(
        id: const Uuid().v4(),
        content: text,
        type: MessageType.user,
        timestamp: DateTime.now());

    final newMessages = [...?state.value?.messages, userMsg];
    state = AsyncData(state.value!.copyWith(messages: newMessages, isLoading: true));

    // 3. Simpan Pesan User ke DB
    await _supabase.from('chat_messages').insert({
      'session_id': sessionId,
      'content': text,
      'is_user': true,
    });

    try {
      // 4. Siapkan Context (History Chat)
      // Ambil 5 pesan terakhir untuk konteks percakapan
      final historyContext = newMessages.length > 5
          ? newMessages.sublist(newMessages.length - 5)
              .map((m) => "${m.isUser ? 'User' : 'Assistant'}: ${m.content}").join("\n")
          : newMessages.map((m) => "${m.isUser ? 'User' : 'Assistant'}: ${m.content}").join("\n");

      // 5. Atur Timeout & Mode
      final isExpert = currentState.activeModel == 'expert';
      final timeoutDuration = isExpert 
          ? const Duration(seconds: 15) // Expert max 15s
          : const Duration(seconds: 5); // Fast max 5s

      // 6. Panggil Edge Function
      final result = await EdgeFunctionService.callFunction('ai_chat', {
        'message': text,
        'context': historyContext, // PENTING: Kirim history agar AI nyambung
        'modelType': currentState.activeModel // kirim 'fast' atau 'expert'
      }).timeout(timeoutDuration, onTimeout: () {
        throw TimeoutException("Waktu habis! AI berpikir terlalu lama.");
      });

      final replyText = result['text'] ?? "Maaf, saya tidak mengerti.";

      // 7. Tambah Balasan AI ke UI
      final aiMsg = Message(
          id: const Uuid().v4(),
          content: replyText,
          type: MessageType.assistant,
          timestamp: DateTime.now());

      state = AsyncData(state.value!.copyWith(
        messages: [...newMessages, aiMsg], 
        isLoading: false
      ));

      // 8. Simpan Balasan AI ke DB
      await _supabase.from('chat_messages').insert({
        'session_id': sessionId,
        'content': replyText,
        'is_user': false,
      });

      if (isVoiceInput) speak(replyText);

    } catch (e) {
      // Error Handling
      String errorText = "Terjadi kesalahan koneksi.";
      if (e is TimeoutException) {
        errorText = currentState.activeModel == 'expert'
            ? "Waktu habis (15s). Coba mode Fast untuk respon lebih cepat."
            : "Waktu habis (5s). Koneksi lambat atau server sibuk.";
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

  // --- VOICE UTILS ---

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