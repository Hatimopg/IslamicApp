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
  // 📍 Kaaba
  static const double kaabaLat = 21.4225;
  static const double kaabaLon = 39.8262;

  // 🎯 précision (± degrés)
  static const double alignThreshold = 1.5;

  double? qiblaDirection;
  double _smoothedAngle = 0;
  bool _aligned = false;
  bool _hasCompass = true;
  String _status = "Initialisation…";

  // 🎛️ animation
  late AnimationController _controller;
  late Animation<double> _animation;

  StreamSubscription<CompassEvent>? _compassSub;

  // 🧠 filtre anti-tremblement (EMA)
  static const double smoothingFactor = 0.15;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);

    _initQibla();
  }

  Future<void> _initQibla() async {
    if (kIsWeb) {
      setState(() => _status = "Boussole non supportée sur le web");
      return;
    }

    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _status = "Permission localisation refusée");
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    qiblaDirection = _calculateQibla(pos.latitude, pos.longitude);

    _compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading == null) {
        _hasCompass = false;
        setState(() => _status = "Calibration requise (mouvement ∞)");
        return;
      }

      _hasCompass = true;

      final rawAngle =
          ((qiblaDirection! - event.heading!) + 360) % 360;

      // 🧠 lissage EMA
      _smoothedAngle = _smoothedAngle == 0
          ? rawAngle
          : _smoothedAngle +
          smoothingFactor * (rawAngle - _smoothedAngle);

      _animation = Tween<double>(
        begin: _animation.value,
        end: _smoothedAngle,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),
      );

      _controller.forward(from: 0);

      _checkAlignment(_smoothedAngle);

      setState(() => _status = "OK");
    });
  }

  void _checkAlignment(double angle) {
    final isAligned =
        angle <= alignThreshold || angle >= 360 - alignThreshold;

    if (_aligned != isAligned) {
      setState(() => _aligned = isAligned);
    }
  }

  double _calculateQibla(double lat, double lon) {
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
    _compassSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: const Text("Qibla"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: qiblaDirection == null
            ? Text(
          _status,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _aligned
                  ? "Aligné avec la Qibla"
                  : "Tourne doucement le téléphone",
              style: TextStyle(
                color: _aligned ? Colors.green : Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),

            /// 🧭 Boussole premium
            AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                return Transform.rotate(
                  angle: -_animation.value * pi / 180,
                  child: child,
                );
              },
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _aligned
                        ? [
                      Colors.green.withOpacity(0.35),
                      const Color(0xFF022C22),
                    ]
                        : const [
                      Color(0xFF1E293B),
                      Color(0xFF020617),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _aligned
                          ? Colors.green.withOpacity(0.6)
                          : Colors.black.withOpacity(0.6),
                      blurRadius: 25,
                    )
                  ],
                  border: Border.all(
                    color: _aligned
                        ? Colors.green
                        : Colors.deepPurpleAccent,
                    width: 3,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 18,
                      child: Icon(
                        Icons.navigation,
                        size: 90,
                        color: _aligned
                            ? Colors.green
                            : Colors.deepPurpleAccent,
                      ),
                    ),
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        border: Border.all(
                          color:
                          _aligned ? Colors.green : Colors.amber,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "🕋",
                          style: TextStyle(fontSize: 34),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            Text(
              "${_smoothedAngle.toStringAsFixed(1)}°",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),

            if (!_hasCompass)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  "Capteur indisponible – orientation GPS",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
