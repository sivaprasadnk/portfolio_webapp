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
    if (_selectedIndex == index) {
      GamificationController.instance.boostSkill(skillName);
    } else {
      setState(() {
        _selectedIndex = index;
      });
      GamificationController.instance.boostSkill(skillName);
    }
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
                  return PortfolioStyledCard(
                    width: double.infinity,
                    cyberHeader: '~/constellation/skill_orbital_reactor.sys',
                    padding: EdgeInsets.all(context.isLargeDevice ? 32 : 18),
                    child: Column(
                      children: [
                        // Top Constellation Telemetry Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.16),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.hub_rounded,
                                      size: 18,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'ORBITAL SKILL CONSTELLATION // TAP ANY NODE TO OVERCLOCK',
                                      style: context.bodySmall.copyWith(
                                        fontSize:
                                            context.isMobileDevice ? 10.5 : 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                        color: context.primaryColor
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedIndex = (activeIndex -
                                              1 +
                                              skills.length) %
                                          skills.length;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.chevron_left_rounded,
                                    color: accent,
                                  ),
                                  tooltip: 'Previous Skill Node',
                                ),
                                Text(
                                  '0${activeIndex + 1} / 0${skills.length}',
                                  style: context.bodySmall.copyWith(
                                    fontSize: 12,
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
                                  tooltip: 'Next Skill Node',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Interactive Orbital Constellation Canvas
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth;
                            final isCompact = maxWidth < 680;
                            final canvasHeight = isCompact ? 500.0 : 540.0;
                            final center =
                                Offset(maxWidth / 2, canvasHeight / 2);
                            final radiusX = isCompact
                                ? (maxWidth * 0.37).clamp(115.0, 210.0)
                                : (maxWidth * 0.36).clamp(200.0, 380.0);
                            final radiusY = isCompact ? 195.0 : 210.0;

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
                                  // Animated Constellation Lines & Rings
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

                                  // Central Power Core Inspector
                                  Positioned(
                                    left: center.dx - (isCompact ? 98 : 125),
                                    top: center.dy - (isCompact ? 105 : 125),
                                    width: isCompact ? 196 : 250,
                                    height: isCompact ? 210 : 250,
                                    child: _buildCentralPowerCore(
                                      context,
                                      activeSkill,
                                      accent,
                                      secondary,
                                      themeState,
                                      isCompact,
                                    ),
                                  ),

                                  // Orbiting Skill Nodes
                                  ...List.generate(skills.length, (index) {
                                    final skill = skills[index];
                                    final pos = nodePositions[index];
                                    final isSelected = index == activeIndex;
                                    final skillName = skill.title.trim();
                                    final boost = GamificationController
                                        .instance
                                        .getSkillBoost(skillName);
                                    final isMax = boost >= 5;
                                    final nodeW = isCompact ? 86.0 : 118.0;
                                    final nodeH = isCompact ? 74.0 : 84.0;

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
                                          onTap: () =>
                                              _selectOrBoostSkill(index, skills),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 260),
                                            curve: Curves.easeOutBack,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? accent.withValues(
                                                      alpha: themeState.isDark
                                                          ? 0.26
                                                          : 0.18,
                                                    )
                                                  : context.scaffoldColor
                                                      .withValues(
                                                      alpha: themeState.isDark
                                                          ? 0.85
                                                          : 0.92,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: isMax
                                                    ? const Color(0xFFF59E0B)
                                                    : isSelected
                                                        ? accent
                                                        : accent.withValues(
                                                            alpha: 0.3,
                                                          ),
                                                width: isSelected ? 2.0 : 1.1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (isMax
                                                          ? const Color(
                                                              0xFFF59E0B)
                                                          : accent)
                                                      .withValues(
                                                    alpha: isSelected
                                                        ? 0.38
                                                        : 0.10,
                                                  ),
                                                  blurRadius:
                                                      isSelected ? 18 : 8,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SvgPicture.asset(
                                                  'assets/svg/${skill.iconName}.svg',
                                                  height: isCompact ? 20 : 24,
                                                  width: isCompact ? 20 : 24,
                                                  colorFilter: ColorFilter.mode(
                                                    isMax
                                                        ? const Color(
                                                            0xFFF59E0B)
                                                        : accent,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  skillName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: context.bodySmall
                                                      .copyWith(
                                                    fontSize:
                                                        isCompact ? 11 : 12.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: context.primaryColor,
                                                  ),
                                                ),
                                                Text(
                                                  isMax
                                                      ? '★ MAX'
                                                      : 'Lv.${boost + 1}',
                                                  style: context.bodySmall
                                                      .copyWith(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isMax
                                                        ? const Color(
                                                            0xFFF59E0B)
                                                        : secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
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
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCentralPowerCore(
    BuildContext context,
    SkillDetails activeSkill,
    Color accent,
    Color secondary,
    ThemeState themeState,
    bool isCompact,
  ) {
    final skillName = activeSkill.title.trim();
    final icon = 'assets/svg/${activeSkill.iconName}.svg';
    final boost = GamificationController.instance.getSkillBoost(skillName);
    final isMax = boost >= 5;
    final progress = (0.75 + (boost * 0.05)).clamp(0.0, 1.0);
    final coreColor = isMax ? const Color(0xFFF59E0B) : accent;

    return GestureDetector(
      onTap: () => GamificationController.instance.boostSkill(skillName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(isCompact ? 14 : 20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              coreColor.withValues(alpha: themeState.isDark ? 0.24 : 0.16),
              context.scaffoldColor.withValues(
                alpha: themeState.isDark ? 0.92 : 0.96,
              ),
            ],
          ),
          border: Border.all(
            color: coreColor.withValues(alpha: 0.65),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: coreColor.withValues(alpha: 0.32),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: isCompact ? 56 : 72,
                  height: isCompact ? 56 : 72,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4.5,
                    backgroundColor:
                        context.primaryColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(coreColor),
                  ),
                ),
                SvgPicture.asset(
                  icon,
                  height: isCompact ? 26 : 34,
                  width: isCompact ? 26 : 34,
                  colorFilter: ColorFilter.mode(
                    coreColor,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              skillName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.displaySmall.copyWith(
                fontSize: isCompact ? 17 : 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${isMax ? "★ MAXED" : "LVL ${boost + 1}"} • ${(progress * 100).toInt()}% MASTERY',
              style: context.bodySmall.copyWith(
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.bold,
                color: coreColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isMax
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : coreColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isMax ? '✓ OVERCLOCKED' : '⚡ BOOST +15 XP',
                style: context.bodySmall.copyWith(
                  fontSize: isCompact ? 9.5 : 10.5,
                  fontWeight: FontWeight.bold,
                  color: isMax
                      ? const Color(0xFF10B981)
                      : (themeState.isDark
                          ? const Color(0xFF090D16)
                          : Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    // Draw outer orbital ellipse
    final orbitPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.18 : 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      ),
      orbitPaint,
    );

    // Draw inner harmonic ellipse
    final innerOrbitPaint = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.12 : 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radiusX * 1.35,
        height: radiusY * 1.35,
      ),
      innerOrbitPaint,
    );

    // Draw constellation spokes & perimeter links
    for (int i = 0; i < nodePositions.length; i++) {
      final pos = nodePositions[i];
      final nextPos = nodePositions[(i + 1) % nodePositions.length];
      final isSelected = i == selectedIndex;

      // Perimeter web line
      final webPaint = Paint()
        ..color = accent.withValues(alpha: 0.10)
        ..strokeWidth = 1.0;
      canvas.drawLine(pos, nextPos, webPaint);

      // Spoke from center core to node
      final spokePaint = Paint()
        ..color = isSelected
            ? accent.withValues(alpha: 0.75)
            : accent.withValues(alpha: 0.16)
        ..strokeWidth = isSelected ? 2.4 : 1.1;
      canvas.drawLine(center, pos, spokePaint);

      // Animated energy pulse orb along the active spoke
      if (isSelected) {
        final t = (phase * 3) % 1.0;
        final pulseOffset = Offset.lerp(center, pos, t)!;
        final pulsePaint = Paint()
          ..color = accent
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(pulseOffset, 5.0, pulsePaint);
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
