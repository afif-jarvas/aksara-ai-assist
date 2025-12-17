import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import '../../../../ui/widgets/animated_background.dart';
import '../../../../core/localization_service.dart';

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
      final GoogleSignIn googleSignIn = GoogleSignIn(); 
      
      // Force SignOut agar user bisa memilih akun (opsional)
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      // 1. Buka Dialog Login Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
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
    
    // Mendefinisikan isDark berdasarkan Theme sistem
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                height: 450, 
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
                          // Tombol Login Google
                          _btn(
                            icon: Icons.g_mobiledata, 
                            label: tr(ref, 'login_google'),
                            bgColor: Colors.white, 
                            onPressed: _handleGoogleLogin,
                            textCol: Colors.black
                          ),
                          const SizedBox(height: 15),
                          // Tombol Login Guest
                          _btn(
                            icon: Icons.person_outline, 
                            label: tr(ref, 'login_guest'),
                            bgColor: Colors.transparent, 
                            onPressed: _handleGuestLogin,
                            outline: true
                          ),
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

  // Widget Button Custom (_btn)
  Widget _btn({
    required IconData icon,
    required String label,
    required Color bgColor,
    required VoidCallback onPressed,
    Color? textCol,
    bool outline = false,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: outline 
        ? BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(15),
          )
        : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: outline ? Colors.transparent : bgColor,
          foregroundColor: textCol ?? Colors.white,
          elevation: outline ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}