import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/message_filter.dart';

class PrivateChatPage extends StatefulWidget {
  final int currentId;
  final int otherId;
  final String otherName;
  final String? otherProfile;

  const PrivateChatPage({
    super.key,
    required this.currentId,
    required this.otherId,
    required this.otherName,
    required this.otherProfile,
  });

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final TextEditingController msgCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();
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

  @override
  void dispose() {
    msgCtrl.dispose();
    scrollCtrl.dispose();
    typingTimer?.cancel();
    super.dispose();
  }

  // ================= MARK SEEN =================
  Future<void> markMessagesAsSeen() async {
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

  // ================= SEND MESSAGE =================
  void sendMessage() {
    final text = msgCtrl.text.trim();
    if (text.isEmpty) return;

    if (MessageFilter.containsForbidden(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⛔ Message interdit"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final chatRef =
    FirebaseFirestore.instance.collection("private_chats").doc(chatId);

    chatRef.collection("messages").add({
      "from": widget.currentId,
      "to": widget.otherId,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
      "seen": false,
    });

    chatRef.update({"typing_${widget.currentId}": false});

    msgCtrl.clear();
    scrollToBottom();
  }

  // ================= AUTO SCROLL =================
  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= TYPING =================
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

  // ================= PROFILE IMAGE =================
  ImageProvider getProfileImage() {
    if (widget.otherProfile == null ||
        !widget.otherProfile!.startsWith("http")) {
      return const AssetImage("assets/default.jpg");
    }
    return NetworkImage(widget.otherProfile!);
  }

  // ================= MESSAGE BUBBLE =================
  Widget messageBubble(Map<String, dynamic> m) {
    final bool isMe = m["from"] == widget.currentId;
    final String msg = m["text"] ?? "";
    final bool seen = m["seen"] == true;

    final timestamp = m["timestamp"] != null
        ? DateFormat("HH:mm").format(m["timestamp"].toDate())
        : "";

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.teal
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
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
                color: isMe
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timestamp,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white70
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Icon(
                    seen
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    size: 14,
                    color: Colors.white70,
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final chatRef =
    FirebaseFirestore.instance.collection("private_chats").doc(chatId);

    final messagesRef = chatRef
        .collection("messages")
        .orderBy("timestamp", descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(backgroundImage: getProfileImage()),
            const SizedBox(width: 12),
            Text(widget.otherName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                scrollToBottom();

                return ListView.builder(
                  controller: scrollCtrl,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final m =
                    docs[i].data() as Map<String, dynamic>;
                    return messageBubble(m);
                  },
                );
              },
            ),
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : Colors.grey.shade200,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgCtrl,
                    onChanged: (txt) => setTyping(txt.isNotEmpty),
                    decoration: const InputDecoration(
                      hintText: "Votre message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
