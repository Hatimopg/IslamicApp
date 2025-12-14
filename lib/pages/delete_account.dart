import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

class DeleteAccountPage extends StatefulWidget {
  final int userId;

  DeleteAccountPage({required this.userId});

  @override
  _DeleteAccountPageState createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  TextEditingController passCtrl = TextEditingController();
  TextEditingController birthCtrl = TextEditingController();

  bool loading = false;

  Future<void> deleteAccount() async {
    setState(() => loading = true);

    final url = Uri.parse(
        "https://exciting-learning-production-d784.up.railway.app/delete-account");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.userId,
        "password": passCtrl.text,
        "birthdate": birthCtrl.text,
      }),
    );

    setState(() => loading = false);

    if (res.statusCode == 200) {
      bool finalConfirm = await _doubleConfirm();

      if (finalConfirm == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPage(
              onLogin: (_) {},
              onToggleTheme: () {}, // 👈 nécessaire
            ),
          ),
              (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Infos incorrectes")));
    }
  }

  // ----------------------------------------------------------
  // POPUP "TAPER SUPPRIMER" (DARK MODE COMPATIBLE)
  // ----------------------------------------------------------
  Future<bool> _doubleConfirm() async {
    TextEditingController confirmCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
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
            SizedBox(height: 10),
            Text(
              "SUPPRIMER",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: confirmCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Tape SUPPRIMER",
                labelStyle: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700]),
                filled: true,
                fillColor:
                isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                border: OutlineInputBorder(),
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Confirmer"),
            onPressed: () {
              if (confirmCtrl.text.trim().toUpperCase() == "SUPPRIMER") {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fieldFill = isDark ? Colors.grey.shade900 : Colors.white;
    final fieldBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: isDark ? Colors.grey.shade600 : Colors.grey,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Supprimer mon compte"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Pour supprimer ton compte, confirme tes informations :",
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // PASSWORD FIELD
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Mot de passe",
                filled: true,
                fillColor: fieldFill,
                border: fieldBorder,
                enabledBorder: fieldBorder,
                labelStyle: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 20),

            // BIRTHDATE FIELD
            TextField(
              controller: birthCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Date de naissance (AAAA-MM-JJ)",
                filled: true,
                fillColor: fieldFill,
                border: fieldBorder,
                enabledBorder: fieldBorder,
                labelStyle: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700]),
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
              child: const Text("Valider"),
            )
          ],
        ),
      ),
    );
  }
}
