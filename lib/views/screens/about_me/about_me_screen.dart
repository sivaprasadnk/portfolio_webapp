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

class AboutMeScreen extends StatefulWidget {
  const AboutMeScreen({super.key});

  @override
  State<AboutMeScreen> createState() => _AboutMeScreenState();
}

class _AboutMeScreenState extends State<AboutMeScreen> {
  int _selectedPerkIndex = 0;

  static const _perks = [
    (
      Icons.bolt_rounded,
      '3.7+ Years',
      'Cross-Platform Flutter',
      'LVL 37',
      'Engineered production-grade Android, iOS, and Web applications with high-frame-rate custom rendering and responsive spatial layouts.',
    ),
    (
      Icons.layers_rounded,
      'Architecture',
      'Clean Architecture & BLoC',
      'S-TIER',
      'Modular domain-driven codebases using BLoC, dependency injection, reactive streams, and testable state machines.',
    ),
    (
      Icons.public_rounded,
      'Open Source',
      'Pub.dev & VS Code Themes',
      'GUILD',
      'Published reusable Flutter packages on pub.dev and crafted developer tooling and themes for the global community.',
    ),
    (
      Icons.fitness_center_rounded,
      'Lifestyle',
      'Fitness & Felintrovert',
      '99 STA',
      'Fueled by discipline, strength training, and creative problem-solving alongside feline companions.',
    ),
  ];

  void _selectPerk(int index) {
    final item = _perks[index];
    setState(() {
      _selectedPerkIndex = index;
    });
    GamificationController.instance.completeQuest('lore_reader');
    GamificationController.instance.addXp(
      15,
      reason: 'Unlocked ${item.$2} Perk (${item.$4})!',
      uniqueKey: 'attr_${item.$2}',
    );
  }

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

                final activePerk = _perks[_selectedPerkIndex];
                final isDesktop = context.isLargeDevice;

                return PortfolioStyledCard(
                  width: double.infinity,
                  cyberHeader: '~/spnk/character_lore_holodeck.md',
                  onTap: () {
                    GamificationController.instance
                        .completeQuest('lore_reader');
                  },
                  padding: EdgeInsets.all(isDesktop ? 36 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Header Bar
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accent.withValues(alpha: 0.22),
                                  secondary.withValues(alpha: 0.14),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_stories_rounded,
                              color: accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Character Lore & Origin Holodeck',
                                  style: context.displaySmall.copyWith(
                                    fontSize: isDesktop ? 22 : 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Spawn Point: Tripunithura, Ernakulam, Kerala, India',
                                  style: context.bodySmall.copyWith(
                                    color: context.primaryColor
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!context.isMobileDevice)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: secondary.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    size: 14,
                                    color: secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SWITCH PERK ORBS FOR +15 XP',
                                    style: context.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Asymmetric Editorial Split (Desktop) or Unified Flow (Mobile)
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _buildNarrativePanel(
                                context,
                                state.content.trim(),
                                accent,
                                secondary,
                              ),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              flex: 5,
                              child: _buildPerkSpotlightConsole(
                                context,
                                activePerk,
                                accent,
                                secondary,
                                themeState,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildNarrativePanel(
                          context,
                          state.content.trim(),
                          accent,
                          secondary,
                        ),
                        const SizedBox(height: 22),
                        _buildPerkSpotlightConsole(
                          context,
                          activePerk,
                          accent,
                          secondary,
                          themeState,
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      imageName: '',
    );
  }

  Widget _buildNarrativePanel(
    BuildContext context,
    String narrative,
    Color accent,
    Color secondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ORIGIN TRANSMISSION // BIOGRAPHY',
                    style: context.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                narrative,
                style: context.bodyLarge.copyWith(
                  height: 1.65,
                  fontSize: context.isLargeDevice ? 19 : 16.5,
                  color: context.primaryColor.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerkSpotlightConsole(
    BuildContext context,
    (IconData, String, String, String, String) activePerk,
    Color accent,
    Color secondary,
    ThemeState themeState,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: themeState.isDark ? 0.12 : 0.08),
            secondary.withValues(alpha: themeState.isDark ? 0.08 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE PERK MATRIX',
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.3,
                  color: context.primaryColor.withValues(alpha: 0.65),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '0${_selectedPerkIndex + 1} / 0${_perks.length}',
                  style: context.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive Perk Selector Dock (No Grid/List — tactile orb selector bar)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_perks.length, (index) {
                final item = _perks[index];
                final isSelected = index == _selectedPerkIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => _selectPerk(index),
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 14 : 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent
                            : context.primaryColor.withValues(alpha: 0.06),
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
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.$1,
                            size: 16,
                            color: isSelected
                                ? (themeState.isDark
                                    ? const Color(0xFF090D16)
                                    : Colors.white)
                                : accent,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            item.$2,
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
          const SizedBox(height: 20),

          // Spotlight Display for Selected Perk
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey(_selectedPerkIndex),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.scaffoldColor.withValues(
                  alpha: themeState.isDark ? 0.55 : 0.75,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: accent.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          activePerk.$1,
                          color: accent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    activePerk.$2,
                                    style: context.displaySmall.copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: secondary.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: secondary.withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: Text(
                                    activePerk.$4,
                                    style: context.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activePerk.$3,
                              style: context.bodySmall.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    activePerk.$5,
                    style: context.bodyMedium.copyWith(
                      fontSize: 15,
                      height: 1.5,
                      color: context.primaryColor.withValues(alpha: 0.8),
                    ),
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
