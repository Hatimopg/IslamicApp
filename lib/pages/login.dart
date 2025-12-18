import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register.dart';
import 'home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/token_storage.dart';

class LoginPage extends StatefulWidget {
  final Function(int userId) onLogin;
  final VoidCallback onToggleTheme;

  const LoginPage({
    required this.onLogin,
    required this.onToggleTheme,
  });

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);

    try {
      final url = Uri.parse(
          "https://exciting-learning-production-d784.up.railway.app/login");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username.text.trim(),
          "password": password.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["token"]);
        await prefs.setInt("userId", data["userId"]);

        widget.onLogin(data["userId"]);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              userId: data["userId"],
              username: data["username"],
              profile: data["profile"] != null && data["profile"] != ""
                  ? "https://exciting-learning-production-d784.up.railway.app/uploads/${data["profile"]}"
                  : "",
              onToggleTheme: widget.onToggleTheme,
            ),
          ),
        );
    } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Identifiants incorrects")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de connexion au serveur")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          )
        ],
      ),

      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(32),

          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
            ],
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "IslamicApp",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.purpleAccent : Colors.purple,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: username,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Nom d'utilisateur",
                  labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: isDark ? Colors.white54 : Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: isDark ? Colors.purpleAccent : Colors.teal),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: password,
                obscureText: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: isDark ? Colors.white54 : Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: isDark ? Colors.purpleAccent : Colors.teal),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              loading
                  ? const CircularProgressIndicator(color: Colors.teal)
                  : ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isDark ? Colors.purpleAccent : Colors.teal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                ),
                child: const Text("Se connecter"),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterPage()),
                  );
                },
                child: Text(
                  "Créer un compte",
                  style: TextStyle(
                      color:
                      isDark ? Colors.purpleAccent : Colors.teal.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
