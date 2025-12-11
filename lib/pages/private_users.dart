import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:islamicapp/pages/private_chat_page.dart';

class PrivateUsersPage extends StatelessWidget {
  final int myId;

  PrivateUsersPage({required this.myId});

  final String baseUrl =
      "https://exciting-learning-production-d784.up.railway.app/";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs
            .where((u) => u["uid"] != myId.toString())
            .toList();

        // ---- FIX 1 : convertir en vrai bool ----
        docs.sort((a, b) {
          final bool aOnline = a["isOnline"] == true;
          final bool bOnline = b["isOnline"] == true;
          return (bOnline ? 1 : 0).compareTo(aOnline ? 1 : 0);
        });

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final u = docs[i];

            // ---- FIX 2 : PHOTO PROPRE ----
            final rawProfile = u["profile"];

            final String? profileUrl =
            (rawProfile != null &&
                rawProfile is String &&
                rawProfile.isNotEmpty &&
                (rawProfile.contains(".jpg") ||
                    rawProfile.contains(".png")))
                ? baseUrl + rawProfile
                : null;

            // ---- FIX 3 : online clean ----
            final bool isOnline = u["isOnline"] == true;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: profileUrl != null
                    ? NetworkImage(profileUrl)
                    : const AssetImage("assets/default.jpg"),
              ),
              title: Text(u["username"] ?? "Utilisateur"),
              subtitle: Text(isOnline ? "En ligne 🔥" : "Hors ligne"),
              trailing: Icon(
                Icons.circle,
                color: isOnline ? Colors.green : Colors.grey,
                size: 12,
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrivateChatPage(
                      currentId: myId,
                      otherId: int.parse(u["uid"]),
                      otherName: u["username"] ?? "Inconnu",
                      otherProfile: profileUrl,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
