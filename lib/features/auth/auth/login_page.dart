import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/localization_service.dart';
import '../../../ui/widgets/animated_background.dart';
import '../../face_recognition/pages/face_recognition_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // --- STATE VARIABLES ---
  bool _isLoading = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Data User untuk Tampilan "Welcome Back"
  User? _currentUser;
  bool _isBiometricEnabled = false;
  String? _savedUserName;
  String? _savedUserEmail;
  String? _savedUserAvatar;

  // [PERBAIKAN ERROR] String ini harus dalam SATU BARIS (Tidak boleh ada enter)
  final String _webClientId = '257837661187-l12a94cob49k62j0kt6iv62046nsootp.apps.googleusercontent.com';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// Mengecek apakah ada sesi user aktif atau data tersimpan
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ambil preferensi user
    final bioEnabled = prefs.getBool('biometric_enabled') ?? false;
    final savedEmail = prefs.getString('saved_email');
    
    // Cek User Firebase saat ini
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (mounted) {
      setState(() {
        _isBiometricEnabled = bioEnabled;
        
        if (firebaseUser != null) {
           // Kasus 1: Sesi Firebase masih aktif
           _currentUser = firebaseUser;
           _savedUserEmail = firebaseUser.email;
           _savedUserName = firebaseUser.displayName ?? 'User';
           _savedUserAvatar = firebaseUser.photoURL;
        } else if (savedEmail != null) {
           // Kasus 2: Sesi habis, tapi data user tersimpan (Login History)
           _savedUserEmail = savedEmail;
           _savedUserName = prefs.getString('saved_name') ?? 'User';
           _savedUserAvatar = prefs.getString('saved_avatar');
        }
      });
    }
  }

  // ===========================================================================
  // FUNGSI: GOOGLE LOGIN
  // ===========================================================================
  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 1. Konfigurasi Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: _webClientId, // Menggunakan variabel class yang sudah diperbaiki
        scopes: ['email', 'profile'],
      );

      // Force SignOut agar dialog "Pilih Akun" selalu muncul
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      // 2. Buka Dialog Native Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 3. Dapatkan Token Autentikasi
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw 'Gagal mendapatkan token autentikasi dari Google.';
      }

      // 4. Buat Kredensial Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Proses Login ke Firebase
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      // 6. Simpan Data User ke Cache Lokal
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', user.email ?? '');
        await prefs.setString('saved_name', user.displayName ?? 'User');
        await prefs.setString('saved_avatar', user.photoURL ?? '');
      }

      // 7. Feedback & Navigasi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(tr(ref, 'login_google_success'))),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        context.go('/home');
      }

    } catch (e) {
      debugPrint("Login Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr(ref, 'google_fail')} $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // FUNGSI: GUEST MODE
  // ===========================================================================
  Future<void> _handleGuestLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // Login Anonymous Firebase
      await FirebaseAuth.instance.signInAnonymously();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest_mode', true);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guest Login Error: $e'), 
            backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // FUNGSI: BIOMETRIK
  // ===========================================================================
  void _handleFaceLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaceRecognitionPage()),
    );
  }

  Future<void> _handleFingerprintLogin() async {
    try {
      final bool canAuthenticate = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr(ref, 'bio_na'))),
          );
        }
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: tr(ref, 'login_bio_prompt'),
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memverifikasi sidik jari.')),
        );
      }
    }
  }

  Future<void> _switchAccount() async {
    setState(() => _isLoading = true);
    
    await FirebaseAuth.instance.signOut();
    try { await GoogleSignIn().signOut(); } catch (_) {}
    
    setState(() {
      _currentUser = null;
      _savedUserEmail = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark || 
                   (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    final bool showReturningUserUI = _savedUserEmail != null && _isBiometricEnabled;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBackground(isDark: isDark, child: const SizedBox()),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  // --- HEADER ---
                  if (showReturningUserUI) ...[
                    // TAMPILAN USER LAMA
                    Container(
                      width: 120, height: 120,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)
                        ],
                        image: DecorationImage(
                          image: NetworkImage(_savedUserAvatar ?? 'https://ui-avatars.com/api/?name=${_savedUserName ?? "User"}'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr(ref, 'login_welcome'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _savedUserName ?? 'User',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ] else ...[
                    // TAMPILAN USER BARU
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
                    Text(
                      tr(ref, 'login_title'),
                      style: GoogleFonts.orbitron(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr(ref, 'login_subtitle'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],

                  const SizedBox(height: 60),

                  // --- CONTROL PANEL ---
                  
                  if (!showReturningUserUI) 
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

                  if (showReturningUserUI)
                    Column(
                      children: [
                        Text(
                          tr(ref, 'login_quick').toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBiometricButton(
                              icon: Icons.face_retouching_natural,
                              label: "Face ID",
                              color: Colors.blueAccent,
                              onTap: _handleFaceLogin,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 40),
                            _buildBiometricButton(
                              icon: Icons.fingerprint,
                              label: "Touch ID",
                              color: Colors.purpleAccent,
                              onTap: _handleFingerprintLogin,
                              isDark: isDark,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 50),
                        
                        TextButton.icon(
                          onPressed: _switchAccount,
                          icon: Icon(Icons.swap_horiz, color: isDark ? Colors.white54 : Colors.black54),
                          label: Text(
                            tr(ref, 'login_switch_account'),
                            style: GoogleFonts.plusJakartaSans(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        )
                      ],
                    ),
                    
                  if (!showReturningUserUI) ...[
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white12)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            tr(ref, 'biometric_setup_hint'),
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.white12)),
                      ],
                    ),
                  ],
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
          isLoading ? "Processing..." : label,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildBiometricButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                width: 1.5
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -2
                )
              ],
            ),
            child: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 34),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        )
      ],
    );
  }
}