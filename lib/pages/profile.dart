import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  final int userId;
  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  bool loading = true;

  Future<void> loadProfile() async {
    final url = Uri.parse(
        "https://exciting-learning-production-d784.up.railway.app/profile/${widget.userId}"
    );

    try {
      final res = await http.get(url);

      if (res.statusCode == 200) {
        setState(() {
          user = jsonDecode(res.body);
          loading = false;
        });
      } else {
        print("Erreur backend: ${res.body}");
      }
    } catch (e) {
      print("Erreur réseau: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ---- PHOTO ----
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.teal.shade300,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 20),

            // ---- NOM ----
            Text(
              user!["username"],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // ---- INFOS ----
            infoLine("Pays", user!["country"]),
            infoLine("Région", user!["region"]),
            infoLine("Naissance", user!["birthdate"]),

            const SizedBox(height: 30),

            // ---- BOUTON MDP ----
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock_reset),
                label: const Text("Modifier le mot de passe"),
                onPressed: () {
                  Navigator.pushNamed(context, "/change-password");
                },
              ),
            ),

            const SizedBox(height: 15),

            // ---- BOUTON LOGOUT ----
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Se déconnecter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, "/login");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- WIDGET INFO ----
  Widget infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$label : ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
