import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<RegisterPage> {
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController birthdate = TextEditingController();

  String country = "Belgique";
  String region = "Bruxelles";

  bool loading = false;

  Future<void> registerUser() async {
    setState(() => loading = true);

    try {
      final url = Uri.parse("http://localhost:3000/register");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username.text,
          "password": password.text,
          "birthdate": birthdate.text,
          "country": country,
          "region": region,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Compte créé avec succès")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'inscription")),
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
      appBar: AppBar(
        title: const Text("Créer un compte"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: username,
              decoration: InputDecoration(labelText: "Nom d'utilisateur"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(labelText: "Mot de passe"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: birthdate,
              decoration: InputDecoration(labelText: "Date de naissance (AAAA-MM-JJ)"),
            ),
            const SizedBox(height: 20),

            const Text("Pays :"),
            DropdownButton(
              value: country,
              items: ["Belgique", "France", "Maroc"]
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => country = v!),
            ),

            const SizedBox(height: 10),

            const Text("Région :"),
            DropdownButton(
              value: region,
              items: ["Bruxelles", "Hainaut", "Liège"]
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => region = v!),
            ),

            const SizedBox(height: 30),

            loading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: registerUser,
              child: const Text("Créer mon compte"),
            ),
          ],
        ),
      ),
    );
  }
}
