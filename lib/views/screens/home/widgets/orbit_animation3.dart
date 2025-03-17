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
  late AnimationController orbitController;
  late Animation<double> orbitAnimation;

  late AnimationController imageFadeController;
  late Animation<double> imageFadeAnimation;

  final List<AnimationController> scaleControllers = [];
  final List<Animation<double>> scaleAnimations = [];
  final List<Animation<double>> opacityAnimations = [];

  final double radius = 150;
  bool _isInitialized = false;

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

    // Fade in animation for the center image
    imageFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    imageFadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: imageFadeController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500)).then((_) {
        if (mounted) {
          imageFadeController.forward(); // Start fading in the image
        }

        // Initialize orbit animation
        orbitController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 5),
        )..repeat();

        orbitAnimation =
            Tween<double>(begin: 0, end: 2 * pi).animate(orbitController);

        // Create individual controllers for each icon
        for (int i = 0; i < planetIcons.length; i++) {
          final controller = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 600),
          );

          final scaleAnimation =
              CurvedAnimation(parent: controller, curve: Curves.easeOutBack);
          final opacityAnimation =
              Tween<double>(begin: 0.0, end: 1.0).animate(controller);

          scaleControllers.add(controller);
          scaleAnimations.add(scaleAnimation);
          opacityAnimations.add(opacityAnimation);

          // Start each animation with a slight delay
          Future.delayed(Duration(milliseconds: i * 150), () {
            if (mounted) {
              controller.forward();
            }
          });
        }

        // Mark initialization as complete
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    });
  }

  Future<void> _handleIconTap(int index) async {
    orbitController.stop(); // Pause animation on tap
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
    orbitController.repeat(); // Resume animation after launching
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
            // Center object with fade-in animation
            FadeTransition(
              opacity: imageFadeAnimation,
              child: SizedBox(
                width: 300,
                height: 300,
                child: Image.asset(
                  'assets/images/picWithBlob.png',
                  width: 315,
                ),
              ),
            ),
            if (_isInitialized) // Render orbit animation only after initialization
              AnimatedBuilder(
                animation: orbitAnimation,
                builder: (context, child) {
                  return Stack(
                    children: List.generate(planetIcons.length, (i) {
                      double angle = orbitAnimation.value +
                          (i * (2 * pi / planetIcons.length));
                      double x = radius * cos(angle);
                      double y = radius * sin(angle);

                      return Positioned(
                        left: 200 + x - (40 + i * 5) / 2,
                        top: 200 + y - (40 + i * 5) / 2,
                        child: FadeTransition(
                          opacity: opacityAnimations[i],
                          child: ScaleTransition(
                            scale: scaleAnimations[i],
                            child: MouseRegion(
                              onEnter: (_) => orbitController.stop(),
                              onExit: (_) => orbitController.repeat(),
                              child: GestureDetector(
                                onTap: () => _handleIconTap(i),
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: 40 + i * 5,
                                    height: 40 + i * 5,
                                    decoration: BoxDecoration(
                                      gradient: i == 0
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF405DE6), // Blue
                                                Color(0xFF5851DB), // Purple
                                                Color(
                                                    0xFF833AB4), // Dark Purple
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
                                          offset: const Offset(2, 4),
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
    if (_isInitialized) {
      orbitController.dispose();
      for (var controller in scaleControllers) {
        controller.dispose();
      }
    }
    imageFadeController.dispose(); // Clean up image fade controller
    super.dispose();
  }
}
