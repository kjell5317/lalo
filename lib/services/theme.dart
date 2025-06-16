// ignore: avoid_web_libraries_in_flutter
// import 'dart:html';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

var themeLight = ThemeData(
    brightness: Brightness.light,
    bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    fontFamily: GoogleFonts.roboto().fontFamily,
    // fontFamily: kIsWeb && window.navigator.userAgent.contains('OS 15_')
    //     ? '-apple-system'
    //     : GoogleFonts.roboto().fontFamily,
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
        backgroundColor: WidgetStateProperty.all<Color>(Colors.orange),
        foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
        padding: WidgetStateProperty.all<EdgeInsets>(
          const EdgeInsets.all(15),
        ),
        textStyle:
            WidgetStateProperty.all<TextStyle>(const TextStyle(fontSize: 20)),
      ),
    ),
    colorScheme: ThemeData()
        .colorScheme
        .copyWith(primary: Colors.orange)
        .copyWith(surface: Colors.white));

var themeDark = themeLight.copyWith(
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
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[400] ?? Colors.grey),
        ),
        labelStyle: const TextStyle(color: Colors.white)),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.orange,
      backgroundColor: Colors.grey[900],
      unselectedItemColor: Colors.grey[100],
    ),
    dialogTheme: DialogThemeData(backgroundColor: Colors.grey[900]));
