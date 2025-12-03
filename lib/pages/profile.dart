import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final int userId;
  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  bool loading = true;
  File? selectedImage;

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

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });

      await uploadImage(File(picked.path));
    }
  }

  Future<void> uploadImage(File file) async {
    final url = Uri.parse("https://exciting-learning-production-d784.up.railway.app/upload-profile");

    var request = http.MultipartRequest("POST", url);
    request.fields["user_id"] = widget.userId.toString();
    request.files.add(await http.MultipartFile.fromPath("profile", file.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      print("Upload OK");
      loadProfile();
    } else {
      print("Erreur upload");
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage!)
                    : (user!["profile"] != null
                    ? NetworkImage(
                    "https://exciting-learning-production-d784.up.railway.app/uploads/${user!["profile"]}")
                    : AssetImage("assets/default.jpg")) as ImageProvider,
              ),
            ),

            SizedBox(height: 10),
            Text(
              user!["username"],
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            infoRow("Pays", user!["country"]),
            infoRow("Région", user!["region"]),
            infoRow("Naissance", user!["birthdate"].split("T")[0]),

            SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, "/change-password");
              },
              icon: Icon(Icons.lock_reset),
              label: Text("Modifier le mot de passe"),
            ),

            SizedBox(height: 15),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/login");
              },
              icon: Icon(Icons.logout),
              label: Text("Se déconnecter"),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text("$label : ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
