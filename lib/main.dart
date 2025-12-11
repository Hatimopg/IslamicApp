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

class _IslamicAppState extends State<IslamicApp> with WidgetsBindingObserver {
  int? userId; // stocke l'id utilisateur connecté

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

  // appelé quand l'app passe background / foreground / fermée
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (userId == null) return;

    final ref =
    FirebaseFirestore.instance.collection("users").doc(userId.toString());

    if (state == AppLifecycleState.resumed) {
      ref.update({"isOnline": true, "lastSeen": DateTime.now()});
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      ref.update({"isOnline": false, "lastSeen": DateTime.now()});
    }
  }

  // méthode appelée par LoginPage pour enregistrer l'id utilisateur
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
      home: LoginPage(onLogin: setLoggedUser),
    );
  }
}
