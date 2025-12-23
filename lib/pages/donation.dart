import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

  Future<void> openLink(String url) async {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Faire un don ❤️"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          section("PALESTINE", urgent: true),
          donationTile(
            title: "UNRWA",
            subtitle: "Aide aux réfugiés palestiniens",
            url: "https://donate.unrwa.org",
            urgent: true,
          ),
          donationTile(
            title: "Islamic Relief – Palestine",
            subtitle: "Aide humanitaire et alimentaire",
            url:
            "https://www.islamic-relief.org/emergencies/palestine/",
            urgent: true,
          ),

          section("SOUDAN", urgent: true),
          donationTile(
            title: "Islamic Relief – Soudan",
            subtitle: "Crise humanitaire et famine",
            url:
            "https://www.islamic-relief.org/emergencies/sudan/",
            urgent: true,
          ),
          donationTile(
            title: "UNICEF – Soudan",
            subtitle: "Protection des enfants déplacés",
            url: "https://www.unicef.org/emergencies/sudan",
            urgent: true,
          ),

          section("RDC"),
          donationTile(
            title: "UNICEF – RDC",
            subtitle: "Enfants victimes de conflits armés",
            url: "https://www.unicef.org/drc",
          ),
          donationTile(
            title: "Médecins Sans Frontières – RDC",
            subtitle: "Soins médicaux et épidémies",
            url: "https://donate.msf.org",
          ),

          section("AUTRES"),
          donationTile(
            title: "Save the Children",
            subtitle: "Protection de l’enfance",
            url: "https://www.savethechildren.org",
          ),
          donationTile(
            title: "Action Against Hunger",
            subtitle: "Lutte contre la famine",
            url: "https://www.actionagainsthunger.org",
          ),
        ],
      ),
    );
  }

  Widget section(String title, {bool urgent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (urgent)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Chip(
                label: Text("URGENCE",
                    style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.red,
              ),
            )
        ],
      ),
    );
  }

  Widget donationTile({
    required String title,
    required String subtitle,
    required String url,
    bool urgent = false,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          urgent ? Colors.red.shade100 : Colors.deepPurple.shade100,
          child: Icon(
            Icons.favorite,
            color: urgent ? Colors.red : Colors.deepPurple,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: () => openLink(url),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text("Faire un don"),
        ),
      ),
    );
  }
}
