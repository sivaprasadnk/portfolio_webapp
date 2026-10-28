import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/home/widgets/download_cv_btn.dart';
import 'package:spnk/views/screens/home/widgets/orbit_animation3.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';

class HomeScreenLarge extends StatefulWidget {
  const HomeScreenLarge({
    super.key,
    this.onExploreProjects,
    this.onPlayArcade,
  });

  final VoidCallback? onExploreProjects;
  final VoidCallback? onPlayArcade;

  @override
  State<HomeScreenLarge> createState() => _HomeScreenLargeState();
}

class _HomeScreenLargeState extends State<HomeScreenLarge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool showImage = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
        setState(() {
          showImage = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final horizontalPad = screenWidth * 0.08;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final accent = state.accentColor;
        final secondary = state.secondaryAccent;
        final isCyber = state.portfolioStyle == PortfolioStyle.cyber;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPad,
            vertical: 28,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 6,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accent
                                    .withOpacity(state.isDark ? 0.16 : 0.10),
                                borderRadius:
                                    BorderRadius.circular(isCyber ? 6 : 999),
                                border:
                                    Border.all(color: accent.withOpacity(0.45)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shield_rounded,
                                    size: 15,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isCyber
                                        ? 'PLAYER_1 // CLASS: FLUTTER_ARCHITECT (LVL 37)'
                                        : 'PLAYER 1 • CLASS: SENIOR FLUTTER DEVELOPER',
                                    style: context.bodySmall.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            if (showImage)
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    GamificationController.instance.addXp(
                                      20,
                                      reason: 'High-fived Dash Mascot! 🐦',
                                      uniqueKey: 'dash_mascot_pet',
                                    );
                                  },
                                  child: Tooltip(
                                    message: 'Tap Dash for +20 XP!',
                                    child: Image.asset(
                                      'assets/images/dash/dash1.png',
                                      height: 56,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          "Hi, I'm",
                          style: context.displaySmall.copyWith(
                            fontSize: 22,
                            color: context.primaryColor.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Sivaprasad NK.",
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                fontSize: 54,
                                height: 1.08,
                                letterSpacing: -1.0,
                              ),
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 540),
                          child: Text(
                            'Flutter Developer and Fitness Enthusiast from Tripunithura, Kerala — explore quests below, power up skills, and squash bugs to level up!',
                            style: context.displaySmall.copyWith(
                              fontSize: 20,
                              height: 1.45,
                              color: context.primaryColor.withOpacity(0.82),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        // Interactive RPG Stat Bars
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              _HeroRpgStatChip(
                                label: 'FLUTTER & DART',
                                stat: '98 / 100',
                                progress: 0.98,
                                color: accent,
                              ),
                              _HeroRpgStatChip(
                                label: 'CLEAN ARCH & BLOC',
                                stat: '95 / 100',
                                progress: 0.95,
                                color: secondary,
                              ),
                              _HeroRpgStatChip(
                                label: 'STAMINA & FITNESS',
                                stat: '99 / 100',
                                progress: 0.99,
                                color: const Color(0xFF10B981),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        DownloadCvBtn(
                          onExploreProjects: widget.onExploreProjects,
                          onPlayArcade: widget.onPlayArcade,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              const Flexible(
                flex: 5,
                child: OrbitAnimation3(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroRpgStatChip extends StatelessWidget {
  const _HeroRpgStatChip({
    required this.label,
    required this.stat,
    required this.progress,
    required this.color,
  });

  final String label;
  final String stat;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          GamificationController.instance.addXp(
            10,
            reason: 'Inspected $label stat!',
            uniqueKey: 'hero_stat_$label',
          );
        },
        child: Container(
          width: 155,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    stat,
                    style: context.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: context.primaryColor.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
