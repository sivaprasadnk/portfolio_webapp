import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/home/widgets/download_cv_btn.dart';
import 'package:spnk/views/screens/home/widgets/orbit_animation3.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';

class HomeScreenLarge extends StatefulWidget {
  const HomeScreenLarge({
    super.key,
    this.onExploreProjects,
    this.onPlayArcade,
  });

  final VoidCallback? onExploreProjects;
  final VoidCallback? onPlayArcade;

  @override
  State<HomeScreenLarge> createState() => _HomeScreenLargeState();
}

class _HomeScreenLargeState extends State<HomeScreenLarge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool showImage = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
        setState(() {
          showImage = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final horizontalPad = screenWidth * 0.08;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final accent = state.accentColor;
        final secondary = state.secondaryAccent;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPad,
            vertical: 28,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 6,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Open-Air Commander Telemetry Header (Zero Box Container)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flare_rounded,
                              size: 16,
                              color: accent,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'COMMANDER_01 // CLASS: SENIOR FLUTTER ARCHITECT (LVL 37)',
                                overflow: TextOverflow.ellipsis,
                                style: context.bodySmall.copyWith(
                                  fontSize: 13,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                  shadows: [
                                    Shadow(
                                      color: accent.withValues(alpha: 0.55),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (showImage)
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    GamificationController.instance.addXp(
                                      20,
                                      reason: 'High-fived Dash Mascot! 🐦',
                                      uniqueKey: 'dash_mascot_pet',
                                    );
                                  },
                                  child: Tooltip(
                                    message: 'Tap Dash for +20 XP!',
                                    child: Image.asset(
                                      'assets/images/dash/dash1.png',
                                      height: 54,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          "Hi, I'm",
                          style: context.displaySmall.copyWith(
                            fontSize: 22,
                            letterSpacing: 1.5,
                            color:
                                context.primaryColor.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Sivaprasad NK.",
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                fontSize: 60,
                                height: 1.05,
                                letterSpacing: -1.2,
                                shadows: [
                                  Shadow(
                                    color: accent.withValues(alpha: 0.25),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Text(
                            'Flutter Developer & Fitness Enthusiast from Tripunithura, Kerala — navigate the open-air astral HUD below, overclock skill stars, and intercept rogue bugs to level up!',
                            style: context.displaySmall.copyWith(
                              fontSize: 20,
                              height: 1.5,
                              color:
                                  context.primaryColor.withValues(alpha: 0.84),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Open-Air Circular Arc Stat Gauges (Zero Box Containers)
                        Wrap(
                          spacing: 28,
                          runSpacing: 16,
                          children: [
                            _OpenAirStatRing(
                              label: 'FLUTTER & DART',
                              valueText: '98%',
                              progress: 0.98,
                              color: accent,
                            ),
                            _OpenAirStatRing(
                              label: 'CLEAN ARCH & BLOC',
                              valueText: '95%',
                              progress: 0.95,
                              color: secondary,
                            ),
                            const _OpenAirStatRing(
                              label: 'FITNESS STAMINA',
                              valueText: '99%',
                              progress: 0.99,
                              color: Color(0xFF10B981),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        DownloadCvBtn(
                          onExploreProjects: widget.onExploreProjects,
                          onPlayArcade: widget.onPlayArcade,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              const Flexible(
                flex: 5,
                child: OrbitAnimation3(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OpenAirStatRing extends StatelessWidget {
  const _OpenAirStatRing({
    required this.label,
    required this.valueText,
    required this.progress,
    required this.color,
  });

  final String label;
  final String valueText;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          GamificationController.instance.addXp(
            10,
            reason: 'Scanned $label reactor stat!',
            uniqueKey: 'hero_stat_$label',
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CustomPaint(
                painter: _StatArcPainter(
                  progress: progress,
                  color: color,
                  trackColor: context.primaryColor.withValues(alpha: 0.14),
                ),
                child: Center(
                  child: Text(
                    valueText,
                    style: context.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: context.bodySmall.copyWith(
                    fontSize: 11.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'REACTOR ONLINE',
                  style: context.bodySmall.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _StatArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StatArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
