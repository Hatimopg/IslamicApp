import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChangePasswordPage extends StatefulWidget {
  final int userId;
  ChangePasswordPage({required this.userId});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  TextEditingController oldPass = TextEditingController();
  TextEditingController newPass = TextEditingController();
  TextEditingController confirmPass = TextEditingController();

  Future<void> changePassword() async {
    if (newPass.text != confirmPass.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }

    final url = Uri.parse("https://exciting-learning-production-d784.up.railway.app/change-password");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.userId,
        "old_password": oldPass.text,
        "new_password": newPass.text,
      }),
    );

    if (res.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Mot de passe mis à jour")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur : ancien mot de passe incorrect")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Modifier le mot de passe")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              decoration: InputDecoration(labelText: "Ancien mot de passe"),
            ),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: InputDecoration(labelText: "Nouveau mot de passe"),
            ),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: InputDecoration(labelText: "Confirmer le mot de passe"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: changePassword,
              child: Text("Valider"),
            )
          ],
        ),
      ),
    );
  }
}
