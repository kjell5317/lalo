import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

var themeLight = ThemeData(
  brightness: Brightness.light,
  colorScheme: ThemeData().colorScheme.copyWith(primary: Colors.orange),
  fontFamily: GoogleFonts.roboto().fontFamily,
  appBarTheme: const AppBarTheme(backgroundColor: Colors.orange),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: Colors.orange,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(Colors.orange),
      foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
    ),
  ),
);

var themeDark = themeLight.copyWith(
    scaffoldBackgroundColor: Colors.grey[900],
    brightness: Brightness.dark,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey[600],
      selectedItemColor: Colors.orange,
    ));
