import 'package:flutter/material.dart';
import 'register.dart';
import 'home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
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
      // 🔥 IMPORTANT : SI TU ES SUR ÉMULATEUR
      // Utilise 10.0.2.2 au lieu de localhost
      final url = Uri.parse("http://localhost:3000/login");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username.text,
          "password": password.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // On check que le token existe
        if (data["token"] != null) {
          // Connexion OK
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur inconnue.")),
          );
        }
      } else {
        // ❌ Mauvais mdp ou user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Identifiants incorrects")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion au serveur")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: username,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),

            loading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: login,
              child: const Text("Login"),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterPage()),
                );
              },
              child: const Text("Créer un compte"),
            )
          ],
        ),
      ),
    );
  }
}
