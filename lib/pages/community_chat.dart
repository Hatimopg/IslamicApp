import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityChatPage extends StatefulWidget {
  @override
  _CommunityChatPageState createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  TextEditingController msgCtrl = TextEditingController();

  Future<void> sendMessage() async {
    if (msgCtrl.text.trim().isEmpty) return;

    FirebaseFirestore.instance.collection("community_chat").add({
      "userId": "123", // remplacer par vrai user
      "username": "UserTest",
      "text": msgCtrl.text.trim(),
      "timestamp": FieldValue.serverTimestamp(),
    });

    msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("community_chat")
                .orderBy("timestamp", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

              final messages = snapshot.data!.docs;

              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  return ListTile(
                    title: Text(msg["username"]),
                    subtitle: Text(msg["text"]),
                  );
                },
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: msgCtrl,
                  decoration: InputDecoration(
                    hintText: "Écrire un message...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.teal),
                onPressed: sendMessage,
              )
            ],
          ),
        )
      ],
    );
  }
}
