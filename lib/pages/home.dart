import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  // Verset
  String verse = "Chargement...";
  String surahName = "";
  int surahNumber = 0;
  int ayahNumber = 0;
  int currentAyah = Random().nextInt(6236) + 1;

  // Audio
  final AudioPlayer player = AudioPlayer();
  bool isPlaying = false;

  // Prières
  Map<String, dynamic>? prayerTimes;
  String nextPrayer = "";
  Duration countdown = Duration.zero;

  // Météo
  Map<String, dynamic>? weather;

  // Localisation
  String country = "Belgium";
  String region = "Brussels";
  String selectedCity = "Brussels";

  final String baseUrl =
      "https://exciting-learning-production-d784.up.railway.app";

  @override
  void initState() {
    super.initState();
    loadUserLocation();

    player.onPlayerComplete.listen((_) {
      setState(() => isPlaying = false);
    });
  }

  // =================== LOCALISATION ===================
  Future<void> loadUserLocation() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/profile/${widget.userId}"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        country = data["country"] ?? "Belgium";
        region = data["region"] ?? "Brussels";
        selectedCity = resolveCity(country, region);
      }
    } catch (e) {
      debugPrint("PROFILE ERROR => $e");
    }

    fetchRandomVerse();
    fetchPrayerTimes();
    fetchWeather();

    setState(() {});
  }

  // =================== VERSET ===================
  Future<void> fetchRandomVerse() async {
    currentAyah = Random().nextInt(6236) + 1;
    try {
      final res = await http.get(
        Uri.parse("https://api.alquran.cloud/v1/ayah/$currentAyah"),
      );

      if (res.statusCode == 200) {
        final d = jsonDecode(res.body)["data"];
        setState(() {
          verse = d["text"];
          surahName = d["surah"]["englishName"];
          surahNumber = d["surah"]["number"];
          ayahNumber = d["numberInSurah"];
        });
      }
    } catch (e) {
      verse = "Erreur de chargement du verset";
    }
  }

  Future<void> playAudio() async {
    final url =
        "https://cdn.islamic.network/quran/audio/128/ar.alafasy/$currentAyah.mp3";

    try {
      await player.stop();
      await player.play(UrlSource(url));
      setState(() => isPlaying = true);
    } catch (e) {
      debugPrint("AUDIO ERROR => $e");
    }
  }

  Future<void> pauseAudio() async {
    await player.pause();
    setState(() => isPlaying = false);
  }

  void nextVerse() {
    player.stop();
    isPlaying = false;
    fetchRandomVerse();
  }

  // =================== PRIÈRES ===================
  Future<void> fetchPrayerTimes() async {
    try {
      final res = await http.get(Uri.parse(
          "https://api.aladhan.com/v1/timingsByCity?city=$selectedCity&country=$country&method=2"));

      if (res.statusCode == 200) {
        prayerTimes = jsonDecode(res.body)["data"]["timings"];
        computeNextPrayer();
      }
    } catch (e) {
      debugPrint("PRAYER ERROR => $e");
    }
    setState(() {});
  }

  void computeNextPrayer() {
    if (prayerTimes == null) return;

    final now = DateTime.now();
    for (var p in ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]) {
      final t = prayerTimes![p].split(":");
      final time = DateTime(
          now.year, now.month, now.day, int.parse(t[0]), int.parse(t[1]));
      if (time.isAfter(now)) {
        nextPrayer = p;
        countdown = time.difference(now);
        return;
      }
    }
    nextPrayer = "Fajr (demain)";
  }

  // =================== METEO ===================
  Future<void> fetchWeather() async {
    try {
      final geo = await http.get(Uri.parse(
          "https://geocoding-api.open-meteo.com/v1/search?name=$selectedCity"));

      final g = jsonDecode(geo.body);
      if (g["results"] == null) return;

      final lat = g["results"][0]["latitude"];
      final lon = g["results"][0]["longitude"];

      final w = await http.get(Uri.parse(
          "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true"));

      weather = jsonDecode(w.body)["current_weather"];
    } catch (e) {
      debugPrint("WEATHER ERROR => $e");
    }
    setState(() {});
  }

  // =================== UI ===================
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

  Widget buildHome() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("Bienvenue, ${widget.username} 👋",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        buildVerseCard(),
        const SizedBox(height: 20),
        buildPrayerCard(),
        const SizedBox(height: 20),
        buildWeatherCard(),
      ],
    );
  }

  Widget buildVerseCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📖 Verset du jour",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(verse),
          Text("Sourate $surahNumber — $surahName ($ayahNumber)"),
          Row(
            children: [
              ElevatedButton(
                  onPressed: isPlaying ? pauseAudio : playAudio,
                  child: Text(isPlaying ? "Pause" : "Écouter")),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: nextVerse,
                  child: const Text("Autre verset")),
            ],
          )
        ],
      ),
    ),
  );

  Widget buildPrayerCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: prayerTimes == null
          ? const Text("Chargement des prières...")
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🕌 Horaires de prière"),
          ...["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
              .map((p) => Text("$p : ${prayerTimes![p]}")),
          Text("Prochaine : $nextPrayer"),
        ],
      ),
    ),
  );

  Widget buildWeatherCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: weather == null
          ? const Text("Chargement météo...")
          : Text(
          "🌤 $selectedCity\nTempérature : ${weather!["temperature"]}°C\nVent : ${weather!["windspeed"]} km/h"),
    ),
  );
}
