import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:islamicapp/pages/private_chat_page.dart';

class PrivateUsersPage extends StatelessWidget {
  final int myId;

  PrivateUsersPage({required this.myId});

  final String baseUrl =
      "https://exciting-learning-production-d784.up.railway.app/uploads/";

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs
            .where((u) => u["uid"] != myId.toString())
            .toList();

        // Trier par online / offline
        docs.sort((a, b) {
          final bool aOnline = a["isOnline"] == true;
          final bool bOnline = b["isOnline"] == true;
          return (bOnline ? 1 : 0).compareTo(aOnline ? 1 : 0);
        });

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final u = docs[i];

            final rawProfile = u["profile"];
            final String? profileUrl =
            (rawProfile != null && rawProfile != "")
                ? baseUrl + rawProfile
                : null;

            final bool isOnline = u["isOnline"] == true;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                    ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: profileUrl != null
                      ? NetworkImage(profileUrl)
                      : const AssetImage("assets/default.jpg")
                  as ImageProvider,
                ),
                title: Text(
                  u["username"] ?? "Utilisateur",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  isOnline ? "En ligne 🔥" : "Hors ligne",
                  style: TextStyle(
                    color: isOnline
                        ? (isDark ? Colors.greenAccent : Colors.green)
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
                trailing: Icon(
                  Icons.circle,
                  color: isOnline ? Colors.green : Colors.grey,
                  size: 14,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrivateChatPage(
                        currentId: myId,
                        otherId: int.parse(u["uid"]),
                        otherName: u["username"] ?? "Utilisateur",
                        otherProfile: profileUrl,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
