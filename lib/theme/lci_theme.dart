import 'package:flutter/material.dart';

const Color lciGreen = Color(0xFF2E7D32);
const Color lciGreenDark = Color(0xFF1B5E20);
const Color lciGreenLight = Color(0xFFA5D6A7);
const Color lciBackground = Color(0xFFF5F7F5);

final ThemeData lciLightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: lciGreen,
    primary: lciGreen,
    secondary: lciGreenDark,
    background: lciBackground,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: lciGreen,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lciGreen,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  ),
  cardTheme: const CardThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    elevation: 4,
  ),
);
