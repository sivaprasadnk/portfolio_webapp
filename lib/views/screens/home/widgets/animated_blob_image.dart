import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedBlobImage extends StatefulWidget {
  final String imageUrl;
  final double size;

  const AnimatedBlobImage({
    super.key,
    required this.imageUrl,
    this.size = 150,
  });

  @override
  State<AnimatedBlobImage> createState() => _AnimatedBlobImageState();
}

class _AnimatedBlobImageState extends State<AnimatedBlobImage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blobAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _blobAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _positionAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.05, 0.05),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Transform.translate(
                offset: _positionAnimation.value * widget.size,
                child: Transform.scale(
                  scale: _blobAnimation.value,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: BlobPainter(color: Colors.blue.withOpacity(0.2)),
                  ),
                ),
              );
            },
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.size / 2),
            child: Image.asset(
              widget.imageUrl,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class BlobPainter extends CustomPainter {
  final Color color;

  BlobPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    final random = Random();

    double xFactor(double value) => value * size.width;
    double yFactor(double value) => value * size.height;

    path.moveTo(xFactor(0.5), yFactor(0));

    for (int i = 0; i < 4; i++) {
      double x1 = xFactor(random.nextDouble());
      double y1 = yFactor(random.nextDouble());
      double x2 = xFactor(random.nextDouble());
      double y2 = yFactor(random.nextDouble());
      double x3 = xFactor(random.nextDouble());
      double y3 = yFactor(random.nextDouble());

      path.cubicTo(x1, y1, x2, y2, x3, y3);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
