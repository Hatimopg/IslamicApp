import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivateChatPage extends StatefulWidget {
  final int currentId;
  final int otherId;
  final String otherName;

  PrivateChatPage({
    required this.currentId,
    required this.otherId,
    required this.otherName,
  });

  @override
  _PrivateChatPageState createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  TextEditingController controller = TextEditingController();

  String get chatId {
    final ids = [widget.currentId, widget.otherId];
    ids.sort();
    return "${ids[0]}_${ids[1]}";
  }

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    FirebaseFirestore.instance
        .collection("private_chats")
        .doc(chatId)
        .collection("messages")
        .add({
      "from": widget.currentId,
      "to": widget.otherId,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
      "seen": false,
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),

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
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final msg = docs[i];
                    final isMe = msg['from'] == widget.currentId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'],
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

          // INPUT
          Row(
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
              ),
            ],
          )
        ],
      ),
    );
  }
}
