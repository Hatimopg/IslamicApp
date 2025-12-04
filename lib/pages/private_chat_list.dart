import 'package:flutter/material.dart';

class PrivateChatListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(12),
      children: [
        Text("Messages non lus", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),

        // exemple
        ListTile(
          leading: CircleAvatar(backgroundColor: Colors.grey),
          title: Text("Ahmed"),
          subtitle: Text("Tu as reçu un message"),
          trailing: CircleAvatar(
            backgroundColor: Colors.red,
            radius: 10,
            child: Text("1", style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),

        SizedBox(height: 20),
        Text("En ligne", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),

        // bulle verte
        ListTile(
          leading: Stack(
            children: [
              CircleAvatar(backgroundColor: Colors.grey),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(radius: 6, backgroundColor: Colors.green),
              )
            ],
          ),
          title: Text("Yassine"),
        ),

        SizedBox(height: 20),
        Text("Hors-ligne", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),

        ListTile(
          leading: Stack(
            children: [
              CircleAvatar(backgroundColor: Colors.grey),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(radius: 6, backgroundColor: Colors.grey),
              )
            ],
          ),
          title: Text("Fatima"),
        ),
      ],
    );
  }
}
