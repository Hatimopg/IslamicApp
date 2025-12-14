import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatefulWidget {
  final int userId;
  final String username;
  final String profileUrl;

  ChatPage({
    required this.userId,
    required this.username,
    required this.profileUrl,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    FirebaseFirestore.instance.collection("community_messages").add({
      "message": messageController.text.trim(),
      "sender_id": widget.userId,
      "username": widget.username,
      "profile": widget.profileUrl,
      "timestamp": FieldValue.serverTimestamp(),
    });

    messageController.clear();
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

    return Scaffold(
      appBar: AppBar(title: const Text("Communauté")),

      body: Column(
        children: [
          // ------------------ MESSAGE LIST ------------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("community_messages")
                  .orderBy("timestamp", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;

                    final msg = data["message"] ?? "";
                    final username = data["username"] ?? "Utilisateur";
                    final profile = data["profile"];

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: getProfileImage(profile),
                        ),
                        title: Text(
                          username,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          msg,
                          style: TextStyle(
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                          ),
                        ),
                        tileColor: isDark
                            ? Colors.teal.withOpacity(0.25)
                            : Colors.teal.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
              color: isDark ? Colors.grey[900] : Colors.grey.shade200,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Écrire un message...",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: sendMessage,
                  child: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
