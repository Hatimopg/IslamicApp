import 'package:flutter/material.dart';
import 'community_chat.dart';
import 'profile.dart';
import 'private_users.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final String username;
  final String profile;

  HomePage({
    required this.userId,
    required this.username,
    required this.profile,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const Center(child: Text("Accueil")),

      CommunityChatPage(
        userId: widget.userId,
        username: widget.username,
        profile: widget.profile,
      ),

      PrivateUsersPage(myId: widget.userId),

      ProfilePage(userId: widget.userId),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        indicatorColor: Colors.teal.shade100,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Accueil"),
          NavigationDestination(icon: Icon(Icons.group), label: "Communauté"),
          NavigationDestination(icon: Icon(Icons.chat), label: "Privé"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
