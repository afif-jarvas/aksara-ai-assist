import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/edge_function_service.dart';
import '../models/message.dart';

part 'assistant_service.g.dart';

class AssistantState {
  final List<Message> messages;
  final bool isListening;
  final bool isLoading;
  final String activeModel;
  final bool isSpeaking;

  AssistantState({
    this.messages = const [],
    this.isListening = false,
    this.isLoading = false,
    this.activeModel = 'flash',
    this.isSpeaking = false,
  });

  AssistantState copyWith(
      {List<Message>? messages,
      bool? isListening,
      bool? isLoading,
      String? activeModel,
      bool? isSpeaking}) {
    return AssistantState(
      messages: messages ?? this.messages,
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
  bool _isInitialized = false;
  static const String _historyKey = 'chat_history_v5';

  @override
  Future<AssistantState> build() async {
    if (!_isInitialized) await _initialize();
    final history = await _loadHistory();
    return AssistantState(messages: history);
  }

  Future<void> _initialize() async {
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      state = AsyncData(state.value!.copyWith(isSpeaking: true));
    });

    _flutterTts.setCompletionHandler(() {
      state = AsyncData(state.value!.copyWith(isSpeaking: false));
    });

    _flutterTts.setCancelHandler(() {
      state = AsyncData(state.value!.copyWith(isSpeaking: false));
    });

    _isInitialized = true;
  }

  void toggleModel() {
    final current = state.value?.activeModel ?? 'flash';
    final newModel = current == 'flash' ? 'pro' : 'flash';
    state = AsyncData(state.value!.copyWith(activeModel: newModel));
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    stopSpeaking();
    state = AsyncData(state.value!.copyWith(messages: []));
  }

  Future<List<Message>> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList(_historyKey);
      if (jsonList == null) return [];
      return jsonList.map((str) {
        final map = jsonDecode(str);
        return Message(
          id: map['id'],
          content: map['content'],
          type: map['isUser'] ? MessageType.user : MessageType.assistant,
          timestamp: DateTime.parse(map['timestamp']),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveHistory(List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = messages
        .map((m) => jsonEncode({
              'id': m.id,
              'content': m.content,
              'isUser': m.isUser,
              'timestamp': m.timestamp.toIso8601String(),
            }))
        .toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  Future<void> sendMessage(String text, {bool isVoiceInput = false}) async {
    if (text.trim().isEmpty) return;
    stopSpeaking();

    final currentState = state.value ?? AssistantState();
    final userMsg = Message(
        id: const Uuid().v4(),
        content: text,
        type: MessageType.user,
        timestamp: DateTime.now());

    final newMessages = [...currentState.messages, userMsg];
    state = AsyncData(
        currentState.copyWith(messages: newMessages, isLoading: true));
    _saveHistory(newMessages);

    try {
      // FIX: Mengirim Context ke AI
      final historyContext = newMessages.length > 6
          ? newMessages
              .sublist(newMessages.length - 6)
              .map((m) => "${m.isUser ? 'User' : 'AI'}: ${m.content}")
              .join("\n")
          : "";

      final result = await EdgeFunctionService.callFunction('ai_chat', {
        'message': text,
        'mode': 'chat',
        'context': historyContext,
        'modelType': currentState.activeModel
      });

      final replyText = result['text'] ?? "Maaf, saya tidak mengerti.";
      final aiMsg = Message(
          id: const Uuid().v4(),
          content: replyText,
          type: MessageType.assistant,
          timestamp: DateTime.now());

      final finalMessages = [...newMessages, aiMsg];
      state = AsyncData(
          state.value!.copyWith(messages: finalMessages, isLoading: false));
      _saveHistory(finalMessages);

      if (isVoiceInput) {
        speak(replyText);
      }
    } catch (e) {
      final errorMsg = Message(
          id: const Uuid().v4(),
          content: "Gagal terhubung: $e",
          type: MessageType.assistant,
          timestamp: DateTime.now());
      state = AsyncData(state.value!
          .copyWith(messages: [...newMessages, errorMsg], isLoading: false));
    }
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
