import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityChat extends StatefulWidget {
  final int userId;
  CommunityChat({required this.userId});

  @override
  _CommunityChatState createState() => _CommunityChatState();
}

class _CommunityChatState extends State<CommunityChat> {
  TextEditingController controller = TextEditingController();

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    FirebaseFirestore.instance.collection("community_messages").add({
      "text": text,
      "sender": widget.userId,
      "timestamp": FieldValue.serverTimestamp(),
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("community_messages")
                .orderBy("timestamp", descending: true)
                .snapshots(),

            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;

              return ListView.builder(
                reverse: true,
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final msg = docs[i];
                  return ListTile(
                    title: Text("${msg["sender"]} : ${msg["text"]}"),
                  );
                },
              );
            },
          ),
        ),

        // barre d'envoi
        Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Écrire un message...",
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
