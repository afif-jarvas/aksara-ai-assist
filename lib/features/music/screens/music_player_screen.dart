import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:just_audio/just_audio.dart'; // Pastikan sudah ada di pubspec
import '../models/music_ai_model.dart';

// ==========================================
// 1. BAGIAN LAMA (GEMINI AI GENERATOR)
// ==========================================
class MusicGeminiService {
  static const String _apiKey = 'AIzaSyAnRF2QlniQDheVIKgz0HcYrL9cs1D5D9M';
  late final GenerativeModel _model;

  MusicGeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
  }

  Future<Map<String, dynamic>> generateSong(String topic, String genre, String mood, String language) async {
    try {
      final promptText = """
        Bertindaklah sebagai penulis lagu profesional. Ciptakan lagu orisinal.
        Topik: "$topic"
        Genre: $genre
        Mood: $mood
        Bahasa Lirik: $language (Sesuaikan dengan bahasa ini)

        Berikan respon HANYA dalam format JSON MURNI tanpa markdown (```json). 
        Jangan ada teks pembuka atau penutup.
        Struktur JSON wajib:
        {
          "title": "Judul Lagu",
          "style": "Deskripsi gaya musik singkat",
          "lyrics": [
            {"section": "Verse 1", "text": "Baris lirik...", "chord": "C"},
            {"section": "Chorus", "text": "Baris lirik...", "chord": "Am"}
          ],
          "trivia": "Satu fakta menarik tentang komposisi ini"
        }
      """;

      final response = await _model.generateContent([Content.text(promptText)]);
      final text = response.text;
      
      if (text == null || text.isEmpty) throw Exception("Empty response");

      final int startIndex = text.indexOf('{');
      final int endIndex = text.lastIndexOf('}');

      if (startIndex == -1 || endIndex == -1) {
        throw Exception("Format JSON tidak ditemukan dalam respon AI");
      }

      final cleanJson = text.substring(startIndex, endIndex + 1);
      return jsonDecode(cleanJson);

    } catch (e) {
      print("Music AI Error: $e");
      return {'error': true, 'message': e.toString()};
    }
  }
}

// ==========================================
// 2. BAGIAN BARU (MUSIC PLAYER STATE & LOGIC)
// ==========================================

// State untuk UI Player
class MusicPlayerState {
  final bool isSearching;
  final bool isPlaying;
  final bool isLoadingLyrics;
  final bool isTranslating;
  final Duration position;
  final Duration duration;
  final List<SongModel> searchResults;
  final List<LyricLine> lyrics;
  final int currentLyricIndex;
  final ChordEvent? currentChord;

  MusicPlayerState({
    this.isSearching = false,
    this.isPlaying = false,
    this.isLoadingLyrics = false,
    this.isTranslating = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.searchResults = const [],
    this.lyrics = const [],
    this.currentLyricIndex = -1,
    this.currentChord,
  });

  MusicPlayerState copyWith({
    bool? isSearching,
    bool? isPlaying,
    bool? isLoadingLyrics,
    bool? isTranslating,
    Duration? position,
    Duration? duration,
    List<SongModel>? searchResults,
    List<LyricLine>? lyrics,
    int? currentLyricIndex,
    ChordEvent? currentChord,
  }) {
    return MusicPlayerState(
      isSearching: isSearching ?? this.isSearching,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoadingLyrics: isLoadingLyrics ?? this.isLoadingLyrics,
      isTranslating: isTranslating ?? this.isTranslating,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      searchResults: searchResults ?? this.searchResults,
      lyrics: lyrics ?? this.lyrics,
      currentLyricIndex: currentLyricIndex ?? this.currentLyricIndex,
      currentChord: currentChord ?? this.currentChord,
    );
  }
}

