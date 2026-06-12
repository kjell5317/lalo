import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand color of Leave a Light on — keep in sync with docs/ (CSS --accent).
const Color brandOrange = Colors.orange;

ThemeData _baseTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandOrange,
    brightness: brightness,
    primary: brandOrange,
  );
  return ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: GoogleFonts.roboto().fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: brandOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: brandOrange.withValues(alpha: 0.25),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      // Keeps sheets phone-sized on desktop/web.
      constraints: BoxConstraints(maxWidth: 480),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(15),
        textStyle: const TextStyle(fontSize: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

final ThemeData themeLight = _baseTheme(Brightness.light);

final ThemeData themeDark = _baseTheme(Brightness.dark).copyWith(
  scaffoldBackgroundColor: Colors.grey[900],
  bottomSheetTheme: _baseTheme(
    Brightness.dark,
  ).bottomSheetTheme.copyWith(backgroundColor: Colors.grey[850]),
  dialogTheme: DialogThemeData(backgroundColor: Colors.grey[850]),
);
