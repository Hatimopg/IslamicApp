import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:islamicapp/pages/private_chat_page.dart';

class PrivateUsersPage extends StatelessWidget {
  final int myId;

  PrivateUsersPage({required this.myId});

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

        // tri online / offline
        docs.sort((a, b) =>
            (b["isOnline"] ? 1 : 0).compareTo(a["isOnline"] ? 1 : 0));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final u = docs[i];

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: u["profile"] != null
                    ? NetworkImage(u["profile"])
                    : AssetImage("assets/default.jpg"),
              ),
              title: Text(u["username"]),
              subtitle: Text(u["isOnline"] ? "En ligne 🔥" : "Hors ligne"),
              trailing:
              u["isOnline"] ? Icon(Icons.circle, color: Colors.green, size: 12)
                  : Icon(Icons.circle, color: Colors.grey, size: 12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrivateChatPage(
                      currentId: myId,
                      otherId: int.parse(u["uid"]),
                      otherName: u["username"],
                      otherProfile: u["profile"],
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
