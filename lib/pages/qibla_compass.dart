import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({super.key});

  @override
  State<QiblaCompassPage> createState() => _QiblaCompassPageState();
}

class _QiblaCompassPageState extends State<QiblaCompassPage> {
  double? direction; // direction téléphone
  double? qiblaDirection;
  bool error = false;
  String errorMessage = "Initialisation…";

  static const double kaabaLat = 21.4225;
  static const double kaabaLon = 39.8262;

  StreamSubscription? compassSub;

  @override
  void initState() {
    super.initState();
    initAll();

    // ⏱️ timeout sécurité (anti loader infini)
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && (direction == null || qiblaDirection == null)) {
        setError("Boussole non disponible sur cet appareil.");
      }
    });
  }

  Future<void> initAll() async {
    try {
      // 📍 Permission localisation
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setError("Permission de localisation refusée.");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      qiblaDirection = calculateQibla(
        pos.latitude,
        pos.longitude,
      );

      // 🧭 Capteur boussole
      compassSub = FlutterCompass.events?.listen((event) {
        if (event.heading == null) {
          setError("Capteur de boussole indisponible.");
          return;
        }

        setState(() {
          direction = event.heading;
        });
      });
    } catch (e) {
      setError("Erreur lors de l’accès aux capteurs.");
    }
  }

  void setError(String msg) {
    setState(() {
      error = true;
      errorMessage = msg;
    });
  }

  double calculateQibla(double lat, double lon) {
    final latRad = lat * pi / 180;
    final lonRad = lon * pi / 180;
    final kaabaLatRad = kaabaLat * pi / 180;
    final kaabaLonRad = kaabaLon * pi / 180;

    final y = sin(kaabaLonRad - lonRad);
    final x = cos(latRad) * tan(kaabaLatRad) -
        sin(latRad) * cos(kaabaLonRad - lonRad);

    final angle = atan2(y, x);
    return (angle * 180 / pi + 360) % 360;
  }

  @override
  void dispose() {
    compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ❌ ERREUR
    if (error) {
      return Scaffold(
        appBar: AppBar(title: const Text("Boussole Qibla")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    // ⏳ CHARGEMENT
    if (direction == null || qiblaDirection == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final angle = qiblaDirection! - direction!;

    // ✅ OK
    return Scaffold(
      appBar: AppBar(title: const Text("Boussole Qibla")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "🕋 Direction de la Qibla",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Transform.rotate(
              angle: angle * pi / 180,
              child: const Icon(
                Icons.navigation,
                size: 180,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "${qiblaDirection!.toStringAsFixed(1)}°",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
