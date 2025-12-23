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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Faire un don ❤️"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "Soutenir des causes humanitaires",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            "Les dons sont effectués directement sur les sites officiels des associations.",
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
          const SizedBox(height: 25),

          donationCard(
            context,
            title: "UNRWA – Palestine",
            subtitle: "Aide aux réfugiés palestiniens",
            image:
            "https://www.unrwa.org/sites/default/files/styles/hero/public/content/resources/photos/gaza_children.jpg",
            url: "https://donate.unrwa.org",
          ),

          donationCard(
            context,
            title: "UNICEF – Urgences enfants",
            subtitle: "Protection et soins pour les enfants",
            image:
            "https://www.unicef.org/sites/default/files/styles/hero_tablet/public/UNICEF-child-refugee.jpg",
            url: "https://www.unicef.org/donate",
          ),

          donationCard(
            context,
            title: "Médecins Sans Frontières – Gaza",
            subtitle: "Soins médicaux en zones de guerre",
            image:
            "https://www.msf.org/sites/default/files/styles/full_width/public/2023-10/gaza-msf.jpg",
            url: "https://donate.msf.org",
          ),

          donationCard(
            context,
            title: "Islamic Relief – Palestine",
            subtitle: "Aide humanitaire et alimentaire",
            image:
            "https://www.islamic-relief.org/wp-content/uploads/2021/05/Palestine-appeal.jpg",
            url: "https://www.islamic-relief.org/emergencies/palestine/",
          ),

          donationCard(
            context,
            title: "Islamic Relief – Soudan",
            subtitle: "Urgence humanitaire – famine & conflits",
            image:
            "https://www.islamic-relief.org/wp-content/uploads/2023/05/sudan-crisis.jpg",
            url: "https://www.islamic-relief.org/emergencies/sudan/",
          ),

          donationCard(
            context,
            title: "UNICEF – RDC",
            subtitle: "Enfants victimes de conflits armés",
            image:
            "https://www.unicef.org/sites/default/files/styles/hero/public/DRC-children.jpg",
            url: "https://www.unicef.org/drc",
          ),

          donationCard(
            context,
            title: "Médecins Sans Frontières – RDC",
            subtitle: "Soins d’urgence et épidémies",
            image:
            "https://www.msf.org/sites/default/files/styles/full_width/public/2022-07/drc-msf.jpg",
            url: "https://donate.msf.org",
          ),
        ],
      ),
    );
  }

  Widget donationCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required String image,
        required String url,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openLink(url),
        hoverColor: Colors.teal.withOpacity(0.05),
        child: Card(
          elevation: 6,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  image,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                        isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => openLink(url),
                        icon: const Icon(Icons.favorite),
                        label: const Text("Faire un don"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
