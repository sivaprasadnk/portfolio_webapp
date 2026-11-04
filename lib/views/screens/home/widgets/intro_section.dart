import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/home/widgets/download_cv_btn.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';

class IntroSection extends StatelessWidget {
  const IntroSection({
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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  Expanded(
                    child: Text(
                      'COMMANDER_01 // SENIOR FLUTTER ARCHITECT',
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall.copyWith(
                        fontSize: 12,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      GamificationController.instance.addXp(
                        20,
                        reason: 'High-fived Dash Mascot! 🐦',
                        uniqueKey: 'dash_mascot_pet',
                      );
                    },
                    child: Image.asset(
                      'assets/images/dash/dash1.png',
                      height: 44,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                "Hi, I'm\nSivaprasad NK.",
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 38,
                      height: 1.08,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Flutter Developer & Fitness Enthusiast from Tripunithura, Kerala — navigate the open-air star map below, overclock skill nodes, and intercept rogue bugs to level up!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 17.5,
                      height: 1.5,
                      color: context.primaryColor.withValues(alpha: 0.85),
                    ),
              ),
              const SizedBox(height: 24),
              DownloadCvBtn(
                onExploreProjects: onExploreProjects,
                onPlayArcade: onPlayArcade,
              ),
            ],
          ),
        );
      },
    );
  }
}
