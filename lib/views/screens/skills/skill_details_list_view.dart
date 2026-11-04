import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:spnk/domain/entity/skill_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/skills/skills_bloc.dart';
import 'package:spnk/views/bloc/skills/skills_state.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/skills/loading_skills_container.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class SkillDetailsListView extends StatefulWidget {
  const SkillDetailsListView({super.key});

  @override
  State<SkillDetailsListView> createState() => _SkillDetailsListViewState();
}

class _SkillDetailsListViewState extends State<SkillDetailsListView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _selectOrBoostSkill(int index, List<SkillDetails> skills) {
    final skillName = skills[index].title.trim();
    setState(() {
      _selectedIndex = index;
    });
    GamificationController.instance.boostSkill(skillName);
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPad =
        context.isMobileDevice ? 16.0 : context.screenWidth * 0.08;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final accent = themeState.accentColor;
          final secondary = themeState.secondaryAccent;

          return BlocBuilder<SkillDetailsBloc, SkillsState>(
            builder: (context, state) {
              if (state.isLoading || state.skillDetails.isEmpty) {
                return const Center(child: LoadingSkillsContainer());
              }

              final skills = state.skillDetails;
              final activeIndex = _selectedIndex.clamp(0, skills.length - 1);
              final activeSkill = skills[activeIndex];

              return ListenableBuilder(
                listenable: GamificationController.instance,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Open-Air Constellation Telemetry Line (No Box Container)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'ASTRAL SKILL CONSTELLATION // TAP ANY STAR NODE TO OVERCLOCK (+15 XP)',
                              style: context.bodySmall.copyWith(
                                fontSize: context.isMobileDevice ? 10.5 : 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.6,
                                color: accent,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedIndex =
                                        (activeIndex - 1 + skills.length) %
                                            skills.length;
                                  });
                                },
                                icon: Icon(
                                  Icons.chevron_left_rounded,
                                  color: accent,
                                ),
                              ),
                              Text(
                                'STAR 0${activeIndex + 1} / 0${skills.length}',
                                style: context.bodySmall.copyWith(
                                  fontSize: 12,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedIndex =
                                        (activeIndex + 1) % skills.length;
                                  });
                                },
                                icon: Icon(
                                  Icons.chevron_right_rounded,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Open-Air Star Constellation Field (Zero Containers)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final isCompact = maxWidth < 680;
                          final canvasHeight = isCompact ? 500.0 : 540.0;
                          final center = Offset(maxWidth / 2, canvasHeight / 2);
                          final radiusX = isCompact
                              ? (maxWidth * 0.37).clamp(115.0, 210.0)
                              : (maxWidth * 0.36).clamp(200.0, 390.0);
                          final radiusY = isCompact ? 195.0 : 215.0;

                          final nodePositions = List.generate(
                            skills.length,
                            (i) {
                              final angle = (-math.pi / 2) +
                                  (2 * math.pi * i / skills.length);
                              return Offset(
                                center.dx + radiusX * math.cos(angle),
                                center.dy + radiusY * math.sin(angle),
                              );
                            },
                          );

                          return SizedBox(
                            width: maxWidth,
                            height: canvasHeight,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Custom-Painted Constellation Filaments & Reactor Rings
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, _) {
                                      return CustomPaint(
                                        painter: _SkillConstellationPainter(
                                          center: center,
                                          radiusX: radiusX,
                                          radiusY: radiusY,
                                          nodePositions: nodePositions,
                                          selectedIndex: activeIndex,
                                          accent: accent,
                                          secondary: secondary,
                                          phase: _pulseController.value,
                                          isDark: themeState.isDark,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Central Open-Air Astral Core (Zero Box Container)
                                Positioned(
                                  left: center.dx - (isCompact ? 105 : 135),
                                  top: center.dy - (isCompact ? 105 : 135),
                                  width: isCompact ? 210 : 270,
                                  height: isCompact ? 210 : 270,
                                  child: _buildOpenAirCentralCore(
                                    context,
                                    activeSkill,
                                    accent,
                                    secondary,
                                    isCompact,
                                  ),
                                ),

                                // Orbiting Open-Air Star Nodes (Zero Box Containers)
                                ...List.generate(skills.length, (index) {
                                  final skill = skills[index];
                                  final pos = nodePositions[index];
                                  final isSelected = index == activeIndex;
                                  final skillName = skill.title.trim();
                                  final boost = GamificationController.instance
                                      .getSkillBoost(skillName);
                                  final isMax = boost >= 5;
                                  final progress =
                                      (0.75 + (boost * 0.05)).clamp(0.0, 1.0);
                                  final starColor = isMax
                                      ? const Color(0xFFF59E0B)
                                      : (isSelected ? accent : secondary);
                                  final nodeW = isCompact ? 96.0 : 124.0;
                                  final nodeH = isCompact ? 86.0 : 96.0;

                                  return Positioned(
                                    left: pos.dx - nodeW / 2,
                                    top: pos.dy - nodeH / 2,
                                    width: nodeW,
                                    height: nodeH,
                                    child: MouseRegion(
                                      onEnter: (_) {
                                        if (!context.isMobileDevice &&
                                            _selectedIndex != index) {
                                          setState(() {
                                            _selectedIndex = index;
                                          });
                                        }
                                      },
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () =>
                                            _selectOrBoostSkill(index, skills),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: isCompact ? 42 : 50,
                                              height: isCompact ? 42 : 50,
                                              child: CustomPaint(
                                                painter: _StarNodeArcPainter(
                                                  progress: progress,
                                                  color: starColor,
                                                  isSelected: isSelected,
                                                ),
                                                child: Center(
                                                  child: SvgPicture.asset(
                                                    'assets/svg/${skill.iconName}.svg',
                                                    height: isCompact ? 20 : 24,
                                                    width: isCompact ? 20 : 24,
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                      starColor,
                                                      BlendMode.srcIn,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              skillName.toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: context.bodySmall.copyWith(
                                                fontSize: isCompact ? 11 : 12.5,
                                                letterSpacing: 1.1,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? starColor
                                                    : context.primaryColor,
                                                shadows: isSelected
                                                    ? [
                                                        Shadow(
                                                          color: starColor
                                                              .withValues(
                                                            alpha: 0.75,
                                                          ),
                                                          blurRadius: 12,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                            ),
                                            Text(
                                              isMax
                                                  ? '★ MAXED'
                                                  : 'LV.${boost + 1} // ${(progress * 100).toInt()}%',
                                              style: context.bodySmall.copyWith(
                                                fontSize: 9.5,
                                                letterSpacing: 1.1,
                                                fontWeight: FontWeight.bold,
                                                color: starColor.withValues(
                                                  alpha: 0.85,
                                                ),
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
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOpenAirCentralCore(
    BuildContext context,
    SkillDetails activeSkill,
    Color accent,
    Color secondary,
    bool isCompact,
  ) {
    final skillName = activeSkill.title.trim();
    final icon = 'assets/svg/${activeSkill.iconName}.svg';
    final boost = GamificationController.instance.getSkillBoost(skillName);
    final isMax = boost >= 5;
    final progress = (0.75 + (boost * 0.05)).clamp(0.0, 1.0);
    final coreColor = isMax ? const Color(0xFFF59E0B) : accent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => GamificationController.instance.boostSkill(skillName),
      child: CustomPaint(
        painter: _CentralCoreReactorPainter(
          progress: progress,
          color: coreColor,
          secondary: secondary,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              height: isCompact ? 32 : 42,
              width: isCompact ? 32 : 42,
              colorFilter: ColorFilter.mode(
                coreColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              skillName.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.displaySmall.copyWith(
                fontSize: isCompact ? 18 : 24,
                letterSpacing: 1.4,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: coreColor.withValues(alpha: 0.6),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${isMax ? "★ MAXED STAR" : "LVL ${boost + 1}"} // ${(progress * 100).toInt()}% MASTERY',
              style: context.bodySmall.copyWith(
                fontSize: isCompact ? 10 : 11.5,
                letterSpacing: 1.3,
                fontWeight: FontWeight.bold,
                color: coreColor,
              ),
            ),
            const SizedBox(height: 12),
            OpenAirActionTrigger(
              label: isMax ? 'Star Overclocked' : 'Overclock +15 XP',
              icon: isMax ? Icons.auto_awesome_rounded : Icons.bolt_rounded,
              color: isMax ? const Color(0xFF10B981) : coreColor,
              isPrimary: true,
              onTap: () => GamificationController.instance.boostSkill(skillName),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarNodeArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isSelected;

  _StarNodeArcPainter({
    required this.progress,
    required this.color,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = isSelected ? 2.8 : 1.8,
    );
  }

  @override
  bool shouldRepaint(covariant _StarNodeArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.isSelected != isSelected;
}

class _CentralCoreReactorPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color secondary;

  _CentralCoreReactorPainter({
    required this.progress,
    required this.color,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Soft radial reactor glow
    canvas.drawCircle(
      center,
      maxR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: maxR)),
    );

    // Outer mastery ring
    canvas.drawCircle(
      center,
      maxR * 0.88,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxR * 0.88),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.2,
    );
  }

  @override
  bool shouldRepaint(covariant _CentralCoreReactorPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _SkillConstellationPainter extends CustomPainter {
  final Offset center;
  final double radiusX;
  final double radiusY;
  final List<Offset> nodePositions;
  final int selectedIndex;
  final Color accent;
  final Color secondary;
  final double phase;
  final bool isDark;

  _SkillConstellationPainter({
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.nodePositions,
    required this.selectedIndex,
    required this.accent,
    required this.secondary,
    required this.phase,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final orbitPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.16 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      ),
      orbitPaint,
    );

    for (int i = 0; i < nodePositions.length; i++) {
      final pos = nodePositions[i];
      final nextPos = nodePositions[(i + 1) % nodePositions.length];
      final isSelected = i == selectedIndex;

      canvas.drawLine(
        pos,
        nextPos,
        Paint()
          ..color = accent.withValues(alpha: 0.12)
          ..strokeWidth = 1.0,
      );

      canvas.drawLine(
        center,
        pos,
        Paint()
          ..color = isSelected
              ? accent.withValues(alpha: 0.8)
              : accent.withValues(alpha: 0.15)
          ..strokeWidth = isSelected ? 2.2 : 1.0,
      );

      if (isSelected) {
        final t = (phase * 3) % 1.0;
        final pulseOffset = Offset.lerp(center, pos, t)!;
        canvas.drawCircle(
          pulseOffset,
          5.0,
          Paint()
            ..color = accent
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkillConstellationPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.phase != phase ||
        oldDelegate.accent != accent;
  }
}
