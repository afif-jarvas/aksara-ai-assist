import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../core/edge_function_service.dart';
import '../models/music_ai_model.dart';

class LyricLine {
  final Duration time;
  final String text;
  String? translation;

  LyricLine({required this.time, required this.text, this.translation});

  LyricLine copyWith({String? translation}) {
    return LyricLine(
      time: time,
      text: text,
      translation: translation ?? this.translation,
    );
  }
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.duration,
  });
}

class MusicState {
  final bool isPlaying;
  final bool isAudioLoading;
  final Duration position;
  final Duration duration;
  final bool isSearching;
  final bool isLoadingLyrics;
  final bool isTranslating;
  final List<Song> searchResults;
  final List<LyricLine> lyrics;
  final int currentLyricIndex;

  final AnalysisResult? aiAnalysis;
  final ChordEvent? currentChord;
  final String currentStructure;

  // --- NEW FIELDS FOR GENERATION ---
  final bool isGenerating;
  final GeneratedMusic? generatedMusic;

  // Getter for general loading state used by UI
  bool get isLoading => isGenerating;

  MusicState({
    this.isPlaying = false,
    this.isAudioLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isSearching = false,
    this.isLoadingLyrics = false,
    this.isTranslating = false,
    this.searchResults = const [],
    this.lyrics = const [],
    this.currentLyricIndex = -1,
    this.aiAnalysis,
    this.currentChord,
    this.currentStructure = "",
    this.isGenerating = false,
    this.generatedMusic,
  });

  MusicState copyWith({
    bool? isPlaying,
    bool? isAudioLoading,
    Duration? position,
    Duration? duration,
    bool? isSearching,
    bool? isLoadingLyrics,
    bool? isTranslating,
    List<Song>? searchResults,
    List<LyricLine>? lyrics,
    int? currentLyricIndex,
    AnalysisResult? aiAnalysis,
    ChordEvent? currentChord,
    String? currentStructure,
    bool? isGenerating,
    GeneratedMusic? generatedMusic,
  }) {
    return MusicState(
      isPlaying: isPlaying ?? this.isPlaying,
      isAudioLoading: isAudioLoading ?? this.isAudioLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isSearching: isSearching ?? this.isSearching,
      isLoadingLyrics: isLoadingLyrics ?? this.isLoadingLyrics,
      isTranslating: isTranslating ?? this.isTranslating,
      searchResults: searchResults ?? this.searchResults,
      lyrics: lyrics ?? this.lyrics,
      currentLyricIndex: currentLyricIndex ?? this.currentLyricIndex,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      currentChord: currentChord ?? this.currentChord,
      currentStructure: currentStructure ?? this.currentStructure,
      isGenerating: isGenerating ?? this.isGenerating,
      generatedMusic: generatedMusic ?? this.generatedMusic,
    );
  }
}

final musicServiceProvider =
    StateNotifierProvider<MusicService, MusicState>((ref) => MusicService(ref));

final lyricsProvider = Provider<List<LyricLine>>((ref) {
  return ref.watch(musicServiceProvider).lyrics;
});

final currentSongProvider = StateProvider<Song?>((ref) => null);

