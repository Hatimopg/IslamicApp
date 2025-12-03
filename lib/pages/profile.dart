import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'change_password.dart';
import 'login.dart';

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
        "https://exciting-learning-production-d784.up.railway.app/profile/${widget.userId}");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        user = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
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
      return Center(child: CircularProgressIndicator());
    }

    if (user == null) {
      return Center(child: Text("Erreur chargement profil"));
    }

    String cleanDate = user!["birthdate"].toString().split("T")[0];

    return Scaffold(
      appBar: AppBar(title: Text("Profil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                // PLUS TARD : ouvrir la galerie
              },
              child: CircleAvatar(
                radius: 55,
                backgroundImage: user!["profile"] != null
                    ? NetworkImage(user!["profile"])
                    : AssetImage("assets/default.jpg") as ImageProvider,
              ),
            ),

            SizedBox(height: 20),
            Text(
              user!["username"],
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            Row(
              children: [
                Text("Pays : ", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(user!["country"]),
              ],
            ),
            Row(
              children: [
                Text("Région : ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(user!["region"]),
              ],
            ),
            Row(
              children: [
                Text("Naissance : ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(cleanDate),
              ],
            ),

            SizedBox(height: 30),

            ElevatedButton.icon(
              icon: Icon(Icons.lock_reset),
              label: Text("Modifier le mot de passe"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangePasswordPage(userId: widget.userId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text("Se déconnecter"),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
