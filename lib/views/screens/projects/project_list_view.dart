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
      reason: 'Launched Mission Portal: ${project.projName}!',
      uniqueKey: 'proj_${project.projName}',
    );
    await launchUrl(Uri.parse(url));
  }

  Future<void> _launchPrimaryMission(ProjectDetails project) async {
    GamificationController.instance.completeQuest('boss_raider');
    GamificationController.instance.addXp(
      20,
      reason: 'Launched Mission Portal: ${project.projName}!',
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Open-Air Laser Horizon Mission Beacons (Zero Box Containers)
                  _buildOpenAirMissionHorizon(
                    context,
                    projects,
                    activeIdx,
                    accent,
                    secondary,
                  ),
                  const SizedBox(height: 36),

                  // 2. Open-Air Holographic Mission Projector (Zero Box Containers)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 340),
                    child: CustomPaint(
                      key: ValueKey(activeProject.projName),
                      painter: _HologramProjectorPainter(
                        accent: accent,
                        secondary: secondary,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 28 : 12,
                          vertical: 24,
                        ),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _buildOpenAirMissionBriefing(
                                      context,
                                      activeProject,
                                      activeIdx,
                                      accent,
                                      secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                  Expanded(
                                    flex: 5,
                                    child: _buildOpenAirPortalControls(
                                      context,
                                      activeProject,
                                      nextProject,
                                      accent,
                                      secondary,
                                      onNextMission: () =>
                                          _selectMission(activeIdx + 1, projects),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildOpenAirMissionBriefing(
                                    context,
                                    activeProject,
                                    activeIdx,
                                    accent,
                                    secondary,
                                  ),
                                  const SizedBox(height: 28),
                                  _buildOpenAirPortalControls(
                                    context,
                                    activeProject,
                                    nextProject,
                                    accent,
                                    secondary,
                                    onNextMission: () =>
                                        _selectMission(activeIdx + 1, projects),
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

  Widget _buildOpenAirMissionHorizon(
    BuildContext context,
    List<ProjectDetails> projects,
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
                'HOLOGRAPHIC MISSION PROJECTOR // SELECT DEPLOYMENT BEACON',
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
                  onPressed: () => _selectMission(activeIdx - 1, projects),
                  icon: Icon(Icons.west_rounded, color: accent, size: 18),
                ),
                Text(
                  '0${activeIdx + 1} / 0${projects.length}',
                  style: context.bodySmall.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                IconButton(
                  onPressed: () => _selectMission(activeIdx + 1, projects),
                  icon: Icon(Icons.east_rounded, color: accent, size: 18),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(projects.length, (index) {
              final proj = projects[index];
              final isSelected = index == activeIdx;

              return Padding(
                padding: const EdgeInsets.only(right: 28),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _selectMission(index, projects),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.flare_rounded
                                  : Icons.circle_outlined,
                              size: isSelected ? 16 : 11,
                              color: isSelected
                                  ? accent
                                  : context.primaryColor.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '0${index + 1} // ${proj.projName.toUpperCase()}',
                              style: context.bodySmall.copyWith(
                                fontSize: 13,
                                letterSpacing: 1.4,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? accent
                                    : context.primaryColor
                                        .withValues(alpha: 0.62),
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
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          height: 2,
                          width: isSelected ? 64 : 0,
                          color: accent,
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

  Widget _buildOpenAirMissionBriefing(
    BuildContext context,
    ProjectDetails project,
    int activeIdx,
    Color accent,
    Color secondary,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -10,
          top: -30,
          child: IgnorePointer(
            child: Text(
              'M0${activeIdx + 1}',
              style: context.displayMedium.copyWith(
                fontSize: context.isLargeDevice ? 100 : 72,
                fontWeight: FontWeight.bold,
                color: accent.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '★ S-RANK MISSION (+60 XP)',
                  style: context.bodySmall.copyWith(
                    fontSize: 11.5,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                ...project.techStackList.map((tool) {
                  return Text(
                    '#${tool.toUpperCase()}',
                    style: context.bodySmall.copyWith(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              project.projName,
              style: context.displaySmall.copyWith(
                fontSize: context.isLargeDevice ? 38 : 28,
                fontWeight: FontWeight.bold,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 18),
            ...project.descList.map((desc) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        desc,
                        style: context.bodyMedium.copyWith(
                          fontSize: 17,
                          height: 1.5,
                          color: context.primaryColor.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildOpenAirPortalControls(
    BuildContext context,
    ProjectDetails project,
    ProjectDetails nextProject,
    Color accent,
    Color secondary, {
    required VoidCallback onNextMission,
  }) {
    final hasPlayStore = project.playStoreUrl.isNotEmpty;
    final hasWeb = project.webUrl.isNotEmpty;
    final hasBoth = hasPlayStore && hasWeb;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasBoth
              ? 'DUAL-VECTOR PORTAL READY // ANDROID & WEB'
              : (hasPlayStore
                  ? 'ANDROID BOSS PORTAL READY'
                  : 'WEB PORTAL READY'),
          style: context.bodySmall.copyWith(
            fontSize: 11.5,
            letterSpacing: 1.8,
            fontWeight: FontWeight.bold,
            color: secondary,
          ),
        ),
        const SizedBox(height: 18),
        if (hasBoth) ...[
          OpenAirActionTrigger(
            label: 'Launch Web App Portal',
            icon: Icons.rocket_launch_rounded,
            color: accent,
            isPrimary: true,
            onTap: () => _launchUrlTarget(project, project.webUrl),
          ),
          const SizedBox(height: 14),
          OpenAirActionTrigger(
            label: 'Google Play Store',
            icon: Icons.android_rounded,
            color: secondary,
            onTap: () => _launchUrlTarget(project, project.playStoreUrl),
          ),
        ] else
          OpenAirActionTrigger(
            label: 'Launch Mission Portal',
            icon: Icons.rocket_launch_rounded,
            color: accent,
            isPrimary: true,
            onTap: () => _launchPrimaryMission(project),
          ),
        const SizedBox(height: 22),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onNextMission,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NEXT BEACON: ${nextProject.projName.toUpperCase()}',
                  style: context.bodySmall.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.east_rounded,
                  size: 16,
                  color: accent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HologramProjectorPainter extends CustomPainter {
  final Color accent;
  final Color secondary;

  _HologramProjectorPainter({required this.accent, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    final reticlePaint = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double len = 22;
    // Top-left & bottom-right holographic targeting brackets
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), reticlePaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), reticlePaint);

    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - len, size.height),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - len),
      reticlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HologramProjectorPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
