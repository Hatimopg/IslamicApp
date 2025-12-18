import 'package:flutter/material.dart';
import '../utils/token_storage.dart';
import 'login.dart';
import 'home.dart';

class AuthGate extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const AuthGate({super.key, required this.onToggleTheme});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = await TokenStorage.getToken();
    final userId = await TokenStorage.getUserId();

    if (!mounted) return;

    if (token != null && userId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            userId: userId,
            username: "Utilisateur",
            profile: "",
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(
            onLogin: (_) {},
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
