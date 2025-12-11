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
          MaterialPageRoute(builder: (_) => LoginPage(onLogin: (_) {})),
              (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Infos incorrectes")));
    }
  }

  // ----------------------------------------------------------
  // POPUP "TAPER SUPPRIMER"
  // ----------------------------------------------------------
  Future<bool> _doubleConfirm() async {
    TextEditingController confirmCtrl = TextEditingController();

    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Dernière confirmation",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("⚠️ Action irréversible !\n\nTape EXACTEMENT :"),
            SizedBox(height: 10),
            Text("SUPPRIMER",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
            SizedBox(height: 10),
            TextField(
              controller: confirmCtrl,
              decoration: InputDecoration(
                labelText: "Tape SUPPRIMER",
                border: OutlineInputBorder(),
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            child: Text("Annuler"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Confirmer"),
            onPressed: () {
              if (confirmCtrl.text.trim().toUpperCase() == "SUPPRIMER") {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Supprimer mon compte"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Pour supprimer ton compte, confirme tes informations :",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),

            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: "Mot de passe",
                  border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),

            TextField(
              controller: birthCtrl,
              decoration: InputDecoration(
                  labelText: "Date de naissance (AAAA-MM-JJ)",
                  border: OutlineInputBorder()),
            ),
            SizedBox(height: 30),

            loading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Valider"),
            )
          ],
        ),
      ),
    );
  }
}