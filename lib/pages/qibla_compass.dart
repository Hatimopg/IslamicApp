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
  double? direction; // direction du téléphone
  double? qiblaDirection;

  static const double kaabaLat = 21.4225;
  static const double kaabaLon = 39.8262;

  @override
  void initState() {
    super.initState();
    initLocation();
    FlutterCompass.events?.listen((event) {
      setState(() => direction = event.heading);
    });
  }

  Future<void> initLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      qiblaDirection = calculateQibla(
        pos.latitude,
        pos.longitude,
      );
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
  Widget build(BuildContext context) {
    if (direction == null || qiblaDirection == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final angle = qiblaDirection! - direction!;

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
                size: 200,
                color: Colors.green,
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
