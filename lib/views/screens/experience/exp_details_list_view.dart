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

class _ExpDetailsListViewState extends State<ExpDetailsListView> {
  int _selectedStageIndex = 0;

  void _selectStage(int index, ExperienceDetails exp) {
    final stageNum = exp.order + 1;
    setState(() {
      _selectedStageIndex = index;
    });
    GamificationController.instance.completeQuest('career_chronicler');
    GamificationController.instance.addXp(
      15,
      reason: 'Cleared Stage 0$stageNum: ${exp.title}!',
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

              return PortfolioStyledCard(
                width: double.infinity,
                cyberHeader:
                    '~/odyssey/stage_0${stageNum}_${activeExp.orgName.split(' ').first.toLowerCase()}.log',
                onTap: () => _selectStage(activeIdx, activeExp),
                padding: EdgeInsets.all(isDesktop ? 36 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Interactive Flight-Path Trajectory Selector Bar
                    _buildTrajectoryBar(
                      context,
                      stages,
                      activeIdx,
                      accent,
                      secondary,
                      themeState,
                    ),
                    const SizedBox(height: 28),

                    // 2. Single Cinematic Stage Spotlight Theatre
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.03, 0.0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey(activeIdx),
                        padding: EdgeInsets.all(isDesktop ? 28 : 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent.withValues(
                                alpha: themeState.isDark ? 0.14 : 0.08,
                              ),
                              secondary.withValues(
                                alpha: themeState.isDark ? 0.07 : 0.04,
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: _buildStagePrimaryInfo(
                                      context,
                                      activeExp,
                                      stageNum,
                                      accent,
                                      secondary,
                                      themeState,
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    flex: 5,
                                    child: _buildStageLootCluster(
                                      context,
                                      activeExp,
                                      stageNum,
                                      accent,
                                      secondary,
                                      themeState,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStagePrimaryInfo(
                                    context,
                                    activeExp,
                                    stageNum,
                                    accent,
                                    secondary,
                                    themeState,
                                  ),
                                  const SizedBox(height: 22),
                                  _buildStageLootCluster(
                                    context,
                                    activeExp,
                                    stageNum,
                                    accent,
                                    secondary,
                                    themeState,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTrajectoryBar(
    BuildContext context,
    List<ExperienceDetails> stages,
    int activeIdx,
    Color accent,
    Color secondary,
    ThemeState themeState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timeline_rounded,
                    color: accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'CAREER ODYSSEY FLIGHT-PATH // SELECT STAGE BEACON',
                      style: context.bodySmall.copyWith(
                        fontSize: context.isMobileDevice ? 10.5 : 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: context.primaryColor.withValues(alpha: 0.7),
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
                    final next =
                        (activeIdx - 1 + stages.length) % stages.length;
                    _selectStage(next, stages[next]);
                  },
                  icon: Icon(Icons.arrow_back_rounded, color: accent, size: 20),
                  tooltip: 'Previous Stage',
                ),
                IconButton(
                  onPressed: () {
                    final next = (activeIdx + 1) % stages.length;
                    _selectStage(next, stages[next]);
                  },
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    color: accent,
                    size: 20,
                  ),
                  tooltip: 'Next Stage',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Stack(
          alignment: Alignment.center,
          children: [
            // Glowing connecting track line
            Container(
              height: 3,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.15),
                    accent,
                    secondary,
                    secondary.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            // Stage Beacons along the flight path
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(stages.length, (index) {
                final exp = stages[index];
                final isSelected = index == activeIdx;
                final stageNo = exp.order + 1;
                final shortOrg = exp.orgName.split(' ').first;

                return GestureDetector(
                  onTap: () => _selectStage(index, exp),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.isMobileDevice ? 12 : 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent
                            : context.scaffoldColor.withValues(
                                alpha: themeState.isDark ? 0.92 : 0.96,
                              ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : accent.withValues(alpha: 0.4),
                          width: isSelected ? 2.0 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(
                              alpha: isSelected ? 0.42 : 0.10,
                            ),
                            blurRadius: isSelected ? 18 : 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? (themeState.isDark
                                      ? const Color(0xFF090D16)
                                      : Colors.white)
                                  : accent.withValues(alpha: 0.18),
                            ),
                            child: Text(
                              '0$stageNo',
                              style: context.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? accent : accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                shortOrg,
                                style: context.bodySmall.copyWith(
                                  fontSize: context.isMobileDevice ? 12 : 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? (themeState.isDark
                                          ? const Color(0xFF090D16)
                                          : Colors.white)
                                      : context.primaryColor,
                                ),
                              ),
                              if (!context.isMobileDevice)
                                Text(
                                  exp.startDate,
                                  style: context.bodySmall.copyWith(
                                    fontSize: 10,
                                    color: isSelected
                                        ? (themeState.isDark
                                                ? const Color(0xFF090D16)
                                                : Colors.white)
                                            .withValues(alpha: 0.75)
                                        : context.primaryColor
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStagePrimaryInfo(
    BuildContext context,
    ExperienceDetails activeExp,
    int stageNum,
    Color accent,
    Color secondary,
    ThemeState themeState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: accent.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'STAGE 0$stageNum • ${activeExp.startDate} – ${activeExp.endDate}',
                style: context.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✓ CLEARED (+15 XP)',
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          activeExp.title,
          style: context.displaySmall.copyWith(
            fontSize: context.isLargeDevice ? 30 : 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: secondary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.castle_rounded,
                size: 18,
                color: secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Guild: ${activeExp.orgName}',
                style: context.bodyMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.primaryColor.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStageLootCluster(
    BuildContext context,
    ExperienceDetails activeExp,
    int stageNum,
    Color accent,
    Color secondary,
    ThemeState themeState,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.scaffoldColor.withValues(
          alpha: themeState.isDark ? 0.65 : 0.82,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 8),
              Text(
                'ACQUIRED TECH ARSENAL & LOOT',
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: context.primaryColor.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: activeExp.detailsList.map((desc) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.14),
                      secondary.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 15,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      desc,
                      style: context.bodySmall.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
