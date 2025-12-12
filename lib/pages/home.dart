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

  // Audio player
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

    // stop automatically at end of audio
    player.onPlayerComplete.listen((_) {
      setState(() => isPlaying = false);
    });
  }

  // ============================================================
  // Charger la localisation depuis ton backend
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
  // API Verset du jour + Audio
  // ============================================================

  Future<void> fetchVerse() async {
    try {
      final res = await http.get(
          Uri.parse("https://api.alquran.cloud/v1/ayah/$currentAyah"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)["data"];

        setState(() {
          verse = data["text"];
          surahName = data["surah"]["englishName"];
          surahNumber = data["surah"]["number"];
          ayahNumber = data["numberInSurah"];
        });
      }
    } catch (e) {
      setState(() => verse = "Erreur lors du chargement.");
    }
  }

  // 🎧 NOUVEL AUDIO 100% COMPATIBLE WEB & ANDROID
  Future<void> playAudio() async {
    final url =
        "https://everyayah.com/data/Alafasy_128kbps/$currentAyah.mp3";

    try {
      await player.stop();
      await player.play(UrlSource(url));
      setState(() => isPlaying = true);
    } catch (e) {
      print("AUDIO ERROR: $e");
    }
  }

  Future<void> pauseAudio() async {
    await player.pause();
    setState(() => isPlaying = false);
  }

  void nextVerse() {
    currentAyah++;
    player.stop();
    setState(() => isPlaying = false);
    fetchVerse();
  }

  // ============================================================
  // Prières
  // ============================================================
  Future<void> fetchPrayerTimes() async {
    final url =
        "https://api.aladhan.com/v1/timingsByCity?city=$selectedCity&country=$country&method=2";

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final timings = jsonDecode(res.body)["data"]["timings"];
        setState(() => prayerTimes = timings);
        computeNextPrayer();
      }
    } catch (_) {}
  }

  void computeNextPrayer() {
    if (prayerTimes == null) return;

    final now = DateTime.now();
    final map = {
      "Fajr": prayerTimes!["Fajr"],
      "Dhuhr": prayerTimes!["Dhuhr"],
      "Asr": prayerTimes!["Asr"],
      "Maghrib": prayerTimes!["Maghrib"],
      "Isha": prayerTimes!["Isha"],
    };

    for (var entry in map.entries) {
      final t = entry.value.split(":");
      final time = DateTime(
          now.year, now.month, now.day, int.parse(t[0]), int.parse(t[1]));

      if (time.isAfter(now)) {
        setState(() {
          nextPrayer = entry.key;
          countdown = time.difference(now);
        });
        return;
      }
    }

    nextPrayer = "Fajr (demain)";
  }

  // ============================================================
  // Météo
  // ============================================================
  Future<void> fetchWeather() async {
    try {
      final geo = await http.get(Uri.parse(
          "https://geocoding-api.open-meteo.com/v1/search?name=$selectedCity"));

      if (geo.statusCode != 200) return;

      final g = jsonDecode(geo.body);
      if (g["results"] == null || g["results"].isEmpty) return;

      final lat = g["results"][0]["latitude"];
      final lon = g["results"][0]["longitude"];

      final res = await http.get(Uri.parse(
          "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true"));

      if (res.statusCode == 200) {
        weather = jsonDecode(res.body)["current_weather"];
        setState(() {});
      }
    } catch (_) {}
  }

  // ============================================================
  // UI HOME
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final pages = [
      buildHome(),
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
        title: Text("IslamicApp"),
        actions: [
          IconButton(
            icon: Icon(Icons.dark_mode),
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

  Widget buildHome() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text(
          "Bienvenue, ${widget.username} 👋",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),

        SizedBox(height: 20),

        buildVerseCard(),

        SizedBox(height: 20),

        buildPrayerCard(),

        SizedBox(height: 20),

        buildWeatherCard(),
      ],
    );
  }

  // ====================== VERSET + AUDIO =======================
  Widget buildVerseCard() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📖 Verset du jour",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

          SizedBox(height: 10),

          Text(verse, style: TextStyle(fontSize: 17, height: 1.5)),

          SizedBox(height: 8),

          Text("Sourate $surahNumber — $surahName, Verset $ayahNumber",
              style: TextStyle(color: Colors.teal.shade700)),

          SizedBox(height: 15),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isPlaying ? pauseAudio : playAudio,
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(isPlaying ? "Pause" : "Écouter"),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: nextVerse,
                child: Text("Verset suivant"),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ====================== PRIÈRES =======================
  Widget buildPrayerCard() {
    if (prayerTimes == null) {
      return Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text("Chargement des horaires..."),
      );
    }

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("🕌 Horaires de prière",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

          SizedBox(height: 10),

          ...["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
              .map((p) => rowPrayer(p, prayerTimes![p])),

          SizedBox(height: 15),

          Text("Prochaine prière : $nextPrayer",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text("Dans ${countdown.inHours}h ${countdown.inMinutes % 60}m"),
        ],
      ),
    );
  }

  Widget rowPrayer(String name, String time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text(time, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ====================== MÉTÉO =======================
  Widget buildWeatherCard() {
    if (weather == null) {
      return Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text("Chargement météo..."),
      );
    }

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "🌤 Météo à $selectedCity\n"
            "Température : ${weather!["temperature"]}°C\n"
            "Vent : ${weather!["windspeed"]} km/h",
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
