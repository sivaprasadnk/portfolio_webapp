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
                  // Open-air containerless Astral Cosmos stream
                  SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 90, bottom: 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 0. HERO SECTOR
                        KeyedSubtree(
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
                        const SizedBox(height: 36),

                        // OPEN-AIR RADAR INTERCEPTOR SIMULATOR
                        KeyedSubtree(
                          key: _arcadeKey,
                          child: const DashBugHuntGameSection(),
                        ),
                        const SizedBox(height: 44),

                        // 1. ABOUT ME SECTOR (LORE & PERK COMPASS)
                        KeyedSubtree(
                          key: _sectionKeys[Screen.aboutMe],
                          child: const AboutMeScreen(),
                        ),
                        const SizedBox(height: 44),

                        // 2. SKILLS SECTOR (ASTRAL CONSTELLATION)
                        KeyedSubtree(
                          key: _sectionKeys[Screen.skills],
                          child: SkillsScreen(),
                        ),
                        const SizedBox(height: 44),

                        // 3. EXPERIENCE SECTOR (CHRONO WARP ODYSSEY)
                        KeyedSubtree(
                          key: _sectionKeys[Screen.experience],
                          child: ExperienceScreen(),
                        ),
                        const SizedBox(height: 44),

                        // 4. PROJECTS SECTOR (HOLOGRAPHIC MISSION PROJECTOR)
                        KeyedSubtree(
                          key: _sectionKeys[Screen.projects],
                          child: ProjectsScreen(),
                        ),
                        const SizedBox(height: 44),

                        // 5. CONTACT ME SECTOR (SUBSPACE COMMS ARRAY)
                        KeyedSubtree(
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
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: CustomPaint(
                            painter: _CursorAuraPainter(
                              color: state.accentColor.withValues(alpha: 0.28),
                            ),
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

                  // Open-Air Floating Achievement & +XP Banner
                  const AchievementToastBanner(),

                  // Open-Air Top Astral HUD Horizon (Zero Box Containers)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: CustomPaint(
                          painter: _HudHorizonLinePainter(
                            accent: state.accentColor,
                            secondary: state.secondaryAccent,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop
                                  ? context.screenWidth * 0.05
                                  : 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                LogoText(
                                  onTap: () => _scrollToSection(Screen.home),
                                ),
                                const SizedBox(width: 18),
                                GamificationHudPill(
                                  compact: context.screenWidth < 1460,
                                  onOpenQuests: () => showQuestLogModal(
                                    context,
                                    onJumpToArcade: _scrollToArcade,
                                  ),
                                ),
                                if (context.screenWidth > 880) ...[
                                  const SizedBox(width: 18),
                                  const StyleSwitcherBar(compact: true),
                                ],
                                const Spacer(),
                                if (isDesktop) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: Screen.values
                                        .map(
                                          (screen) => TabItem(
                                            title: screen.menuName,
                                            screen: screen,
                                            onSelect: _scrollToSection,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  const SizedBox(width: 18),
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TorchIcon(),
                                      SizedBox(width: 12),
                                      BrightnessSwitch(),
                                      SizedBox(width: 12),
                                      ThemeIcon(),
                                    ],
                                  ),
                                ] else ...[
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      BrightnessSwitch(),
                                      SizedBox(width: 12),
                                      ThemeIcon(),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  const MenuIcon(),
                                ],
                              ],
                            ),
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

class _HudHorizonLinePainter extends CustomPainter {
  final Color accent;
  final Color secondary;

  _HudHorizonLinePainter({required this.accent, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0.0),
          accent.withValues(alpha: 0.65),
          secondary.withValues(alpha: 0.65),
          secondary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, size.height - 2, size.width, 2))
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HudHorizonLinePainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.secondary != secondary;
}

class _CursorAuraPainter extends CustomPainter {
  final Color color;
  _CursorAuraPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 45, paint);
  }

  @override
  bool shouldRepaint(covariant _CursorAuraPainter oldDelegate) =>
      oldDelegate.color != color;
}

class SpotlightPainter extends CustomPainter {
  final Offset pointerPosition;
  final Color bgColor;

  SpotlightPainter(this.pointerPosition, this.bgColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.95)
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
