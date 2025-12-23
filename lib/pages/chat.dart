import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController captchaCtrl = TextEditingController();

  bool loading = false;
  bool passwordVisible = false;

  // CAPTCHA IMAGE
  bool showCaptcha = false;
  late Image captchaImage;

  final String baseUrl =
      "https://exciting-learning-production-d784.up.railway.app";

  // ----------------------------------------------------------
  // LOAD CAPTCHA IMAGE
  // ----------------------------------------------------------
  void loadCaptcha() {
    setState(() {
      captchaImage = Image.network(
        "$baseUrl/captcha-image?${DateTime.now().millisecondsSinceEpoch}",
        height: 60,
      );
      showCaptcha = true;
    });
  }

  // ----------------------------------------------------------
  // LOGIN
  // ----------------------------------------------------------
  Future<void> login() async {
    if (username.text.trim().isEmpty ||
        password.text.trim().isEmpty) {
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
          "captcha": captchaCtrl.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await TokenStorage.save(data["token"], data["userId"]);

        setState(() {
          showCaptcha = false;
          captchaCtrl.clear();
        });

        widget.onLogin(data["userId"]);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              userId: data["userId"],
              username: data["username"],
              profile: data["profile"] != null && data["profile"] != ""
                  ? "$baseUrl/uploads/${data["profile"]}"
                  : "",
              onToggleTheme: widget.onToggleTheme,
            ),
          ),
        );
      } else if (response.statusCode == 429 ||
          response.body.contains("Captcha")) {
        loadCaptcha();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sécurité activée. Résous le captcha."),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Identifiants incorrects")),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur serveur")),
      );
    }

    setState(() => loading = false);
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
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
              const Text(
                "IslamicApp",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

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

              if (showCaptcha) ...[
                const SizedBox(height: 16),
                captchaImage,
                const SizedBox(height: 8),
                TextField(
                  controller: captchaCtrl,
                  decoration:
                  const InputDecoration(labelText: "Captcha"),
                ),
              ],

              const SizedBox(height: 26),

              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: login,
                child: const Text("Se connecter"),
              ),

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
