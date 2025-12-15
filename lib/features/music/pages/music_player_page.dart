import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../core/localization_service.dart';
import '../services/music_service.dart';

class MusicPlayerPage extends ConsumerStatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  ConsumerState<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends ConsumerState<MusicPlayerPage> {
  late MusicGeminiService _musicService;
  
  final TextEditingController _topicController = TextEditingController();
  String _selectedGenre = 'Pop';
  String _selectedMood = 'Happy'; // Default value (akan ditranslate di UI)
  bool _isLoading = false;
  Map<String, dynamic>? _songResult;

  // List Pilihan (Bisa ditambah)
  final List<String> _genres = ['Pop', 'Jazz', 'Rock', 'Dangdut', 'Indie', 'R&B', 'Ballad'];
  final List<String> _moods = ['Happy', 'Sad', 'Romantic', 'Energetic', 'Chill', 'Melancholy'];

  @override
  void initState() {
    super.initState();
    _musicService = MusicGeminiService();
  }

  void _createSong() async {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'music_error_input')), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _songResult = null;
    });

    FocusScope.of(context).unfocus(); // Tutup keyboard

    // Ambil kode bahasa user saat ini (id, en, ja, dst)
    final userLanguage = ref.read(localeProvider).languageCode;

    // Kirim request ke AI
    final result = await _musicService.generateSong(
      _topicController.text, 
      _selectedGenre, 
      _selectedMood,
      userLanguage
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _songResult = result;
      });

      // Handle Error dari Service
      if (result.containsKey('error') && result['error'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(ref, 'music_error_gen')), 
            backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    
    // Warna Tema
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D3436);
    final hintColor = isDark ? Colors.white38 : Colors.black38;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr(ref, 'music_title'), // "Aksara Songsmith"
          style: GoogleFonts.plusJakartaSans(
            color: textColor, fontWeight: FontWeight.bold, fontSize: 18
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER SECTION ---
            Text(
              tr(ref, 'music_create_title'), // "Buat Lagu Orisinal"
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w800, color: textColor
              ),
            ),
            const SizedBox(height: 20),

            // --- FORM INPUT ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input Topik
                  _buildLabel(tr(ref, 'music_topic_label'), textColor),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _topicController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: tr(ref, 'music_topic_hint'),
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.queue_music, color: Colors.purpleAccent),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Genre & Mood
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          tr(ref, 'music_genre_label'), 
                          _genres, 
                          _selectedGenre, 
                          (v) => setState(() => _selectedGenre = v!), 
                          isDark, textColor, cardColor
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown(
                          tr(ref, 'music_mood_label'), 
                          _moods, 
                          _selectedMood, 
                          (v) => setState(() => _selectedMood = v!), 
                          isDark, textColor, cardColor
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tombol Create
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createSong,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ).copyWith(
                        elevation: MaterialStateProperty.all(8),
                        shadowColor: MaterialStateProperty.all(Colors.purpleAccent.withOpacity(0.4)),
                      ),
                      child: _isLoading 
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              const SizedBox(width: 12),
                              Text(tr(ref, 'music_btn_loading')),
                            ],
                          )
                        : Text(tr(ref, 'music_btn_create'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- RESULT SECTION ---
            if (_songResult != null && !_songResult!.containsKey('error'))
              _buildSongResult(_songResult!, isDark, textColor, cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text, 
      style: GoogleFonts.plusJakartaSans(
        color: color.withOpacity(0.7), 
        fontSize: 13, 
        fontWeight: FontWeight.w600
      )
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged, bool isDark, Color textColor, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, textColor),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: cardColor,
              icon: Icon(Icons.arrow_drop_down_rounded, color: textColor),
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontFamily: 'Plus Jakarta Sans'),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSongResult(Map<String, dynamic> data, bool isDark, Color textColor, Color cardColor) {
    final title = data['title'] ?? 'Untitled';
    final style = data['style'] ?? 'Unknown Style';
    final lyrics = data['lyrics'] as List;
    final trivia = data['trivia'] ?? '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr(ref, 'music_result_title'), 
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
            ),
            IconButton(
              icon: Icon(Icons.copy, size: 20, color: Colors.purpleAccent),
              onPressed: () {
                // Fitur Copy Lirik (Opsional)
                Clipboard.setData(ClipboardData(text: "$title\n\n${lyrics.map((e) => "${e['section']}\n${e['text']}").join('\n\n')}"));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(ref, 'music_copy'))));
              }, 
            )
          ],
        ),
        const SizedBox(height: 16),

        // 1. Kartu Kaset (Header Lagu)
        GlassmorphicContainer(
          width: double.infinity,
          height: 140,
          borderRadius: 24,
          blur: 20,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(
            colors: [const Color(0xFF8E2DE2).withOpacity(0.8), const Color(0xFF4A00E0).withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderGradient: LinearGradient(colors: [Colors.white24, Colors.white10]),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.album_rounded, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title, 
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white
                )
              ),
              const SizedBox(height: 4),
              Text(
                style, 
                style: GoogleFonts.sourceCodePro(fontSize: 12, color: Colors.white70)
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. List Lirik & Chord
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lyrics.length,
          separatorBuilder: (c, i) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final line = lyrics[index];
            final section = line['section'].toString().toUpperCase();
            final text = line['text'];
            final chord = line['chord'];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        section,
                        style: TextStyle(
                          color: Colors.purpleAccent, 
                          fontWeight: FontWeight.w900, 
                          fontSize: 11,
                          letterSpacing: 1.2
                        ),
                      ),
                      if (chord != null && chord.toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            chord,
                            style: GoogleFonts.robotoMono(
                              color: Colors.orange[800], 
                              fontWeight: FontWeight.bold,
                              fontSize: 13
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: GoogleFonts.plusJakartaSans(
                      color: textColor.withOpacity(0.9),
                      fontSize: 16,
                      height: 1.5
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // 3. Trivia Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.2))
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(ref, 'music_trivia'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trivia,
                      style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}