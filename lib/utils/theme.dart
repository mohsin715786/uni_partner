import 'package:flutter/material.dart';

class NeoTheme {
  NeoTheme._();

  static const Color background = Color(0xFFF8F3EA);
  static const Color surface = Color(0xFFFFF8EE);
  static const Color stroke = Color(0xFF1E1E1E);
  static const Color shadow = Color(0xFF1E1E1E);

  static const Color yellow = Color(0xFFF4DD67);
  static const Color pink = Color(0xFFF6B7B2);
  static const Color cyan = Color(0xFF8FD3D1);
  static const Color blue = Color(0xFF8FB6FF);
  static const Color mint = Color(0xFF9ED9A6);
  static const Color purple = Color(0xFFC7B6F9);
  static const Color orange = Color(0xFFF6B26B);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: stroke,
      colorScheme: const ColorScheme.light(
        primary: stroke,
        secondary: yellow,
        surface: surface,
        onSurface: stroke,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: stroke,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: stroke,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: stroke, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: stroke,
          elevation: 0,
          side: const BorderSide(color: stroke, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: yellow,
        foregroundColor: stroke,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: stroke, width: 2.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: stroke, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: stroke, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: stroke, width: 2.5),
        ),
        labelStyle: const TextStyle(
          color: stroke,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: stroke,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
      ),
    );
  }
}
