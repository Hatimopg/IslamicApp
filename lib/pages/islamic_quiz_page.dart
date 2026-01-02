import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class IslamicQuizPage extends StatefulWidget {
  const IslamicQuizPage({super.key});

  @override
  State<IslamicQuizPage> createState() => _IslamicQuizPageState();
}

class _IslamicQuizPageState extends State<IslamicQuizPage>
    with SingleTickerProviderStateMixin {

  // ================= MODE =================
  String? selectedMode; // "easy" | "medium" | "hard"

  // ================= AUDIO =================
  final AudioPlayer sfxPlayer = AudioPlayer();
  bool isMuted = false;

  Future<void> playSfx(String file) async {
    if (isMuted || kIsWeb) return;
    await sfxPlayer.stop();
    await sfxPlayer.play(AssetSource("sounds/$file"), volume: 1.0);
  }

  Future<void> loadMute() async {
    final prefs = await SharedPreferences.getInstance();
    isMuted = prefs.getBool("quiz_muted") ?? false;
  }

  Future<void> toggleMute() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isMuted = !isMuted);
    await prefs.setBool("quiz_muted", isMuted);
  }

  // ================= GAME =================
  final Random _random = Random();
  int questionIndex = 0;
  int score = 0;
  int record = 0;

  bool answered = false;
  int? selectedIndex;

  // ================= TIMER =================
  int maxTime = 10;
  int timeLeft = 10;
  Timer? timer;
  late AnimationController timerController;

  late List<Map<String, dynamic>> quiz;
  late Map<String, dynamic> currentQuestion;

  // ================= QUESTIONS =================

  final easyQuestions = [
    {"q": "Combien de prières obligatoires par jour ?", "a": ["3", "4", "5", "6"], "c": 2},
    {"q": "Quelle est la direction de la prière ?", "a": ["Médine", "Jérusalem", "La Kaaba", "Damas"], "c": 2},
    {"q": "Quel est le livre sacré de l’Islam ?", "a": ["Bible", "Torah", "Coran", "Zabour"], "c": 2},
    {"q": "Quel mois est celui du jeûne ?", "a": ["Rajab", "Ramadan", "Muharram", "Safar"], "c": 1},
    {"q": "Combien de piliers de l’Islam ?", "a": ["3", "4", "5", "6"], "c": 2},
    {"q": "Quelle prière est faite à l’aube ?", "a": ["Fajr", "Dhuhr", "Asr", "Isha"], "c": 0},
    {"q": "Quelle prière est faite la nuit ?", "a": ["Asr", "Maghrib", "Isha", "Fajr"], "c": 2},
    {"q": "Combien de rak‘ah dans le Fajr ?", "a": ["2", "3", "4", "5"], "c": 0},
    {"q": "Quelle ville est la plus sacrée ?", "a": ["Médine", "La Mecque", "Jérusalem", "Damas"], "c": 1},
    {"q": "Quel animal est interdit ?", "a": ["Mouton", "Poulet", "Bœuf", "Porc"], "c": 3},
    {"q": "Quelle sourate ouvre le Coran ?", "a": ["Al-Baqara", "Al-Fatiha", "An-Nas", "Al-Ikhlas"], "c": 1},
    {"q": "Combien de sourates dans le Coran ?", "a": ["112", "113", "114", "115"], "c": 2},
    {"q": "Quel prophète a reçu le Coran ?", "a": ["Issa", "Moussa", "Muhammad ﷺ", "Ibrahim"], "c": 2},
    {"q": "Quelle prière est au coucher du soleil ?", "a": ["Asr", "Maghrib", "Isha", "Dhuhr"], "c": 1},
    {"q": "Combien de jours dure Ramadan ?", "a": ["28", "29-30", "30", "31"], "c": 1},
    {"q": "Quel pilier est la prière ?", "a": ["Zakat", "Salat", "Hajj", "Sawm"], "c": 1},
    {"q": "Quel pilier est le jeûne ?", "a": ["Zakat", "Salat", "Sawm", "Hajj"], "c": 2},
    {"q": "Quel pilier est l’aumône ?", "a": ["Zakat", "Salat", "Sawm", "Hajj"], "c": 0},
    {"q": "Quel pilier est le pèlerinage ?", "a": ["Salat", "Sawm", "Zakat", "Hajj"], "c": 3},
    {"q": "Quel prophète a construit l’arche ?", "a": ["Nuh", "Ibrahim", "Moussa", "Issa"], "c": 0},
  ];


  final mediumQuestions = [
    {"q": "Quel ange a transmis la révélation ?", "a": ["Israfil", "Mikail", "Jibril", "Azrael"], "c": 2},
    {"q": "Quelle sourate est la plus courte ?", "a": ["Al-Kawthar", "Al-Ikhlas", "An-Nas", "Al-Falaq"], "c": 0},
    {"q": "Quel prophète a fendu la mer ?", "a": ["Ibrahim", "Moussa", "Nuh", "Issa"], "c": 1},
    {"q": "Quel pilier concerne l’aumône ?", "a": ["Zakat", "Hajj", "Salat", "Sawm"], "c": 0},
    {"q": "Quel prophète a parlé dans le berceau ?", "a": ["Issa", "Yusuf", "Moussa", "Nuh"], "c": 0},
    {"q": "Quelle sourate parle du monothéisme pur ?", "a": ["Al-Fatiha", "Al-Ikhlas", "An-Nas", "Al-Falaq"], "c": 1},
    {"q": "Combien de rak‘ah dans Dhuhr ?", "a": ["2", "3", "4", "5"], "c": 2},
    {"q": "Quel prophète a été jeté au feu ?", "a": ["Nuh", "Ibrahim", "Moussa", "Issa"], "c": 1},
    {"q": "Quel calife a succédé directement au Prophète ﷺ ?", "a": ["Omar", "Ali", "Abu Bakr", "Othman"], "c": 2},
    {"q": "Quelle prière est faite l’après-midi ?", "a": ["Dhuhr", "Asr", "Maghrib", "Isha"], "c": 1},
    {"q": "Quelle sourate est récitée à chaque prière ?", "a": ["Al-Baqara", "Al-Fatiha", "Al-Ikhlas", "An-Nas"], "c": 1},
    {"q": "Combien de rak‘ah dans Maghrib ?", "a": ["2", "3", "4", "5"], "c": 1},
    {"q": "Quel mois vient avant Ramadan ?", "a": ["Rajab", "Chaabane", "Safar", "Muharram"], "c": 1},
    {"q": "Quel prophète est appelé Khalil Allah ?", "a": ["Issa", "Moussa", "Ibrahim", "Nuh"], "c": 2},
    {"q": "Quel est le premier pilier de l’Islam ?", "a": ["Salat", "Zakat", "Chahada", "Sawm"], "c": 2},
    {"q": "Quel ange soufflera dans la trompe ?", "a": ["Jibril", "Israfil", "Mikail", "Azrael"], "c": 1},
    {"q": "Quelle sourate est la plus longue ?", "a": ["Al-Imran", "An-Nisa", "Al-Baqara", "Al-Maida"], "c": 2},
    {"q": "Combien de rak‘ah dans Isha ?", "a": ["2", "3", "4", "5"], "c": 2},
    {"q": "Quel prophète a reçu la Torah ?", "a": ["Issa", "Ibrahim", "Moussa", "Nuh"], "c": 2},
    {"q": "Quelle ville est appelée Al-Madina ?", "a": ["La Mecque", "Jérusalem", "Médine", "Damas"], "c": 2},
  ];


  final hardQuestions = [
    {"q": "Quel compagnon est surnommé Al-Farouq ?", "a": ["Ali", "Abu Bakr", "Omar", "Othman"], "c": 2},
    {"q": "Quelle sourate fut révélée entièrement d’un seul coup ?", "a": ["Al-Fatiha", "Al-An’am", "Al-Ikhlas", "Al-Kawthar"], "c": 1},
    {"q": "Quel prophète est appelé Dhabihullah ?", "a": ["Ibrahim", "Ismail", "Ishaq", "Yaqub"], "c": 1},
    {"q": "Quel calife a compilé le Coran officiel ?", "a": ["Omar", "Ali", "Abu Bakr", "Othman"], "c": 3},
    {"q": "Combien d’années dura la révélation ?", "a": ["20", "21", "22", "23"], "c": 3},
    {"q": "Quelle bataille est appelée Al-Furqan ?", "a": ["Uhud", "Badr", "Khandaq", "Hunayn"], "c": 1},
    {"q": "Quel compagnon a appelé à la prière ?", "a": ["Abu Bakr", "Bilal", "Omar", "Salman"], "c": 1},
    {"q": "Quel prophète a interprété les rêves ?", "a": ["Yusuf", "Moussa", "Issa", "Nuh"], "c": 0},
    {"q": "Quelle sourate ne commence pas par Bismillah ?", "a": ["Al-Baqara", "At-Tawbah", "Al-Anfal", "Al-Maida"], "c": 1},
    {"q": "Combien de fois le nom Muhammad est cité ?", "a": ["3", "4", "5", "6"], "c": 1},
    {"q": "Quel compagnon a épousé deux filles du Prophète ﷺ ?", "a": ["Ali", "Omar", "Othman", "Zubayr"], "c": 2},
    {"q": "Quel est le premier verset révélé ?", "a": ["Iqra", "Bismillah", "Al-Fatiha", "Qul"], "c": 0},
    {"q": "Quel ange est chargé de la mort ?", "a": ["Israfil", "Jibril", "Azrael", "Mikail"], "c": 2},
    {"q": "Quelle sourate est appelée le cœur du Coran ?", "a": ["Ya-Sin", "Al-Baqara", "Ar-Rahman", "Al-Waqia"], "c": 0},
    {"q": "Quel compagnon est enterré à Al-Baqi ?", "a": ["Hamza", "Bilal", "Othman", "Zayd"], "c": 2},
    {"q": "Quel prophète a vécu le plus longtemps ?", "a": ["Ibrahim", "Nuh", "Moussa", "Adam"], "c": 1},
    {"q": "Quel est le nom du traité signé à La Mecque ?", "a": ["Badr", "Hudaybiyyah", "Uhud", "Hunayn"], "c": 1},
    {"q": "Combien de versets dans Al-Fatiha ?", "a": ["6", "7", "8", "9"], "c": 1},
    {"q": "Quel compagnon est surnommé Dhun-Nurayn ?", "a": ["Ali", "Omar", "Othman", "Abu Bakr"], "c": 2},
    {"q": "Quel prophète a construit la Kaaba ?", "a": ["Adam", "Ibrahim", "Ismail", "Ibrahim & Ismail"], "c": 3},
  ];


  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    loadMute();
    loadRecord();
  }

  // ================= START GAME =================

  void startGame(String mode) {
    selectedMode = mode;

    if (mode == "easy") {
      quiz = List.from(easyQuestions);
      maxTime = 15;
    } else if (mode == "medium") {
      quiz = List.from(mediumQuestions);
      maxTime = 12;
    } else {
      quiz = List.from(hardQuestions);
      maxTime = 8;
    }

    quiz.shuffle();
    quiz = quiz.take(20).toList();

    questionIndex = 0;
    score = 0;

    timerController =
        AnimationController(vsync: this, duration: Duration(seconds: maxTime));

    loadQuestion();
    setState(() {});
  }

  void loadQuestion() {
    answered = false;
    selectedIndex = null;
    currentQuestion = quiz[questionIndex];
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timeLeft = maxTime;
    timerController.forward(from: 0);

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => timeLeft--);

      if (timeLeft == 0) {
        t.cancel();
        answered = true;
        playSfx("wrong.mp3");
        Future.delayed(const Duration(seconds: 2), nextQuestion);
      }
    });
  }

  void answer(int i) {
    if (answered) return;
    timer?.cancel();

    final bool isCorrect = i == currentQuestion["c"];

    setState(() {
      answered = true;
      selectedIndex = i;
      if (isCorrect) score++;
    });

    playSfx(isCorrect ? "correct.mp3" : "wrong.mp3");
    Future.delayed(const Duration(seconds: 2), nextQuestion);
  }

  void nextQuestion() async {
    if (questionIndex == quiz.length - 1) {
      await saveRecord();
      playSfx("finish.mp3");
      showEnd();
      return;
    }
    setState(() {
      questionIndex++;
      loadQuestion();
    });
  }

  Future<void> loadRecord() async {
    final prefs = await SharedPreferences.getInstance();
    record = prefs.getInt("record") ?? 0;
  }

  Future<void> saveRecord() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > record) prefs.setInt("record", score);
  }

  Color btnColor(int i) {
    if (!answered) return Colors.deepPurple;
    if (i == currentQuestion["c"]) return Colors.green;
    if (i == selectedIndex) return Colors.red;
    return Colors.grey;
  }

  void showEnd() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("🏆 Résultat"),
        content: Text("Score : $score / 20\nRecord : $record"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => selectedMode = null);
            },
            child: const Text("Retour modes"),
          )
        ],
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    // ====== MODE SELECTION ======
    if (selectedMode == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("🕋 Choisis ton mode")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              modeBtn("🟢 Facile", "20 questions • 15s", Colors.green, "easy"),
              modeBtn("🟠 Moyen", "20 questions • 12s", Colors.orange, "medium"),
              modeBtn("🔴 Difficile", "20 questions • 8s", Colors.red, "hard"),
            ],
          ),
        ),
      );
    }

    // ====== QUIZ ======
    return Scaffold(
      appBar: AppBar(
        title: const Text("🕋 Quiz Islamique"),
        actions: [
          IconButton(
            icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: toggleMute,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Question ${questionIndex + 1}/20 • ⏱ $timeLeft s"),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: timerController.value),
            const SizedBox(height: 30),
            Text(
              currentQuestion["q"],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ...List.generate(
              4,
                  (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnColor(i),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => answer(i),
                    child: Text(currentQuestion["a"][i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget modeBtn(String title, String sub, Color color, String mode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () => startGame(mode),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 22)),
              Text(sub),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    timerController.dispose();
    sfxPlayer.dispose();
    super.dispose();
  }
}
