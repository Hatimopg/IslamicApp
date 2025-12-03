import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'change_password.dart';
import 'package:image_picker/image_picker.dart';

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

    final res = await http.get(url);

    if (res.statusCode == 200) {
      setState(() {
        user = jsonDecode(res.body);
        loading = false;
      });
    }
  }

  String cleanDate(String date) {
    return date.split("T")[0];
  }

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final request = http.MultipartRequest(
      "POST",
      Uri.parse(
          "https://exciting-learning-production-d784.up.railway.app/upload-profile"),
    );

    request.fields["user_id"] = widget.userId.toString();
    request.files
        .add(await http.MultipartFile.fromPath("image", file.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Photo mise à jour !")));
      loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors du téléchargement")));
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

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Profil"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickProfileImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.teal,
                backgroundImage: user!["profile"] != null
                    ? NetworkImage(user!["profile"])
                    : null,
                child: user!["profile"] == null
                    ? Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 15),

            Text(
              user!["username"],
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            // Infos utilisateur
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Pays : ${user!['country']}",
                  style: TextStyle(fontSize: 16)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Région : ${user!['region']}",
                  style: TextStyle(fontSize: 16)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Naissance : ${cleanDate(user!['birthdate'])}",
                  style: TextStyle(fontSize: 16)),
            ),

            SizedBox(height: 30),

            // Modifier mot de passe
            ElevatedButton.icon(
              icon: Icon(Icons.lock_reset),
              label: Text("Modifier le mot de passe"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangePasswordPage(
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 15),

            // Déconnexion
            ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text("Se déconnecter"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, "/login", (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
