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

class _QiblaCompassPageState extends State<QiblaCompassPage>
    with SingleTickerProviderStateMixin {
  double? direction;
  double? qiblaDirection;
  String status = "Initialisation…";

  StreamSubscription<CompassEvent>? compassSub;
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0;

  static const double kaabaLat = 21.4225;
  static const double kaabaLon = 39.8262;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    initAll();
  }

  Future<void> initAll() async {
    if (kIsWeb) {
      setState(() => status = "Boussole non supportée sur le web");
      return;
    }

    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => status = "Permission localisation refusée");
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    qiblaDirection =
        calculateQibla(position.latitude, position.longitude);

    compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading == null) {
        setState(() => status = "Calibrage… bouge le téléphone en ∞");
        return;
      }

      final newAngle =
          ((qiblaDirection! - event.heading!) + 360) % 360;

      _animation = Tween<double>(
        begin: _currentAngle,
        end: newAngle,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));

      _controller.forward(from: 0);
      _currentAngle = newAngle;

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
    final x = cos(latRad) * tan(kaabaLatRad) -
        sin(latRad) * cos(kaabaLonRad - lonRad);

    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  @override
  void dispose() {
    compassSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Qibla"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: qiblaDirection == null || direction == null
            ? Text(
          status,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Direction de la Qibla",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),

            /// 🧭 Boussole
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_animation.value * pi / 180,
                  child: child,
                );
              },
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF020617),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 20,
                    )
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    /// Aiguille
                    Positioned(
                      top: 20,
                      child: Icon(
                        Icons.navigation,
                        size: 80,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),

                    /// Kaaba centre
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        border: Border.all(
                          color: Colors.amber,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "🕋",
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),
            Text(
              "${qiblaDirection!.toStringAsFixed(1)}°",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
