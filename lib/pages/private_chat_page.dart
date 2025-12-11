import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PrivateChatPage extends StatefulWidget {
  final int currentId;
  final int otherId;
  final String otherName;
  final String? otherProfile;

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
  TextEditingController msgCtrl = TextEditingController();
  ScrollController scrollCtrl = ScrollController();

  Timer? typingTimer;

  String get chatId {
    final ids = [widget.currentId, widget.otherId]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  @override
  void initState() {
    super.initState();
    markMessagesAsSeen();
  }

  // ----------------------- MARK SEEN -----------------------
  void markMessagesAsSeen() async {
    final ref = FirebaseFirestore.instance
        .collection("private_chats")
        .doc(chatId)
        .collection("messages");

    final unread = await ref
        .where("to", isEqualTo: widget.currentId)
        .where("seen", isEqualTo: false)
        .get();

    for (var doc in unread.docs) {
      doc.reference.update({"seen": true});
    }
  }

  // ----------------------- SEND MESSAGE -----------------------
  void sendMessage() {
    final text = msgCtrl.text.trim();
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

    FirebaseFirestore.instance
        .collection("private_chats")
        .doc(chatId)
        .update({"typing_${widget.currentId}": false});

    msgCtrl.clear();
    scrollToBottom();
  }

  // ----------------------- SCROLL AUTO -----------------------
  void scrollToBottom() {
    Future.delayed(Duration(milliseconds: 200), () {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ----------------------- TYPING INDICATOR -----------------------
  void setTyping(bool isTyping) {
    final doc =
    FirebaseFirestore.instance.collection("private_chats").doc(chatId);

    doc.update({"typing_${widget.currentId}": isTyping});

    typingTimer?.cancel();

    if (isTyping) {
      typingTimer = Timer(const Duration(seconds: 1), () {
        doc.update({"typing_${widget.currentId}": false});
      });
    }
  }

  // ----------------------- UI MESSAGE BUBBLE -----------------------
  Widget messageBubble(Map<String, dynamic> m) {
    final bool isMe = m["from"] == widget.currentId;
    final String msg = m["text"];
    final bool seen = m["seen"] == true;

    final timestamp = m["timestamp"] != null
        ? DateFormat("HH:mm").format(m["timestamp"].toDate())
        : "";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.teal : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),

            // TIMESTAMP
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timestamp,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Icon(
                    seen ? Icons.check_circle : Icons.check_circle_outline,
                    size: 14,
                    color: Colors.white70,
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------- PROFILE IMAGE -----------------------
  ImageProvider getProfileImage() {
    if (widget.otherProfile == null || widget.otherProfile!.isEmpty) {
      return const AssetImage("assets/default.jpg");
    }
    return NetworkImage(widget.otherProfile!);
  }

  // ----------------------- BUILD -----------------------
  @override
  Widget build(BuildContext context) {
    final chatRef = FirebaseFirestore.instance
        .collection("private_chats")
        .doc(chatId);

    final messagesRef = chatRef
        .collection("messages")
        .orderBy("timestamp", descending: true);

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Row(
          children: [
            CircleAvatar(backgroundImage: getProfileImage()),
            const SizedBox(width: 12),
            Text(widget.otherName),
          ],
        ),
      ),

      // ----------------------- BODY -----------------------
      body: Column(
        children: [
          // 🔥 TYPING INDICATOR
          StreamBuilder(
            stream: chatRef.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || !snap.data!.exists) return SizedBox();

              final data = snap.data!.data() as Map<String, dynamic>? ?? {};
              final bool otherTyping =
                  data["typing_${widget.otherId}"] == true;

              return otherTyping
                  ? Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  "${widget.otherName} est en train d’écrire...",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              )
                  : SizedBox(height: 0);
            },
          ),

          // 🔥 MESSAGES
          Expanded(
            child: StreamBuilder(
              stream: messagesRef.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snap.data!.docs;

                return ListView.builder(
                  controller: scrollCtrl,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final m = docs[i].data() as Map<String, dynamic>;
                    return messageBubble(m);
                  },
                );
              },
            ),
          ),

          // 🔥 INPUT BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgCtrl,
                    onChanged: (txt) => setTyping(txt.isNotEmpty),
                    decoration: InputDecoration(
                      hintText: "Votre message...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
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
