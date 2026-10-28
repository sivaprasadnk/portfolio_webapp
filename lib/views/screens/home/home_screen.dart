import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/bloc/screen_details/screen_bloc.dart';
import 'package:spnk/views/bloc/screen_details/screen_event.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/about_me/about_me_screen.dart';
import 'package:spnk/views/screens/contact_me/contact_me_screen.dart';
import 'package:spnk/views/screens/experience/experience_screen.dart';
import 'package:spnk/views/screens/home/home_screen_large.dart';
import 'package:spnk/views/screens/home/home_screen_small.dart';
import 'package:spnk/views/screens/home/widgets/animated_footer.dart';
import 'package:spnk/views/screens/home/widgets/home_screen_drawer.dart';
import 'package:spnk/views/screens/home/widgets/logo_text.dart';
import 'package:spnk/views/screens/home/widgets/menu_icon.dart';
import 'package:spnk/views/screens/home/widgets/tab_item.dart';
import 'package:spnk/views/screens/home/widgets/theme_icon.dart';
import 'package:spnk/views/screens/home/widgets/theme_switch.dart';
import 'package:spnk/views/screens/home/widgets/torch_icon.dart';
import 'package:spnk/views/screens/projects/projects_screen.dart';
import 'package:spnk/views/screens/skills/skills_screen.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/Home';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isProgrammaticScroll = false;

  final Map<Screen, GlobalKey> _sectionKeys = {
    for (final s in Screen.values) s: GlobalKey(),
  };
  final GlobalKey _arcadeKey = GlobalKey();

  Offset _mousePosition = Offset.zero;
  Offset _pointerPosition = const Offset(0, 0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 220) {
      GamificationController.instance.completeQuest('first_scroll');
    }
    if (_isProgrammaticScroll || !mounted) return;

    Screen? activeScreen;
    double bestDistance = double.infinity;

    for (final entry in _sectionKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final pos = box.localToGlobal(Offset.zero);
          final dist = (pos.dy - 120).abs();
          if (dist < bestDistance) {
            bestDistance = dist;
            activeScreen = entry.key;
          }
        }
      }
    }

    if (activeScreen != null) {
      final current = context.read<ScreenBloc>().state.selectedScreen;
      if (current != activeScreen) {
        context.read<ScreenBloc>().add(UpdateScreen(screen: activeScreen));
      }
    }
  }

  Future<void> _scrollToSection(Screen screen) async {
    if (screen != Screen.home) {
      GamificationController.instance.completeQuest('first_scroll');
    }
    context.read<ScreenBloc>().add(UpdateScreen(screen: screen));
    final ctx = _sectionKeys[screen]?.currentContext;
    if (ctx != null) {
      _isProgrammaticScroll = true;
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        alignment: 0.0,
      );
      if (mounted) {
        _isProgrammaticScroll = false;
      }
    }
  }

  Future<void> _scrollToArcade() async {
    final ctx = _arcadeKey.currentContext;
    if (ctx != null) {
      _isProgrammaticScroll = true;
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        alignment: 0.1,
      );
      if (mounted) {
        _isProgrammaticScroll = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.screenWidth > 1280;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final showSpotLight = state.showSpotLight;

        return MouseRegion(
          cursor: showSpotLight ? SystemMouseCursors.none : MouseCursor.defer,
          onHover: (PointerHoverEvent event) {
            setState(() {
              _mousePosition = event.position;
            });
          },
          child: PortfolioStyleBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              endDrawer: HomeScreenDrawer(
                onSelectScreen: _scrollToSection,
              ),
              body: Stack(
                children: [
                  // Single-page smooth-scrolling gamified content
                  SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 96, bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 0. HERO SECTION
                        Container(
                          key: _sectionKeys[Screen.home],
                          child: context.screenWidth < 995
                              ? HomeScreenSmall(
                                  onExploreProjects: () =>
                                      _scrollToSection(Screen.projects),
                                  onPlayArcade: _scrollToArcade,
                                )
                              : HomeScreenLarge(
                                  onExploreProjects: () =>
                                      _scrollToSection(Screen.projects),
                                  onPlayArcade: _scrollToArcade,
                                ),
                        ),
                        const SizedBox(height: 28),

                        // INTERACTIVE MINI-GAME ARCADE SECTION
                        Container(
                          key: _arcadeKey,
                          child: const DashBugHuntGameSection(),
                        ),
                        const SizedBox(height: 36),

                        // 1. ABOUT ME SECTION (CHARACTER LORE)
                        Container(
                          key: _sectionKeys[Screen.aboutMe],
                          child: const AboutMeScreen(),
                        ),
                        const SizedBox(height: 36),

                        // 2. SKILLS SECTION (SKILL TREE POWER-UPS)
                        Container(
                          key: _sectionKeys[Screen.skills],
                          child: SkillsScreen(),
                        ),
                        const SizedBox(height: 36),

                        // 3. EXPERIENCE SECTION (CAMPAIGN STAGES)
                        Container(
                          key: _sectionKeys[Screen.experience],
                          child: ExperienceScreen(),
                        ),
                        const SizedBox(height: 36),

                        // 4. PROJECTS SECTION (BOSS MISSIONS)
                        Container(
                          key: _sectionKeys[Screen.projects],
                          child: ProjectsScreen(),
                        ),
                        const SizedBox(height: 36),

                        // 5. CONTACT ME SECTION (GUILD COMMS)
                        Container(
                          key: _sectionKeys[Screen.contactMe],
                          child: ContactMeScreen(),
                        ),
                        const SizedBox(height: 56),

                        // FOOTER
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: AnimatedFooter(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ambient cursor glow on desktop when spotlight is off
                  if (!showSpotLight && isDesktop)
                    Positioned(
                      left: _mousePosition.dx - 35,
                      top: _mousePosition.dy - 35,
                      child: IgnorePointer(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: state.accentColor.withOpacity(0.32),
                                spreadRadius: 40,
                                blurRadius: 90,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Spotlight overlay when TorchIcon is toggled
                  if (showSpotLight)
                    Positioned.fill(
                      child: MouseRegion(
                        onHover: (event) {
                          setState(() {
                            _pointerPosition = event.localPosition;
                          });
                        },
                        child: CustomPaint(
                          painter: SpotlightPainter(
                            _pointerPosition,
                            context.scaffoldColor,
                          ),
                        ),
                      ),
                    ),

                  // Floating Achievement & +XP Toast Overlay
                  const AchievementToastBanner(),

                  // Sticky Top Navbar + Player HUD
                  Positioned(
                    top: 12,
                    left: isDesktop ? context.screenWidth * 0.03 : 10,
                    right: isDesktop ? context.screenWidth * 0.03 : 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        state.portfolioStyle == PortfolioStyle.cyber ? 8 : 999,
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          height: 68,
                          padding: EdgeInsets.symmetric(
                            horizontal: context.isMobileDevice ? 12 : 20,
                          ),
                          decoration: BoxDecoration(
                            color: state.cardSurfaceColor.withOpacity(
                              state.isDark ? 0.82 : 0.90,
                            ),
                            borderRadius: BorderRadius.circular(
                              state.portfolioStyle == PortfolioStyle.cyber
                                  ? 8
                                  : 999,
                            ),
                            border: Border.all(
                              color: state.cardBorderColor,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              LogoText(
                                onTap: () => _scrollToSection(Screen.home),
                              ),
                              const SizedBox(width: 10),
                              GamificationHudPill(
                                compact: !isDesktop,
                                onOpenQuests: () => showQuestLogModal(
                                  context,
                                  onJumpToArcade: _scrollToArcade,
                                ),
                              ),
                              if (context.screenWidth > 760) ...[
                                const SizedBox(width: 10),
                                const StyleSwitcherBar(compact: true),
                              ],
                              const Spacer(),
                              if (isDesktop) ...[
                                ...Screen.values.map(
                                  (screen) => TabItem(
                                    title: screen.menuName,
                                    screen: screen,
                                    onSelect: _scrollToSection,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const TorchIcon(),
                                const SizedBox(width: 12),
                                const BrightnessSwitch(),
                                const SizedBox(width: 12),
                                const ThemeIcon(),
                              ] else ...[
                                const BrightnessSwitch(),
                                const SizedBox(width: 12),
                                const ThemeIcon(),
                                const SizedBox(width: 12),
                                const MenuIcon(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final Offset pointerPosition;
  final Color bgColor;

  SpotlightPainter(this.pointerPosition, this.bgColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    final fullScreenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    const spotlightRadius = 80.0;
    final spotlightPath = Path()
      ..addOval(
        Rect.fromCircle(center: pointerPosition, radius: spotlightRadius),
      );

    final overlayPath = Path.combine(
      PathOperation.difference,
      fullScreenPath,
      spotlightPath,
    );

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) {
    return oldDelegate.pointerPosition != pointerPosition;
  }
}
