import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. PROVIDERS (Pastikan bagian ini ada) ---
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// Provider Ukuran Font (Slider 0.8x - 1.2x)
final fontSizeProvider = StateProvider<double>((ref) => 1.0);

// Provider Gaya Font (Dropdown)
final fontFamilyProvider = StateProvider<String>((ref) => 'modern');

// --- 2. THEME NOTIFIER ---
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool('isDarkMode', state == ThemeMode.dark);
  }
}

// --- 3. APP THEME BUILDER (Logika Ganti Font) ---
class AppTheme {
  static const Color ghibliBlue = Color(0xFF89CFF0);
  static const Color ghibliGreen = Color(0xFFA8D5BA);
  static const Color ghibliCream = Color(0xFFFFFDD0);

  static const Color galaxyDeep = Color(0xFF0F0C29);
  static const Color galaxyPurple = Color(0xFF302B63);
  static const Color galaxyCyan = Color(0xFF24CBFF);

  // Helper: Memilih Font Sesuai Pilihan
  static TextTheme _buildTextTheme(String fontFamily) {
    switch (fontFamily) {
      case 'classic':
        return GoogleFonts.merriweatherTextTheme();
      case 'mono':
        return GoogleFonts.dmMonoTextTheme();
      default:
        return GoogleFonts.exo2TextTheme(); // Modern (Default)
    }
  }

  // Tema Terang (Menerima parameter fontFamily)
  static ThemeData lightTheme(String fontFamily) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: ghibliBlue,
          secondary: ghibliGreen,
          surface: ghibliCream,
          background: Colors.white,
        ),
        // Terapkan font yang dipilih
        textTheme: _buildTextTheme(fontFamily).apply(
            bodyColor: Colors.brown[900], displayColor: Colors.brown[900]),
      );

  // Tema Gelap (Menerima parameter fontFamily)
  static ThemeData darkTheme(String fontFamily) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: galaxyCyan,
          secondary: galaxyPurple,
          surface: galaxyDeep,
          background: galaxyDeep,
        ),
        // Terapkan font yang dipilih
        textTheme: _buildTextTheme(fontFamily)
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
      );
}
