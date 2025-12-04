import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivateChatPage extends StatefulWidget {
  final int currentId;
  final int otherId;
  final String otherName;
  final String otherProfile;

  PrivateChatPage({
    required this.currentId,
    required this.otherId,
    required this.otherName,
    required this.otherProfile,
  });

  @override
  _PrivateChatPageState createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  TextEditingController msg = TextEditingController();

  String get chatId {
    final ids = [widget.currentId, widget.otherId];
    ids.sort();
    return "${ids[0]}_${ids[1]}";
  }

  void send() {
    if (msg.text.trim().isEmpty) return;

    FirebaseFirestore.instance
        .collection("private_chats")
        .doc(chatId)
        .collection("messages")
        .add({
      "from": widget.currentId,
      "to": widget.otherId,
      "text": msg.text,
      "timestamp": FieldValue.serverTimestamp(),
      "seen": false,
    });

    msg.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.otherProfile)),
            SizedBox(width: 10),
            Text(widget.otherName),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("private_chats")
                  .doc(chatId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return Center(child: CircularProgressIndicator());

                final docs = snap.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final m = docs[i];
                    final bool isMe = m["from"] == widget.currentId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m["text"],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Row(
            children: [
              Expanded(child: TextField(controller: msg)),
              IconButton(
                icon: Icon(Icons.send, color: Colors.teal),
                onPressed: send,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
