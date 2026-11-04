import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/domain/entity/project_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/project/project_bloc.dart';
import 'package:spnk/views/bloc/project/project_state.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/projects/loading_project_container.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectListView extends StatefulWidget {
  const ProjectListView({super.key});

  @override
  State<ProjectListView> createState() => _ProjectListViewState();
}

class _ProjectListViewState extends State<ProjectListView> {
  int _selectedMissionIndex = 0;

  Future<void> _launchUrlTarget(ProjectDetails project, String url) async {
    if (url.isEmpty) return;
    GamificationController.instance.completeQuest('boss_raider');
    GamificationController.instance.addXp(
      20,
      reason: 'Raided Mission: ${project.projName}!',
      uniqueKey: 'proj_${project.projName}',
    );
    await launchUrl(Uri.parse(url));
  }

  Future<void> _launchPrimaryMission(ProjectDetails project) async {
    GamificationController.instance.completeQuest('boss_raider');
    GamificationController.instance.addXp(
      20,
      reason: 'Raided Mission: ${project.projName}!',
      uniqueKey: 'proj_${project.projName}',
    );
    final containsPlayStoreUrl = project.playStoreUrl.isNotEmpty;
    final containsWebUrl = project.webUrl.isNotEmpty;
    if (containsPlayStoreUrl && containsWebUrl) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await launchUrl(Uri.parse(project.playStoreUrl));
      } else {
        await launchUrl(Uri.parse(project.webUrl));
      }
    } else if (containsPlayStoreUrl) {
      await launchUrl(Uri.parse(project.playStoreUrl));
    } else if (containsWebUrl) {
      await launchUrl(Uri.parse(project.webUrl));
    }
  }

  void _selectMission(int index, List<ProjectDetails> projects) {
    setState(() {
      _selectedMissionIndex = (index + projects.length) % projects.length;
    });
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

          return BlocBuilder<ProjectBloc, ProjectState>(
            builder: (context, state) {
              if (state.isLoading || state.projectList.isEmpty) {
                return const Center(child: LoadingProjectContainer());
              }

              final projects = state.projectList;
              final activeIdx =
                  _selectedMissionIndex.clamp(0, projects.length - 1);
              final activeProject = projects[activeIdx];
              final nextProject = projects[(activeIdx + 1) % projects.length];
              final isDesktop = context.isLargeDevice;

              return PortfolioStyledCard(
                width: double.infinity,
                cyberHeader:
                    '~/missions/deck_0${activeIdx + 1}_${activeProject.projName.toLowerCase().replaceAll(' ', '_')}.quest',
                padding: EdgeInsets.all(isDesktop ? 36 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Mission Selector Orbit Dock
                    _buildMissionOrbitDock(
                      context,
                      projects,
                      activeIdx,
                      accent,
                      secondary,
                      themeState,
                    ),
                    const SizedBox(height: 28),

                    // 2. 3D-Perspective Stacked Mission Spotlight Stage
                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // Subtle 3D Back-Deck Depth Layer 2
                        Transform.translate(
                          offset: const Offset(0, 18),
                          child: Transform.scale(
                            scale: 0.94,
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: secondary.withValues(
                                  alpha: themeState.isDark ? 0.06 : 0.04,
                                ),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: secondary.withValues(alpha: 0.16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Subtle 3D Back-Deck Depth Layer 1
                        Transform.translate(
                          offset: const Offset(0, 9),
                          child: Transform.scale(
                            scale: 0.97,
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: accent.withValues(
                                  alpha: themeState.isDark ? 0.08 : 0.05,
                                ),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.22),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Active Foreground Mission Stage
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 360),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.96,
                                  end: 1.0,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: _buildActiveMissionStage(
                            context,
                            activeProject,
                            nextProject,
                            activeIdx,
                            projects.length,
                            accent,
                            secondary,
                            themeState,
                            isDesktop,
                            onNextMission: () =>
                                _selectMission(activeIdx + 1, projects),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMissionOrbitDock(
    BuildContext context,
    List<ProjectDetails> projects,
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      color: accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'HOLOGRAPHIC MISSION DECK // SELECT ACTIVE DEPLOYMENT',
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
                  onPressed: () => _selectMission(activeIdx - 1, projects),
                  icon: Icon(Icons.chevron_left_rounded, color: accent),
                  tooltip: 'Previous Mission',
                ),
                Text(
                  '0${activeIdx + 1} / 0${projects.length}',
                  style: context.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                IconButton(
                  onPressed: () => _selectMission(activeIdx + 1, projects),
                  icon: Icon(Icons.chevron_right_rounded, color: accent),
                  tooltip: 'Next Mission',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(projects.length, (index) {
              final proj = projects[index];
              final isSelected = index == activeIdx;
              final hasPlayStore = proj.playStoreUrl.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () => _selectMission(index, projects),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 16 : 13,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent
                          : context.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? accent
                            : accent.withValues(alpha: 0.25),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasPlayStore
                              ? Icons.sports_esports_rounded
                              : Icons.public_rounded,
                          size: 15,
                          color: isSelected
                              ? (themeState.isDark
                                  ? const Color(0xFF090D16)
                                  : Colors.white)
                              : accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '0${index + 1} • ${proj.projName}',
                          style: context.bodySmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? (themeState.isDark
                                    ? const Color(0xFF090D16)
                                    : Colors.white)
                                : context.primaryColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveMissionStage(
    BuildContext context,
    ProjectDetails project,
    ProjectDetails nextProject,
    int activeIdx,
    int totalCount,
    Color accent,
    Color secondary,
    ThemeState themeState,
    bool isDesktop, {
    required VoidCallback onNextMission,
  }) {
    final hasPlayStore = project.playStoreUrl.isNotEmpty;
    final hasWeb = project.webUrl.isNotEmpty;
    final hasBoth = hasPlayStore && hasWeb;

    return Container(
      key: ValueKey(project.projName),
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 32 : 20),
      decoration: BoxDecoration(
        color: context.scaffoldColor.withValues(
          alpha: themeState.isDark ? 0.90 : 0.96,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: accent.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: themeState.isDark ? 0.18 : 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 7,
                  child: _buildMissionBriefing(
                    context,
                    project,
                    activeIdx,
                    accent,
                    secondary,
                    themeState,
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 5,
                  child: _buildMissionLaunchPortal(
                    context,
                    project,
                    nextProject,
                    hasPlayStore,
                    hasWeb,
                    hasBoth,
                    accent,
                    secondary,
                    themeState,
                    onNextMission: onNextMission,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMissionBriefing(
                  context,
                  project,
                  activeIdx,
                  accent,
                  secondary,
                  themeState,
                ),
                const SizedBox(height: 24),
                _buildMissionLaunchPortal(
                  context,
                  project,
                  nextProject,
                  hasPlayStore,
                  hasWeb,
                  hasBoth,
                  accent,
                  secondary,
                  themeState,
                  onNextMission: onNextMission,
                ),
              ],
            ),
    );
  }

  Widget _buildMissionBriefing(
    BuildContext context,
    ProjectDetails project,
    int activeIdx,
    Color accent,
    Color secondary,
    ThemeState themeState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'MISSION 0${activeIdx + 1} // S-RANK • +60 XP',
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
            ...project.techStackList.map((tool) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: themeState.isDark ? 0.16 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  tool,
                  style: context.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          project.projName,
          style: context.displaySmall.copyWith(
            fontSize: context.isLargeDevice ? 32 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...project.descList.map((desc) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 14,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    desc,
                    style: context.bodyMedium.copyWith(
                      fontSize: 16.5,
                      height: 1.45,
                      color: context.primaryColor.withValues(alpha: 0.88),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMissionLaunchPortal(
    BuildContext context,
    ProjectDetails project,
    ProjectDetails nextProject,
    bool hasPlayStore,
    bool hasWeb,
    bool hasBoth,
    Color accent,
    Color secondary,
    ThemeState themeState, {
    required VoidCallback onNextMission,
  }) {
    final radius =
        themeState.portfolioStyle == PortfolioStyle.cyber ? 8.0 : 999.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: themeState.isDark ? 0.16 : 0.10),
            secondary.withValues(alpha: themeState.isDark ? 0.10 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasBoth
                    ? Icons.devices_rounded
                    : (hasPlayStore
                        ? Icons.android_rounded
                        : Icons.language_rounded),
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Text(
                hasBoth
                    ? 'MULTI-PLATFORM PORTAL'
                    : (hasPlayStore
                        ? 'ANDROID BOSS ARENA'
                        : 'WEB PORTAL MISSION'),
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasBoth) ...[
            InkWell(
              onTap: () => _launchUrlTarget(project, project.webUrl),
              borderRadius: BorderRadius.circular(radius),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Launch Web App',
                      style: context.bodySmall.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: themeState.isDark
                            ? const Color(0xFF090D16)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.rocket_launch_rounded,
                      size: 16,
                      color: themeState.isDark
                          ? const Color(0xFF090D16)
                          : Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _launchUrlTarget(project, project.playStoreUrl),
              borderRadius: BorderRadius.circular(radius),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: themeState.isDark ? 0.16 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.android_rounded,
                      size: 17,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Get on Google Play',
                      style: context.bodySmall.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            InkWell(
              onTap: () => _launchPrimaryMission(project),
              borderRadius: BorderRadius.circular(radius),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Launch Mission',
                      style: context.bodySmall.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: themeState.isDark
                            ? const Color(0xFF090D16)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.rocket_launch_rounded,
                      size: 16,
                      color: themeState.isDark
                          ? const Color(0xFF090D16)
                          : Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Divider(color: themeState.cardBorderColor, height: 1),
          const SizedBox(height: 12),
          InkWell(
            onTap: onNextMission,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Up Next: ${nextProject.projName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall.copyWith(
                        fontSize: 12.5,
                        color: context.primaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cycle Deck',
                        style: context.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: secondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
