import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatCommunityPage extends StatefulWidget {
  final int userId;
  final String username;
  final String profile;

  ChatCommunityPage({
    required this.userId,
    required this.username,
    required this.profile,
  });

  @override
  _ChatCommunityPageState createState() => _ChatCommunityPageState();
}

class _ChatCommunityPageState extends State<ChatCommunityPage> {
  final TextEditingController msg = TextEditingController();

  void send() {
    if (msg.text.trim().isEmpty) return;

    FirebaseFirestore.instance.collection("community_messages").add({
      "message": msg.text,
      "sender_id": widget.userId,
      "username": widget.username,
      "profile": widget.profile,
      "timestamp": FieldValue.serverTimestamp(),
    });

    msg.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Communauté")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("community_messages")
                  .orderBy("timestamp", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView(
                  children: docs.map((d) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (d["profile"] != null &&
                            d["profile"].toString().isNotEmpty)
                            ? NetworkImage(d["profile"])
                            : AssetImage("assets/default.jpg") as ImageProvider,
                      ),
                      title: Text(d["username"] ?? "User"),
                      subtitle: Text(d["message"]),
                      tileColor: Colors.teal.shade50,
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // Zone d'envoi
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(child: TextField(controller: msg)),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.teal),
                  onPressed: send,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
