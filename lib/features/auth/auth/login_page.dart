import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../ui/widgets/animated_background.dart';
import '../../face_recognition/services/face_recognition_service.dart';
import '../../../../core/localization_service.dart'; // Wajib import ini

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;
  final LocalAuthentication auth = LocalAuthentication();

  // ID Client Google (Sesuaikan jika perlu)
  final String _webClientId =
      '257837661187-l12a94cob49k62j0kt6iv62046nsootp.apps.googleusercontent.com';

  Future<void> _handleBiometricLogin() async {
    try {
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        final bool didAuthenticate = await auth.authenticate(
            localizedReason: tr(ref, 'login_bio_prompt'), // "Pindai sidik jari..."
            options: const AuthenticationOptions(
                stickyAuth: true, biometricOnly: true));
        if (didAuthenticate) {
          if (mounted) context.go('/home');
        }
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr(ref, 'bio_na')))); // "Biometrik tidak tersedia"
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${tr(ref, 'error')}: $e')));
    }
  }

  Future<void> _handleFaceLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final image = await ImagePicker()
          .pickImage(source: ImageSource.camera, maxWidth: 600);
      
      if (image != null) {
        final faceService = ref.read(faceRecognitionServiceProvider.notifier);
        
        // Menggunakan fungsi BARU yang ada di Service (Server-side)
        final isSuccess = await faceService.loginWithFace(image);
        
        if (isSuccess) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr(ref, 'face_login_success')), // "Wajah Terdeteksi..."
                  backgroundColor: Colors.green
                )
             );
             context.go('/home');
          }
        } else {
          // Jika wajah tidak valid
          throw tr(ref, 'face_na'); // "Wajah tidak terdeteksi"
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${tr(ref, 'error')}: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn =
          GoogleSignIn(serverClientId: _webClientId);
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) throw 'ID Token Google null.';

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${tr(ref, 'google_fail')} $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInAnonymously();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan bahasa secara real-time
    ref.watch(localeProvider); 

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned.fill(
              child: AnimatedBackground(isDark: true, child: SizedBox())),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 620,
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
                        const Icon(Icons.fingerprint,
                            size: 80, color: Colors.cyanAccent),
                        const SizedBox(height: 20),
                        
                        // JUDUL TERJEMAHAN (Bukan Raw Text Lagi)
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
                          // TOMBOL TERJEMAHAN
                          _btn(Icons.fingerprint, tr(ref, 'login_bio'),
                              Colors.green, _handleBiometricLogin),
                          _btn(Icons.face_retouching_natural, tr(ref, 'login_face'),
                              Colors.blue, _handleFaceLogin),
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

  Widget _btn(IconData icon, String label, Color color, VoidCallback onTap,
      {Color textCol = Colors.white, bool outline = false}) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                    backgroundColor: outline ? Colors.transparent : color,
                    foregroundColor: textCol,
                    elevation: outline ? 0 : 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: outline
                            ? const BorderSide(color: Colors.white54)
                            : BorderSide.none)),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, color: textCol),
                  const SizedBox(width: 12),
                  Text(label,
                      style: GoogleFonts.exo2(
                          fontSize: 16, fontWeight: FontWeight.bold))
                ]))));
  }
}