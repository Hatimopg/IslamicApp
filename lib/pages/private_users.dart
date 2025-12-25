import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:islamicapp/pages/private_chat_page.dart';

class PrivateUsersPage extends StatefulWidget {
  final int myId;

  const PrivateUsersPage({super.key, required this.myId});

  @override
  State<PrivateUsersPage> createState() => _PrivateUsersPageState();
}

class _PrivateUsersPageState extends State<PrivateUsersPage> {
  String search = "";

  String chatIdFor(int a, int b) {
    final ids = [a, b]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ================= SEARCH =================
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Rechercher un utilisateur...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor:
              isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => search = v.toLowerCase()),
          ),
        ),

        // ================= USERS LIST =================
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
            FirebaseFirestore.instance.collection("users").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs
                  .map((d) => d.data() as Map<String, dynamic>)
                  .where((u) =>
              u["uid"]?.toString() != widget.myId.toString())
                  .where((u) {
                final name =
                    u["username"]?.toString().toLowerCase() ?? "";
                return name.contains(search);
              })
                  .toList();

              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    "Aucun utilisateur trouvé",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              // online first
              users.sort((a, b) {
                final bool aOnline = a["isOnline"] == true;
                final bool bOnline = b["isOnline"] == true;
                return (bOnline ? 1 : 0).compareTo(aOnline ? 1 : 0);
              });

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final u = users[i];

                  final String username =
                      u["username"]?.toString() ?? "Utilisateur";
                  final String uidStr = u["uid"]?.toString() ?? "0";
                  final int otherId = int.tryParse(uidStr) ?? 0;

                  final String profileRaw =
                      u["profile"]?.toString() ?? "";
                  final String? profileUrl =
                  profileRaw.startsWith("http") ? profileRaw : null;

                  final bool isOnline = u["isOnline"] == true;
                  final String chatId =
                  chatIdFor(widget.myId, otherId);

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (otherId == 0) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrivateChatPage(
                            currentId: widget.myId,
                            otherId: otherId,
                            otherName: username,
                            otherProfile: profileUrl,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                        isDark ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (!isDark)
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                            ),
                        ],
                      ),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: profileUrl != null
                                  ? NetworkImage(profileUrl)
                                  : const AssetImage(
                                  "assets/default.jpg")
                              as ImageProvider,
                            ),
                            // online badge
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? Colors.green
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                            isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          isOnline ? "En ligne" : "Vu récemment",
                          style: TextStyle(
                            color: isOnline
                                ? (isDark
                                ? Colors.greenAccent
                                : Colors.green)
                                : (isDark
                                ? Colors.white70
                                : Colors.black54),
                          ),
                        ),

                        // ================= UNREAD BADGE =================
                        trailing: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("private_chats")
                              .doc(chatId)
                              .collection("messages")
                              .where("to",
                              isEqualTo: widget.myId)
                              .where("seen", isEqualTo: false)
                              .snapshots(),
                          builder: (context, snap) {
                            if (!snap.hasData ||
                                snap.data!.docs.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final int count = snap.data!.docs.length;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: Text(
                                count > 9 ? "9+" : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
