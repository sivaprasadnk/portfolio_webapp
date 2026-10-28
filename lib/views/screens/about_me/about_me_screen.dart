import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/bloc/about_me/about_me_bloc.dart';
import 'package:spnk/views/bloc/about_me/about_me_state.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/about_me/loading_abt_me_container.dart';
import 'package:spnk/views/screens/screen_section.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class AboutMeScreen extends StatelessWidget {
  const AboutMeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPad =
        context.isMobileDevice ? 16.0 : context.screenWidth * 0.08;

    return ScreenSection(
      title: Screen.aboutMe.screenTitle,
      details: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final accent = themeState.accentColor;
            final secondary = themeState.secondaryAccent;

            return BlocBuilder<AboutMeBloc, AboutMeState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const LoadingAbtMeContainer();
                }

                final highlights = [
                  (
                    Icons.bolt_rounded,
                    '3.7+ Years',
                    'Cross-Platform Flutter',
                    'LVL 37',
                  ),
                  (
                    Icons.layers_rounded,
                    'Architecture',
                    'Clean Architecture & BLoC',
                    'S-TIER',
                  ),
                  (
                    Icons.public_rounded,
                    'Open Source',
                    'Pub.dev & VS Code Themes',
                    'GUILD',
                  ),
                  (
                    Icons.fitness_center_rounded,
                    'Lifestyle',
                    'Fitness & Felintrovert',
                    '99 STA',
                  ),
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PortfolioStyledCard(
                      width: double.infinity,
                      cyberHeader: '~/spnk/character_lore.md',
                      onTap: () {
                        GamificationController.instance
                            .completeQuest('lore_reader');
                      },
                      padding: EdgeInsets.all(
                        context.isLargeDevice ? 32 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  child: Icon(
                                    Icons.auto_stories_rounded,
                                    color: accent,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Character Lore & Origin Story',
                                        style: context.displaySmall.copyWith(
                                          fontSize: 21,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Spawn Point: Tripunithura, Ernakulam, Kerala, India',
                                        style: context.bodySmall.copyWith(
                                          color: context.primaryColor
                                              .withOpacity(0.65),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: secondary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: secondary.withOpacity(0.45),
                                  ),
                                ),
                                child: Text(
                                  'TAP CARDS FOR +XP',
                                  style: context.bodySmall.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            state.content.trim(),
                            style: context.bodyLarge.copyWith(
                              height: 1.6,
                              fontSize: context.isLargeDevice ? 20 : 17,
                              color: context.primaryColor.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: highlights.map((item) {
                        return PortfolioStyledCard(
                          width: context.isLargeDevice ? 265 : double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          cyberHeader: '~/attr/${item.$2.toLowerCase()}',
                          onTap: () {
                            GamificationController.instance
                                .completeQuest('lore_reader');
                            GamificationController.instance.addXp(
                              15,
                              reason: 'Unlocked ${item.$2} Perk (${item.$4})!',
                              uniqueKey: 'attr_${item.$2}',
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      accent.withOpacity(0.2),
                                      secondary.withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  item.$1,
                                  color: accent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.$2,
                                          style: context.displaySmall.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent.withOpacity(0.16),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.$4,
                                            style: context.bodySmall.copyWith(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.$3,
                                      style: context.bodySmall.copyWith(
                                        fontSize: 14,
                                        color: context.primaryColor
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      imageName: '',
    );
  }
}
