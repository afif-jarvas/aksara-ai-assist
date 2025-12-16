import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization_service.dart';
import '../../../ui/widgets/animated_background.dart';
import '../../../ui/theme/app_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;

  // [REVISI] Variabel _webClientId DIHAPUS.
  // Kita biarkan plugin membaca otomatis dari google-services.json

  @override
  void initState() {
    super.initState();
    // Cek jika user sudah login sebelumnya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser != null) {
        context.go('/home');
      }
    });
  }

  // ===========================================================================
  // FUNGSI: GOOGLE LOGIN (AUTO DETECT JSON)
  // ===========================================================================
  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // [PERBAIKAN UTAMA DI SINI]
      // Kita hapus parameter 'serverClientId'.
      // Biarkan kosong agar Flutter membaca otomatis konfigurasi yang benar dari JSON.
      final GoogleSignIn googleSignIn = GoogleSignIn(); 
      // Catatan: Jika butuh scope khusus, bisa tambah: scopes: ['email', 'profile']

      // Force SignOut agar user bisa memilih akun (opsional)
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      // 1. Buka Dialog Login Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User membatalkan login
        setState(() => _isLoading = false);
        return;
      }

      // 2. Ambil Authentication Token
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Buat Credential untuk Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign In ke Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 5. Sukses -> Pindah ke Home
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Berhasil!'), backgroundColor: Colors.green),
        );
        context.go('/home');
      }

    } catch (e) {
      debugPrint("Login Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal Login: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // FUNGSI: GUEST LOGIN
  // ===========================================================================
  Future<void> _handleGuestLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInAnonymously();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest_mode', true);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guest Login Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil theme dari Riverpod
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark || 
                   (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Animasi
          Positioned.fill(
            child: AnimatedBackground(isDark: isDark, child: const SizedBox()),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LOGO / ICON ---
                  Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome, size: 60, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 35),
                  
                  // --- TITLE ---
                  Text(
                    tr(ref, 'login_title'), // "AKSARA AI"
                    style: GoogleFonts.orbitron(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr(ref, 'login_subtitle'), // "Asisten AI Cerdas..."
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // --- LOGIN BUTTONS ---
                  GlassmorphicContainer(
                    width: double.infinity,
                    height: 200,
                    borderRadius: 24,
                    blur: 20,
                    alignment: Alignment.center,
                    border: 1,
                    linearGradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderGradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.1)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPrimaryButton(
                            label: tr(ref, 'login_btn_google'),
                            icon: FontAwesomeIcons.google,
                            backgroundColor: Colors.white,
                            textColor: Colors.black,
                            onPressed: _handleGoogleLogin,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 16),
                          _buildPrimaryButton(
                            label: tr(ref, 'login_btn_guest'),
                            icon: FontAwesomeIcons.userSecret,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            textColor: Colors.white,
                            onPressed: _handleGuestLogin,
                            isLoading: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        icon: isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
          : Icon(icon, size: 20),
        label: Text(
          isLoading ? "Loading..." : label,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}