class MusicService extends StateNotifier<MusicState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  final Ref _ref;
  Timer? _debounce;

  MusicService(this._ref) : super(MusicState()) {
    _initPlayerListeners();
  }

  // --- NEW METHOD: Music Generation ---
  Future<void> generateMusic(String prompt) async {
    state = state.copyWith(isGenerating: true);
    
    // Simulate AI processing delay
    await Future.delayed(const Duration(seconds: 3));

    try {
      // TODO: Replace with actual Edge Function call when available
      // final result = await EdgeFunctionService.callFunction('music_gen', {'prompt': prompt});
      
      // Dummy Result for Demo
      final dummyResult = GeneratedMusic(
        title: "AI Generated: $prompt",
        imageUrl: "https://picsum.photos/400/400", // Random image
        audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", // Free sample audio
      );

      state = state.copyWith(
        isGenerating: false,
        generatedMusic: dummyResult,
      );
    } catch (e) {
      state = state.copyWith(isGenerating: false);
      print("Music Generation Error: $e");
    }
  }

  void _initPlayerListeners() {
    _audioPlayer.playerStateStream.listen((playerState) {
      final processingState = playerState.processingState;
      final isBuffering = processingState == ProcessingState.buffering ||
          processingState == ProcessingState.loading;

      if (processingState == ProcessingState.completed) {
        state = state.copyWith(isPlaying: false, position: Duration.zero);
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      } else {
        state = state.copyWith(
            isPlaying: playerState.playing,
            isAudioLoading: state.isAudioLoading ? true : isBuffering);
      }
    });

    _audioPlayer.durationStream.listen((d) {
      state = state.copyWith(duration: d ?? Duration.zero);
    });

    _audioPlayer.positionStream.listen((pos) {
      final index = _calculateCurrentLyricIndex(pos);
      _updateAIAnalysis(pos);
      state = state.copyWith(position: pos, currentLyricIndex: index);
    });
  }

  int _calculateCurrentLyricIndex(Duration pos) {
    if (state.lyrics.isEmpty) return -1;
    return state.lyrics.lastIndexWhere((line) => line.time <= pos);
  }

  Future<void> searchSongs(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(isSearching: false, searchResults: []);
      return;
    }
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      state = state.copyWith(isSearching: true, searchResults: []);
      try {
        final result = await _yt.search.search(query);
        final songs = result.where((v) => !v.isLive).take(10).map((video) {
          return Song(
            id: video.id.value,
            title: video.title,
            artist: video.author,
            coverUrl: video.thumbnails.highResUrl,
            duration: video.duration.toString(),
          );
        }).toList();
        state = state.copyWith(searchResults: songs, isSearching: false);
      } catch (e) {
        state = state.copyWith(isSearching: false);
      }
    });
  }

  Future<void> playSong(Song song) async {
    _ref.read(currentSongProvider.notifier).state = song;

    try {
      if (_audioPlayer.playing) await _audioPlayer.stop();
    } catch (_) {}

    state = state.copyWith(
        isLoadingLyrics: true,
        isAudioLoading: true,
        isPlaying: false,
        lyrics: [],
        currentLyricIndex: -1,
        aiAnalysis: null,
        currentChord: null,
        currentStructure: "");

    _fetchLyricsWithAI(song.title, song.artist);
    _generateMusicAnalysis(song.title);

    try {
      final manifest = await _yt.videos.streamsClient.getManifest(song.id);
      var streamUrl = "";
      try {
        streamUrl = manifest.audioOnly.withHighestBitrate().url.toString();
      } catch (_) {
        streamUrl = manifest.muxed.withHighestBitrate().url.toString();
      }

      await _audioPlayer.setUrl(streamUrl);
      _audioPlayer.play();

      state = state.copyWith(isAudioLoading: false, isPlaying: true);
    } catch (e) {
      print("Playback Error: $e");
      state = state.copyWith(isAudioLoading: false, isPlaying: false);
    }
  }

  Future<void> _fetchLyricsWithAI(String title, String artist) async {
    try {
      final prompt = """
      Buatkan lirik lagu lengkap dengan sinkronisasi waktu (format LRC) untuk lagu: "$title" oleh "$artist".
      Format wajib setiap baris: [mm:ss.xx] Lirik lagu disini.
      Jika lagu instrumental, tulis [00:00.00] (Instrumental).
      Jangan ada teks pembuka/penutup, langsung format LRC saja.
      """;

      final response = await EdgeFunctionService.callFunction(
          'ai_chat', {'message': prompt, 'mode': 'general'});
      final rawText = response['text'] ?? "";
      final parsedLyrics = _parseLRC(rawText);
      state = state.copyWith(lyrics: parsedLyrics, isLoadingLyrics: false);
    } catch (e) {
      state = state.copyWith(isLoadingLyrics: false, lyrics: [
        LyricLine(time: Duration.zero, text: "Lirik tidak ditemukan.")
      ]);
    }
  }

  Future<void> translateLyrics() async {
    if (state.lyrics.isEmpty || state.isTranslating) return;
    state = state.copyWith(isTranslating: true);
    try {
      final fullLyricsText = state.lyrics.map((l) => l.text).join("\n");
      final prompt =
          "Terjemahkan lirik ini ke Bahasa Indonesia baris per baris:\n$fullLyricsText";
      final response = await EdgeFunctionService.callFunction(
          'ai_chat', {'message': prompt, 'mode': 'general'});

      final translatedLines = (response['text'] ?? "").split('\n');
      final List<LyricLine> updatedLyrics = [];

      for (int i = 0; i < state.lyrics.length; i++) {
        String? trans;
        if (i < translatedLines.length) {
          final t = translatedLines[i].trim();
          if (t.isNotEmpty) trans = t;
        }
        updatedLyrics.add(state.lyrics[i].copyWith(translation: trans));
      }
      state = state.copyWith(lyrics: updatedLyrics, isTranslating: false);
    } catch (e) {
      state = state.copyWith(isTranslating: false);
    }
  }

  List<LyricLine> _parseLRC(String lrcString) {
    final List<LyricLine> lyrics = [];
    final RegExp regex = RegExp(r'\[(\d{1,2}):(\d{1,2})\.(\d{1,3})\](.*)');
    for (final line in lrcString.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!.padRight(3, '0').substring(0, 3));
        final text = match.group(4)!.trim();
        if (text.isNotEmpty) {
          lyrics.add(LyricLine(
              time: Duration(minutes: min, seconds: sec, milliseconds: ms),
              text: text));
        }
      }
    }
    return lyrics;
  }

  void _generateMusicAnalysis(String title) async {
    await Future.delayed(const Duration(seconds: 1));
    final random = Random();
    final durationSec =
        state.duration.inSeconds > 0 ? state.duration.inSeconds : 180;
    List<String> prog = ['C', 'G', 'Am', 'F', 'Em', 'Dm', 'Bb'];
    List<ChordEvent> chords = [];
    for (int i = 0; i < durationSec; i += 3) {
      chords.add(ChordEvent(
          timestamp: Duration(seconds: i),
          name: prog[random.nextInt(prog.length)]));
    }
    state = state.copyWith(
        aiAnalysis: AnalysisResult(
            chords: chords, beats: [], structure: [], bpm: 120, key: "C"));
  }

  void _updateAIAnalysis(Duration pos) {
    if (state.aiAnalysis != null) {
      try {
        final activeChord =
            state.aiAnalysis!.chords.lastWhere((c) => c.timestamp <= pos);
        if (activeChord != state.currentChord)
          state = state.copyWith(currentChord: activeChord);
      } catch (_) {}
    }
  }

  Future<void> seek(Duration pos) => _audioPlayer.seek(pos);
  Future<void> pause() => _audioPlayer.pause();
  Future<void> play() => _audioPlayer.play();

  @override
  void dispose() {
    _audioPlayer.dispose();
    _yt.close();
    super.dispose();
  }
}