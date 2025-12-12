import 'dart:async'; // Tambahkan ini untuk TimeoutException
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    this.activeModel = 'fast', // Default ganti jadi 'fast'
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
  
  // Helper untuk mendapatkan deskripsi model
  String get modelDescription {
    if (activeModel == 'expert') {
      return "Menganalisis semua lalu memberikan jawaban detail";
    }
    return "Menjawab pertanyaan dengan cepat";
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
    await _flutterTts.setPitch(1.0);

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

  // --- LOGIC DATABASE ---

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
      print('Error fetching sessions: $e');
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
    try {
      await _supabase.from('chat_sessions').delete().eq('id', sessionId);
      final sessions = await _fetchSessions();
      
      if (state.value?.currentSessionId == sessionId) {
        state = AsyncData(state.value!.copyWith(
          historySessions: sessions,
          messages: [],
          currentSessionId: null
        ));
      } else {
        state = AsyncData(state.value!.copyWith(historySessions: sessions));
      }
    } catch (e) {
      print("Gagal hapus: $e");
    }
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    try {
      await _supabase.from('chat_sessions').update({'title': newTitle}).eq('id', sessionId);
      final sessions = await _fetchSessions();
      state = AsyncData(state.value!.copyWith(historySessions: sessions));
    } catch (_) {}
  }

  Future<void> togglePinSession(String sessionId, bool currentStatus) async {
    try {
      await _supabase.from('chat_sessions').update({'is_pinned': !currentStatus}).eq('id', sessionId);
      final sessions = await _fetchSessions();
      state = AsyncData(state.value!.copyWith(historySessions: sessions));
    } catch (_) {}
  }

  // --- LOGIC PENGIRIMAN PESAN & TIMEOUT ---

  Future<void> sendMessage(String text, {bool isVoiceInput = false}) async {
    if (text.trim().isEmpty) return;
    stopSpeaking();

    final currentState = state.value ?? AssistantState();
    String? sessionId = currentState.currentSessionId;

    // 1. Buat Sesi Baru jika perlu
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
        return;
      }
    }

    // 2. UI Update (User Message)
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
      // 4. Siapkan Konteks & Model
      final historyContext = newMessages.length > 6
          ? newMessages.sublist(newMessages.length - 6)
              .map((m) => "${m.isUser ? 'User' : 'AI'}: ${m.content}").join("\n")
          : "";

      // Mapping nama model untuk Backend
      // Jika di UI 'fast' -> kirim 'flash' ke backend (sesuai backend lama)
      // Jika di UI 'expert' -> kirim 'pro' ke backend
      final backendModelName = currentState.activeModel == 'expert' ? 'pro' : 'flash';

      // 5. SETTING TIMEOUT
      // Fast: 5 detik, Expert: 15 detik
      final timeoutDuration = currentState.activeModel == 'fast' 
          ? const Duration(seconds: 5) 
          : const Duration(seconds: 15);

      print("Mengirim request dengan model: ${currentState.activeModel}, Timeout: ${timeoutDuration.inSeconds}s");

      // 6. Panggil AI dengan Timeout
      final result = await EdgeFunctionService.callFunction('ai_chat', {
        'message': text,
        'mode': 'chat',
        'context': historyContext,
        'modelType': backendModelName 
      }).timeout(timeoutDuration, onTimeout: () {
        throw TimeoutException("Waktu habis. Coba lagi atau gunakan mode Expert.");
      });

      final replyText = result['text'] ?? "Maaf, saya tidak mengerti.";
      
      final aiMsg = Message(
          id: const Uuid().v4(),
          content: replyText,
          type: MessageType.assistant,
          timestamp: DateTime.now());

      final finalMessages = [...newMessages, aiMsg];
      state = AsyncData(state.value!.copyWith(
        messages: finalMessages, 
        isLoading: false
      ));

      await _supabase.from('chat_messages').insert({
        'session_id': sessionId,
        'content': replyText,
        'is_user': false,
      });

      if (isVoiceInput) speak(replyText);

    } catch (e) {
      // Handle Timeout & Error Lain
      String errorText = "Terjadi kesalahan.";
      if (e is TimeoutException) {
        errorText = "Waktu habis (${currentState.activeModel == 'fast' ? '5s' : '15s'}). Server sibuk atau koneksi lambat.";
      } else {
        errorText = "Gagal: ${e.toString()}";
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

  // --- MODEL SWITCHING ---
  void toggleModel() {
    final current = state.value?.activeModel ?? 'fast';
    // Logic Toggle: Fast <-> Expert
    final newModel = current == 'fast' ? 'expert' : 'fast';
    state = AsyncData(state.value!.copyWith(activeModel: newModel));
  }

  Future<void> toggleListening() async {
    final currentState = state.value ?? AssistantState();

    if (currentState.isSpeaking) {
      await stopSpeaking();
      return;
    }

    if (currentState.isListening) {
      await _speechToText.stop();
      state = AsyncData(currentState.copyWith(isListening: false));
    } else {
      bool available = await _speechToText.initialize();
      if (available) {
        state = AsyncData(currentState.copyWith(isListening: true));
        _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              sendMessage(result.recognizedWords, isVoiceInput: true);
              state = AsyncData(state.value!.copyWith(isListening: false));
            }
          },
          localeId: "id_ID",
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
}