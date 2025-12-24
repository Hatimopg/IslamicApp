import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IslamicQuizPage extends StatefulWidget {
  const IslamicQuizPage({super.key});

  @override
  State<IslamicQuizPage> createState() => _IslamicQuizPageState();
}

class _IslamicQuizPageState extends State<IslamicQuizPage>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();

  // GAME STATE
  int questionIndex = 0;
  int score = 0;
  int record = 0;

  bool answered = false;
  int? selectedIndex;

  // TIMER
  static const int maxTime = 10;
  int timeLeft = maxTime;
  Timer? timer;
  late AnimationController timerController;

  late List<Map<String, dynamic>> quiz;
  late Map<String, dynamic> currentQuestion;

  // 🕋 30 QUESTIONS EXACTES
  final List<Map<String, dynamic>> allQuestions = [
    {"q": "Quelle est la direction de la prière ?", "a": ["Jérusalem", "Médine", "La Kaaba", "Damas"], "c": 2},
    {"q": "Combien de prières obligatoires par jour ?", "a": ["3", "4", "5", "6"], "c": 2},
    {"q": "Quel est le dernier prophète de l’Islam ?", "a": ["Issa", "Moussa", "Ibrahim", "Muhammad ﷺ"], "c": 3},
    {"q": "Quel mois est consacré au jeûne ?", "a": ["Rajab", "Ramadan", "Chaabane", "Muharram"], "c": 1},
    {"q": "Combien de rakʿah dans le Fajr ?", "a": ["2", "3", "4", "5"], "c": 0},
    {"q": "Quelle est la première sourate du Coran ?", "a": ["Al-Baqara", "Al-Fatiha", "An-Nas", "Al-Ikhlas"], "c": 1},
    {"q": "Combien de piliers de l’Islam ?", "a": ["3", "4", "5", "6"], "c": 2},
    {"q": "Quel ange a transmis le Coran ?", "a": ["Israfil", "Mikail", "Jibril", "Azrael"], "c": 2},
    {"q": "Combien de sourates dans le Coran ?", "a": ["112", "113", "114", "115"], "c": 2},
    {"q": "Quelle prière est au coucher du soleil ?", "a": ["Fajr", "Dhuhr", "Asr", "Maghrib"], "c": 3},
    {"q": "Quelle est la ville sainte de l’Islam ?", "a": ["Bagdad", "Médine", "La Mecque", "Damas"], "c": 2},
    {"q": "Quelle prière est nocturne ?", "a": ["Asr", "Isha", "Dhuhr", "Maghrib"], "c": 1},
    {"q": "Combien de rakʿah dans le Dhuhr ?", "a": ["2", "3", "4", "5"], "c": 2},
    {"q": "Quel prophète a construit l’arche ?", "a": ["Ibrahim", "Nuh", "Moussa", "Issa"], "c": 1},
    {"q": "Quel pilier concerne l’aumône ?", "a": ["Chahada", "Zakat", "Sawm", "Hajj"], "c": 1},
    {"q": "Combien de jours dure le Ramadan ?", "a": ["28", "29 ou 30", "30", "31"], "c": 1},
    {"q": "Quel prophète a parlé dans le berceau ?", "a": ["Issa", "Yusuf", "Moussa", "Nuh"], "c": 0},
    {"q": "Quel animal est interdit ?", "a": ["Bœuf", "Mouton", "Porc", "Poulet"], "c": 2},
    {"q": "Combien de rakʿah dans l’Isha ?", "a": ["2", "3", "4", "5"], "c": 2},
    {"q": "Quelle sourate est la plus courte ?", "a": ["Al-Kawthar", "An-Nas", "Al-Falaq", "Al-Ikhlas"], "c": 0},
    {"q": "Quel prophète a été jeté au feu ?", "a": ["Nuh", "Ibrahim", "Moussa", "Issa"], "c": 1},
    {"q": "Quel pilier concerne le pèlerinage ?", "a": ["Zakat", "Sawm", "Hajj", "Chahada"], "c": 2},
    {"q": "Combien de rakʿah dans le Maghrib ?", "a": ["2", "3", "4", "5"], "c": 1},
    {"q": "Quel est le livre sacré de l’Islam ?", "a": ["Bible", "Torah", "Coran", "Zabour"], "c": 2},
    {"q": "Quel prophète a fendu la mer ?", "a": ["Ibrahim", "Moussa", "Nuh", "Issa"], "c": 1},
    {"q": "Quelle sourate parle du monothéisme pur ?", "a": ["Al-Baqara", "Al-Ikhlas", "Al-Fatiha", "An-Nas"], "c": 1},
    {"q": "Quel pilier concerne la profession de foi ?", "a": ["Zakat", "Hajj", "Sawm", "Chahada"], "c": 3},
    {"q": "Combien de prières obligatoires ?", "a": ["4", "5", "6", "7"], "c": 1},
    {"q": "Quel prophète est appelé Khalil Allah ?", "a": ["Moussa", "Ibrahim", "Issa", "Nuh"], "c": 1},
    {"q": "Quel mois vient juste avant Ramadan ?", "a": ["Rajab", "Chaabane", "Muharram", "Safar"], "c": 1},
  ];

  @override
  void initState() {
    super.initState();
    timerController =
        AnimationController(vsync: this, duration: const Duration(seconds: maxTime));
    loadRecord();
    startGame();
  }

  void startGame() {
    quiz = List.from(allQuestions)..shuffle();
    quiz = quiz.take(30).toList();
    questionIndex = 0;
    score = 0;
    loadQuestion();
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
        Future.delayed(const Duration(seconds: 1), nextQuestion);
      }
    });
  }

  void answer(int i) {
    if (answered) return;
    timer?.cancel();

    setState(() {
      answered = true;
      selectedIndex = i;
      if (i == currentQuestion["c"]) score++;
    });
    Future.delayed(const Duration(seconds: 1), nextQuestion);
  }


  void nextQuestion() async {
    if (questionIndex == 29) {
      await saveRecord();
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
    final bool newRecord = score >= record;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("🏆 Classement"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎯 Score partie
            Text(
              "🎯 Score de la partie",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "$score / 30",
              style: const TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 16),

            // 🥇 Record
            Text(
              "🥇 Meilleur score",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "${record} / 30",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 16),

            // 🔥 Message dynamique
            Text(
              newRecord
                  ? "🔥 Nouveau record, ماشاالله !"
                  : "💪 Bien joué, continue !",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: newRecord ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(startGame);
              },
              child: const Text("Rejouer"),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    timer?.cancel();
    timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🕋 Quiz Islamique")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Question ${questionIndex + 1}/30 • ⏱ $timeLeft s"),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: timerController.value),
            const SizedBox(height: 30),
            Text(currentQuestion["q"],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ...List.generate(
              4,
                  (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: btnColor(i)),
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
}
