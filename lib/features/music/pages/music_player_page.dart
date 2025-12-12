import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization_service.dart';

class MusicPlayerPage extends ConsumerStatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  ConsumerState<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends ConsumerState<MusicPlayerPage> {
  bool isPlaying = false;
  double sliderValue = 0.3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Mengambil warna teks yang kontras (putih di dark mode, hitam di light mode)
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      // Pastikan background tidak transparan agar tidak "menyatu" dengan aplikasi lain
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: AppBar(
        title: Text(tr(ref, 'music_player_title')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cover Art dengan Shadow agar menonjol
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black54 : Colors.grey.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  size: 120,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 40),
              
              // Judul & Artis (Masalah Kontras Diperbaiki)
              Text(
                tr(ref, 'unknown_song'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor, // Wajib menggunakan onSurface
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(ref, 'unknown_artist'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: textColor.withOpacity(0.7), // Sedikit pudar tapi tetap terbaca
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Slider
              Row(
                children: [
                  Text("0:45", style: TextStyle(color: textColor)),
                  Expanded(
                    child: Slider(
                      value: sliderValue,
                      activeColor: theme.primaryColor,
                      inactiveColor: isDark ? Colors.grey[700] : Colors.grey[300],
                      onChanged: (val) => setState(() => sliderValue = val),
                    ),
                  ),
                  Text("3:12", style: TextStyle(color: textColor)),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: textColor,
                    onPressed: () {},
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: IconButton(
                      iconSize: 35,
                      icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      color: Colors.white, // Ikon tombol play selalu putih
                      onPressed: () => setState(() => isPlaying = !isPlaying),
                    ),
                  ),
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.skip_next_rounded),
                    color: textColor,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}