import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:just_audio/just_audio.dart';
// IMPORTANT: Import localization_service for themeProvider, not app_theme.dart
import '../../../core/localization_service.dart'; 
import '../models/music_ai_model.dart';
import '../services/music_service.dart';

class MusicPlayerPage extends ConsumerStatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  ConsumerState<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends ConsumerState<MusicPlayerPage> {
  final _promptController = TextEditingController();
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _promptController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _generateMusic() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    // Call service to generate music
    // Note: Ensure MusicService is implemented correctly
    await ref.read(musicServiceProvider.notifier).generateMusic(prompt);
  }

  Future<void> _playPause(String? url) async {
    if (url == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    // CORRECTED: Use providers from localization_service.dart
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final musicState = ref.watch(musicServiceProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Aksara Music", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Input Section
            GlassmorphicContainer(
              width: double.infinity,
              height: 160,
              borderRadius: 20,
              blur: 20,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderGradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.1)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _promptController,
                      style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: "Deskripsikan musik yang diinginkan...",
                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      maxLines: 2,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: musicState.isLoading ? null : _generateMusic,
                        icon: musicState.isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                            : const Icon(Icons.music_note_rounded),
                        label: Text(musicState.isLoading ? "Sedang Membuat..." : "Buat Musik"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Result Section
            if (musicState.generatedMusic != null) ...[
              Text("Hasil Generasi", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: musicState.generatedMusic!.imageUrl != null 
                            ? DecorationImage(image: NetworkImage(musicState.generatedMusic!.imageUrl!), fit: BoxFit.cover)
                            : null,
                        color: Colors.grey[800],
                      ),
                      child: musicState.generatedMusic!.imageUrl == null 
                          ? const Icon(Icons.album, size: 60, color: Colors.white54) 
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _playPause(musicState.generatedMusic!.audioUrl),
                          icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, size: 60, color: Colors.deepPurpleAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(musicState.generatedMusic!.title ?? "Untitled Track", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}