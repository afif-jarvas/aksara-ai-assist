import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../core/localization_service.dart';
import '../../auth/auth/login_page.dart';
import '../../face_recognition/pages/face_enrollment_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _fingerprintEnabled = true; // Simulasi Toggle

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr(ref, 'settings_title'),
          style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionHeader(tr(ref, 'settings_account'), isDark),
          const SizedBox(height: 10),
          
          // --- FACE ID SETUP ---
          _settingCard(
            isDark: isDark,
            icon: Icons.face_retouching_natural,
            color: Colors.blueAccent,
            title: tr(ref, 'settings_face_setup'),
            subtitle: tr(ref, 'settings_face_desc'),
            onTap: () {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login required")));
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceEnrollmentPage()));
            },