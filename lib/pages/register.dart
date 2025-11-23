import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inscription")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
            TextField(
              controller: birthdate,
              decoration: InputDecoration(labelText: "Date de naissance"),
            ),
            const SizedBox(height: 10),
            DropdownButton(
              value: country,
              items: ["Belgique", "France", "Maroc"]
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => country = v!),
            ),
            DropdownButton(
              value: region,
              items: ["Bruxelles", "Hainaut", "Liège"]
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => region = v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Créer mon compte"),
            )
          ],
        ),
      ),
    );
  }
}
