import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/localization_service.dart';
import '../../legal/pages/privacy_policy_page.dart';
import '../../about/pages/about_page.dart';

class AssistantPage extends ConsumerWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    
    // REVISI: Warna teks Hitam Pekat di Light Mode
    final textColor = isDark ? Colors.white : Colors.black;
    final currentFont = ref.watch(fontFamilyProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      // APP BAR
      appBar: AppBar(
        title: Text(
          tr(ref, 'assist_title'),
          style: GoogleFonts.getFont(currentFont,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        // Icon theme diambil dari AppTheme, tapi dipastikan disini juga
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: textColor),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      
      // DRAWER (SIDEBAR)
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: Column(
          children: [
            // Header Logo
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.blueAccent.withOpacity(0.05),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 48, color: isDark ? Colors.cyanAccent : Colors.blueAccent),
                    const SizedBox(height: 10),
                    Text(
                      tr(ref, 'app_name'),
                      style: GoogleFonts.getFont(currentFont,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(context, ref, Icons.home_rounded, tr(ref, 'home'), textColor, () {
                    Navigator.pop(context); 
                  }),
                  _buildDrawerItem(context, ref, Icons.history_rounded, tr(ref, 'history'), textColor, () {
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(context, ref, Icons.settings_rounded, tr(ref, 'settings'), textColor, () {
                    Navigator.pop(context);
                    _showSettingsModal(context, ref);
                  }),
                  Divider(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  _buildDrawerItem(context, ref, Icons.info_outline_rounded, tr(ref, 'about_app'), textColor, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
                  }),
                  _buildDrawerItem(context, ref, Icons.privacy_tip_outlined, tr(ref, 'privacy'), textColor, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
                  }),
                ],
              ),
            ),

            // FOOTER: USER PROFILE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
                color: isDark ? const Color(0xFF252525) : const Color(0xFFFAFAFA),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: const AssetImage('assets/images/apip.jpg'), 
                    backgroundColor: Colors.grey.shade300,
                    onBackgroundImageError: (_,__) {},
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(ref, 'user_name_placeholder'),
                          style: GoogleFonts.getFont(currentFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          tr(ref, 'user_role_placeholder'),
                          style: GoogleFonts.getFont(currentFont,
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey[700], // Grey lebih gelap
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // BODY CHAT
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: isDark ? Colors.white24 : Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    tr(ref, 'assist_intro'),
                    style: GoogleFonts.getFont(currentFont,
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.grey[700], // Kontras lebih kuat
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Input Field Area
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                // REVISI: Background input di light mode sedikit lebih gelap agar terlihat bedanya dengan background putih
                color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr(ref, 'assist_hint'),
                      style: GoogleFonts.getFont(currentFont, color: isDark ? Colors.white54 : Colors.grey[600]),
                    ),
                  ),
                  Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, WidgetRef ref, IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color.withOpacity(0.7)),
      title: Text(
        title,
        style: GoogleFonts.getFont(ref.watch(fontFamilyProvider),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showSettingsModal(BuildContext context, WidgetRef ref) {
    final isDark = ref.read(themeProvider) == ThemeMode.dark;
    final currentFont = ref.watch(fontFamilyProvider);
    final modalTextColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(ref, 'settings'), style: GoogleFonts.getFont(currentFont, fontWeight: FontWeight.bold, fontSize: 20, color: modalTextColor)),
            const SizedBox(height: 20),
            
            Text(tr(ref, 'language'), style: GoogleFonts.getFont(currentFont, color: isDark ? Colors.white70 : Colors.grey[700])),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _langBtn(ref, 'Indonesia', 'id', currentFont),
                  const SizedBox(width: 10),
                  _langBtn(ref, 'English', 'en', currentFont),
                  const SizedBox(width: 10),
                  _langBtn(ref, '中文', 'zh', currentFont),
                  const SizedBox(width: 10),
                  _langBtn(ref, '日本語', 'ja', currentFont),
                  const SizedBox(width: 10),
                  _langBtn(ref, '한국어', 'ko', currentFont),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(tr(ref, 'font_style'), style: GoogleFonts.getFont(currentFont, color: isDark ? Colors.white70 : Colors.grey[700])),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: ref.watch(fontFamilyProvider),
                dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                iconEnabledColor: modalTextColor,
                underline: const SizedBox(),
                items: ['Plus Jakarta Sans', 'Roboto', 'Lato', 'Poppins', 'Montserrat']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f, style: GoogleFonts.getFont(f, color: modalTextColor)))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(fontFamilyProvider.notifier).state = val;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _langBtn(WidgetRef ref, String label, String code, String font) {
    final isActive = ref.watch(localeProvider).languageCode == code;
    return GestureDetector(
      onTap: () => ref.read(localeProvider.notifier).state = Locale(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.blueAccent : (Colors.grey.shade400)),
        ),
        child: Text(
          label,
          style: GoogleFonts.getFont(font, 
            color: isActive ? Colors.white : (ref.watch(themeProvider) == ThemeMode.dark ? Colors.white70 : Colors.black87), 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}