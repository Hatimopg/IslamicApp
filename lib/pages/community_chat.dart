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
      "profile": widget.profile,
      "timestamp": FieldValue.serverTimestamp(),
    });

    msgCtrl.clear();
  }

  ImageProvider getProfileImage(String? url) {
    if (url == null || url.isEmpty || !url.contains(".")) {
      return const AssetImage("assets/default.jpg");
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isDark ? Colors.grey.shade900 : Colors.teal.shade50;
    final inputBg = isDark ? Colors.grey.shade900 : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text("Communauté")),

      body: Column(
        children: [
          // ------------------ MESSAGE LIST ------------------
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("community_messages")
                  .orderBy("timestamp", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data() as Map<String, dynamic>;

                    final username = m["username"] ?? "Utilisateur";
                    final message = m["message"] ?? "";
                    final profile = m["profile"];

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: getProfileImage(profile),
                        ),
                        title: Text(
                          username,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          message,
                          style: TextStyle(
                            color: isDark ? Colors.grey[300] : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ------------------ INPUT BAR ------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgCtrl,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Écrire un message...",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
