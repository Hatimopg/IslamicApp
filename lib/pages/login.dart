import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'register.dart';
import 'home.dart';
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
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool loading = false;
  bool passwordVisible = false;

  // 🔐 Remember me
  bool rememberMe = false;
  String? savedUsername;
  String? savedPassword;

  // 🔥 Tentatives locales
  int attemptsLeft = 5;

  final String baseUrl =
      "https://exciting-learning-production-d784.up.railway.app";

  @override
  void initState() {
    super.initState();
    loadSavedUser();
  }

  // ================= LOAD SAVED USER =================
  Future<void> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();

    final remember = prefs.getBool("remember_me") ?? false;
    if (!remember) return;

    setState(() {
      rememberMe = true;
      savedUsername = prefs.getString("saved_username");
      savedPassword = prefs.getString("saved_password");
    });
  }

  // ================= SAVE / CLEAR =================
  Future<void> saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("remember_me", true);
    await prefs.setString("saved_username", username.text.trim());
    await prefs.setString("saved_password", password.text.trim());
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("remember_me");
    await prefs.remove("saved_username");
    await prefs.remove("saved_password");
  }

  // ================= LOGIN =================
  Future<void> login() async {
    if (attemptsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Trop de tentatives. Réessayez plus tard."),
        ),
      );
      return;
    }

    if (username.text.trim().isEmpty || password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username.text.trim(),
          "password": password.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 🔥 TOKEN
        await TokenStorage.save(data["token"], data["userId"]);

        // 🔐 REMEMBER ME
        if (rememberMe) {
          await saveCredentials();
        } else {
          await clearCredentials();
        }

        widget.onLogin(data["userId"]);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              userId: data["userId"],
              username: data["username"],
              profile: data["profile"] ?? "",
              onToggleTheme: widget.onToggleTheme,
            ),
          ),
        );
      } else {
        attemptsLeft--;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Identifiants incorrects — tentatives restantes : $attemptsLeft",
            ),
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de connexion au serveur")),
      );
    }

    setState(() => loading = false);
  }

  // ================= UI =================
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

              // 👤 USER CARD
              if (savedUsername != null && savedPassword != null) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    username.text = savedUsername!;
                    password.text = savedPassword!;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 10),
                        Text(savedUsername!),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              TextField(
                controller: username,
                decoration:
                const InputDecoration(labelText: "Nom d'utilisateur"),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: password,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  suffixIcon: IconButton(
                    icon: Icon(passwordVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => passwordVisible = !passwordVisible),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (v) =>
                        setState(() => rememberMe = v ?? false),
                  ),
                  const Text("Se souvenir de moi"),
                ],
              ),

              const SizedBox(height: 16),

              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: login,
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
                child: const Text("Créer un compte"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
