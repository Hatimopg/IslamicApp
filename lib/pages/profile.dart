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
    final url = Uri.parse("https://exciting-learning-production-d784.up.railway.app/profile/${widget.userId}");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      setState(() {
        user = jsonDecode(res.body);
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: Text("Profil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/default.jpg"), // plus tard → upload
            ),
            const SizedBox(height: 20),
            Text("Nom : ${user!['username']}"),
            Text("Pays : ${user!['country']}"),
            Text("Région : ${user!['region']}"),
            Text("Naissance : ${user!['birthdate']}"),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, "/change-password");
              },
              child: Text("Modifier le mot de passe"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/login");
              },
              child: Text("Se déconnecter"),
            )
          ],
        ),
      ),
    );
  }
}
