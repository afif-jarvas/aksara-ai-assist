import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Method Helper untuk membuat TextTheme dinamis
  static TextTheme _buildTextTheme(String fontFamily, Color fontColor) {
    // Ambil typography standar material
    final base = Typography.material2021().englishLike;

    // Helper untuk apply font ke setiap style
    TextStyle apply(TextStyle? s) {
      try {
        // Coba load Google Font. Jika string font salah/offline, gunakan fallback.
        return GoogleFonts.getFont(fontFamily, textStyle: s).copyWith(color: fontColor);
      } catch (_) {
        // Fallback ke Plus Jakarta Sans jika gagal
        return GoogleFonts.plusJakartaSans(textStyle: s, color: fontColor);
      }
    }

    return base.copyWith(
      displayLarge: apply(base.displayLarge),
      displayMedium: apply(base.displayMedium),
      displaySmall: apply(base.displaySmall),
      headlineLarge: apply(base.headlineLarge),
      headlineMedium: apply(base.headlineMedium),
      headlineSmall: apply(base.headlineSmall),
      titleLarge: apply(base.titleLarge),
      titleMedium: apply(base.titleMedium),
      titleSmall: apply(base.titleSmall),
      bodyLarge: apply(base.bodyLarge),
      bodyMedium: apply(base.bodyMedium),
      bodySmall: apply(base.bodySmall),
      labelLarge: apply(base.labelLarge),
      labelMedium: apply(base.labelMedium),
      labelSmall: apply(base.labelSmall),
    );
  }

  // LIGHT THEME
  static ThemeData lightTheme(String fontFamily) {
    // Teks Hitam untuk background terang
    final textTheme = _buildTextTheme(fontFamily, Colors.black87);
    
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF6200EE),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      cardColor: const Color(0xFFF5F5F5),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6200EE),
        secondary: Color(0xFF03DAC6),
        surface: Colors.white,
        onSurface: Colors.black87, // Penting untuk kontras
      ),
      fontFamily: fontFamily, // Global font fallback
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      useMaterial3: true,
    );
  }

  // DARK THEME
  static ThemeData darkTheme(String fontFamily) {
    // Teks Putih untuk background gelap
    final textTheme = _buildTextTheme(fontFamily, Colors.white);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFBB86FC),
      scaffoldBackgroundColor: const Color(0xFF121212), // Dark Material BG
      cardColor: const Color(0xFF1E1E1E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFBB86FC),
        secondary: Color(0xFF03DAC6),
        surface: Color(0xFF121212),
        onSurface: Colors.white, // Penting untuk kontras
      ),
      fontFamily: fontFamily,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      useMaterial3: true,
    );
  }
}