import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:islamicapp/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/login.dart';
import 'pages/home.dart';
import 'utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔔 ICI EXACTEMENT
  await NotificationService.init();

  runApp(IslamicApp());
}


class IslamicApp extends StatefulWidget {
  @override
  State<IslamicApp> createState() => _IslamicAppState();
}

class _IslamicAppState extends State<IslamicApp> with WidgetsBindingObserver {
  int? userId;

  // ⭐ THEME MODE GLOBAL (light/dark)
  ThemeMode themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      themeMode =
      themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

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

    if (state == AppLifecycleState.resumed) {
      ref.update({"isOnline": true, "lastSeen": DateTime.now()});
    } else {
      ref.update({"isOnline": false, "lastSeen": DateTime.now()});
    }
  }

  void setLoggedUser(int id) {
    userId = id;
    FirebaseFirestore.instance
        .collection("users")
        .doc(userId.toString())
        .update({
      "isOnline": true,
      "lastSeen": DateTime.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ⭐ APPLIQUE LE THEME GLOBAL
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),

      home: LoginPage(
        onLogin: setLoggedUser,
        onToggleTheme: toggleTheme, // ⭐ IMPORTANT
      ),
    );
  }
}
