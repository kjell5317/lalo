import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

var themeLight = ThemeData(
  brightness: Brightness.light,
  backgroundColor: Colors.white,
  bottomSheetTheme: BottomSheetThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
  colorScheme: ThemeData().colorScheme.copyWith(primary: Colors.orange),
  fontFamily: GoogleFonts.roboto().fontFamily,
  appBarTheme: AppBarTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.orange,
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24)),
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
        padding: MaterialStateProperty.all<EdgeInsets>(
          const EdgeInsets.all(20),
        )),
  ),
);

var themeDark = themeLight.copyWith(
    dialogBackgroundColor: Colors.grey[900],
    bottomSheetTheme: themeLight.bottomSheetTheme.copyWith(
      backgroundColor: Colors.grey[900],
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    iconTheme: const IconThemeData(color: Colors.white),
    brightness: Brightness.dark,
    appBarTheme: themeLight.appBarTheme.copyWith(
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),
        iconTheme: const IconThemeData(color: Colors.white)),
    inputDecorationTheme: themeLight.inputDecorationTheme.copyWith(
        border: const OutlineInputBorder(),
        labelStyle: const TextStyle(color: Colors.white)),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.orange,
      backgroundColor: Colors.grey[900],
      unselectedItemColor: Colors.grey[100],
    ));
