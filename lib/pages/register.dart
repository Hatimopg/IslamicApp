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

  bool loading = false;

  String selectedCountry = "Belgique";
  String selectedRegion = "Bruxelles";

  final Map<String, List<String>> regions = {
    "Belgique": [
      "Bruxelles", "Hainaut", "Liège", "Flandre Occidentale",
      "Flandre Orientale", "Luxembourg", "Namur", "Brabant Wallon"
    ],
    "France": [
      "Île-de-France", "Auvergne-Rhône-Alpes", "Occitanie", "Hauts-de-France",
      "Grand Est", "Normandie", "Nouvelle-Aquitaine", "Bretagne"
    ],
    "Maroc": [
      "Casablanca-Settat", "Rabat-Salé-Kénitra", "Fès-Meknès",
      "Marrakech-Safi", "Tanger-Tétouan-Al Hoceima",
      "Souss-Massa", "Oriental", "Laâyoune-Sakia El Hamra"
    ]
  };

  Future<void> registerUser() async {
    setState(() => loading = true);

    try {
      final url = Uri.parse(
          "https://exciting-learning-production-d784.up.railway.app/register"
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username.text.trim(),
          "password": password.text.trim(),
          "birthdate": birthdate.text.trim(),
          "country": selectedCountry,
          "region": selectedRegion,
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

  Future<void> pickBirthdate() async {
    DateTime? selected = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      birthdate.text = "${selected.year}-${selected.month}-${selected.day}";
    }
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
              decoration: const InputDecoration(labelText: "Nom d'utilisateur"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mot de passe"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: birthdate,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Date de naissance",
                suffixIcon: Icon(Icons.calendar_month),
              ),
              onTap: pickBirthdate,
            ),

            const SizedBox(height: 20),

            const Text("Pays :"),
            DropdownButton(
              value: selectedCountry,
              isExpanded: true,
              items: regions.keys
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (c) {
                setState(() {
                  selectedCountry = c!;
                  selectedRegion = regions[c]!.first;
                });
              },
            ),

            const SizedBox(height: 12),

            const Text("Région :"),
            DropdownButton(
              value: selectedRegion,
              isExpanded: true,
              items: regions[selectedCountry]!
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (r) => setState(() => selectedRegion = r!),
            ),

            const SizedBox(height: 30),

            loading
                ? const Center(child: CircularProgressIndicator())
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
