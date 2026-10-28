import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
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

  bool _isInitialized = false;

  final List<Color> planetColors = const [
    Color.fromRGBO(88, 81, 219, 1), // Purple
    Colors.green, // WhatsApp
    Color.fromRGBO(10, 102, 194, 1), // LinkedIn Blue
    Color.fromRGBO(24, 23, 23, 1), // GitHub Black
    Colors.purple, // Dart
    Colors.teal, // Store
  ];

  final List<IconData> planetIcons = const [
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
      Future.delayed(const Duration(milliseconds: 400)).then((_) {
        if (!mounted) return;
        imageFadeController.forward();

        orbitController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 7),
        )..repeat();

        orbitAnimation =
            Tween<double>(begin: 0, end: 2 * pi).animate(orbitController);

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

          Future.delayed(Duration(milliseconds: i * 120), () {
            if (mounted) {
              controller.forward();
            }
          });
        }

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    });
  }

  Future<void> _handleIconTap(int index) async {
    GamificationController.instance.completeQuest('loot_collector');
    orbitController.stop();
    try {
      if (await canLaunchUrl(Uri.parse(urls[index]))) {
        await launchUrl(Uri.parse(urls[index]));
      }
    } catch (e) {
      debugPrint("## Error: $e");
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      orbitController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double boxSize =
        context.isMobileDevice ? min(context.screenWidth - 32, 330) : 400;
    final double center = boxSize / 2;
    final double radius = boxSize * 0.375;
    final double imgSize = boxSize * 0.72;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;

        return Center(
          child: SizedBox(
            width: boxSize,
            height: boxSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle glowing orbital ring matching active style
                Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withOpacity(0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.08),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                FadeTransition(
                  opacity: imageFadeAnimation,
                  child: SizedBox(
                    width: imgSize,
                    height: imgSize,
                    child: Image.asset(
                      'assets/images/picWithBlob.png',
                      width: imgSize,
                    ),
                  ),
                ),
                if (_isInitialized)
                  AnimatedBuilder(
                    animation: orbitAnimation,
                    builder: (context, child) {
                      return Stack(
                        children: List.generate(planetIcons.length, (i) {
                          final double angle = orbitAnimation.value +
                              (i * (2 * pi / planetIcons.length));
                          final double x = radius * cos(angle);
                          final double y = radius * sin(angle);

                          final double minIcon =
                              context.isMobileDevice ? 26 : 30;
                          final double maxIcon =
                              context.isMobileDevice ? 42 : 50;
                          final double size = lerpDouble(
                            minIcon,
                            maxIcon,
                            (y + radius) / (2 * radius),
                          )!;

                          final double shadowBlur = lerpDouble(
                            4,
                            12,
                            (y + radius) / (2 * radius),
                          )!;
                          final double shadowOffset = lerpDouble(
                            2,
                            8,
                            (y + radius) / (2 * radius),
                          )!;
                          final double iconOpacity = lerpDouble(
                            0.55,
                            1.0,
                            (y + radius) / (2 * radius),
                          )!;

                          return Positioned(
                            left: center + x - size / 2,
                            top: center + y - size / 2,
                            child: RepaintBoundary(
                              key: ValueKey(i),
                              child: Opacity(
                                opacity: iconOpacity,
                                child: FadeTransition(
                                  opacity: opacityAnimations[i],
                                  child: ScaleTransition(
                                    scale: scaleAnimations[i],
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      onEnter: (_) => orbitController.stop(),
                                      onExit: (_) => orbitController.repeat(),
                                      child: GestureDetector(
                                        onTap: () => _handleIconTap(i),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Container(
                                            width: size,
                                            height: size,
                                            decoration: BoxDecoration(
                                              gradient: i == 0
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Color(0xFF405DE6),
                                                        Color(0xFF5851DB),
                                                        Color(0xFF833AB4),
                                                        Color(0xFFE1306C),
                                                        Color(0xFFFD1D1D),
                                                        Color(0xFFFCAF45),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    )
                                                  : null,
                                              color: i != 0
                                                  ? planetColors[i]
                                                  : null,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.25),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.35),
                                                  blurRadius: shadowBlur,
                                                  offset:
                                                      Offset(0, shadowOffset),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Icon(
                                                planetIcons[i],
                                                color: Colors.white,
                                                size: size * 0.5,
                                              ),
                                            ),
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
      },
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
    imageFadeController.dispose();
    super.dispose();
  }
}
