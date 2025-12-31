import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'pages/login.dart';
import 'utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 INIT FIREBASE (OBLIGATOIRE AVANT TOUT)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔔 INIT NOTIFICATIONS (SAFE – ANTI CRASH RELEASE)
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint("⚠️ Notification init failed: $e");
  }

  runApp(const IslamicApp());
}

/* ============================================================
   APP ROOT
=============================================================== */

class IslamicApp extends StatefulWidget {
  const IslamicApp({super.key});

  @override
  State<IslamicApp> createState() => _IslamicAppState();
}

class _IslamicAppState extends State<IslamicApp>
    with WidgetsBindingObserver {
  int? userId;

  // 🌗 THEME GLOBAL
  ThemeMode themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      themeMode =
      themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  /* ============================================================
     LIFECYCLE
  =============================================================== */

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (userId == null) return;

    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(userId.toString());

    // 🔥 SAFE UPDATE (ANTI CRASH RELEASE)
    try {
      ref.update({
        "isOnline": state == AppLifecycleState.resumed,
        "lastSeen": DateTime.now(),
      });
    } catch (e) {
      debugPrint("⚠️ Firestore lifecycle update failed: $e");
    }
  }

  /* ============================================================
     LOGIN CALLBACK
  =============================================================== */

  void setLoggedUser(int id) {
    userId = id;

    try {
      FirebaseFirestore.instance
          .collection("users")
          .doc(userId.toString())
          .update({
        "isOnline": true,
        "lastSeen": DateTime.now(),
      });
    } catch (e) {
      debugPrint("⚠️ Firestore login update failed: $e");
    }
  }

  /* ============================================================
     UI
  =============================================================== */

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🌗 THEMES
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),

      home: LoginPage(
        onLogin: setLoggedUser,
        onToggleTheme: toggleTheme,
      ),
    );
  }
}
