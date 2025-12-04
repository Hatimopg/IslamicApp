import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'private_chat_page.dart';

class PrivateUsersPage extends StatelessWidget {
  final int currentId;

  PrivateUsersPage({required this.currentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs
            .where((u) => u['uid'] != currentId)
            .toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) {
            final u = users[i];
            final online = u['isOnline'] == true;

            return ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: u['profile'] != null
                        ? NetworkImage(u['profile'])
                        : AssetImage("assets/default.jpg") as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 6,
                      backgroundColor: online ? Colors.green : Colors.grey,
                    ),
                  )
                ],
              ),
              title: Text(u['username']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrivateChatPage(
                      currentId: currentId,
                      otherId: u['uid'],
                      otherName: u['username'],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
