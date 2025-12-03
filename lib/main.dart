import 'package:flutter/material.dart';
import 'pages/login.dart';

void main() {
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF0F766E);
    final Color secondary = const Color(0xFFA3E635);
    final Color gold = const Color(0xFFD4AF37);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Islamic App",
      theme: ThemeData(
        useMaterial3: true,

        // 🌙 Couleurs premium
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          surface: Colors.white,
          background: const Color(0xFFF7F7F7),
          brightness: Brightness.light,
        ),

        // 🔤 Police moderne Inter
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: "Inter",
            fontSize: 16,
            color: Color(0xFF1A1A1A),
          ),
          titleLarge: TextStyle(
            fontFamily: "Inter",
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),

        // 🔲 Champs de texte version premium
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primary, width: 2),
          ),
          labelStyle: TextStyle(
            color: Colors.grey.shade700,
            fontFamily: "Inter",
          ),
        ),

        // 🔘 Boutons stylés
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return primary.withOpacity(0.8);
              }
              return primary;
            }),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            elevation: WidgetStateProperty.all(3),
          ),
        ),

        // 🔽 Snackbars modernes
        snackBarTheme: SnackBarThemeData(
          backgroundColor: primary,
          contentTextStyle: const TextStyle(
            fontFamily: "Inter",
            color: Colors.white,
          ),
        ),

        // 🧭 Navigation modernisée
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: secondary.withOpacity(0.25),
          labelTextStyle: WidgetStatePropertyAll(
            const TextStyle(fontFamily: "Inter"),
          ),
        ),
      ),

      home: LoginPage(),
    );
  }
}
