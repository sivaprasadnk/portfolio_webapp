import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadCvBtn extends StatelessWidget {
  const DownloadCvBtn({
    super.key,
    this.onExploreProjects,
    this.onPlayArcade,
  });

  final VoidCallback? onExploreProjects;
  final VoidCallback? onPlayArcade;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final accent = state.accentColor;
        final secondary = state.secondaryAccent;

        return Wrap(
          spacing: 18,
          runSpacing: 14,
          children: [
            OpenAirActionTrigger(
              label: 'Claim CV Scroll (+75 XP)',
              icon: Icons.workspace_premium_rounded,
              color: accent,
              isPrimary: true,
              onTap: () async {
                GamificationController.instance.completeQuest('loot_collector');
                try {
                  await launchUrl(Uri.parse(resumeLink));
                } catch (e) {
                  debugPrint('## Error launching URL: $e');
                }
              },
            ),
            if (onPlayArcade != null)
              OpenAirActionTrigger(
                label: 'Engage Bug Hunt',
                icon: Icons.radar_rounded,
                color: secondary,
                onTap: onPlayArcade!,
              ),
            if (onExploreProjects != null)
              OpenAirActionTrigger(
                label: 'Warp to Missions',
                icon: Icons.explore_rounded,
                color: accent,
                onTap: () {
                  GamificationController.instance.completeQuest('first_scroll');
                  onExploreProjects!();
                },
              ),
          ],
        );
      },
    );
  }
}
