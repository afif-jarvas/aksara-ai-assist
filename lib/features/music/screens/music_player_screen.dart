import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/music_service.dart'; // Sesuaikan path ini
import '../models/music_ai_model.dart'; // Sesuaikan path ini

class MusicPlayerScreen extends ConsumerStatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  ConsumerState<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends ConsumerState<MusicPlayerScreen> {
  // Controller untuk lirik auto-scroll
  final ScrollController _lyricsController = ScrollController();

  @override
  void dispose() {
    _lyricsController.dispose();
    super.dispose();
  }

  // Fungsi Helper: Scroll ke lirik aktif
  void _scrollToCurrentLyric(int index) {
    if (index != -1 && _lyricsController.hasClients) {
      // Perkiraan tinggi per item lirik (misal 60 pixel)
      // Ini cara simpel. Untuk presisi tinggi butuh library tambahan, tapi ini cukup.
      const double itemHeight = 60.0;
      final double offset =
          (index * itemHeight) - 100; // -100 agar agak di tengah

      _lyricsController.animateTo(
        offset < 0 ? 0 : offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(musicServiceProvider);
    final musicNotifier = ref.read(musicServiceProvider.notifier);
    final currentSong = ref.watch(currentSongProvider);

    // [FIX PROBLEM 1]: Trigger Auto Scroll saat index berubah
    ref.listen(musicServiceProvider, (previous, next) {
      if (previous?.currentLyricIndex != next.currentLyricIndex) {
        _scrollToCurrentLyric(next.currentLyricIndex);
      }
    });

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Stack(
        children: [
          // 1. Background Image / Gradient
          Positioned.fill(
            child: currentSong != null && currentSong.coverUrl.isNotEmpty
                ? Image.network(currentSong.coverUrl,
                    fit: BoxFit.cover,
                    color: Colors.black54,
                    colorBlendMode: BlendMode.darken)
                : Container(color: Colors.black),
          ),

          // 2. Konten Utama (Header, Disk, Controls)
          SafeArea(
            child: Column(
              children: [
                // Header Search
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Cari Lagu...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      suffixIcon: musicState.isSearching
                          ? Transform.scale(
                              scale: 0.5,
                              child:
                                  const CircularProgressIndicator()) // const dipindah ke dalam child
                          : const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onSubmitted: (query) => musicNotifier.searchSongs(query),
                  ),
                ),

                // List Hasil Search (Overlay jika ada)
                if (musicState.searchResults.isNotEmpty)
                  Container(
                    height: 200,
                    color: Colors.black87,
                    child: ListView.builder(
                      itemCount: musicState.searchResults.length,
                      itemBuilder: (context, index) {
                        final song = musicState.searchResults[index];
                        return ListTile(
                          leading: Image.network(song.coverUrl, width: 50),
                          title: Text(song.title,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 1),
                          subtitle: Text(song.artist,
                              style: const TextStyle(color: Colors.grey)),
                          onTap: () {
                            musicNotifier.playSong(song);
                            // Tutup hasil search manual jika perlu
                          },
                        );
                      },
                    ),
                  ),

                const Spacer(),

                // Cover Art (Berputar atau Statis)
                if (currentSong != null) ...[
                  CircleAvatar(
                    radius: 100,
                    backgroundImage: NetworkImage(currentSong.coverUrl),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentSong.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    currentSong.artist,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  // Tampilkan Chord AI
                  if (musicState.currentChord != null)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text("Chord: ${musicState.currentChord!.name}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],

                const Spacer(),

                // Player Controls (Slider & Buttons)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      Slider(
                        value: musicState.position.inSeconds.toDouble(),
                        max: musicState.duration.inSeconds.toDouble(),
                        onChanged: (val) =>
                            musicNotifier.seek(Duration(seconds: val.toInt())),
                        activeColor: Colors.cyanAccent,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous,
                                color: Colors.white, size: 40),
                            onPressed:
                                () {}, // Implement prev song if list exists
                          ),
                          FloatingActionButton(
                            backgroundColor: Colors.white,
                            onPressed: () {
                              musicState.isPlaying
                                  ? musicNotifier.pause()
                                  : musicNotifier.play();
                            },
                            child: Icon(
                              musicState.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next,
                                color: Colors.white, size: 40),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Ruang kosong di bawah agar tidak tertutup DraggableSheet saat collapsed
                const SizedBox(height: 80),
              ],
            ),
          ),

          // 3. [FITUR SWIPE UP & LIRIK]
          DraggableScrollableSheet(
            initialChildSize: 0.15, // Tinggi awal (hanya intip dikit)
            minChildSize: 0.15,
            maxChildSize: 0.9, // Tinggi maksimal (full screen)
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black54, blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: Column(
                  children: [
                    // Handle Bar (Garis kecil di atas)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 10),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    // Header Panel Lirik
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Lirik & AI Translate",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),

                          // [FIX PROBLEM 2 & 4]: Tombol Translate Eksplisit
                          if (musicState.lyrics.isNotEmpty)
                            TextButton.icon(
                              onPressed: musicState.isTranslating
                                  ? null
                                  : () => musicNotifier.translateLyrics(),
                              icon: musicState.isTranslating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.translate,
                                      color: Colors.cyanAccent),
                              label: Text(
                                musicState.isTranslating
                                    ? "Menerjemahkan..."
                                    : "Translate AI",
                                style:
                                    const TextStyle(color: Colors.cyanAccent),
                              ),
                            )
                        ],
                      ),
                    ),

                    const Divider(color: Colors.white24),

                    // List Lirik (Scrollable)
                    Expanded(
                      child: musicState.isLoadingLyrics
                          ? const Center(child: CircularProgressIndicator())
                          : musicState.lyrics.isEmpty
                              ? const Center(
                                  child: Text("Lirik belum tersedia",
                                      style: TextStyle(color: Colors.white54)))
                              // Gunakan ListView.builder dengan controller terpisah
                              // atau gabungkan logic scrollController dari DraggableSheet
                              // (Disini kita pakai logic khusus agar Auto Scroll jalan di dalam Sheet)
                              : ListView.builder(
                                  // Kita bind _lyricsController ke state agar bisa di-animate
                                  controller: _lyricsController,
                                  padding: const EdgeInsets.all(20),
                                  itemCount: musicState.lyrics.length,
                                  itemExtent:
                                      70.0, // Tinggi tetap agar kalkulasi scroll akurat
                                  itemBuilder: (context, index) {
                                    final line = musicState.lyrics[index];
                                    final isActive =
                                        index == musicState.currentLyricIndex;

                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      decoration: isActive
                                          ? BoxDecoration(
                                              color: Colors.white10,
                                              borderRadius:
                                                  BorderRadius.circular(8))
                                          : null,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Lirik Asli
                                          Text(
                                            line.text,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: isActive
                                                  ? Colors.white
                                                  : Colors.white60,
                                              fontSize: isActive ? 18 : 16,
                                              fontWeight: isActive
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),

                                          // [FITUR TRANSLATE AI]
                                          if (line.translation != null)
                                            Text(
                                              line.translation!,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color:
                                                    Colors.cyanAccent.shade100,
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
