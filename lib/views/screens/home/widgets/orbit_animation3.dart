import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class OrbitAnimation3 extends StatefulWidget {
  const OrbitAnimation3({super.key});

  @override
  _OrbitAnimation3State createState() => _OrbitAnimation3State();
}

class _OrbitAnimation3State extends State<OrbitAnimation3>
    with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  final double radius = 150;
  final List<Color> planetColors = [
    Color.fromRGBO(88, 81, 219, 1), // Purple
    Colors.green, // WhatsApp
    Color.fromRGBO(10, 102, 194, 1), // LinkedIn Blue
    Color.fromRGBO(24, 23, 23, 1), // GitHub Black
    Colors.purple, // Dart
    Colors.teal, // Store
  ];

  final List<IconData> planetIcons = [
    FontAwesomeIcons.instagram,
    FontAwesomeIcons.whatsapp,
    FontAwesomeIcons.linkedin,
    FontAwesomeIcons.github,
    FontAwesomeIcons.dartLang,
    FontAwesomeIcons.store,
  ];

  final List<String> urls = [
    instaLink,
    whatsappWebLink,
    linkedInLink,
    githubLink,
    pubDevLink,
    vsCodeThemesLink,
  ];

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    animation = Tween<double>(begin: 0, end: 2 * pi).animate(controller);
  }

  Future<void> _handleIconTap(int index) async {
    controller.stop(); // Pause animation on tap
    try {
      if (await canLaunchUrl(Uri.parse(urls[index]))) {
        await launchUrl(Uri.parse(urls[index]));
      } else {
        debugPrint("## Could not launch URL");
      }
    } catch (e) {
      debugPrint("## Error: $e");
    }
    await Future.delayed(Duration(milliseconds: 500));
    controller.repeat(); // Resume animation after launching
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 400,
        height: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center object
            SizedBox(
              width: 300,
              height: 300,
              child: Image.asset(
                'assets/images/picWithBlob.png',
                width: 315,
              ),
            ),
            // Orbiting icons
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Stack(
                  children: List.generate(planetIcons.length, (i) {
                    double angle =
                        animation.value + (i * (2 * pi / planetIcons.length));
                    double x = radius * cos(angle);
                    double y = radius * sin(angle);

                    return Positioned(
                      left: 200 + x - (40 + i * 5) / 2,
                      top: 200 + y - (40 + i * 5) / 2,
                      child: MouseRegion(
                        onEnter: (_) =>
                            controller.stop(), // Pause animation on hover
                        onExit: (_) => controller
                            .repeat(), // Resume animation on mouse leave
                        child: GestureDetector(
                          onTap: () => _handleIconTap(i),
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 40 + i * 5,
                              height: 40 + i * 5,
                              decoration: BoxDecoration(
                                gradient: i == 0
                                    ? LinearGradient(
                                        colors: [
                                          Color(0xFF405DE6), // Blue
                                          Color(0xFF5851DB), // Purple
                                          Color(0xFF833AB4), // Dark Purple
                                          Color(0xFFE1306C), // Red-Pink
                                          Color(0xFFFD1D1D), // Red
                                          Color(0xFFFCAF45), // Yellow
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: i != 0 ? planetColors[i] : null,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  planetIcons[i],
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
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
    controller.dispose();
    super.dispose();
  }
}
