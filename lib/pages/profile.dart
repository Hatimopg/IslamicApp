import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'change_password.dart';
import 'login.dart';
import 'delete_account.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  const ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  bool loading = true;

  final String baseUrl =
      "https://exciting-learning-production-d784.up.railway.app";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // =====================================================
  // CHARGER LE PROFIL
  // =====================================================
  Future<void> loadProfile() async {
    final url = Uri.parse("$baseUrl/profile/${widget.userId}");
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

  // =====================================================
  // UPLOAD PHOTO
  // =====================================================
  Future<void> pickImageAndUpload() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/upload-profile"),
    );

    request.fields["user_id"] = widget.userId.toString();

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        "profile",
        bytes,
        filename: image.name,
      ));
    } else {
      request.files.add(
        await http.MultipartFile.fromPath("profile", image.path),
      );
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Photo mise à jour !")));
      loadProfile();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Erreur upload")));
    }
  }

  // =====================================================
  // LOGOUT → Firestore isOnline = false
  // =====================================================
  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": widget.userId}),
      );
    } catch (e) {}

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
    );
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (user == null) return const Center(child: Text("Erreur chargement profil"));

    String birth = user!["birthdate"].toString().split("T")[0];

    final hasPic = user!["profile"] != null && user!["profile"] != "";
    final img = hasPic
        ? NetworkImage("$baseUrl/uploads/${user!["profile"]}")
        : const AssetImage("assets/default.jpg") as ImageProvider;

    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(radius: 60, backgroundImage: img),
                GestureDetector(
                  onTap: pickImageAndUpload,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 22),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),
            Text(
              user!["username"],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            infoRow("Pays", user!["country"]),
            infoRow("Région", user!["region"]),
            infoRow("Naissance", birth),

            const SizedBox(height: 35),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChangePasswordPage(userId: widget.userId)),
                );
              },
              icon: const Icon(Icons.lock_reset),
              label: const Text("Modifier le mot de passe"),
              style: btnStyle(Colors.teal),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              label: const Text("Se déconnecter"),
              style: btnStyle(Colors.red),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text("Supprimer mon compte"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeleteAccountPage(userId: widget.userId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label : ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  ButtonStyle btnStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
