import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

import '../utils/location_mapper.dart';
import 'community_chat.dart';
import 'private_users.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final String username;
  final String profile;
  final VoidCallback onToggleTheme;

  const HomePage({
    required this.userId,
    required this.username,
    required this.profile,
    required this.onToggleTheme,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  // Verset
  String verse = "Chargement...";
  String surahName = "";
  int surahNumber = 0;
  int ayahNumber = 0;

  // Audio
  final AudioPlayer player = AudioPlayer();
  bool isPlaying = false;

  // Prières
  Map<String, dynamic>? prayerTimes;
  String nextPrayer = "";
  Duration countdown = Duration.zero;

  // Météo
  Map<String, dynamic>? weather;

  // Localisation user
  String country = "";
  String region = "";
  String selectedCity = "Brussels";

  int currentAyah = 1;

  @override
  void initState() {
    super.initState();
    loadUserLocation();

    // Arrêt automatique
    player.onPlayerComplete.listen((_) {
      setState(() => isPlaying = false);
    });
  }

  // ============================================================
  //   LOCALISATION
  // ============================================================
  Future<void> loadUserLocation() async {
    final res = await http.get(Uri.parse(
        "https://exciting-learning-production-d784.up.railway.app/profile/${widget.userId}"));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        country = data["country"];
        region = data["region"];
        selectedCity = resolveCity(country, region);
      });

      fetchVerse();
      fetchPrayerTimes();
      fetchWeather();
    }
  }

  // ============================================================
  //   VERSET + AUDIO
  // ============================================================

  Future<void> fetchVerse() async {
    try {
      final res =
      await http.get(Uri.parse("https://api.alquran.cloud/v1/ayah/$currentAyah"));

      if (res.statusCode == 200) {
        final d = jsonDecode(res.body)["data"];

        setState(() {
          verse = d["text"];
          surahName = d["surah"]["englishName"];
          surahNumber = d["surah"]["number"];
          ayahNumber = d["numberInSurah"];
        });
      }
    } catch (_) {
      verse = "Erreur lors du chargement.";
    }
  }

  // AUDIO EVERY AYAH (100% Web + Android)
  Future<void> playAudio() async {
    final url =
        "https://cdn.islamic.network/quran/audio/128/ar.alafasy/$currentAyah.mp3";

    try {
      // Vérifie si l'audio existe
      final check = await http.get(Uri.parse(url));

      if (check.statusCode != 200) {
        print("AUDIO NOT FOUND for ayah $currentAyah");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Audio indisponible pour ce verset")),
        );
        return;
      }

      await player.stop();
      await player.play(UrlSource(url));

      setState(() => isPlaying = true);

    } catch (e) {
      print("AUDIO ERROR => $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur audio")),
      );
    }
  }


  Future<void> pauseAudio() async {
    await player.pause();
    setState(() => isPlaying = false);
  }

  void nextVerse() {
    currentAyah++;
    player.stop();
    isPlaying = false;
    fetchVerse();
    setState(() {});
  }

  // ============================================================
  //   PRIÈRES
  // ============================================================
  Future<void> fetchPrayerTimes() async {
    try {
      final res = await http.get(Uri.parse(
          "https://api.aladhan.com/v1/timingsByCity?city=$selectedCity&country=$country&method=2"));

      if (res.statusCode == 200) {
        prayerTimes = jsonDecode(res.body)["data"]["timings"];
        computeNextPrayer();
        setState(() {});
      }
    } catch (_) {}
  }

  void computeNextPrayer() {
    if (prayerTimes == null) return;

    final now = DateTime.now();
    final list = {
      "Fajr": prayerTimes!["Fajr"],
      "Dhuhr": prayerTimes!["Dhuhr"],
      "Asr": prayerTimes!["Asr"],
      "Maghrib": prayerTimes!["Maghrib"],
      "Isha": prayerTimes!["Isha"],
    };

    for (var e in list.entries) {
      final t = e.value.split(":");
      final prayerTime =
      DateTime(now.year, now.month, now.day, int.parse(t[0]), int.parse(t[1]));

      if (prayerTime.isAfter(now)) {
        nextPrayer = e.key;
        countdown = prayerTime.difference(now);
        return;
      }
    }

    nextPrayer = "Fajr (demain)";
  }

  // ============================================================
  //   METEO
  // ============================================================
  Future<void> fetchWeather() async {
    try {
      final geo =
      await http.get(Uri.parse("https://geocoding-api.open-meteo.com/v1/search?name=$selectedCity"));

      final g = jsonDecode(geo.body);
      if (g["results"] == null) return;

      final lat = g["results"][0]["latitude"];
      final lon = g["results"][0]["longitude"];

      final w = await http.get(Uri.parse(
          "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true"));

      weather = jsonDecode(w.body)["current_weather"];
      setState(() {});
    } catch (_) {}
  }

  // ============================================================
  //   UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      buildHome(isDark),
      CommunityChatPage(
        userId: widget.userId,
        username: widget.username,
        profile: widget.profile,
      ),
      PrivateUsersPage(myId: widget.userId),
      ProfilePage(userId: widget.userId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("IslamicApp"),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          )
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Accueil"),
          NavigationDestination(icon: Icon(Icons.group), label: "Communauté"),
          NavigationDestination(icon: Icon(Icons.chat), label: "Privé"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  Widget buildHome(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          "Bienvenue, ${widget.username} 👋",
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        buildVerseCard(isDark),
        const SizedBox(height: 20),
        buildPrayerCard(isDark),
        const SizedBox(height: 20),
        buildWeatherCard(isDark),
      ],
    );
  }

  // ====================== VERSET =======================
  Widget buildVerseCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.shade700 : Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📖 Verset du jour",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(verse, style: const TextStyle(fontSize: 17, height: 1.5)),
          const SizedBox(height: 8),
          Text(
            "Sourate $surahNumber — $surahName, Verset $ayahNumber",
            style: TextStyle(color: Colors.teal.shade200),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isPlaying ? pauseAudio : playAudio,
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(isPlaying ? "Pause" : "Écouter"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: nextVerse,
                child: const Text("Verset suivant"),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ====================== PRIÈRES =======================
  Widget buildPrayerCard(bool isDark) {
    if (prayerTimes == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.green.shade700 : Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text("Chargement des horaires..."),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.orange.shade700 : Colors.orange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🕌 Horaires de prière",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
              .map((p) => rowPrayer(p, prayerTimes![p])),
          const SizedBox(height: 15),
          Text("Prochaine prière : $nextPrayer",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("Dans ${countdown.inHours}h ${countdown.inMinutes % 60}m"),
        ],
      ),
    );
  }

  Widget rowPrayer(String name, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ====================== MÉTÉO =======================
  Widget buildWeatherCard(bool isDark) {
    if (weather == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.blue.shade800 : Colors.blue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text("Chargement météo..."),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.purple.shade700 : Colors.purple,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "🌤 Météo à $selectedCity\n"
            "Température : ${weather!["temperature"]}°C\n"
            "Vent : ${weather!["windspeed"]} km/h",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
