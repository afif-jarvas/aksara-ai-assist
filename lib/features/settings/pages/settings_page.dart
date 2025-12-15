import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization_service.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/animated_background.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Bersihkan semua data lokal
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal logout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBackground(isDark: isDark, child: const SizedBox()),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark, ref),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    children: [
                      // [REMOVED] Bagian Bahasa dihapus sesuai instruksi
                      
                      const SizedBox(height: 20),
                      _buildSectionTitle(tr(ref, 'settings_appearance'), isDark),
                      const SizedBox(height: 10),
                      _buildThemeTile(context, ref, isDark),

                      const SizedBox(height: 30),
                      _buildSectionTitle(tr(ref, 'settings_general'), isDark),
                      const SizedBox(height: 10),
                      _buildMenuTile(
                        context,
                        icon: Icons.info_outline,
                        title: tr(ref, 'about_title'),
                        isDark: isDark,
                        onTap: () => context.push('/about'),
                      ),
                      _buildMenuTile(
                        context,
                        icon: Icons.privacy_tip_outlined,
                        title: tr(ref, 'privacy_title'),
                        isDark: isDark,
                        onTap: () => context.push('/privacy-policy'),
                      ),

                      const SizedBox(height: 40),
                      _buildLogoutButton(context, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(width: 10),
          Text(
            tr(ref, 'settings_title'),
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.cyanAccent : Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white60 : Colors.black54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, WidgetRef ref, bool isDark) {
    final currentTheme = ref.watch(themeProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.purpleAccent.withOpacity(0.1) : Colors.purpleAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.dark_mode_outlined,
            color: isDark ? Colors.purpleAccent : Colors.purple,
          ),
        ),
        title: Text(
          tr(ref, 'settings_theme'), // "Tema Aplikasi"
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<ThemeMode>(
            value: currentTheme,
            dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white : Colors.black,
            ),
            items: [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text(tr(ref, 'theme_system')),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text(tr(ref, 'theme_light')),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text(tr(ref, 'theme_dark')),
              ),
            ],
            onChanged: (ThemeMode? newMode) {
              if (newMode != null) {
                ref.read(themeProvider.notifier).setTheme(newMode);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
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
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.blueAccent.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.blueAccent : Colors.blue,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.redAccent.shade200, Colors.redAccent.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleLogout(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "Keluar Akun", // Bisa diganti tr(ref, 'logout')
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}