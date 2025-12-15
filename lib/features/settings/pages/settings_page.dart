import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [WAJIB]
import '../../../core/localization_service.dart';
import 'language_page.dart'; 

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() {
      _isBiometricEnabled = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? "Login Biometrik Diaktifkan" : "Login Biometrik Dinonaktifkan")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(ref, 'settings_title'), 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF121212),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(ref, 'settings_general'),
          
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: tr(ref, 'language'),
            subtitle: "Bahasa Indonesia, English...",
            color: Colors.blueAccent,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const LanguagePage()));
            },
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 20),

          // --- BAGIAN SECURITY (Setup Biometrik) ---
          _buildSectionHeader(ref, 'settings_account'),

          // Toggle Aktifkan Biometrik (Logika "Daftar dulu baru bisa login wajah")
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: SwitchListTile(
              value: _isBiometricEnabled,
              onChanged: _toggleBiometric,
              title: Text(
                "Login Biometrik",
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Text(
                "Aktifkan login wajah/jari saat masuk",
                style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fingerprint, color: Colors.purpleAccent, size: 24),
              ),
              activeColor: Colors.blueAccent,
            ),
          ),

          // Menu Setup Wajah
          _buildSettingsTile(
            context,
            icon: Icons.face,
            title: tr(ref, 'settings_face_setup'),
            subtitle: tr(ref, 'settings_face_desc'),
            color: Colors.greenAccent,
            onTap: () {
              Navigator.pushNamed(context, '/face-enrollment');
            },
          ),

          const SizedBox(height: 10),

          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: tr(ref, 'logout'),
            subtitle: "Keluar dari akun",
            color: Colors.redAccent,
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              // Reset juga biometrik saat logout jika diinginkan, atau biarkan
              // final prefs = await SharedPreferences.getInstance();
              // await prefs.setBool('biometric_enabled', false); 
              
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(WidgetRef ref, String titleKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        tr(ref, titleKey).toUpperCase(),
        style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(subtitle, style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }
}