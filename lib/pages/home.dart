import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

import '../utils/location_mapper.dart';
import '../utils/city_storage.dart';
import '../utils/token_storage.dart';
import '../utils/notification_service.dart';
import '../theme/lci_theme.dart';

import 'community_chat.dart';
import 'private_users.dart';
import 'profile.dart';
import 'qibla_compass.dart';
import 'donation.dart';
import 'islamic_quiz_page.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final String username;
  final String profile;
  final VoidCallback onToggleTheme;

  const HomePage({
    super.key,
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

  // ---------------- VERSET ----------------
  String verse = "Chargement...";
  String surahName = "";
  int surahNumber = 0;
  int ayahNumber = 0;
  int currentAyah = Random().nextInt(6236) + 1;

  final AudioPlayer player = AudioPlayer();
  bool isPlaying = false;

  // ---------------- PRIÈRES ----------------
  Map<String, dynamic>? prayerTimes;
  String nextPrayer = "";
  Duration countdown = Duration.zero;

  // ---------------- MÉTÉO ----------------
  Map<String, dynamic>? weather;

  // ---------------- LOCALISATION ----------------
  String country = "Belgium"; // API AlAdhan → anglais
  String region = "";
  String selectedCity = "Brussels";

  final String baseUrl =
      "https://exciting-learning-production-d784.up.railway.app";

  @override
  void initState() {
    super.initState();
    loadUserLocation();
    fetchRandomVerse();

    player.onPlayerComplete.listen((_) {
      setState(() => isPlaying = false);
    });
  }

  // ================= LOCALISATION =================
  Future<void> loadUserLocation() async {
    // 1️⃣ ville déjà choisie
    final savedCity = await CityStorage.get();
    if (savedCity != null) {
      setState(() => selectedCity = savedCity);
      fetchPrayerTimes();
      fetchWeather();
      return;
    }

    // 2️⃣ sinon via profil
    try {
      final token = await TokenStorage.getToken();

      if (token == null) throw Exception("NO TOKEN");

      final res = await http.get(
        Uri.parse("$baseUrl/profile/${widget.userId}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final c = data["country"]?.toString() ?? "";
        final r = data["region"]?.toString() ?? "";

        final city = resolveCity(c, r);

        setState(() => selectedCity = city);
        await CityStorage.save(city);
      }
    } catch (_) {
      setState(() => selectedCity = "Ronse");
    }

    fetchPrayerTimes();
    fetchWeather();
  }

  // ================= CITY PICKER =================
  void showCityPicker() {
    const belgianCities = [
      "Ronse",
      "Brussels",
      "Antwerp",
      "Ghent",
      "Charleroi",
      "Liège",
      "Mons",
      "Tournai",
      "Arlon",
      "Bruges",
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: belgianCities.map((city) {
          return ListTile(
            title: Text(city),
            trailing: city == selectedCity
                ? const Icon(Icons.check, color: Colors.teal)
                : null,
            onTap: () async {
              Navigator.pop(context);
              setState(() => selectedCity = city);
              await CityStorage.save(city);
              fetchPrayerTimes();
              fetchWeather();
            },
          );
        }).toList(),
      ),
    );
  }


  // ================= VERSET =================
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
    } catch (_) {
      setState(() => verse = "Erreur de chargement du verset");
    }
  }

  Future<void> playAudio() async {
    final url =
        "https://cdn.islamic.network/quran/audio/128/ar.alafasy/$currentAyah.mp3";
    try {
      await player.stop();
      await player.play(UrlSource(url));
      setState(() => isPlaying = true);
    } catch (_) {}
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

  // ================= PRIÈRES =================
  Future<void> fetchPrayerTimes() async {
    try {
      final res = await http.get(Uri.parse(
          "https://api.aladhan.com/v1/timingsByCity?city=$selectedCity&country=$country&method=2"));

      if (res.statusCode == 200) {
        setState(() {
          prayerTimes = jsonDecode(res.body)["data"]["timings"];
        });
        computeNextPrayer();

        scheduleAdhanNotifications();
      }
      else {
        setState(() => prayerTimes = {});
      }
    } catch (_) {
      setState(() => prayerTimes = {});
    }
  }

  void computeNextPrayer() {
    if (prayerTimes == null || prayerTimes!.isEmpty) return;

    final now = DateTime.now();

    for (final p in ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]) {
      final t = prayerTimes![p].split(":");
      final time = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(t[0]),
        int.parse(t[1]),
      );

      if (time.isAfter(now)) {
        setState(() => nextPrayer = p);
        return;
      }
    }

    setState(() => nextPrayer = "Fajr (demain)");
  }


  void scheduleAdhanNotifications() {
    if (prayerTimes == null || prayerTimes!.isEmpty) return;

    final now = DateTime.now();
    int id = 0;

    for (final p in ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]) {
      final t = prayerTimes![p].split(":");

      DateTime time = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(t[0]),
        int.parse(t[1]),
      );

      // Si l'heure est déjà passée → demain
      if (time.isBefore(now)) {
        time = time.add(const Duration(days: 1));
      }

      NotificationService.schedule(
        id: id++,
        title: "🕌 Appel à la prière",
        body: "C'est l'heure de $p",
        time: time,
      );
    }
  }

  // ================= MÉTÉO =================
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

      setState(() {
        weather = jsonDecode(w.body)["current_weather"];
      });
    } catch (_) {}
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final pages = [
      buildHome(), // 0 Accueil
      CommunityChatPage(
        userId: widget.userId,
        username: widget.username,
        profile: widget.profile,
      ),            // 1 Communauté
      PrivateUsersPage(myId: widget.userId), // 2 Privé
      IslamicQuizPage(),  // 3 Jeu
      const QiblaCompassPage(), // 4 Qibla
      DonationPage(), // 5 Dons
      ProfilePage(userId: widget.userId), // 6 Profil
    ];



    return Scaffold(
      appBar: AppBar(
        title: const Text("LCI Ronse"),
        backgroundColor: lciGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_city),
            onPressed: showCityPicker,
          ),
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        indicatorColor: lciGreenLight,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Accueil"),
          NavigationDestination(icon: Icon(Icons.group), label: "Publique"),
          NavigationDestination(icon: Icon(Icons.chat), label: "Privé"),
          NavigationDestination(icon: Icon(Icons.games), label: "Jeu"),
          NavigationDestination(icon: Icon(Icons.explore), label: "Qibla"),
          NavigationDestination(icon: Icon(Icons.favorite), label: "Dons"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  Widget buildHome() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        "Bienvenue, ${widget.username} 👋",
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 20),
      buildVerseCard(),
      const SizedBox(height: 20),
      buildPrayerCard(),
      const SizedBox(height: 20),
      buildWeatherCard(),
    ],
  );

  Widget buildVerseCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📖 Verset du jour",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(verse),
          const SizedBox(height: 6),
          Text("Sourate $surahNumber — $surahName ($ayahNumber)"),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: isPlaying ? pauseAudio : playAudio,
                child: Text(isPlaying ? "Pause" : "Écouter"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: nextVerse,
                child: const Text("Autre verset"),
              ),
            ],
          )
        ],
      ),
    ),
  );

  Widget buildPrayerCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: prayerTimes == null || prayerTimes!.isEmpty
          ? const Text("Horaires indisponibles")
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🕌 Horaires de prière"),
          ...["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
              .map((p) => Text("$p : ${prayerTimes![p]}")),
          const SizedBox(height: 8),
          Text("Prochaine : $nextPrayer"),
        ],
      ),
    ),
  );

  Widget buildWeatherCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: weather == null
          ? const Text("Météo indisponible")
          : Text(
        "🌤 $selectedCity\nTempérature : ${weather!["temperature"]}°C\nVent : ${weather!["windspeed"]} km/h",
      ),
    ),
  );
}
