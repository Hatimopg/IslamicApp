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
  double? direction;
  double? qiblaDirection;
  String status = "Calibration de la boussole…";

  StreamSubscription<CompassEvent>? compassSub;

  static const double kaabaLat = 21.4225;
  static const double kaabaLon = 39.8262;

  @override
  void initState() {
    super.initState();
    initAll();
  }

  Future<void> initAll() async {
    if (kIsWeb) {
      setState(() => status = "Boussole non supportée sur le web.");
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => status = "Permission localisation refusée.");
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    qiblaDirection = calculateQibla(
      position.latitude,
      position.longitude,
    );

    compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading == null) return;

      setState(() {
        direction = event.heading;
        status = "OK";
      });
    });
  }

  double calculateQibla(double lat, double lon) {
    final latRad = lat * pi / 180;
    final lonRad = lon * pi / 180;
    final kaabaLatRad = kaabaLat * pi / 180;
    final kaabaLonRad = kaabaLon * pi / 180;

    final y = sin(kaabaLonRad - lonRad);
    final x =
        cos(latRad) * tan(kaabaLatRad) -
            sin(latRad) * cos(kaabaLonRad - lonRad);

    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  @override
  void dispose() {
    compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (direction == null || qiblaDirection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Boussole Qibla")),
        body: Center(
          child: Text(
            status,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final angle = (qiblaDirection! - direction! + 360) % 360;

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
              angle: -angle * pi / 180,
              child: const Icon(Icons.navigation,
                  size: 180, color: Colors.deepPurple),
            ),
            const SizedBox(height: 20),
            Text("${qiblaDirection!.toStringAsFixed(1)}°"),
          ],
        ),
      ),
    );
  }
}
