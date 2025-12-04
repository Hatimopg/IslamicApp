import 'package:flutter/material.dart';
import 'community_chat.dart';
import 'private_chat_list.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Discussions"),
        bottom: TabBar(
          onTap: (i) => setState(() => selected = i),
          tabs: const [
            Tab(text: "Communautaire"),
            Tab(text: "Messages privés"),
          ],
        ),
      ),
      body: selected == 0 ? CommunityChatPage() : PrivateChatListPage(),
    );
  }
}
