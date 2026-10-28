import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/home/widgets/download_cv_btn.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PortfolioStyledCard(
            width: double.infinity,
            cyberHeader: '~/spnk/hero_profile.sh',
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
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
                            Flexible(
                              child: Text(
                                isCyber
                                    ? 'SYS.ONLINE // FLUTTER_DEV'
                                    : 'Available for Flutter Projects',
                                overflow: TextOverflow.ellipsis,
                                style: context.bodySmall.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Image.asset(
                      'assets/images/dash/dash1.png',
                      height: 40,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Hi, I'm\nSivaprasad NK.",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 34,
                        height: 1.12,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Flutter Developer and Fitness Enthusiast from Tripunithura, Kerala — building fast, clean, cross-platform mobile & web experiences.',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 18,
                        height: 1.45,
                        color: context.primaryColor.withOpacity(0.84),
                      ),
                ),
                const SizedBox(height: 22),
                DownloadCvBtn(onExploreProjects: onExploreProjects),
              ],
            ),
          ),
        );
      },
    );
  }
}
