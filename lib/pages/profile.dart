import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'change_password.dart';
import 'login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

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

  // ---------------------------------------------------------------------
  // UPLOAD PHOTO DE PROFIL
  // ---------------------------------------------------------------------
  Future<void> pickImageAndUpload() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final uri = Uri.parse(
        "https://exciting-learning-production-d784.up.railway.app/upload-profile");

    var request = http.MultipartRequest("POST", uri);
    request.fields["user_id"] = widget.userId.toString();

    // --------------------------------------------------
    // WEB UPLOAD
    // --------------------------------------------------
    if (kIsWeb) {
      final bytes = await image.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          "profile",
          bytes,
          filename: image.name,
        ),
      );
    }
    // --------------------------------------------------
    // MOBILE UPLOAD (Android / iOS)
    // --------------------------------------------------
    else {
      request.files.add(
        await http.MultipartFile.fromPath(
          "profile",
          image.path,
        ),
      );
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo de profil mise à jour !")),
      );
      loadProfile(); // recharge le profil
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'upload")),
      );
    }
  }


  // ---------------------------------------------------------------------
  // WIDGET PHOTO DE PROFIL + ICON CAMÉRA
  // ---------------------------------------------------------------------
  Widget buildProfilePicture() {
    final bool hasPicture =
        user!["profile"] != null && user!["profile"].toString().isNotEmpty;

    final imageUrl = hasPicture
        ? "https://exciting-learning-production-d784.up.railway.app/uploads/${user!["profile"]}"
        : "assets/default.jpg";

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: hasPicture
              ? NetworkImage(imageUrl)
              : AssetImage("assets/default.jpg") as ImageProvider,
        ),
        GestureDetector(
          onTap: pickImageAndUpload,
          child: Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.camera_alt, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());
    if (user == null) return Center(child: Text("Erreur chargement profil"));

    String cleanDate = user!["birthdate"].toString().split("T")[0];

    return Scaffold(
      appBar: AppBar(title: Text("Profil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildProfilePicture(),

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
