import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/home/widgets/download_cv_btn.dart';

class IntroSection extends StatelessWidget {
  const IntroSection({super.key, this.onExploreProjects});

  final VoidCallback? onExploreProjects;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final accent = state.accentColor;
        final isCyber = state.portfolioStyle == PortfolioStyle.cyber;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(state.isDark ? 0.14 : 0.10),
                  borderRadius: BorderRadius.circular(isCyber ? 6 : 999),
                  border: Border.all(color: accent.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCyber
                          ? 'STATUS: READY_FOR_FLUTTER_PROJECTS'
                          : 'Available for Flutter & Cross-Platform Projects',
                      style: context.bodySmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Hi, I'm\nSivaprasad NK.",
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 38,
                      height: 1.15,
                    ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Text(
                  'Flutter Developer and Fitness Enthusiast from Tripunithura, Kerala.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        height: 1.45,
                        color: context.primaryColor.withOpacity(0.82),
                      ),
                ),
              ),
              const SizedBox(height: 24),
              DownloadCvBtn(onExploreProjects: onExploreProjects),
            ],
          ),
        );
      },
    );
  }
}
