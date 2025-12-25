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

  // ================= SCROLL =================
  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
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

  // ================= DATE SEPARATOR =================
  Widget dateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            DateFormat("dd MMM yyyy").format(date),
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ================= MESSAGE BUBBLE =================
  Widget messageBubble(Map<String, dynamic> m, bool showDate) {
    final bool isMe = m["from"] == widget.currentId;
    final String msg = m["text"] ?? "";
    final bool seen = m["seen"] == true;

    final DateTime time = m["timestamp"] != null
        ? m["timestamp"].toDate()
        : DateTime.now();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        if (showDate) dateSeparator(time),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.teal
                  : (isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
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
                      DateFormat("HH:mm").format(time),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white70
                            : (isDark
                            ? Colors.white70
                            : Colors.black54),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Icon(
                        seen
                            ? Icons.done_all
                            : Icons.done,
                        size: 14,
                        color: seen
                            ? Colors.lightGreenAccent
                            : Colors.white70,
                      ),
                    ]
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          // ================= TYPING INDICATOR =================
          StreamBuilder<DocumentSnapshot>(
            stream: chatRef.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || !snap.data!.exists) {
                return const SizedBox.shrink();
              }

              final data = snap.data!.data() as Map<String, dynamic>;
              final bool otherTyping =
                  data["typing_${widget.otherId}"] == true;

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: otherTyping
                    ? Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    "${widget.otherName} écrit…",
                    style: const TextStyle(
                        fontStyle: FontStyle.italic),
                  ),
                )
                    : const SizedBox.shrink(),
              );
            },
          ),

          // ================= MESSAGES =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                markMessagesAsSeen();

                DateTime? lastDate;

                return ListView.builder(
                  controller: scrollCtrl,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final m =
                    docs[i].data() as Map<String, dynamic>;
                    final ts = m["timestamp"]?.toDate();
                    final showDate = ts != null &&
                        (lastDate == null ||
                            !DateUtils.isSameDay(ts, lastDate!));
                    lastDate = ts;

                    return messageBubble(m, showDate);
                  },
                );
              },
            ),
          ),

          // ================= INPUT =================
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark
                ? Colors.grey.shade900
                : Colors.grey.shade200,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgCtrl,
                    onChanged: (text) {
                      setTyping(text.isNotEmpty);
                      setState(() {}); // 🔥 OBLIGATOIRE POUR ACTIVER LE BOUTON
                    },
                    decoration: const InputDecoration(
                      hintText: "Votre message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: msgCtrl.text.trim().isEmpty
                        ? Colors.grey
                        : Colors.teal,
                  ),
                  onPressed: msgCtrl.text.trim().isEmpty
                      ? null
                      : sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
