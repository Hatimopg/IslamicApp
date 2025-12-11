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
    ensureChatDocumentExists();
    markMessagesAsSeen();
  }

  // ----------------------- ENSURE CHAT DOCUMENT EXISTS -----------------------
  Future<void> ensureChatDocumentExists() async {
    final docRef =
    FirebaseFirestore.instance.collection("private_chats").doc(chatId);

    await docRef.set({}, SetOptions(merge: true));
  }

  // ----------------------- MARK SEEN -----------------------
  Future<void> markMessagesAsSeen() async {
    final chatDoc = FirebaseFirestore.instance
        .collection("private_chats")
        .doc(chatId);

    await chatDoc.set({}, SetOptions(merge: true));

    final ref = chatDoc.collection("messages");

    final unread = await ref
        .where("to", isEqualTo: widget.currentId)
        .where("seen", isEqualTo: false)
        .get();

    for (var doc in unread.docs) {
      doc.reference.update({"seen": true});
    }
  }

  // ----------------------- SEND MESSAGE -----------------------
  Future<void> sendMessage() async {
    final text = msgCtrl.text.trim();
    if (text.isEmpty) return;

    final chatDoc =
    FirebaseFirestore.instance.collection("private_chats").doc(chatId);

    await chatDoc.set({}, SetOptions(merge: true));

    await chatDoc.collection("messages").add({
      "from": widget.currentId,
      "to": widget.otherId,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
      "seen": false,
    });

    await chatDoc.set({
      "typing_${widget.currentId}": false
    }, SetOptions(merge: true));

    msgCtrl.clear();
    scrollToBottom();
  }

  // ----------------------- SCROLL AUTO -----------------------
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ----------------------- TYPING INDICATOR -----------------------
  void setTyping(bool isTyping) {
    final ref = FirebaseFirestore.instance
        .collection("private_chats")
        .doc(chatId);

    ref.set({
      "typing_${widget.currentId}": isTyping
    }, SetOptions(merge: true));

    typingTimer?.cancel();

    if (isTyping) {
      typingTimer = Timer(const Duration(seconds: 1), () {
        ref.set({
          "typing_${widget.currentId}": false
        }, SetOptions(merge: true));
      });
    }
  }

  // ----------------------- UI MESSAGE BUBBLE -----------------------
  Widget messageBubble(Map<String, dynamic> m) {
    final bool isMe = m["from"] == widget.currentId;
    final String message = m["text"];
    final bool seen = m["seen"] == true;

    final timestamp = m["timestamp"] != null
        ? DateFormat("HH:mm").format(m["timestamp"].toDate())
        : "";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.teal : Colors.grey.shade300,
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
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
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
                    seen
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------- AVATAR -----------------------
  ImageProvider getProfileImage() {
    if (widget.otherProfile == null || widget.otherProfile!.isEmpty) {
      return const AssetImage("assets/default.jpg");
    }
    return NetworkImage(widget.otherProfile!);
  }

  // ----------------------- BUILD -----------------------
  @override
  Widget build(BuildContext context) {
    final chatDoc =
    FirebaseFirestore.instance.collection("private_chats").doc(chatId);

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

      body: Column(
        children: [
          // ---------- TYPING INDICATOR ----------
          StreamBuilder(
            stream: chatDoc.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || !snap.data!.exists) return SizedBox();

              final data = snap.data!.data() as Map<String, dynamic>? ?? {};
              final typing = data["typing_${widget.otherId}"] == true;

              return typing
                  ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "${widget.otherName} est en train d’écrire...",
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700),
                ),
              )
                  : const SizedBox(height: 0);
            },
          ),

          // ---------- MESSAGES ----------
          Expanded(
            child: StreamBuilder(
              stream: chatDoc
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  controller: scrollCtrl,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) =>
                      messageBubble(docs[i].data() as Map<String, dynamic>),
                );
              },
            ),
          ),

          // ---------- INPUT ----------
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgCtrl,
                    onChanged: (value) => setTyping(value.isNotEmpty),
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
