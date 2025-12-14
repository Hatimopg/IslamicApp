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
      "Bruxelles",
      "Hainaut",
      "Liège",
      "Flandre Occidentale",
      "Flandre Orientale",
      "Luxembourg",
      "Namur",
      "Brabant Wallon"
    ],
    "France": [
      "Île-de-France",
      "Auvergne-Rhône-Alpes",
      "Occitanie",
      "Hauts-de-France",
      "Grand Est",
      "Normandie",
      "Nouvelle-Aquitaine",
      "Bretagne"
    ],
    "Maroc": [
      "Casablanca-Settat",
      "Rabat-Salé-Kénitra",
      "Fès-Meknès",
      "Marrakech-Safi",
      "Tanger-Tétouan-Al Hoceima",
      "Souss-Massa",
      "Oriental",
      "Laâyoune-Sakia El Hamra"
    ]
  };

  Future<void> registerUser() async {
    setState(() => loading = true);

    try {
      final url = Uri.parse(
          "https://exciting-learning-production-d784.up.railway.app/register");

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un compte"),
        backgroundColor: isDark ? Colors.black : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // ------------------ USERNAME ------------------
            TextField(
              controller: username,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Nom d'utilisateur",
                labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87),
                enabledBorder: OutlineInputBorder(
                    borderSide:
                    BorderSide(color: isDark ? Colors.white54 : Colors.grey)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal)),
              ),
            ),

            const SizedBox(height: 12),

            // ------------------ PASSWORD ------------------
            TextField(
              controller: password,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Mot de passe",
                labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87),
                enabledBorder: OutlineInputBorder(
                    borderSide:
                    BorderSide(color: isDark ? Colors.white54 : Colors.grey)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal)),
              ),
            ),

            const SizedBox(height: 12),

            // ------------------ BIRTHDATE ------------------
            TextField(
              controller: birthdate,
              readOnly: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Date de naissance",
                labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87),
                suffixIcon: const Icon(Icons.calendar_month),
                enabledBorder: OutlineInputBorder(
                    borderSide:
                    BorderSide(color: isDark ? Colors.white54 : Colors.grey)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal)),
              ),
              onTap: pickBirthdate,
            ),

            const SizedBox(height: 20),

            // ------------------ COUNTRY ------------------
            Text(
              "Pays :",
              style:
              TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 5),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton(
                value: selectedCountry,
                dropdownColor:
                isDark ? Colors.grey.shade900 : Colors.white,
                underline: SizedBox(),
                isExpanded: true,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black),
                items: regions.keys
                    .map((c) =>
                    DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (c) {
                  setState(() {
                    selectedCountry = c!;
                    selectedRegion = regions[c]!.first;
                  });
                },
              ),
            ),

            const SizedBox(height: 12),

            // ------------------ REGION ------------------
            Text(
              "Région :",
              style:
              TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 5),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton(
                value: selectedRegion,
                dropdownColor:
                isDark ? Colors.grey.shade900 : Colors.white,
                underline: SizedBox(),
                isExpanded: true,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black),
                items: regions[selectedCountry]!
                    .map((r) =>
                    DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (r) => setState(() => selectedRegion = r!),
              ),
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