// Controller Logic (Notifier)
class MusicService extends StateNotifier<MusicPlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  // ignore: unused_field
  final MusicGeminiService _geminiService = MusicGeminiService(); // Opsional jika butuh AI
  SongModel? _currentSong;

  MusicService() : super(MusicPlayerState()) {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    // Listen posisi lagu
    _audioPlayer.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
      _updateCurrentLyric(pos);
    });

    // Listen durasi lagu
    _audioPlayer.durationStream.listen((dur) {
      state = state.copyWith(duration: dur ?? Duration.zero);
    });

    // Listen status player
    _audioPlayer.playerStateStream.listen((playerState) {
      state = state.copyWith(isPlaying: playerState.playing);
    });
  }

  // --- ACTIONS ---

  Future<void> searchSongs(String query) async {
    state = state.copyWith(isSearching: true, searchResults: []);
    
    // MOCK DATA (Karena kita belum konek YouTube API beneran di sini)
    // Nanti bisa diganti pakai `youtube_explode_dart`
    await Future.delayed(const Duration(seconds: 1));
    
    final dummyResults = List.generate(5, (index) => SongModel(
      id: '$index',
      title: "$query Song ${index + 1}",
      artist: "Artist ${index + 1}",
      coverUrl: "https://picsum.photos/seed/${index + 100}/300/300",
      audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", 
    ));
    state = state.copyWith(isSearching: false, searchResults: dummyResults);
  }

  Future<void> playSong(SongModel song) async {
    _currentSong = song;
    // Reset state
    state = state.copyWith(
      lyrics: [], 
      currentLyricIndex: -1, 
      isLoadingLyrics: true
    );

    try {
      await _audioPlayer.setUrl(song.audioUrl);
      _audioPlayer.play();
      
      // Mock Load Lyrics (Nanti bisa fetch dari API)
      await _fetchMockLyrics();

    } catch (e) {
      print("Error playing song: $e");
    }
  }

  Future<void> _fetchMockLyrics() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulasi network
    // Dummy Lirik
    final dummyLyrics = [
      LyricLine(text: "Ini adalah intro lagu...", timestamp: const Duration(seconds: 5)),
      LyricLine(text: "Mulai masuk ke verse pertama", timestamp: const Duration(seconds: 10)),
      LyricLine(text: "Musik semakin kencang", timestamp: const Duration(seconds: 15)),
      LyricLine(text: "Reffrain yang sangat indah", timestamp: const Duration(seconds: 20)),
      LyricLine(text: "Kembali tenang...", timestamp: const Duration(seconds: 25)),
    ];
    state = state.copyWith(lyrics: dummyLyrics, isLoadingLyrics: false);
  }

  void _updateCurrentLyric(Duration position) {
    if (state.lyrics.isEmpty) return;
    
    // Cari lirik yang timestamp-nya paling dekat & kurang dari posisi sekarang
    int newIndex = -1;
    for (int i = 0; i < state.lyrics.length; i++) {
      if (position >= state.lyrics[i].timestamp) {
        newIndex = i;
      } else {
        break; 
      }
    }

    if (newIndex != state.currentLyricIndex) {
      state = state.copyWith(currentLyricIndex: newIndex);
    }
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  void pause() {
    _audioPlayer.pause();
  }

  void play() {
    _audioPlayer.play();
  }

  Future<void> translateLyrics() async {
    if (state.isTranslating || state.lyrics.isEmpty) return;
    
    state = state.copyWith(isTranslating: true);
    
    // Simulasi Translate AI
    await Future.delayed(const Duration(seconds: 2));
    
    final translatedLyrics = state.lyrics.map((line) {
      return LyricLine(
        text: line.text,
        timestamp: line.timestamp,
        translation: "${line.text} (Translated)" // Mock translation
      );
    }).toList();

    state = state.copyWith(
      lyrics: translatedLyrics,
      isTranslating: false
    );
  }
  
  // Getter untuk Current Song Provider
  SongModel? get currentSong => _currentSong;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

// ==========================================
// 3. PROVIDERS (GLOBAL ACCESS)
// ==========================================

// Provider Utama (State & Logic)
final musicServiceProvider = StateNotifierProvider<MusicService, MusicPlayerState>((ref) {
  return MusicService();
});

// Provider Khusus untuk mengambil data lagu yang sedang diputar
final currentSongProvider = Provider<SongModel?>((ref) {
  // Kita watch musicServiceProvider hanya untuk memicu rebuild jika state berubah,
  // tapi sebenarnya data lagu ada di notifier-nya.
  // Cara lebih bersih: simpan currentSong di MusicPlayerState. 
  // Tapi untuk quick fix agar compatible dengan UI Screen Anda:
  return ref.watch(musicServiceProvider.notifier).currentSong;
});