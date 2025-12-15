import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart'; 
import '../../../core/localization_service.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final activeColor = isDark ? Colors.cyanAccent : Colors.blue[700];
    final currentFont = ref.watch(fontFamilyProvider);

    TextStyle safeFont(String fontName, {double? fontSize, FontWeight? fontWeight, Color? color, double? height}) {
      try {
        return GoogleFonts.getFont(fontName, fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);
      } catch (e) {
        return GoogleFonts.plusJakartaSans(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
              ? [const Color(0xFF0F0C29), const Color(0xFF302B63)]
              : [const Color(0xFFE3F2FD), const Color(0xFFF3E5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                tr(ref, 'about_app'), 
                style: safeFont(currentFont, fontWeight: FontWeight.bold, color: textColor)
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: textColor),
              bottom: TabBar(
                controller: _tabController,
                labelColor: activeColor,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                indicatorColor: activeColor,
                indicatorWeight: 3,
                labelStyle: safeFont(currentFont, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: tr(ref, 'tab_bg')),
                  Tab(text: tr(ref, 'tab_feat')),
                  Tab(text: tr(ref, 'tab_dev')),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _BackgroundTab(currentFont, safeFont, version: _version, buildNumber: _buildNumber),
                _FeaturesTab(currentFont, safeFont),
                _AuthorsTab(currentFont, safeFont),
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
  final Function safeFont;
  final String version;
  final String buildNumber;

  const _BackgroundTab(this.font, this.safeFont, {this.version = '1.0.0', this.buildNumber = '1'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.5),
                width: 1.5
              ),
              gradient: LinearGradient(
                colors: isDark 
                  ? [Colors.black.withOpacity(0.3), Colors.white.withOpacity(0.05)]
                  : [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, size: 50, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 24),
                Text(
                  tr(ref, 'app_name'),
                  style: safeFont(font, 
                    fontSize: 24.0, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : Colors.black
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black45 : Colors.white54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  child: Text(
                    "v$version (Build $buildNumber)",
                    style: GoogleFonts.sourceCodePro(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  tr(ref, 'about_bg_text'),
                  style: safeFont(font,
                    fontSize: 16.0,
                    height: 1.6,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr(ref, 'copyright_text'),
            style: safeFont(font, 
              fontSize: 12.0, 
              color: isDark ? Colors.white54 : Colors.black38
            ),
          )
        ],
      ),
    );
  }
}

class _FeaturesTab extends ConsumerWidget {
  final String font;
  final Function safeFont;
  const _FeaturesTab(this.font, this.safeFont);

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
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final item = features[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isDark ? Colors.white12 : Colors.white54),
            boxShadow: [
              if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ]
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color),
            ),
            title: Text(
              item['title'] as String, 
              style: safeFont(font, fontWeight: FontWeight.bold, fontSize: 16.0, color: isDark ? Colors.white : Colors.black)
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(
                  item['desc'] as String, 
                  style: safeFont(font, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)
                ),
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
  final Function safeFont;
  const _AuthorsTab(this.font, this.safeFont);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? Colors.cyanAccent : Colors.blue[700];
    
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
        // --- DESAIN BARU: Vertical Card Besar ---
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white12 : Colors.white70),
            gradient: LinearGradient(
              colors: isDark 
                ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                : [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
              // 1. FOTO BESAR (120px)
              Container(
                width: 120, 
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor ?? Colors.blue, 
                    width: 3
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), 
                      blurRadius: 12,
                      offset: const Offset(0, 6)
                    )
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    author['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: Colors.grey[800], 
                      child: const Icon(Icons.person, size: 60, color: Colors.white)
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 2. NAMA (Lebih Besar)
              Text(
                author['name']!,
                style: safeFont(font,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // 3. NIM
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black45 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12)
                ),
                child: Text(
                  author['nim']!,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 14, 
                    color: isDark ? Colors.white70 : Colors.black87, 
                    fontWeight: FontWeight.w600
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