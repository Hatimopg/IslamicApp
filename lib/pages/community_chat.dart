import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityChatPage extends StatefulWidget {
  final int userId;
  final String username;
  final String profile;

  CommunityChatPage({
    required this.userId,
    required this.username,
    required this.profile,
  });

  @override
  _CommunityChatPageState createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  TextEditingController msgCtrl = TextEditingController();

  void sendMessage() {
    if (msgCtrl.text.trim().isEmpty) return;

    FirebaseFirestore.instance.collection("community_messages").add({
      "message": msgCtrl.text.trim(),
      "sender_id": widget.userId,
      "username": widget.username,
      "profile": widget.profile, // <-- ok même si null
      "timestamp": FieldValue.serverTimestamp(),
    });

    msgCtrl.clear();
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

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data() as Map<String, dynamic>;

                    final username = m["username"] ?? "Utilisateur";
                    final message = m["message"] ?? "";
                    final profile = m["profile"]; // peut être null

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profile != null
                            ? NetworkImage(profile)
                            : AssetImage("assets/default.jpg")
                        as ImageProvider,
                      ),
                      title: Text(username),
                      subtitle: Text(message),
                      tileColor: Colors.teal.shade50,
                    );
                  },
                );
              },
            ),
          ),

          // INPUT MESSAGE
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: msgCtrl)),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.teal),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
