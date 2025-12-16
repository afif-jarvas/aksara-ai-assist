import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // TAMBAHKAN INI
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/edge_function_service.dart';
import '../../../core/activity_provider.dart';
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
  final bool isSpeaking;

  AssistantState({
    this.messages = const [],
    this.historySessions = const [],
    this.currentSessionId,
    this.isListening = false,
    this.isLoading = false,
    this.isSpeaking = false,
  });

  AssistantState copyWith({
    List<Message>? messages,
    List<ChatSession>? historySessions,
    String? currentSessionId,
    bool? isListening,
    bool? isLoading,
    bool? isSpeaking,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      historySessions: historySessions ?? this.historySessions,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isListening: isListening ?? this.isListening,
      isLoading: isLoading ?? this.isLoading,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}

// --- SERVICE PROVIDER ---

@riverpod
class AssistantService extends _$AssistantService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  // Gunakan Client Supabase untuk DB
  final _supabase = Supabase.instance.client; 
  // Gunakan Firebase Auth untuk User ID
  final _auth = FirebaseAuth.instance; 
  
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

  // --- SESSION MANAGEMENT (MODIFIED FOR FIREBASE UID) ---

  Future<List<ChatSession>> _fetchSessions() async {
    try {
      // PERUBAHAN 1: Ambil ID dari Firebase, bukan Supabase Auth
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final response = await _supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', userId) // Menggunakan UID Firebase
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);
      
      return (response as List).map((e) => ChatSession.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching sessions: $e");
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

  // --- FEATURES ---

  Future<void> deleteSession(String sessionId) async {
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

  Future<void> sendMessage(String text, {bool isVoiceInput = false}) async {
    if (text.trim().isEmpty) return;
    stopSpeaking();

    // 1. UPDATE UI DULUAN (OPTIMISTIC)
    final currentState = state.value ?? AssistantState();
    final tempId = const Uuid().v4();
    
    final userMsg = Message(
        id: tempId,
        content: text,
        type: MessageType.user,
        timestamp: DateTime.now());

    final optimisticMessages = [...?currentState.messages, userMsg];
    
    state = AsyncData(currentState.copyWith(
      messages: optimisticMessages, 
      isLoading: true
    ));

    // 2. DAPATKAN FIREBASE USER ID
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
       // Handle jika user belum login
       final errorMsg = Message(id: const Uuid().v4(), content: "Silakan login kembali.", type: MessageType.assistant, timestamp: DateTime.now());
       state = AsyncData(state.value!.copyWith(messages: [...optimisticMessages, errorMsg], isLoading: false));
       return;
    }

    String? sessionId = currentState.currentSessionId;

    try {
      // 3. LOGIKA SUPABASE DB (Create Session)
      if (sessionId == null) {
        final title = text.length > 30 ? "${text.substring(0, 30)}..." : text;
        final sessionRes = await _supabase.from('chat_sessions').insert({
          'user_id': userId, // PENTING: Gunakan UID Firebase
          'title': title,
        }).select().single();
        
        sessionId = sessionRes['id'];
        
        final updatedSessions = await _fetchSessions();
        state = AsyncData(state.value!.copyWith(
          currentSessionId: sessionId,
          historySessions: updatedSessions
        ));
      }

      // Log Activity (Optional)
      try {
        ref.read(activityProvider.notifier).addActivity(
          'assist_title', 
          'assist_intro',
          Icons.auto_awesome_rounded,
          Colors.blueAccent,
        );
      } catch (_) {}

      // Simpan Pesan User ke Supabase
      await _supabase.from('chat_messages').insert({
        'session_id': sessionId,
        'content': text,
        'is_user': true,
      });

      // 4. PANGGIL EDGE FUNCTION (AI)
      // Context history
      final historyContext = optimisticMessages.length > 5
          ? optimisticMessages.sublist(optimisticMessages.length - 5)
              .map((m) => "${m.isUser ? 'User' : 'Assistant'}: ${m.content}").join("\n")
          : optimisticMessages.map((m) => "${m.isUser ? 'User' : 'Assistant'}: ${m.content}").join("\n");

      const timeoutDuration = Duration(seconds: 15);

      // Panggil AI Chat (Mengirim userID Firebase ke Edge Function agar AI kenal user)
      final result = await EdgeFunctionService.aiChat(
        message: text,
        userId: userId, // PENTING: Oper ID Firebase ke backend AI
      ).timeout(timeoutDuration);

      final replyText = result['text'] ?? "Maaf, saya tidak mengerti.";

      // 5. TAMPILKAN BALASAN AI
      final aiMsg = Message(
          id: const Uuid().v4(),
          content: replyText,
          type: MessageType.assistant,
          timestamp: DateTime.now());

      final currentMessagesAfterWait = state.value?.messages ?? [];
      
      state = AsyncData(state.value!.copyWith(
        messages: [...currentMessagesAfterWait, aiMsg], 
        isLoading: false
      ));

      // Simpan Balasan AI ke DB
      await _supabase.from('chat_messages').insert({
        'session_id': sessionId,
        'content': replyText,
        'is_user': false,
      });

      if (isVoiceInput) speak(replyText);

    } catch (e) {
      String errorText = "Terjadi kesalahan koneksi.";
      if (e is TimeoutException) {
        errorText = "Koneksi lambat. Mohon coba lagi.";
      } else {
        errorText = "Error: $e";
      }

      final errorMsg = Message(
          id: const Uuid().v4(),
          content: errorText,
          type: MessageType.assistant,
          timestamp: DateTime.now());
      
      final currentMessages = state.value?.messages ?? [];
      state = AsyncData(state.value!.copyWith(
        messages: [...currentMessages, errorMsg], 
        isLoading: false
      ));
    }
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