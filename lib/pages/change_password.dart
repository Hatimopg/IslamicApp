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

  bool loading = false;

  Future<void> changePassword() async {
    if (newPass.text.trim() != confirmPass.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }

    setState(() => loading = true);

    final url = Uri.parse(
        "https://exciting-learning-production-d784.up.railway.app/change-password");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.userId,
        "old_password": oldPass.text.trim(),
        "new_password": newPass.text.trim(),
      }),
    );

    setState(() => loading = false);

    if (response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mot de passe mis à jour")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ancien mot de passe incorrect")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final inputDecoration = InputDecoration(
      labelStyle: TextStyle(
        color: isDark ? Colors.grey[300] : Colors.grey[800],
      ),
      filled: true,
      fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text("Modifier le mot de passe")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: inputDecoration.copyWith(
                labelText: "Ancien mot de passe",
              ),
            ),
            SizedBox(height: 12),

            TextField(
              controller: newPass,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: inputDecoration.copyWith(
                labelText: "Nouveau mot de passe",
              ),
            ),
            SizedBox(height: 12),

            TextField(
              controller: confirmPass,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: inputDecoration.copyWith(
                labelText: "Confirmer le mot de passe",
              ),
            ),

            SizedBox(height: 25),

            loading
                ? CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: changePassword,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text("Valider"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
