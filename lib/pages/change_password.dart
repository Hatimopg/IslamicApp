import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/token_storage.dart';

class ChangePasswordPage extends StatefulWidget {
  ChangePasswordPage({super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  TextEditingController oldPass = TextEditingController();
  TextEditingController newPass = TextEditingController();
  TextEditingController confirmPass = TextEditingController();

  bool loading = false;
  bool oldVisible = false;
  bool newVisible = false;
  bool confirmVisible = false;

  final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  Future<void> changePassword() async {
    if (newPass.text.trim() != confirmPass.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }

    if (!passwordRegex.hasMatch(newPass.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Mot de passe faible (8 caractères, maj, min, chiffre, spécial)"),
        ),
      );
      return;
    }

    final token = await TokenStorage.getToken();
    if (token == null) return;

    setState(() => loading = true);

    final url = Uri.parse(
        "https://exciting-learning-production-d784.up.railway.app/change-password");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // 🔐 IMPORTANT
      },
      body: jsonEncode({
        "old_password": oldPass.text.trim(),
        "new_password": newPass.text.trim(),
      }),
    );

    setState(() => loading = false);

    if (response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mot de passe mis à jour")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ancien mot de passe incorrect")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    InputDecoration deco(String label, bool visible, VoidCallback toggle) {
      return InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Modifier le mot de passe")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: oldPass,
              obscureText: !oldVisible,
              decoration:
              deco("Ancien mot de passe", oldVisible, () {
                setState(() => oldVisible = !oldVisible);
              }),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: newPass,
              obscureText: !newVisible,
              decoration:
              deco("Nouveau mot de passe", newVisible, () {
                setState(() => newVisible = !newVisible);
              }),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: confirmPass,
              obscureText: !confirmVisible,
              decoration:
              deco("Confirmer le mot de passe", confirmVisible, () {
                setState(() => confirmVisible = !confirmVisible);
              }),
            ),
            const SizedBox(height: 25),

            loading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: changePassword,
                child: const Text("Valider"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
