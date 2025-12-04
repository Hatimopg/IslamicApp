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
  TextEditingController password = TextEditingController();
  TextEditingController birthdate = TextEditingController();

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
        "password": password.text.trim(),
        "birthdate": birthdate.text.trim(),
      }),
    );

    setState(() => loading = false);

    if (res.statusCode == 200) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
            (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Compte supprimé avec succès.")),
      );
    } else {
      final data = jsonDecode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["error"] ?? "Erreur lors de la suppression")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Supprimer mon compte")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Confirme ton identité avant de supprimer ton compte.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),

            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(labelText: "Mot de passe"),
            ),
            SizedBox(height: 14),

            TextField(
              controller: birthdate,
              decoration:
              InputDecoration(labelText: "Date de naissance (AAAA-MM-JJ)"),
            ),

            SizedBox(height: 30),

            loading
                ? CircularProgressIndicator()
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: deleteAccount,
              child: Text("Supprimer mon compte"),
            ),
          ],
        ),
      ),
    );
  }
}
