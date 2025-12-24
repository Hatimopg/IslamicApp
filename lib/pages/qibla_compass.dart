import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({super.key});

  @override
  State<QiblaCompassPage> createState() => _QiblaCompassPageState();
}

class _QiblaCompassPageState extends State<QiblaCompassPage> {
  double? direction; // direction du téléphone (Nord magnétique)
  double? qiblaDirection; // direction Qibla (Nord géographique)
  bool error = false;
  String errorMessage = "Initialisation…";

  StreamSubscription<CompassEvent>? compassSub;

  // Coordonnées de la Kaaba
  static const double kaabaLat = 21.4225;
  static const double kaabaLon = 39.8262;

  @override
  void initState() {
    super.initState();
    initAll();

    // ⏱️ Sécurité : éviter loader infini
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && (direction == null || qiblaDirection == null)) {
        setError("Boussole indisponible sur cet appareil.");
      }
    });
  }

  Future<void> initAll() async {
    try {
      // ❌ Flutter Web : pas de boussole
      if (kIsWeb) {
        setError("La boussole n’est pas supportée sur le web.");
        return;
      }

      // 📍 Permissions GPS
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setError("Permission de localisation refusée.");
        return;
      }

      // 📍 Position utilisateur
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 🕋 Calcul Qibla
      qiblaDirection = calculateQibla(
        position.latitude,
        position.longitude,
      );

      // 🧭 Capteur boussole
      compassSub = FlutterCompass.events?.listen((event) {
        if (event.heading == null) {
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

  // 🧮 Calcul angle Qibla
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

    // ⏳ Chargement
    if (direction == null || qiblaDirection == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🔁 Angle final corrigé
    final angle = (qiblaDirection! - direction! + 360) % 360;

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
              angle: -angle * pi / 180, // ⬅️ IMPORTANT
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

            const SizedBox(height: 16),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Bougez le téléphone en forme de 8 pour calibrer la boussole",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
