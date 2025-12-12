import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../core/localization_service.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black; // Hitam Pekat
    final activeColor = isDark ? Colors.cyanAccent : Colors.blue[700]; // Biru lebih tua
    final currentFont = ref.watch(fontFamilyProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                ? [const Color(0xFF0F0C29), const Color(0xFF302B63)]
                : [const Color(0xFFE3F2FD), const Color(0xFFF3E5F5)], // Light Gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(tr(ref, 'about_app'), style: GoogleFonts.getFont(currentFont, fontWeight: FontWeight.bold, color: textColor)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: textColor),
              bottom: TabBar(
                labelColor: activeColor,
                // Unselected label di Light Mode pakai hitam transparan
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                indicatorColor: activeColor,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.getFont(currentFont, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: tr(ref, 'tab_bg')),
                  Tab(text: tr(ref, 'tab_feat')),
                  Tab(text: tr(ref, 'tab_dev')),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _BackgroundTab(currentFont),
                _FeaturesTab(currentFont),
                _AuthorsTab(currentFont),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundTab extends ConsumerWidget {
  final String font;
  const _BackgroundTab(this.font);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 450,
        borderRadius: 20,
        blur: 15,
        alignment: Alignment.center,
        border: 2,
        // Linear Gradient Glass diperkuat agar terlihat di background terang
        linearGradient: LinearGradient(
          colors: isDark 
            ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
            : [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.3)], // Lebih solid di light mode
        ),
        borderGradient: LinearGradient(
          colors: isDark
            ? [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.1)]
            : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.5)], // Border lebih terlihat
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 60, color: Theme.of(context).primaryColor),
              const SizedBox(height: 20),
              Text(
                tr(ref, 'about_bg_text'),
                style: GoogleFonts.getFont(font,
                  fontSize: 16,
                  height: 1.6,
                  // Gunakan warna hitam pekat jika light mode
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturesTab extends ConsumerWidget {
  final String font;
  const _FeaturesTab(this.font);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = [
      {'title': tr(ref, 'feat_title_assist'), 'icon': Icons.chat_bubble_outline_rounded, 'color': Colors.blue, 'desc': tr(ref, 'feat_desc_assist')},
      {'title': tr(ref, 'feat_title_face'), 'icon': Icons.face_retouching_natural_rounded, 'color': Colors.orange, 'desc': tr(ref, 'feat_desc_face')},
      {'title': tr(ref, 'feat_title_ocr'), 'icon': Icons.document_scanner_rounded, 'color': Colors.green, 'desc': tr(ref, 'feat_desc_ocr')},
      {'title': tr(ref, 'feat_title_obj'), 'icon': Icons.image_search_rounded, 'color': Colors.pink, 'desc': tr(ref, 'feat_desc_obj')},
      {'title': tr(ref, 'feat_title_music'), 'icon': Icons.music_note_rounded, 'color': Colors.purple, 'desc': tr(ref, 'feat_desc_music')},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final item = features[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            // Background putih solid di light mode agar tulisan terbaca jelas
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isDark ? Colors.white12 : Colors.white54),
            boxShadow: [
              if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ]
          ),
          child: ExpansionTile(
            leading: Icon(item['icon'] as IconData, color: item['color'] as Color),
            title: Text(item['title'] as String, style: GoogleFonts.getFont(font, fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(item['desc'] as String, style: GoogleFonts.getFont(font, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthorsTab extends ConsumerWidget {
  final String font;
  const _AuthorsTab(this.font);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // REVISI: Menggunakan tr() untuk Role agar diterjemahkan
    final authors = [
      {'name': 'Ananda Afif Fauzan', 'nim': '2303421025', 'image': 'assets/images/apip.jpg', 'role': tr(ref, 'role_ai')},
      {'name': 'Muhammad Febryadi', 'nim': '2303421027', 'image': 'assets/images/febry.jpg', 'role': tr(ref, 'role_mobile')},
      {'name': 'Lintang Dyahayuningsih', 'nim': '2303421038', 'image': 'assets/images/lintang.jpg', 'role': tr(ref, 'role_ui')},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: authors.length,
      itemBuilder: (context, index) {
        final author = authors[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 110,
            borderRadius: 20,
            blur: 20,
            alignment: Alignment.center,
            border: 2,
            // Glass effect di Light Mode dibuat lebih 'frosted'
            linearGradient: LinearGradient(
              colors: isDark 
                ? [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)]
                : [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.3)],
            ),
            borderGradient: LinearGradient(
              colors: isDark
                ? [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.1)]
                : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.5)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        author['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(color: Colors.grey, child: const Icon(Icons.person, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          author['name']!,
                          style: GoogleFonts.getFont(font,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            // Warna teks dalam glass card
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black38 : Colors.white54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                author['nim']!,
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 11, 
                                  color: isDark ? Colors.white : Colors.black87, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Role kini dinamis sesuai bahasa
                            Text(
                              author['role']!,
                              style: GoogleFonts.getFont(font, fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}