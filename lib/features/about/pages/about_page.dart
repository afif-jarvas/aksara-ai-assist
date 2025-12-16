import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart'; 
import '../../../core/localization_service.dart';
import '../../../ui/theme/app_theme.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Default value agar tidak blank saat loading
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initPackageInfo();
  }

  // Fungsi aman untuk load versi aplikasi
  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (e) {
      debugPrint("Gagal load version: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper Judul Tab 5 Bahasa
  String _getTabTitle(WidgetRef ref, int index) {
    final lang = ref.watch(localeProvider).languageCode;
    switch (index) {
      case 0: 
        if (lang == 'id') return 'Tentang';
        if (lang == 'zh') return '关于';
        if (lang == 'ja') return '概要';
        if (lang == 'ko') return '정보';
        return 'About';
      case 1:
        if (lang == 'id') return 'Fitur';
        if (lang == 'zh') return '功能';
        if (lang == 'ja') return '機能';
        if (lang == 'ko') return '기능';
        return 'Features';
      case 2:
        if (lang == 'id') return 'Tim';
        if (lang == 'zh') return '团队';
        if (lang == 'ja') return 'チーム';
        if (lang == 'ko') return '팀';
        return 'Team';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark || 
                   (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Stack(
      children: [
        // 1. LAYER BACKGROUND (Gradient Full Screen)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF0F0C29), const Color(0xFF302B63)] // Gradient Gelap
                  : [const Color(0xFFE3F2FD), const Color(0xFFF3E5F5)], // Gradient Terang
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),

        // 2. LAYER KONTEN (Scaffold Transparan)
        Scaffold(
          backgroundColor: Colors.transparent, // Wajib transparan agar background terlihat
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              tr(ref, 'about_title'),
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: isDark ? Colors.cyanAccent : Colors.blue[700],
              unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
              indicatorColor: isDark ? Colors.cyanAccent : Colors.blue[700],
              indicatorWeight: 3,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: _getTabTitle(ref, 0)),
                Tab(text: _getTabTitle(ref, 1)),
                Tab(text: _getTabTitle(ref, 2)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _BackgroundTab(version: _version, buildNumber: _buildNumber, isDark: isDark),
              _FeaturesTab(isDark: isDark),
              _AuthorsTab(isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// TAB 1: BACKGROUND (INFO APLIKASI)
// =============================================================================
class _BackgroundTab extends ConsumerWidget {
  final String version;
  final String buildNumber;
  final bool isDark;

  const _BackgroundTab({
    required this.version, 
    required this.buildNumber, 
    required this.isDark
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.cyanAccent.withOpacity(0.3) : Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: const Icon(Icons.auto_awesome, size: 60, color: Colors.blueAccent),
          ),
          const SizedBox(height: 24),
          
          // Nama App
          Text(
            "AKSARA AI",
            style: GoogleFonts.orbitron(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: isDark ? Colors.cyanAccent : Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          
          // Versi Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
            ),
            child: Text(
              "v$version (Build $buildNumber)",
              style: GoogleFonts.sourceCodePro(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Konten Deskripsi (Standard Container, Bukan Glassmorphic yang bikin blank)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.08) 
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(ref, 'about_desc_title'), // "Apa itu Aksara AI?"
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr(ref, 'about_desc_content'), // Konten Panjang
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    height: 1.6,
                    color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          Text(
            "© 2024 Aksara AI Team",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 2: FEATURES (FITUR)
// =============================================================================
class _FeaturesTab extends ConsumerWidget {
  final bool isDark;
  const _FeaturesTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = [
      {
        'title': tr(ref, 'feat_title_assist'), 
        'desc': tr(ref, 'feature_chat'),
        'icon': Icons.chat_bubble_outline_rounded,
        'color': Colors.blueAccent,
      },
      {
        'title': tr(ref, 'face_title'),
        'desc': tr(ref, 'feature_face'),
        'icon': Icons.face_retouching_natural_rounded,
        'color': Colors.orangeAccent,
      },
      {
        'title': tr(ref, 'ocr_title'),
        'desc': tr(ref, 'feature_ocr'),
        'icon': Icons.document_scanner_rounded,
        'color': Colors.greenAccent,
      },
      {
        'title': tr(ref, 'qr_title'),
        'desc': tr(ref, 'feature_qr'),
        'icon': Icons.qr_code_scanner_rounded,
        'color': Colors.pinkAccent,
      },
      {
        'title': tr(ref, 'music_title'),
        'desc': tr(ref, 'desc_music'),
        'icon': Icons.music_note_rounded,
        'color': Colors.purpleAccent,
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: features.length,
      separatorBuilder: (ctx, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = features[index];
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 28),
            ),
            title: Text(
              item['title'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                item['desc'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// TAB 3: AUTHORS (TIM PENGEMBANG)
// =============================================================================
class _AuthorsTab extends ConsumerWidget {
  final bool isDark;
  const _AuthorsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authors = [
      {'name': 'Ananda Afif Fauzan', 'nim': '2303421025', 'image': 'assets/images/apip.jpg'},
      {'name': 'Muhammad Febryadi', 'nim': '2303421027', 'image': 'assets/images/febry.jpg'},
      {'name': 'Lintang Dyahayuningsih', 'nim': '2303421038', 'image': 'assets/images/lintang.jpg'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: authors.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final author = authors[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Foto Profil
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Image.asset(
                      author['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 2. Nama
              Text(
                author['name']!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // 3. NIM
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.blueAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  author['nim']!,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 14,
                    color: isDark ? Colors.blueAccent[100] : Colors.blueAccent[700],
                    fontWeight: FontWeight.w700,
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