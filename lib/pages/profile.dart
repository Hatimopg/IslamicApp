import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'change_password.dart';
import 'login.dart';
import 'delete_account.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../utils/token_storage.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
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

  // ================= LOAD PROFILE =================
  Future<void> loadProfile() async {
    try {
      final token = await TokenStorage.getToken();

      if (token == null) {
        debugPrint("NO TOKEN");
        setState(() => loading = false);
        return;
      }

      final res = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        user = jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint("PROFILE ERROR => $e");
    }

    setState(() => loading = false);
  }

  // ================= UPLOAD AVATAR =================
  Future<void> pickImageAndUpload() async {
    final token = await TokenStorage.getToken();
    if (token == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/upload-profile"),
    );

    request.headers["Authorization"] = "Bearer $token";

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "profile",
          await image.readAsBytes(),
          filename: image.name,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          "profile",
          image.path,
        ),
      );
    }

    final res = await request.send();
    if (res.statusCode == 200) {
      loadProfile();
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    try {
      final token = await TokenStorage.getToken();

      await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
    } catch (_) {}

    await TokenStorage.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(
          onLogin: (_) {},
          onToggleTheme: () {},
        ),
      ),
          (_) => false,
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (user == null) {
      return const Center(child: Text("Impossible de charger le profil"));
    }

    final username = user!["username"] ?? "Utilisateur";
    final country = user!["country"] ?? "—";
    final region = user!["region"] ?? "—";
    final birth = user!["birthdate"] != null
        ? user!["birthdate"].toString().split("T")[0]
        : "—";

    ImageProvider img;

    final profile = user!["profile"];

    if (profile != null && profile is String && profile.startsWith("http")) {
      img = NetworkImage(profile);
    } else {
      img = const AssetImage("assets/default.jpg");
    }


    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // -------- AVATAR --------
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(radius: 60, backgroundImage: img),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: pickImageAndUpload,
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              username,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            infoRow("Pays", country),
            infoRow("Région", region),
            infoRow("Naissance", birth),

            const SizedBox(height: 30),

            // -------- CHANGE PASSWORD --------
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChangePasswordPage(),
                ),
              ),
              child: const Text("Modifier le mot de passe"),
            ),

            const SizedBox(height: 12),

            // -------- LOGOUT --------
            ElevatedButton(
              onPressed: logout,
              child: const Text("Se déconnecter"),
            ),

            const SizedBox(height: 12),

            // -------- DELETE ACCOUNT --------
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DeleteAccountPage(userId: widget.userId),
                ),
              ),
              child: const Text("Supprimer mon compte"),
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
          Text(
            "$label : ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
