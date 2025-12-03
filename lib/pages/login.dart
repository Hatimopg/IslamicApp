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

        if (data["token"] != null && data["userId"] != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(userId: data["userId"]),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur : serveur ne renvoie pas l'ID")),
          );
        }
      } else {
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
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Container(
          width: 420,
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "IslamicApp",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 30),

              TextField(
                controller: username,
                decoration: InputDecoration(labelText: "Nom d'utilisateur"),
              ),
              SizedBox(height: 14),

              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(labelText: "Mot de passe"),
              ),
              SizedBox(height: 26),

              loading
                  ? CircularProgressIndicator(color: Colors.teal)
                  : ElevatedButton(
                onPressed: login,
                child: Text("Se connecter"),
              ),

              SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterPage()),
                  );
                },
                child: Text(
                  "Créer un compte",
                  style: TextStyle(color: Colors.teal.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
