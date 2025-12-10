import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startCinematicSequence();
  }

  Future<void> _startCinematicSequence() async {
    // 1. Tunggu animasi intro selesai (5 detik)
    await Future.delayed(const Duration(seconds: 5));

    // 2. FORCE LOGOUT (Agar user wajib login ulang tiap restart)
    if (Supabase.instance.client.auth.currentSession != null) {
      await Supabase.instance.client.auth.signOut();
    }

    if (mounted) {
      // 3. Selalu arahkan ke Login Page
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // SEQUENCE 1: Logo & Aksara AI
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 80, color: Colors.cyan)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(delay: 200.ms, duration: 1000.ms)
                    .fadeOut(delay: 2000.ms, duration: 500.ms),
                const SizedBox(height: 20),
                Text(
                  "AKSARA AI",
                  style: GoogleFonts.orbitron(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .shimmer(delay: 1000.ms, color: Colors.purpleAccent)
                    .fadeOut(delay: 2000.ms, duration: 500.ms),
              ],
            ),

            // SEQUENCE 2: MIRION HOSTAGE (DIKEMBALIKAN)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "GOLDEN AGE",
                  style: GoogleFonts.exo2(color: Colors.grey, fontSize: 14),
                )
                    .animate()
                    .fadeIn(delay: 3000.ms, duration: 500.ms)
                    .fadeOut(delay: 4500.ms, duration: 500.ms),
                const SizedBox(height: 10),
                Text(
                  "MIRION HOSTAGE", // TEKS INI SUDAH KEMBALI
                  style: GoogleFonts.cinzel(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                    letterSpacing: 2,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 3200.ms, duration: 800.ms)
                    .fadeOut(delay: 4500.ms, duration: 500.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
