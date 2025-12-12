import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:islamicapp/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(IslamicApp());
}

class IslamicApp extends StatefulWidget {
  @override
  State<IslamicApp> createState() => _IslamicAppState();
}

class _IslamicAppState extends State<IslamicApp>
    with WidgetsBindingObserver {

  int? userId;
  bool isDarkMode = false; // 🌙 mode nuit

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

  // 🔥 change state online/offline firebase
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
        .doc(id.toString())
        .update({"isOnline": true, "lastSeen": DateTime.now()});
  }

  // 🌙 toggle theme global
  void toggleTheme() {
    setState(() => isDarkMode = !isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.teal.shade200,
        ),
      ),

      home: LoginPage(
        onLogin: setLoggedUser,
        onToggleTheme: toggleTheme, // 🔥 pour HomePage
      ),
    );
  }
}
