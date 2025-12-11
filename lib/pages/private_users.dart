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
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs
            .where((u) => u["uid"] != myId.toString())
            .toList();

        // Trier online
        docs.sort((a, b) =>
            (b["isOnline"] == true ? 1 : 0).compareTo(a["isOnline"] == true ? 1 : 0));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final u = docs[i];

            final profile = (u["profile"] != null && u["profile"] != "")
                ? baseUrl + u["profile"]
                : "";

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: profile != ""
                    ? NetworkImage(profile)
                    : AssetImage("assets/default.jpg") as ImageProvider,
              ),
              title: Text(u["username"] ?? "Utilisateur"),
              subtitle: Text(u["isOnline"] == true ? "En ligne 🔥" : "Hors ligne"),
              trailing: Icon(
                Icons.circle,
                color: u["isOnline"] == true ? Colors.green : Colors.grey,
                size: 12,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrivateChatPage(
                      currentId: myId,
                      otherId: int.parse(u["uid"]),
                      otherName: u["username"] ?? "Utilisateur",
                      otherProfile: profile,
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
