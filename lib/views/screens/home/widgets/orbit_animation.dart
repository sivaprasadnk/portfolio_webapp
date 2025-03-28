import 'dart:math';

import 'package:flutter/material.dart';

class OrbitAnimationScreen extends StatefulWidget {
  const OrbitAnimationScreen({super.key});

  @override
  _OrbitAnimationScreenState createState() => _OrbitAnimationScreenState();
}

class _OrbitAnimationScreenState extends State<OrbitAnimationScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> controllers;
  late List<Animation<double>> animations;

  final List<double> radii = [60, 100, 150, 200]; // Different orbit distances
  final List<Color> planetColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
  ]; // Planet colors
  final List<int> durations = [4, 6, 8, 10]; // Different animation speeds
  final List<String> labels = [
    "About",
    "Skills",
    "Experience",
    "Projects",
  ]; // Labels for each planet

  @override
  void initState() {
    super.initState();
    controllers = List.generate(
      radii.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(seconds: durations[index]),
      )..repeat(),
    );

    animations = controllers
        .map(
          (controller) =>
              Tween<double>(begin: 0, end: 2 * pi).animate(controller),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Draw all orbits
            CustomPaint(
              size: Size(radii.last * 2, radii.last * 2),
              painter: OrbitPainter(radii),
            ),
            // Center object (Sun) - Portfolio Center
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.yellow, blurRadius: 20)],
              ),
              child: Center(
                child: Text(
                  "Me",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Generate multiple orbiting objects with labels
            for (int i = 0; i < radii.length; i++)
              AnimatedBuilder(
                animation: animations[i],
                builder: (context, child) {
                  double angle = animations[i].value;
                  double x = radii[i] * cos(angle);
                  double y = radii[i] * sin(angle);
                  return Transform.translate(
                    offset: Offset(x, y),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40 + i * 5, // Varying planet size
                          height: 40 + i * 5,
                          decoration: BoxDecoration(
                            color: planetColors[i],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: planetColors[i], blurRadius: 10),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          labels[i],
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

// Painter to draw multiple orbits
class OrbitPainter extends CustomPainter {
  final List<double> radii;

  OrbitPainter(this.radii);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (double radius in radii) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
