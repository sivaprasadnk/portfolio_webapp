import 'dart:math';

import 'package:flutter/material.dart';

class CircularOrbit extends StatefulWidget {
  @override
  _CircularOrbitState createState() => _CircularOrbitState();
}

class _CircularOrbitState extends State<CircularOrbit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          children: [
            // Draw the orbit
            CustomPaint(
              size: const Size(200, 200),
              painter: OrbitPainter(),
            ),
            // Animate the image
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    cos(2 * pi * _controller.value),
                    sin(2 * pi * _controller.value),
                  ),
                  child: child,
                );
              },
              child: Container(
                height: 100,
                width: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
              ),
              // child: Image.asset(
              //   'assets/images/dash/dash1.png',
              //   width: 50,
              //   height: 50,
              // ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
