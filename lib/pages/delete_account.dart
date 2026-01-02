import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import '../utils/token_storage.dart';

class DeleteAccountPage extends StatefulWidget {
  final int userId;

  const DeleteAccountPage({super.key, required this.userId});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController passCtrl = TextEditingController();

  bool loading = false;
  bool passwordVisible = false;

  Future<void> deleteAccount() async {
    setState(() => loading = true);

    final token = await TokenStorage.getToken();
    if (token == null) {
      setState(() => loading = false);
      return;
    }

    final url = Uri.parse(
      "https://exciting-learning-production-d784.up.railway.app/delete-account",
    );

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "password": passCtrl.text.trim(), // ✅ MDP UNIQUEMENT
      }),
    );

    setState(() => loading = false);

    if (res.statusCode == 200) {
      final confirmed = await _doubleConfirm();
      if (!confirmed) return;

      await TokenStorage.clear();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(
            onLogin: (_) {},
            onToggleTheme: () {},
          ),
        ),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mot de passe incorrect"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ----------------------------------------------------------
  // DOUBLE CONFIRMATION
  // ----------------------------------------------------------
  Future<bool> _doubleConfirm() async {
    final TextEditingController confirmCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          "Dernière confirmation",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "⚠️ Action irréversible !\n\nTape EXACTEMENT :",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "SUPPRIMER",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(
                labelText: "Tape SUPPRIMER",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              if (confirmCtrl.text.trim().toUpperCase() == "SUPPRIMER") {
                Navigator.pop(context, true);
              }
            },
            child: const Text("Confirmer"),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Supprimer mon compte"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Confirme ton mot de passe pour supprimer définitivement ton compte",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),

            TextField(
              controller: passCtrl,
              obscureText: !passwordVisible,
              decoration: InputDecoration(
                labelText: "Mot de passe",
                suffixIcon: IconButton(
                  icon: Icon(
                    passwordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => passwordVisible = !passwordVisible),
                ),
              ),
            ),

            const SizedBox(height: 30),

            loading
                ? const CircularProgressIndicator(color: Colors.red)
                : ElevatedButton(
              onPressed: deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Supprimer définitivement"),
            ),
          ],
        ),
      ),
    );
  }
}
