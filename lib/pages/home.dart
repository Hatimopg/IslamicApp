import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:hijri/hijri_calendar.dart';

import '../theme/lci_theme.dart';
import '../utils/location_mapper.dart';
import '../utils/city_storage.dart';
import '../utils/token_storage.dart';
import '../utils/notification_service.dart';

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
  int calendarPage = 0;
  int versePage = 0;

  /* ===================== LES DOTS PR LE SWIPE ===================== */

  Widget buildDots(int count, int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
            (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == index ? 14 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == index ? lciGreen : lciGreenLight,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }


  /* ===================== VERSET ===================== */
  final AudioPlayer player = AudioPlayer();
  bool isPlaying = false;

  String verse = "Chargement...";
  String surahName = "";
  int surahNumber = 0;
  int ayahNumber = 0;
  int currentAyah = Random().nextInt(6236) + 1;

  /* ===================== HADITH ===================== */
  String hadith = "Chargement...";
  String hadithSource = "";

  /* ===================== PRIÈRES ===================== */
  Map<String, dynamic>? prayerTimes;
  String nextPrayer = "";

  /* ===================== MÉTÉO ===================== */
  Map<String, dynamic>? weather;

  /* ===================== LOCALISATION ===================== */
  String country = "Belgium";
  String selectedCity = "Brussels";

  final String baseUrl =
      "https://exciting-learning-production-d784.up.railway.app";

  @override
  void initState() {
    super.initState();
    loadUserLocation();
    fetchRandomVerse();
    fetchHadith();

    player.onPlayerComplete.listen((_) {
      setState(() => isPlaying = false);
    });
  }

  /* ===================== LOCALISATION ===================== */
  Future<void> loadUserLocation() async {
    final savedCity = await CityStorage.get();
    if (savedCity != null) {
      setState(() => selectedCity = savedCity);
    } else {
      try {
        final token = await TokenStorage.getToken();
        if (token == null) throw Exception();

        final res = await http.get(
          Uri.parse("$baseUrl/profile/${widget.userId}"),
          headers: {"Authorization": "Bearer $token"},
        );

        if (res.statusCode == 200) {
          final d = jsonDecode(res.body);
          final city = resolveCity(d["country"] ?? "", d["region"] ?? "");
          setState(() => selectedCity = city);
          await CityStorage.save(city);
        }
      } catch (_) {
        setState(() => selectedCity = "Ronse");
      }
    }

    fetchPrayerTimes();
    fetchWeather();
  }

  /* ===================== CITY PICKER ===================== */
  void showCityPicker() {
    const cities = [
      "Ronse",
      "Brussels",
      "Antwerp",
      "Ghent",
      "Liège",
      "Mons",
      "Bruges"
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: cities
            .map((c) => ListTile(
          title: Text(c),
          trailing:
          c == selectedCity ? const Icon(Icons.check) : null,
          onTap: () async {
            Navigator.pop(context);
            setState(() => selectedCity = c);
            await CityStorage.save(c);
            fetchPrayerTimes();
            fetchWeather();
          },
        ))
            .toList(),
      ),
    );
  }

  /* ===================== VERSET ===================== */
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
      setState(() => verse = "Erreur de chargement");
    }
  }

  Future<void> playAudio() async {
    final url =
        "https://cdn.islamic.network/quran/audio/128/ar.alafasy/$currentAyah.mp3";
    await player.stop();
    await player.play(UrlSource(url));
    setState(() => isPlaying = true);
  }

  /* ===================== HADITH ===================== */
  Future<void> fetchHadith() async {
    try {
      final res = await http.get(
        Uri.parse("https://api.hadith.sutanlab.id/books/muslim?range=1-1"),
      );

      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() {
          hadith = d["data"]["hadiths"][0]["arab"] ??
              "Hadith indisponible";
          hadithSource = "Sahih Muslim";
        });
      } else {
        setState(() => hadith = "Hadith indisponible");
      }
    } catch (_) {
      setState(() => hadith = "Erreur de chargement du hadith");
    }
  }


  /* ===================== PRIÈRES ===================== */
  Future<void> fetchPrayerTimes() async {
    try {
      final res = await http.get(Uri.parse(
          "https://api.aladhan.com/v1/timingsByCity?city=$selectedCity&country=$country&method=2"));

      if (res.statusCode == 200) {
        prayerTimes = jsonDecode(res.body)["data"]["timings"];
        computeNextPrayer();
        scheduleAdhanNotifications();
        setState(() {});
      }
    } catch (_) {}
  }

  void computeNextPrayer() {
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
        nextPrayer = p;
        return;
      }
    }
    nextPrayer = "Fajr (demain)";
  }

  void scheduleAdhanNotifications() {
    if (prayerTimes == null) return;
    int id = 0;
    final now = DateTime.now();

    for (final p in ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]) {
      final t = prayerTimes![p].split(":");
      DateTime time = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(t[0]),
        int.parse(t[1]),
      );
      if (time.isBefore(now)) time = time.add(const Duration(days: 1));

      NotificationService.schedule(
        id: id++,
        title: "🕌 Appel à la prière",
        body: "C'est l'heure de $p",
        time: time,
      );
    }
  }

  /* ===================== MÉTÉO ===================== */
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

  /* ===================== UI ===================== */
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
      IslamicQuizPage(),
      const QiblaCompassPage(),
      DonationPage(),
      ProfilePage(userId: widget.userId),
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

  /* ===================== HOME ===================== */
  Widget buildHome() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        "Bienvenue, ${widget.username} 👋",
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 20),
      buildHijriCalendar(),
      const SizedBox(height: 24),
      buildSwipeVerseHadith(),
      const SizedBox(height: 20),
      buildPrayerCard(),
      const SizedBox(height: 20),
      buildWeatherCard(),
    ],
  );

  /* ===================== CALENDRIER ===================== */

  Widget buildHijriCalendar() {
    final h = HijriCalendar.now();

    final events = [
      {"title": "🌙 Ramadan", "date": "17 février 2026"},
      {"title": "🕌 Laylat al-Qadr", "date": "8 avril 2026"},
      {"title": "🐑 Aïd al-Fitr", "date": "19 mars 2026"},
      {"title": "🐪 Aïd al-Adha", "date": "27 mai 2026"},
    ];

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView(
            onPageChanged: (i) => setState(() => calendarPage = i),
            children: [
              // PAGE 1 — DATE
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [lciGreen, lciGreenDark],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "📅 Aujourd’hui (Hijri)",
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "${h.hDay} ${h.longMonthName}",
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      "${h.hYear} AH",
                      style: const TextStyle(
                          fontSize: 18, color: Colors.white70),
                    ),
                    const Spacer(),
                    Text(
                      "📆 ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),

              // PAGE 2 — ÉVÉNEMENTS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "✨ Dates importantes 2026",
                        style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      ...events.map(
                            (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.event, size: 18, color: lciGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${e["title"]} — ${e["date"]}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        buildDots(2, calendarPage),
      ],
    );
  }


  /* ===================== SWIPE ===================== */
  Widget buildSwipeVerseHadith() => Column(
    children: [
      SizedBox(
        height: 260,
        child: PageView(
          onPageChanged: (i) => setState(() => versePage = i),
          children: [
            buildVerseCard(),
            buildHadithCard(),
          ],
        ),
      ),
      const SizedBox(height: 10),
      buildDots(2, versePage),
    ],
  );


  Widget buildVerseCard() => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 👇 ICI (tout en haut)
          Row(
            children: const [
              Icon(Icons.swipe, size: 16, color: lciGreen),
              SizedBox(width: 6),
              Text(
                "Glisse pour changer",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            "📖 Verset du jour",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),
          Expanded(child: Text(verse)),
          Text("Sourate $surahNumber — $surahName ($ayahNumber)"),
          Row(
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: isPlaying ? player.pause : playAudio,
              ),
              TextButton(
                onPressed: fetchRandomVerse,
                child: const Text("Autre verset"),
              )
            ],
          )
        ],
      ),
    ),
  );


  Widget buildHadithCard() => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 👇 ICI AUSSI
          Row(
            children: const [
              Icon(Icons.swipe, size: 16, color: lciGreen),
              SizedBox(width: 6),
              Text(
                "Glisse pour changer",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            "🕌 Hadith du jour",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),
          Expanded(child: Text(hadith)),
          Text(hadithSource, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );


  /* ===================== PRIÈRES ===================== */
  Widget buildPrayerCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: prayerTimes == null
          ? const Text("Horaires indisponibles")
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🕌 Horaires de prière",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
              .map((p) => Text("$p : ${prayerTimes![p]}")),
          const SizedBox(height: 8),
          Text("⏭ Prochaine : $nextPrayer"),
        ],
      ),
    ),
  );

  /* ===================== MÉTÉO ===================== */
  Widget buildWeatherCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: weather == null
          ? const Text("Météo indisponible")
          : Text(
        "🌤 $selectedCity\nTempérature : ${weather!["temperature"]}°C\nVent : ${weather!["windspeed"]} km/h",
      ),
    ),
  );
}
