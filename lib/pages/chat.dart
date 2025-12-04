import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 🔥 obligatoire
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Text(
            "Chat",
            style: TextStyle(
              color: Colors.teal.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.teal,
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Communauté"),
              Tab(text: "Messages privés"),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            // ------------------------------
            // ONGLET 1 : CHAT COMMUNAUTAIRE
            // ------------------------------
            Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: const [
                      Text("UserTest"),
                      Text("d"),
                    ],
                  ),
                ),

                // Champ d'envoi de message
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: "Écrire un message...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: () {
                          // PLUS TARD: sendMessage()
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),

            // ------------------------------
            // ONGLET 2 : LISTE DES USERS (MESSAGES PRIVÉS)
            // ------------------------------
            Container(
              alignment: Alignment.center,
              child: Text(
                "Liste des utilisateurs bientôt...",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
