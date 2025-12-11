import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../ui/widgets/animated_background.dart';
import '../../../../ui/theme/app_theme.dart';
import '../../../core/localization_service.dart';
import '../services/music_service.dart';
import '../models/music_ai_model.dart';

class MusicPlayerPage extends ConsumerStatefulWidget {
  const MusicPlayerPage({super.key});
  @override
  ConsumerState<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends ConsumerState<MusicPlayerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rotateController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10));
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLyric(int index) {
    if (index != -1 && _scrollController.hasClients) {
      const double itemHeight = 40.0;
      final double offset = (index * itemHeight) - 100;
      _scrollController.animateTo(offset < 0 ? 0 : offset,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _showSearchModal() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Consumer(builder: (context, ref, _) {
              final service = ref.read(musicServiceProvider.notifier);
              final state = ref.watch(musicServiceProvider);
              return DraggableScrollableSheet(
                  initialChildSize: 0.9,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (_, controller) => Container(
                      decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20))),
                      child: Column(children: [
                        Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white),
                                onChanged: (val) {
                                  service.searchSongs(val);
                                },
                                decoration: InputDecoration(
                                    hintText: tr(ref, 'music_search_hint'),
                                    hintStyle:
                                        const TextStyle(color: Colors.grey),
                                    suffixIcon: state.isSearching
                                        ? Transform.scale(
                                            scale: 0.5,
                                            child:
                                                const CircularProgressIndicator(
                                                    color: Colors.cyanAccent))
                                        : const Icon(Icons.search,
                                            color: Colors.white),
                                    filled: true,
                                    fillColor: Colors.white10,
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                onSubmitted: (val) {
                                  service.searchSongs(val);
                                })),
                        Expanded(
                            child: state.isSearching
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.cyanAccent))
                                : ListView.builder(
                                    controller: controller,
                                    itemCount: state.searchResults.length,
                                    itemBuilder: (context, index) {
                                      final song = state.searchResults[index];
                                      return ListTile(
                                          leading: CachedNetworkImage(
                                              imageUrl: song.coverUrl,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url,
                                                      error) =>
                                                  const Icon(Icons.music_note,
                                                      color: Colors.white)),
                                          title: Text(song.title,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                              maxLines: 1),
                                          subtitle: Text(song.artist,
                                              style: const TextStyle(
                                                  color: Colors.grey)),
                                          onTap: () {
                                            service.playSong(song);
                                            Navigator.pop(context);
                                            _searchController.clear();
                                          });
                                    }))
                      ])));
            }));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider); // Listen Language Change
    final musicState = ref.watch(musicServiceProvider);
    final musicService = ref.read(musicServiceProvider.notifier);
    final currentSong = ref.watch(currentSongProvider);
    final lyrics = musicState.lyrics;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    final displaySong = currentSong ??
        Song(
            id: '0',
            title: tr(ref, 'music_no_song'),
            artist: tr(ref, 'music_artist_hint'),
            coverUrl: '',
            duration: '0');

    ref.listen(musicServiceProvider, (prev, next) {
      if (prev?.currentLyricIndex != next.currentLyricIndex) {
        _scrollToCurrentLyric(next.currentLyricIndex);
      }
    });
    if (musicState.isPlaying && !_rotateController.isAnimating) {
      _rotateController.repeat();
    } else if (!musicState.isPlaying) {
      _rotateController.stop();
    }

    return Scaffold(
      body: AnimatedBackground(
          isDark: isDark,
          child: Column(children: [
            SafeArea(
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.white, size: 30),
                              onPressed: () => Navigator.pop(context)),
                          Text(tr(ref, 'music_title'),
                              style: GoogleFonts.exo2(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          IconButton(
                              icon: const Icon(Icons.search,
                                  color: Colors.white, size: 30),
                              onPressed: _showSearchModal)
                        ]))),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                  AnimatedBuilder(
                      builder: (_, child) => Transform.rotate(
                          angle: _rotateController.value * 2 * pi,
                          child: child),
                      animation: _rotateController,
                      child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                      displaySong.coverUrl.isNotEmpty
                                          ? displaySong.coverUrl
                                          : "https://via.placeholder.com/150"),
                                  fit: BoxFit.cover),
                              border: Border.all(color: Colors.black, width: 8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 30)
                              ]))),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(children: [
                        Text(displaySong.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.merriweather(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text(displaySong.artist,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.exo2(
                                fontSize: 16, color: Colors.white70))
                      ])),
                ])),
            GlassmorphicContainer(
                width: double.infinity,
                height: 320,
                borderRadius: 30,
                blur: 20,
                alignment: Alignment.center,
                border: 0,
                linearGradient: LinearGradient(colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.6)
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderGradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05)
                ]),
                child: Column(children: [
                  Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                          onPressed: musicState.isTranslating
                              ? null
                              : () => musicService.translateLyrics(),
                          icon: musicState.isTranslating
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.cyanAccent))
                              : const Icon(Icons.translate,
                                  color: Colors.cyanAccent, size: 16),
                          label: Text(
                              musicState.isTranslating
                                  ? tr(ref, 'music_translating')
                                  : tr(ref, 'music_translate'),
                              style:
                                  const TextStyle(color: Colors.cyanAccent)))),
                  Expanded(
                      child: musicState.isLoadingLyrics
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white))
                          : ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              itemCount: lyrics.isEmpty ? 1 : lyrics.length,
                              itemBuilder: (context, index) {
                                if (lyrics.isEmpty) {
                                  return Center(
                                      child: Text(tr(ref, 'music_empty'),
                                          style: const TextStyle(
                                              color: Colors.white54)));
                                }
                                final line = lyrics[index];
                                final bool isActive =
                                    index == musicState.currentLyricIndex;
                                return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Column(children: [
                                      Text(line.text,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.exo2(
                                              fontSize: isActive ? 20 : 14,
                                              fontWeight: isActive
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isActive
                                                  ? Colors.white
                                                  : Colors.white38)),
                                      if (line.translation != null)
                                        Text(line.translation!,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.exo2(
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.cyanAccent))
                                    ]));
                              })),
                  Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Slider(
                            value: musicState.position.inSeconds.toDouble(),
                            max: musicState.duration.inSeconds.toDouble() > 0
                                ? musicState.duration.inSeconds.toDouble()
                                : 1.0,
                            onChanged: (val) => musicService
                                .seek(Duration(seconds: val.toInt())),
                            activeColor: Colors.cyanAccent,
                            inactiveColor: Colors.white24),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.skip_previous,
                                      color: Colors.white, size: 40),
                                  onPressed: () {}),
                              GestureDetector(
                                  onTap: () {
                                    if (musicState.isAudioLoading) return;
                                    musicState.isPlaying
                                        ? musicService.pause()
                                        : musicService.play();
                                  },
                                  child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white),
                                      child: musicState.isAudioLoading
                                          ? const Padding(
                                              padding: EdgeInsets.all(20.0),
                                              child: CircularProgressIndicator(
                                                  color: Colors.black,
                                                  strokeWidth: 3))
                                          : Icon(
                                              musicState.isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color: Colors.black,
                                              size: 40))),
                              IconButton(
                                  icon: const Icon(Icons.skip_next,
                                      color: Colors.white, size: 40),
                                  onPressed: () {})
                            ])
                      ]))
                ]))
          ])),
    );
  }
}
