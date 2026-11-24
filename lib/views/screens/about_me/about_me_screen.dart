import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/bloc/about_me/about_me_bloc.dart';
import 'package:spnk/views/bloc/about_me/about_me_state.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/about_me/loading_abt_me_container.dart';
import 'package:spnk/views/screens/screen_section.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';

class AboutMeScreen extends StatefulWidget {
  const AboutMeScreen({super.key});

  @override
  State<AboutMeScreen> createState() => _AboutMeScreenState();
}

class _AboutMeScreenState extends State<AboutMeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _compassController;
  int _selectedPerkIndex = 0;

  static const _perks = [
    (
      Icons.bolt_rounded,
      '5 Years Exp',
      'AI Coding & Flutter',
      'LVL 50',
      '5 years engineering production Android, iOS, and Web apps, now actively focused on AI-assisted coding and intelligent tools.',
    ),
    (
      Icons.layers_rounded,
      'Architecture',
      'Clean Architecture & BLoC',
      'S-TIER',
      'Modular domain-driven codebases using BLoC, dependency injection, reactive streams, and testable state machines.',
    ),
    (
      Icons.public_rounded,
      'Open Source',
      'Pub.dev & VS Code Themes',
      'GUILD',
      'Published reusable Flutter packages on pub.dev and crafted developer tooling and themes for the global community.',
    ),
    (
      Icons.directions_run_rounded,
      'Endurance',
      'Gym & Regular Running',
      '99 STA',
      'Endurance athlete training consistently in the gym and running regularly with discipline from Ernakulam.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _compassController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _compassController.dispose();
    super.dispose();
  }

  void _selectPerk(int index) {
    final item = _perks[index];
    setState(() {
      _selectedPerkIndex = index;
    });
    GamificationController.instance.completeQuest('lore_reader');
    GamificationController.instance.addXp(
      15,
      reason: 'Aligned ${item.$2} Star Perk (${item.$4})!',
      uniqueKey: 'attr_${item.$2}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPad =
        context.isMobileDevice ? 16.0 : context.screenWidth * 0.08;

    return ScreenSection(
      title: Screen.aboutMe.screenTitle,
      details: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final accent = themeState.accentColor;
            final secondary = themeState.secondaryAccent;

            return BlocBuilder<AboutMeBloc, AboutMeState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const LoadingAbtMeContainer();
                }

                final activePerk = _perks[_selectedPerkIndex];
                final isDesktop = context.isLargeDevice;

                return isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildOpenAirNarrative(
                              context,
                              state.content.trim(),
                              accent,
                              secondary,
                            ),
                          ),
                          const SizedBox(width: 48),
                          Expanded(
                            flex: 5,
                            child: _buildOpenAirPerkCompass(
                              context,
                              activePerk,
                              accent,
                              secondary,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOpenAirNarrative(
                            context,
                            state.content.trim(),
                            accent,
                            secondary,
                          ),
                          const SizedBox(height: 36),
                          _buildOpenAirPerkCompass(
                            context,
                            activePerk,
                            accent,
                            secondary,
                          ),
                        ],
                      );
              },
            );
          },
        ),
      ),
      imageName: '',
    );
  }

  Widget _buildOpenAirNarrative(
    BuildContext context,
    String narrative,
    Color accent,
    Color secondary,
  ) {
    return CustomPaint(
      painter: _LoreSpinePainter(accent: accent, secondary: secondary),
      child: Padding(
        padding: const EdgeInsets.only(left: 24, top: 6, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  color: accent,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'ORIGIN CODEX // SPAWN: TRIPUNITHURA, KERALA, INDIA',
                    style: context.bodySmall.copyWith(
                      fontSize: 12,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              narrative,
              style: context.bodyLarge.copyWith(
                height: 1.7,
                fontSize: context.isLargeDevice ? 20 : 17,
                color: context.primaryColor.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenAirPerkCompass(
    BuildContext context,
    (IconData, String, String, String, String) activePerk,
    Color accent,
    Color secondary,
  ) {
    const double compassSize = 260;
    const Offset center = Offset(compassSize / 2, compassSize / 2);
    const double radius = 92;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'ASTRAL PERK COMPASS // TAP ANY STAR (+15 XP)',
          style: context.bodySmall.copyWith(
            fontSize: 11,
            letterSpacing: 1.8,
            fontWeight: FontWeight.bold,
            color: secondary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: compassSize,
          height: compassSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _compassController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _PerkCompassPainter(
                        phase: _compassController.value,
                        selectedIndex: _selectedPerkIndex,
                        accent: accent,
                        secondary: secondary,
                      ),
                    );
                  },
                ),
              ),
              // Center Active Perk Readout (Open-Air, No Box)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    activePerk.$1,
                    color: accent,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activePerk.$4,
                    style: context.bodySmall.copyWith(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.bold,
                      color: secondary,
                      shadows: [
                        Shadow(
                          color: secondary.withValues(alpha: 0.7),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 4 Orbiting Perk Star Beacons in Open Space
              ...List.generate(_perks.length, (index) {
                final item = _perks[index];
                final isSelected = index == _selectedPerkIndex;
                final angle = (-math.pi / 2) + (index * math.pi / 2);
                final pos = Offset(
                  center.dx + radius * math.cos(angle),
                  center.dy + radius * math.sin(angle),
                );

                return Positioned(
                  left: pos.dx - 46,
                  top: pos.dy - 24,
                  width: 92,
                  height: 48,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _selectPerk(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.$1,
                            size: isSelected ? 22 : 18,
                            color: isSelected
                                ? accent
                                : context.primaryColor.withValues(alpha: 0.55),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$2.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.bodySmall.copyWith(
                              fontSize: 10.5,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? accent
                                  : context.primaryColor.withValues(alpha: 0.7),
                              shadows: isSelected
                                  ? [
                                      Shadow(
                                        color: accent.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Column(
            key: ValueKey(_selectedPerkIndex),
            children: [
              Text(
                '${activePerk.$2.toUpperCase()} // ${activePerk.$3.toUpperCase()}',
                textAlign: TextAlign.center,
                style: context.displaySmall.copyWith(
                  fontSize: 18,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                activePerk.$5,
                textAlign: TextAlign.center,
                style: context.bodyMedium.copyWith(
                  fontSize: 15.5,
                  height: 1.5,
                  color: context.primaryColor.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoreSpinePainter extends CustomPainter {
  final Color accent;
  final Color secondary;

  _LoreSpinePainter({required this.accent, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent,
          secondary,
          secondary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 4, size.height))
      ..strokeWidth = 2.0;

    canvas.drawLine(const Offset(2, 0), Offset(2, size.height), linePaint);
    canvas.drawCircle(const Offset(2, 12), 4.5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _LoreSpinePainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _PerkCompassPainter extends CustomPainter {
  final double phase;
  final int selectedIndex;
  final Color accent;
  final Color secondary;

  _PerkCompassPainter({
    required this.phase,
    required this.selectedIndex,
    required this.accent,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Outer & inner compass rings
    final ringPaint = Paint()
      ..color = accent.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(center, 92, ringPaint);
    canvas.drawCircle(
      center,
      46,
      Paint()
        ..color = secondary.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Pointer beam to selected perk star
    final targetAngle = (-math.pi / 2) + (selectedIndex * math.pi / 2);
    final targetPos = Offset(
      center.dx + 72 * math.cos(targetAngle),
      center.dy + 72 * math.sin(targetAngle),
    );
    canvas.drawLine(
      center,
      targetPos,
      Paint()
        ..color = accent.withValues(alpha: 0.8)
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _PerkCompassPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.phase != phase ||
      oldDelegate.accent != accent;
}
