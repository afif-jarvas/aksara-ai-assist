import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Warna Custom
  static const Color ghibliBlue = Color(0xFF89CFF0);
  static const Color ghibliGreen = Color(0xFFA8D5BA);
  static const Color ghibliCream = Color(0xFFFFFDD0);

  static const Color galaxyDeep = Color(0xFF0F0C29);
  static const Color galaxyPurple = Color(0xFF302B63);
  static const Color galaxyCyan = Color(0xFF24CBFF);

  // Helper: Membangun TextTheme secara dinamis berdasarkan nama font
  static TextTheme _buildTextTheme(String fontFamily) {
    try {
      // 1. Dapatkan referensi TextStyle dari GoogleFonts untuk memicu loading font
      final TextStyle fontStyle = GoogleFonts.getFont(fontFamily);
      
      // 2. Gunakan TextTheme standar Material 3 sebagai basis agar ukuran font (size) tetap proporsional
      final TextTheme baseTextTheme = Typography.material2021().englishLike;
      
      // 3. Terapkan fontFamily baru ke seluruh gaya teks di dalam theme ini
      return baseTextTheme.apply(fontFamily: fontStyle.fontFamily);
    } catch (e) {
      // Fallback jika nama font tidak ditemukan atau error loading
      return GoogleFonts.plusJakartaSansTextTheme();
    }
  }

  // --- LIGHT THEME ---
  static ThemeData lightTheme(String fontFamily) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Putih sedikit abu agar mata nyaman
        colorScheme: ColorScheme.light(
          primary: Colors.blueAccent,
          secondary: ghibliGreen,
          surface: Colors.white,
          background: const Color(0xFFF8F9FA),
          onSurface: Colors.black, // Kontras tinggi
        ),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // Ikon Status Bar HITAM
            statusBarBrightness: Brightness.light, // iOS
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        // Terapkan font dinamis dan paksa warna menjadi Hitam Pekat
        textTheme: _buildTextTheme(fontFamily).apply(
          bodyColor: Colors.black, 
          displayColor: Colors.black,
        ),
      );

  // --- DARK THEME ---
  static ThemeData darkTheme(String fontFamily) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: galaxyCyan,
          secondary: galaxyPurple,
          surface: const Color(0xFF1E1E1E),
          background: const Color(0xFF121212),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light, // Ikon Status Bar PUTIH
            statusBarBrightness: Brightness.dark,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        // Terapkan font dinamis dan paksa warna menjadi Putih
        textTheme: _buildTextTheme(fontFamily).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      );
}