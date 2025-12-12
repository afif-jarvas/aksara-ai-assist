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
    final textColor = isDark ? Colors.white : Colors.black87;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
        appBar: AppBar(
          title: Text(tr(ref, 'about_app'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          bottom: TabBar(
            labelColor: isDark ? Colors.blueAccent : Colors.blue,
            unselectedLabelColor: isDark ? Colors.grey : Colors.grey[600],
            indicatorColor: isDark ? Colors.blueAccent : Colors.blue,
            labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Latar Belakang"),
              Tab(text: "Fitur Utama"),
              Tab(text: "Pengembang"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BackgroundTab(),
            _FeaturesTab(),
            _AuthorsTab(),
          ],
        ),
      ),
    );
  }
}

class _BackgroundTab extends StatelessWidget {
  const _BackgroundTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Text(
              "​Aksara AI lahir dari sebuah ide sederhana: bagaimana jika setiap orang memiliki asisten pribadi yang selalu siap membantu kapan saja?\n\n"
              "​Di tengah derasnya arus informasi, kami percaya bahwa teknologi Artificial Intelligence harusnya memudahkan, bukan membingungkan. Aksara AI dibangun untuk menjadi teman cerdasmu dalam belajar, berkarya, dan menemukan jawaban.\n\n"
              "​Menggabungkan kecanggihan Large Language Model dengan antarmuka yang ramah, Aksara AI hadir untuk meningkatkan produktivitas dan kreativitasmu sehari-hari.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                height: 1.6,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesTab extends StatelessWidget {
  const _FeaturesTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Data Fitur
    final features = [
      {
        'title': 'Aksara Assistant',
        'icon': Icons.chat_bubble_outline_rounded,
        'color': Colors.blue,
        'desc': 'Chatbot cerdas yang siap menjawab pertanyaanmu, membantumu menulis, atau sekadar teman mengobrol. Dilengkapi mode "Pakar" untuk analisis mendalam dan mode "Cepat" untuk respons instan.'
      },
      {
        'title': 'Pengenalan Wajah',
        'icon': Icons.face_retouching_natural_rounded,
        'color': Colors.orange,
        'desc': 'Teknologi biometrik canggih untuk mengidentifikasi dan memverifikasi wajah secara real-time. Berguna untuk keamanan dan personalisasi pengalaman pengguna.'
      },
      {
        'title': 'Pemindaian Teks (OCR)',
        'icon': Icons.document_scanner_rounded,
        'color': Colors.green,
        'desc': 'Ubah gambar dokumen fisik menjadi teks digital yang bisa diedit hanya dalam hitungan detik. Mendukung berbagai bahasa dan tulisan tangan yang jelas.'
      },
      {
        'title': 'Deteksi Objek',
        'icon': Icons.image_search_rounded,
        'color': Colors.pink,
        'desc': 'Arahkan kameramu ke benda di sekitarmu, dan AI akan memberitahumu benda apa itu. Membantu tunanetra atau sekadar untuk belajar kosakata baru.'
      },
      {
        'title': 'Aksara Music',
        'icon': Icons.music_note_rounded,
        'color': Colors.purple,
        'desc': 'Jelaskan musik yang ingin kamu dengar, dan AI akan membuatkannya untukmu. Eksplorasi kreativitas musik tanpa batas.'
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final item = features[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color),
            ),
            title: Text(
              item['title'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  item['desc'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthorsTab extends StatelessWidget {
  const _AuthorsTab();

  @override
  Widget build(BuildContext context) {
    final authors = [
      {
        'name': 'Ananda Afif Fauzan',
        'nim': '2303421025',
        'image': 'assets/images/apip.jpg',
      },
      {
        'name': 'Muhammad Febryadi',
        'nim': '2303421027',
        'image': 'assets/images/febry.jpg',
      },
      {
        'name': 'Lintang Dyahayuningsih',
        'nim': '2303421038',
        'image': 'assets/images/lintang.jpg',
      },
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
            height: 100,
            borderRadius: 16,
            blur: 15,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              colors: [Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderGradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.1)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        author['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          author['name']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Agar kontras di atas glass
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "NIM: ${author['nim']}",
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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