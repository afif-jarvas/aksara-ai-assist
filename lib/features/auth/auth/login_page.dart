import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../ui/widgets/animated_background.dart';
import '../../../../core/localization_service.dart'; // Wajib import ini

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;

  // ID Client Google (Sesuaikan jika perlu)
  final String _webClientId =
      '257837661187-l12a94cob49k62j0kt6iv62046nsootp.apps.googleusercontent.com';

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
    // Memantau perubahan bahasa secara real-time
    ref.watch(localeProvider);

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
              padding: const EdgeInsets.all(20),
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 450, // Tinggi dikurangi karena tombol berkurang
                borderRadius: 20,
                blur: 15,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05)
                ]),
                borderGradient: LinearGradient(colors: [
                  Colors.cyan.withOpacity(0.5),
                  Colors.purple.withOpacity(0.1)
                ]),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mengganti icon fingerprint menjadi lock karena biometrik dihapus
                        const Icon(Icons.lock_person,
                            size: 80, color: Colors.cyanAccent),
                        const SizedBox(height: 20),

                        // JUDUL TERJEMAHAN
                        Text(tr(ref, 'login_title'),
                            style: GoogleFonts.orbitron(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 3)),

                        const SizedBox(height: 40),
                        if (_isLoading)
                          const CircularProgressIndicator(
                              color: Colors.cyanAccent)
                        else ...[
                          _btn(Icons.g_mobiledata, tr(ref, 'login_google'),
                              Colors.white, _handleGoogleLogin,
                              textCol: Colors.black),
                          _btn(Icons.person_outline, tr(ref, 'login_guest'),
                              Colors.transparent, _handleGuestLogin,
                              outline: true),
                        ]
                      ]),
                ),
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