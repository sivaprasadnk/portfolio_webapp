import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/domain/entity/experience_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/experience/exp_details_bloc.dart';
import 'package:spnk/views/bloc/experience/exp_details_state.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/experience/loading_exp_container.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class ExpDetailsListView extends StatefulWidget {
  const ExpDetailsListView({super.key});

  @override
  State<ExpDetailsListView> createState() => _ExpDetailsListViewState();
}

class _ExpDetailsListViewState extends State<ExpDetailsListView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  int _selectedStageIndex = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _selectStage(int index, ExperienceDetails exp) {
    final stageNum = exp.order + 1;
    setState(() {
      _selectedStageIndex = index;
    });
    GamificationController.instance.completeQuest('career_chronicler');
    GamificationController.instance.addXp(
      15,
      reason: 'Activated Warp Gate 0$stageNum: ${exp.title}!',
      uniqueKey: 'exp_stage_$stageNum',
    );
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

          return BlocBuilder<ExpDetailsBloc, ExpDetailsState>(
            builder: (context, state) {
              if (state.isLoading || state.expList.isEmpty) {
                return const Center(child: LoadingExpContainer());
              }

              final stages = state.expList;
              final activeIdx = _selectedStageIndex.clamp(0, stages.length - 1);
              final activeExp = stages[activeIdx];
              final stageNum = activeExp.order + 1;
              final isDesktop = context.isLargeDevice;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Open-Air Sine-Wave Chrono Warp Path (Zero Box Containers)
                  _buildOpenAirWarpWave(
                    context,
                    stages,
                    activeIdx,
                    accent,
                    secondary,
                  ),
                  const SizedBox(height: 36),

                  // 2. Open-Air Holographic Stage Projection (Zero Box Containers)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 340),
                    child: CustomPaint(
                      key: ValueKey(activeIdx),
                      painter: _StageHorizonPainter(
                        accent: accent,
                        secondary: secondary,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: _buildOpenAirStageInfo(
                                      context,
                                      activeExp,
                                      stageNum,
                                      accent,
                                      secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 44),
                                  Expanded(
                                    flex: 5,
                                    child: _buildOpenAirSkillRunes(
                                      context,
                                      activeExp,
                                      stageNum,
                                      accent,
                                      secondary,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildOpenAirStageInfo(
                                    context,
                                    activeExp,
                                    stageNum,
                                    accent,
                                    secondary,
                                  ),
                                  const SizedBox(height: 28),
                                  _buildOpenAirSkillRunes(
                                    context,
                                    activeExp,
                                    stageNum,
                                    accent,
                                    secondary,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOpenAirWarpWave(
    BuildContext context,
    List<ExperienceDetails> stages,
    int activeIdx,
    Color accent,
    Color secondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'CHRONO WARP ODYSSEY // SELECT STAR-GATE BEACON (+15 XP)',
                style: context.bodySmall.copyWith(
                  fontSize: context.isMobileDevice ? 10.5 : 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8,
                  color: accent,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    final next =
                        (activeIdx - 1 + stages.length) % stages.length;
                    _selectStage(next, stages[next]);
                  },
                  icon: Icon(Icons.west_rounded, color: accent, size: 18),
                ),
                IconButton(
                  onPressed: () {
                    final next = (activeIdx + 1) % stages.length;
                    _selectStage(next, stages[next]);
                  },
                  icon: Icon(Icons.east_rounded, color: accent, size: 18),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 86,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ChronoWavePainter(
                        phase: _waveController.value,
                        accent: accent,
                        secondary: secondary,
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(stages.length, (index) {
                  final exp = stages[index];
                  final isSelected = index == activeIdx;
                  final stageNo = exp.order + 1;
                  final shortOrg = exp.orgName.split(' ').first.toUpperCase();

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _selectStage(index, exp),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'GATE 0$stageNo',
                            style: context.bodySmall.copyWith(
                              fontSize: 10.5,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? accent
                                  : context.primaryColor.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            isSelected
                                ? Icons.flare_rounded
                                : Icons.radio_button_checked_rounded,
                            size: isSelected ? 26 : 18,
                            color: isSelected ? accent : secondary,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            shortOrg,
                            style: context.bodySmall.copyWith(
                              fontSize: context.isMobileDevice ? 12 : 14,
                              letterSpacing: 1.3,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? accent
                                  : context.primaryColor
                                      .withValues(alpha: 0.75),
                              shadows: isSelected
                                  ? [
                                      Shadow(
                                        color: accent.withValues(alpha: 0.8),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOpenAirStageInfo(
    BuildContext context,
    ExperienceDetails activeExp,
    int stageNum,
    Color accent,
    Color secondary,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Giant Sculptural Open-Air Stage Watermark
        Positioned(
          left: -8,
          top: -28,
          child: IgnorePointer(
            child: Text(
              '0$stageNum',
              style: context.displayMedium.copyWith(
                fontSize: context.isLargeDevice ? 110 : 80,
                fontWeight: FontWeight.bold,
                color: accent.withValues(alpha: 0.10),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WARP GATE 0$stageNum // ${activeExp.startDate.toUpperCase()} — ${activeExp.endDate.toUpperCase()}',
              style: context.bodySmall.copyWith(
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              activeExp.title,
              style: context.displaySmall.copyWith(
                fontSize: context.isLargeDevice ? 36 : 26,
                height: 1.15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.castle_rounded,
                  size: 18,
                  color: secondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GUILD: ${activeExp.orgName.toUpperCase()}',
                    style: context.bodyMedium.copyWith(
                      fontSize: 16,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.bold,
                      color: secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OpenAirActionTrigger(
              label: 'Synchronize Stage Telemetry (+15 XP)',
              icon: Icons.bolt_rounded,
              color: accent,
              onTap: () => _selectStage(_selectedStageIndex, activeExp),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpenAirSkillRunes(
    BuildContext context,
    ExperienceDetails activeExp,
    int stageNum,
    Color accent,
    Color secondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACQUIRED STAR-RUNES & ARSENAL',
          style: context.bodySmall.copyWith(
            fontSize: 11.5,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
            color: context.primaryColor.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: activeExp.detailsList.map((desc) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Text(
                  desc.toUpperCase(),
                  style: context.bodySmall.copyWith(
                    fontSize: 14,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor.withValues(alpha: 0.9),
                    shadows: [
                      Shadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ChronoWavePainter extends CustomPainter {
  final double phase;
  final Color accent;
  final Color secondary;

  _ChronoWavePainter({
    required this.phase,
    required this.accent,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final path = Path();
    for (double x = 0; x <= size.width; x += 6) {
      final y = cy +
          10 * math.sin((x / size.width * 2 * math.pi) + (phase * 2 * math.pi));
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0.1),
          accent.withValues(alpha: 0.65),
          secondary.withValues(alpha: 0.65),
          secondary.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _ChronoWavePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.accent != accent;
}

class _StageHorizonPainter extends CustomPainter {
  final Color accent;
  final Color secondary;

  _StageHorizonPainter({required this.accent, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0.5),
          secondary.withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1.2;

    canvas.drawLine(const Offset(0, 0), Offset(size.width * 0.75, 0), paint);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width * 0.45, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _StageHorizonPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
