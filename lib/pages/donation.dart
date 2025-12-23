import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  final List<bool> _visible = [];

  @override
  void initState() {
    super.initState();

    _visible.addAll(List.generate(donations.length, (_) => false));

    Future.delayed(const Duration(milliseconds: 150), () {
      for (int i = 0; i < _visible.length; i++) {
        Future.delayed(Duration(milliseconds: 120 * i), () {
          if (mounted) setState(() => _visible[i] = true);
        });
      }
    });
  }

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
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: donations.length,
        itemBuilder: (context, i) {
          final d = donations[i];

          return AnimatedOpacity(
            opacity: _visible[i] ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: AnimatedSlide(
              offset: _visible[i] ? Offset.zero : const Offset(0, 0.12),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: donationCard(context, d),
            ),
          );
        },
      ),
    );
  }

  Widget donationCard(BuildContext context, Donation d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openLink(d.url),
        child: Card(
          elevation: 6,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                    child: Image.network(
                      d.image,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.image, size: 40),
                        ),
                      ),
                    ),
                  ),
                  if (d.urgent)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "URGENCE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d.subtitle,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => openLink(d.url),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                        ),
                        child: const Text("Faire un don"),
                      ),
                    ),
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

/* ============================================================
   DATA
=============================================================== */

class Donation {
  final String title;
  final String subtitle;
  final String image;
  final String url;
  final bool urgent;

  Donation({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.url,
    this.urgent = false,
  });
}

final List<Donation> donations = [
  // ================= PALESTINE =================
  Donation(
    title: "UNRWA – Palestine",
    subtitle: "Aide aux réfugiés palestiniens",
    urgent: true,
    image:
    "https://images.unsplash.com/photo-1603570417596-96c8c3a0d3d2",
    url: "https://donate.unrwa.org",
  ),
  Donation(
    title: "Islamic Relief – Palestine",
    subtitle: "Aide humanitaire et alimentaire",
    urgent: true,
    image:
    "https://images.unsplash.com/photo-1588072432836-e10032774350",
    url: "https://www.islamic-relief.org/emergencies/palestine/",
  ),
  Donation(
    title: "Médecins Sans Frontières – Gaza",
    subtitle: "Soins médicaux d’urgence",
    urgent: true,
    image:
    "https://images.unsplash.com/photo-1584515933487-779824d29309",
    url: "https://donate.msf.org",
  ),

  // ================= SOUDAN =================
  Donation(
    title: "Islamic Relief – Soudan",
    subtitle: "Crise humanitaire et famine",
    urgent: true,
    image:
    "https://images.unsplash.com/photo-1526256262350-7da7584cf5eb",
    url: "https://www.islamic-relief.org/emergencies/sudan/",
  ),
  Donation(
    title: "UNICEF – Soudan",
    subtitle: "Aide aux enfants déplacés",
    urgent: true,
    image:
    "https://images.unsplash.com/photo-1599058917212-d750089bc07e",
    url: "https://www.unicef.org/emergencies/sudan",
  ),

  // ================= RDC =================
  Donation(
    title: "UNICEF – RDC",
    subtitle: "Protection des enfants en zones de conflit",
    image:
    "https://images.unsplash.com/photo-1603570417596-96c8c3a0d3d2",
    url: "https://www.unicef.org/drc",
  ),
  Donation(
    title: "Médecins Sans Frontières – RDC",
    subtitle: "Soins médicaux et épidémies",
    image:
    "https://images.unsplash.com/photo-1584515933487-779824d29309",
    url: "https://www.msf.org/drc",
  ),

  // ================= AUTRES =================
  Donation(
    title: "Médecins Sans Frontières",
    subtitle: "Urgences médicales mondiales",
    image:
    "https://images.unsplash.com/photo-1509099836639-18ba1795216d",
    url: "https://donate.msf.org",
  ),
  Donation(
    title: "UNICEF – Monde",
    subtitle: "Protection et soins pour les enfants",
    image:
    "https://images.unsplash.com/photo-1542816417-0983c9c9ad53",
    url: "https://www.unicef.org/donate",
  ),
];
