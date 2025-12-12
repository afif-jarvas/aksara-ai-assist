import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- NOTE: Providers (themeProvider, fontSizeProvider) moved to core/localization_service.dart ---

class AppTheme {
  static const Color ghibliBlue = Color(0xFF89CFF0);
  static const Color ghibliGreen = Color(0xFFA8D5BA);
  static const Color ghibliCream = Color(0xFFFFFDD0);

  static const Color galaxyDeep = Color(0xFF0F0C29);
  static const Color galaxyPurple = Color(0xFF302B63);
  static const Color galaxyCyan = Color(0xFF24CBFF);

  // Helper: Select Font Family
  static TextTheme _buildTextTheme(String fontFamily) {
    switch (fontFamily) {
      case 'Roboto':
        return GoogleFonts.robotoTextTheme();
      case 'Lato':
        return GoogleFonts.latoTextTheme();
      case 'Poppins':
        return GoogleFonts.poppinsTextTheme();
      case 'Montserrat':
        return GoogleFonts.montserratTextTheme();
      default:
        return GoogleFonts.plusJakartaSansTextTheme();
    }
  }

  // Light Theme
  static ThemeData lightTheme(String fontFamily) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: ghibliBlue,
          secondary: ghibliGreen,
          surface: ghibliCream,
          background: Colors.white,
        ),
        textTheme: _buildTextTheme(fontFamily).apply(
            bodyColor: Colors.brown[900], displayColor: Colors.brown[900]),
      );

  // Dark Theme
  static ThemeData darkTheme(String fontFamily) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: galaxyCyan,
          secondary: galaxyPurple,
          surface: galaxyDeep,
          background: galaxyDeep,
        ),
        textTheme: _buildTextTheme(fontFamily)
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
      );
}