import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 🔹 Pays -> Régions dynamiques
final Map<String, List<String>> regionsByCountry = {
  "Belgique": [
    "Bruxelles",
    "Hainaut",
    "Liège",
    "Namur",
    "Luxembourg",
    "Flandre Occidentale",
    "Flandre Orientale",
    "Anvers",
    "Limbourg"
  ],
  "France": [
    "Île-de-France",
    "Occitanie",
    "Nouvelle-Aquitaine",
    "Auvergne-Rhône-Alpes",
    "Grand Est",
    "Hauts-de-France",
    "Normandie",
    "Bretagne",
    "PACA",
  ],
  "Maroc": [
    "Casablanca-Settat",
    "Rabat-Salé-Kénitra",
    "Tanger-Tétouan-Al Hoceïma",
    "Fès-Meknès",
    "Marrakech-Safi",
    "Souss-Massa",
    "Oriental",
    "Drâa-Tafilalet",
  ]
};

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
    if (username.text.isEmpty ||
        password.text.isEmpty ||
        birthdate.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs")));
      return;
    }

    setState(() => loading = true);

    try {
      final url = Uri.parse("https://exciting-learning-production-d784.up.railway.app/register");

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
          const SnackBar(content: Text("Compte créé avec succès")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'inscription")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de connexion au serveur")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un compte"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: username,
              decoration: InputDecoration(
                labelText: "Nom d'utilisateur",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Mot de passe",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: birthdate,
              decoration: InputDecoration(
                labelText: "Date de naissance (AAAA-MM-JJ)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Pays :", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton(
              value: country,
              isExpanded: true,
              items: regionsByCountry.keys
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  country = v!;
                  region = regionsByCountry[country]!.first;
                });
              },
            ),

            const SizedBox(height: 10),

            const Text("Région :", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton(
              value: region,
              isExpanded: true,
              items: regionsByCountry[country]!
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => region = v!),
            ),

            const SizedBox(height: 30),

            loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: registerUser,
              child: const Text(
                "Créer mon compte",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
