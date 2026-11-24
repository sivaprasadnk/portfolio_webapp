import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spnk/data/constants.dart';
import 'package:spnk/domain/entity/contact_details.dart';
import 'package:spnk/domain/entity/experience_details.dart';
import 'package:spnk/domain/entity/project_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:spnk/views/bloc/about_me/about_me_bloc.dart';
import 'package:spnk/views/bloc/about_me/about_me_state.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_bloc.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_state.dart';
import 'package:spnk/views/bloc/experience/exp_details_bloc.dart';
import 'package:spnk/views/bloc/experience/exp_details_state.dart';
import 'package:spnk/views/bloc/project/project_bloc.dart';
import 'package:spnk/views/bloc/project/project_state.dart';
import 'package:spnk/views/bloc/skills/skills_bloc.dart';
import 'package:spnk/views/bloc/skills/skills_state.dart';
import 'package:spnk/views/screens/arcade/arcade_screen.dart';
import 'package:spnk/views/screens/christmas/christmas_painters.dart';
import 'package:spnk/views/screens/christmas/christmas_theme_config.dart';
import 'package:spnk/views/screens/home/grid/interactive_grid_home_screen.dart';
import 'package:spnk/views/screens/home/widgets/logo_text.dart';
import 'package:spnk/views/screens/qrcode/qr_code_screen.dart';
import 'package:spnk/views/screens/racing/racing_portfolio_screen.dart';
import 'package:spnk/views/screens/solar/solar_system_screen.dart';
import 'package:spnk/views/screens/yt_downloader/yt_downloader_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ChristmasPortfolioScreen extends StatefulWidget {
  const ChristmasPortfolioScreen({super.key});

  @override
  State<ChristmasPortfolioScreen> createState() =>
      _ChristmasPortfolioScreenState();
}

class _ChristmasPortfolioScreenState extends State<ChristmasPortfolioScreen>
    with SingleTickerProviderStateMixin {
  static const Set<String> _supportedSkillSvgs = {
    'dart',
    'flutter',
    'firebase2',
    'html',
    'css',
  };

  late final Ticker _ticker;
  final ScrollController _scrollController = ScrollController();
  final SnowfallSimulation _snowSim = SnowfallSimulation();

  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _experienceKey = GlobalKey();
  final GlobalKey _projectsKey = GlobalKey();
  final GlobalKey _skillsKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  double _elapsedSeconds = 0.0;
  double _lastTickSeconds = 0.0;
  double _scrollOffset = 0.0;
  Offset _pointerNorm = Offset.zero;
  bool _snowEnabled = true;
  bool _reducedMotion = false;
  int _selectedExpIndex = 0;
  String? _copiedContactKey;

  @override
  void initState() {
    super.initState();
    _snowSim.ensureInitialized();
    _scrollController.addListener(() {
      if (!mounted) return;
      setState(() => _scrollOffset = _scrollController.offset);
    });
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final now = elapsed.inMicroseconds / 1000000.0;
    final dt = (now - _lastTickSeconds).clamp(0.0, 0.05);
    _lastTickSeconds = now;
    if (_reducedMotion) return;
    setState(() {
      _elapsedSeconds = now;
      if (_snowEnabled) {
        _snowSim.step(dt, now);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: _reducedMotion ? Duration.zero : const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  void _openV4Classic() {
    Navigator.of(context).pushNamed(InteractiveGridHomeScreen.routeName);
  }

  void _openRacingV2() {
    if (kIsWeb) {
      launchUrl(Uri.parse('/v2/'), webOnlyWindowName: '_self');
      return;
    }
    Navigator.of(context).pushNamed(RacingPortfolioScreen.routeName);
  }

  void _openSolarV3() {
    Navigator.of(context).pushNamed(SolarSystemPortfolioScreen.routeName);
  }

  Future<void> _launchExternal(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;
    try {
      await launchUrl(Uri.parse(trimmed));
    } catch (e) {
      debugPrint('## Error launching $trimmed: $e');
    }
  }

  Future<void> _copyText(String key, String value) async {
    await Clipboard.setData(ClipboardData(text: value.trim()));
    if (!mounted) return;
    setState(() => _copiedContactKey = key);
  }

  void _openProjectAction(ProjectDetails project) {
    if (project.webUrl == qrCodeToolLink) {
      Navigator.of(context).pushNamed(QrCodeScreen.routeName);
      return;
    }
    if (project.webUrl == arcadeHubLink) {
      Navigator.of(context).pushNamed(ArcadeScreen.routeName);
      return;
    }
    if (project.webUrl == ytDownloaderLink) {
      Navigator.of(context).pushNamed(YtDownloaderScreen.routeName);
      return;
    }
    if (project.webUrl == racingGameV2Link) {
      _openRacingV2();
      return;
    }
    if (project.webUrl == solarSystemV3Link) {
      _openSolarV3();
      return;
    }
    if (project.webUrl.isNotEmpty) {
      _launchExternal(project.webUrl);
      return;
    }
    if (project.playStoreUrl.isNotEmpty) {
      _launchExternal(project.playStoreUrl);
    }
  }

  void _showProjectDialog(ProjectDetails project) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: _FrostedChristmasCard(
            glowColor: ChristmasThemeConfig.champagneGold,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.ac_unit_rounded,
                      color: ChristmasThemeConfig.champagneGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        project.projName,
                        style: context.displaySmall.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: ChristmasThemeConfig.snowWhite,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: ChristmasThemeConfig.champagneGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: project.techStackList
                      .map((tech) => _FestiveBadge(label: tech, isGold: true))
                      .toList(),
                ),
                const SizedBox(height: 14),
                ...project.descList.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: ChristmasThemeConfig.champagneGold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            d.replaceAll('\n', ' '),
                            style: context.bodySmall.copyWith(
                              fontSize: 14,
                              color: ChristmasThemeConfig.snowWhite
                                  .withValues(alpha: 0.90),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (project.webUrl.isNotEmpty)
                      _GoldGradientButton(
                        label: 'Launch Live Demo',
                        icon: Icons.open_in_new_rounded,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _openProjectAction(project);
                        },
                      ),
                    if (project.playStoreUrl.isNotEmpty)
                      _FestiveOutlinedButton(
                        label: 'View on Play Store',
                        icon: Icons.shop_rounded,
                        color: ChristmasThemeConfig.icyBlue,
                        onTap: () => _launchExternal(project.playStoreUrl),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: ChristmasThemeConfig.midnightBlue,
      body: LayoutBuilder(
        builder: (context, viewport) {
          final maxW = viewport.maxWidth;
          final viewSize = Size(viewport.maxWidth, viewport.maxHeight);

          return Listener(
            onPointerHover: (e) {
              if (_reducedMotion) return;
              final nx = viewSize.width > 0
                  ? ((e.localPosition.dx / viewSize.width) * 2 - 1).clamp(-1.0, 1.0)
                  : 0.0;
              final ny = viewSize.height > 0
                  ? ((e.localPosition.dy / viewSize.height) * 2 - 1).clamp(-1.0, 1.0)
                  : 0.0;
              setState(() {
                _pointerNorm = Offset(nx, ny);
                if (_snowEnabled) {
                  _snowSim.addCursorFlake(e.localPosition, _elapsedSeconds);
                }
              });
            },
            child: Stack(
              children: [
                // Layer 1: Winter sky, snow-capped mountains, snowfall, Santa sleigh & snowflake cursor trail
                Positioned.fill(
                  child: CustomPaint(
                    painter: ChristmasSkyAndSnowPainter(
                      simulation: _snowSim,
                      elapsedSeconds: _elapsedSeconds,
                      snowEnabled: _snowEnabled,
                      reducedMotion: _reducedMotion,
                    ),
                  ),
                ),

                // Layer 2: Frosted glass navigation bar + full portfolio content
                Column(
                  children: [
                    _buildFestiveNavBar(context, maxW),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: maxW >= 1200 ? 40 : (maxW >= 700 ? 24 : 14),
                          vertical: maxW >= 700 ? 24 : 16,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1240),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                KeyedSubtree(
                                  key: _heroKey,
                                  child: _buildHeroSection(context, maxW),
                                ),
                                const SizedBox(height: 28),
                                KeyedSubtree(
                                  key: _aboutKey,
                                  child: _ScrollRevealSection(
                                    revealProgress: _revealFor(120),
                                    child: _buildAboutSection(context, maxW),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                KeyedSubtree(
                                  key: _experienceKey,
                                  child: _ScrollRevealSection(
                                    revealProgress: _revealFor(420),
                                    child: _buildExperienceTimelineSection(
                                      context,
                                      maxW,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                KeyedSubtree(
                                  key: _projectsKey,
                                  child: _ScrollRevealSection(
                                    revealProgress: _revealFor(760),
                                    child: _buildProjectsSection(context, maxW),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                KeyedSubtree(
                                  key: _skillsKey,
                                  child: _ScrollRevealSection(
                                    revealProgress: _revealFor(1120),
                                    child: _buildSkillsSection(context, maxW),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                KeyedSubtree(
                                  key: _contactKey,
                                  child: _ScrollRevealSection(
                                    revealProgress: _revealFor(1380),
                                    child: _buildContactSection(context, maxW),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildFooter(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _revealFor(double triggerOffset) {
    if (_reducedMotion) return 1.0;
    return ((_scrollOffset + 620.0 - triggerOffset) / 280.0).clamp(0.0, 1.0);
  }

  Widget _buildFestiveNavBar(BuildContext context, double maxW) {
    final countdown = ChristmasThemeConfig.countdownLabel(DateTime.now());

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          key: const ValueKey('christmas_nav_bar'),
          decoration: BoxDecoration(
            color: ChristmasThemeConfig.midnightBlue.withValues(alpha: 0.78),
            border: const Border(
              bottom: BorderSide(
                color: ChristmasThemeConfig.frostBorder,
                width: 1.1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: ChristmasThemeConfig.champagneGold.withValues(alpha: 0.14),
                blurRadius: 18,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: maxW >= 1200 ? 40 : (maxW >= 700 ? 22 : 12),
            vertical: 10,
          ),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Row(
                  children: [
                    // Ornament / Snowflake beside logo
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            ChristmasThemeConfig.crimsonGlow,
                            ChristmasThemeConfig.burgundy,
                          ],
                        ),
                        border: Border.all(
                          color: ChristmasThemeConfig.champagneGold.withValues(alpha: 0.8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ChristmasThemeConfig.champagneGold.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.ac_unit_rounded,
                        size: 16,
                        color: ChristmasThemeConfig.champagneGold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    LogoText(onTap: () => _scrollToSection(_heroKey)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _NavHoverLink(
                              label: 'About',
                              onTap: () => _scrollToSection(_aboutKey),
                            ),
                            _NavHoverLink(
                              label: 'Experience',
                              onTap: () => _scrollToSection(_experienceKey),
                            ),
                            _NavHoverLink(
                              label: 'Projects',
                              onTap: () => _scrollToSection(_projectsKey),
                            ),
                            _NavHoverLink(
                              label: 'Skills',
                              onTap: () => _scrollToSection(_skillsKey),
                            ),
                            _NavHoverLink(
                              label: 'Contact',
                              onTap: () => _scrollToSection(_contactKey),
                            ),
                            const SizedBox(width: 8),
                            // Christmas Countdown Widget
                            Container(
                              key: const ValueKey('christmas_countdown_pill'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: ChristmasThemeConfig.burgundy.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: ChristmasThemeConfig.champagneGold.withValues(alpha: 0.65),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.park_rounded,
                                    size: 13,
                                    color: ChristmasThemeConfig.champagneGold,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    countdown,
                                    style: context.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: ChristmasThemeConfig.champagneGold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Let It Snow toggle (always pinned & clickable)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        key: const ValueKey('let_it_snow_toggle'),
                        onTap: () => setState(() => _snowEnabled = !_snowEnabled),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _snowEnabled
                                ? ChristmasThemeConfig.icyBlue.withValues(alpha: 0.16)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _snowEnabled
                                  ? ChristmasThemeConfig.icyBlue
                                  : Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.ac_unit_rounded,
                                size: 13,
                                color: _snowEnabled
                                    ? ChristmasThemeConfig.icyBlue
                                    : ChristmasThemeConfig.snowWhite.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _snowEnabled ? 'Let It Snow: ON' : 'Let It Snow: OFF',
                                style: context.bodySmall.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _snowEnabled
                                      ? ChristmasThemeConfig.icyBlue
                                      : ChristmasThemeConfig.snowWhite.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (maxW >= 1040) ...[
                      const SizedBox(width: 8),
                      _NavPortalPill(
                        label: 'CLASSIC /v4',
                        color: ChristmasThemeConfig.icyBlue,
                        onTap: _openV4Classic,
                      ),
                      const SizedBox(width: 6),
                      _NavPortalPill(
                        label: '3D RACER /v2',
                        color: ChristmasThemeConfig.champagneGold,
                        onTap: _openRacingV2,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, double maxW) {
    final isDesktop = maxW >= 880;
    final isMobile = maxW < 560;

    final heroContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Festive greeting pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: ChristmasThemeConfig.burgundyCardGradient,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: ChristmasThemeConfig.champagneGold.withValues(alpha: 0.75),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 15,
                color: ChristmasThemeConfig.champagneGold,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Merry Christmas & Happy New Year!',
                  style: context.bodySmall.copyWith(
                    fontSize: isMobile ? 11.5 : 12.5,
                    fontWeight: FontWeight.bold,
                    color: ChristmasThemeConfig.champagneGold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    ChristmasThemeConfig.champagneGold,
                    ChristmasThemeConfig.crimsonGlow,
                    ChristmasThemeConfig.icyBlue,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ChristmasThemeConfig.champagneGold.withValues(alpha: 0.35),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/propic3.png',
                  width: isMobile ? 64 : 84,
                  height: isMobile ? 64 : 84,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sivaprasad NK',
                    style: context.displayMedium.copyWith(
                      fontSize: isMobile ? 30 : 44,
                      height: 1.06,
                      color: ChristmasThemeConfig.snowWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Senior Flutter Architect • 3.7+ Years • Kerala, India',
                    style: context.bodySmall.copyWith(
                      fontSize: isMobile ? 13 : 16,
                      color: ChristmasThemeConfig.champagneGold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Crafting responsive cross-platform Flutter, Clean Architecture, and interactive WebGL experiences from Tripunithura, Kerala.',
          style: context.bodySmall.copyWith(
            fontSize: 15.5,
            height: 1.55,
            color: ChristmasThemeConfig.snowWhite.withValues(alpha: 0.88),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _GoldGradientButton(
              label: 'Download CV',
              icon: Icons.download_rounded,
              onTap: () => _launchExternal(resumeLink),
            ),
            _FestiveOutlinedButton(
              label: 'Explore Projects',
              icon: Icons.rocket_launch_rounded,
              color: ChristmasThemeConfig.icyBlue,
              onTap: () => _scrollToSection(_projectsKey),
            ),
            _FestiveOutlinedButton(
              label: 'Contact Me',
              icon: Icons.mail_rounded,
              color: ChristmasThemeConfig.champagneGold,
              onTap: () => _scrollToSection(_contactKey),
            ),
            _FestiveOutlinedButton(
              label: 'Classic /v4',
              icon: Icons.grid_view_rounded,
              color: ChristmasThemeConfig.icyBlue,
              onTap: _openV4Classic,
            ),
            _FestiveOutlinedButton(
              label: '3D Racer /v2',
              icon: Icons.sports_motorsports_rounded,
              color: ChristmasThemeConfig.champagneGold,
              onTap: _openRacingV2,
            ),
            _FestiveOutlinedButton(
              label: '3D Solar /v3',
              icon: Icons.public_rounded,
              color: const Color(0xFFC084FC),
              onTap: _openSolarV3,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SocialChip(
              label: 'GitHub',
              icon: FontAwesomeIcons.github,
              onTap: () => _launchExternal(githubLink),
            ),
            _SocialChip(
              label: 'LinkedIn',
              icon: FontAwesomeIcons.linkedinIn,
              onTap: () => _launchExternal(linkedInLink),
            ),
            _SocialChip(
              label: 'Pub.dev',
              icon: Icons.widgets_rounded,
              onTap: () => _launchExternal(pubDevLink),
            ),
            _SocialChip(
              label: 'VS Code',
              icon: Icons.palette_rounded,
              onTap: () => _launchExternal(vsCodeThemesLink),
            ),
          ],
        ),
      ],
    );

    final treeShowcase = SizedBox(
      width: isDesktop ? 320 : 260,
      height: isDesktop ? 350 : 280,
      child: CustomPaint(
        painter: Christmas3DTreePainter(
          elapsedSeconds: _elapsedSeconds,
          reducedMotion: _reducedMotion,
          pointerOffset: _pointerNorm,
        ),
      ),
    );

    return _FrostedChristmasCard(
      glowColor: ChristmasThemeConfig.champagneGold,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Twinkling Christmas string lights along the top of the Hero
          SizedBox(
            height: 26,
            width: double.infinity,
            child: CustomPaint(
              painter: TwinklingLightsGarlandPainter(
                elapsedSeconds: _elapsedSeconds,
                reducedMotion: _reducedMotion,
                bulbCount: maxW >= 900 ? 22 : 12,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 28,
              10,
              isMobile ? 16 : 28,
              26,
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 7, child: heroContent),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: Center(child: treeShowcase),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      heroContent,
                      const SizedBox(height: 18),
                      treeShowcase,
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, double maxW) {
    return BlocBuilder<AboutMeBloc, AboutMeState>(
      builder: (context, state) {
        final bio = state.content.trim().isNotEmpty
            ? state.content.trim()
            : aboutMeDetailsContent.content.trim();

        return _FrostedChristmasCard(
          glowColor: ChristmasThemeConfig.icyBlue,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.ac_unit_rounded,
                eyebrow: 'WINTER CHRONICLE',
                title: 'About Me',
                accent: ChristmasThemeConfig.icyBlue,
              ),
              const SizedBox(height: 14),
              Text(
                bio,
                style: context.bodySmall.copyWith(
                  fontSize: 15,
                  height: 1.65,
                  color: ChristmasThemeConfig.snowWhite.withValues(alpha: 0.90),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _FestiveBadge(label: '3.7+ Years Experience', isGold: true),
                  _FestiveBadge(label: '6+ Apps Shipped', isGold: false),
                  _FestiveBadge(label: 'Clean Architecture', isGold: true),
                  _FestiveBadge(label: 'Flutter Architect', isGold: false),
                  _FestiveBadge(label: 'Fitness Enthusiast', isGold: true),
                  _FestiveBadge(label: 'Felintrovert', isGold: false),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExperienceTimelineSection(BuildContext context, double maxW) {
    return BlocBuilder<ExpDetailsBloc, ExpDetailsState>(
      builder: (context, state) {
        final exps = state.expList.isNotEmpty ? state.expList : expDetailsList;
        final ordered = List<ExperienceDetails>.of(exps)
          ..sort((a, b) => b.order.compareTo(a.order));
        final activeIdx = _selectedExpIndex.clamp(0, ordered.length - 1);

        return _FrostedChristmasCard(
          glowColor: ChristmasThemeConfig.champagneGold,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.timeline_rounded,
                eyebrow: 'GOLDEN CAREER TIMELINE',
                title: 'Experience',
                accent: ChristmasThemeConfig.champagneGold,
              ),
              const SizedBox(height: 18),
              ...ordered.asMap().entries.map((entry) {
                final idx = entry.key;
                final exp = entry.value;
                final isLast = idx == ordered.length - 1;
                final selected = idx == activeIdx;
                final twinkle = _reducedMotion
                    ? 0.9
                    : 0.6 + 0.4 * math.sin(_elapsedSeconds * 3.0 + idx);

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Glowing golden vertical timeline & ornament node
                      SizedBox(
                        width: 34,
                        child: Column(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: selected
                                      ? const [
                                          ChristmasThemeConfig.champagneGold,
                                          ChristmasThemeConfig.crimsonGlow,
                                        ]
                                      : [
                                          ChristmasThemeConfig.pineEmerald,
                                          ChristmasThemeConfig.warmGold.withValues(alpha: 0.7),
                                        ],
                                ),
                                border: Border.all(
                                  color: ChristmasThemeConfig.champagneGold
                                      .withValues(alpha: twinkle),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (selected
                                            ? ChristmasThemeConfig.champagneGold
                                            : ChristmasThemeConfig.crimsonGlow)
                                        .withValues(alpha: 0.5 * twinkle),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: ChristmasThemeConfig.snowWhite,
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2.5,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        ChristmasThemeConfig.champagneGold,
                                        ChristmasThemeConfig.warmGold.withValues(alpha: 0.35),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedExpIndex = idx),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? ChristmasThemeConfig.burgundy.withValues(alpha: 0.34)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? ChristmasThemeConfig.champagneGold
                                            .withValues(alpha: 0.85)
                                        : Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          exp.orgName,
                                          style: context.bodyLarge.copyWith(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: ChristmasThemeConfig.champagneGold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ChristmasThemeConfig.icyBlue
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '${exp.startDate} — ${exp.endDate}',
                                            style: context.bodySmall.copyWith(
                                              fontSize: 11.5,
                                              color: ChristmasThemeConfig.icyBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      exp.title,
                                      style: context.bodyMedium.copyWith(
                                        fontSize: 15,
                                        color: ChristmasThemeConfig.snowWhite,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: exp.detailsList
                                          .map(
                                            (d) => _FestiveBadge(
                                              label: d,
                                              isGold: selected,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectsSection(BuildContext context, double maxW) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        final projects =
            state.projectList.isNotEmpty ? state.projectList : projectList;

        return _FrostedChristmasCard(
          glowColor: ChristmasThemeConfig.crimsonGlow,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.card_giftcard_rounded,
                eyebrow: 'WINTER SHOWCASE',
                title: 'Projects',
                accent: ChristmasThemeConfig.champagneGold,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final cols = w >= 920 ? 3 : (w >= 580 ? 2 : 1);
                  const spacing = 14.0;
                  final itemW = (w - spacing * (cols - 1)) / cols;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: projects.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final project = entry.value;
                      return SizedBox(
                        width: math.max(200, itemW),
                        child: _ChristmasProjectCard(
                          project: project,
                          elapsedSeconds: _elapsedSeconds,
                          reducedMotion: _reducedMotion,
                          hasInternalSnow: idx.isEven,
                          seed: 100 + idx,
                          onOpenDetail: () => _showProjectDialog(project),
                          onLaunch: () => _openProjectAction(project),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkillsSection(BuildContext context, double maxW) {
    return BlocBuilder<SkillDetailsBloc, SkillsState>(
      builder: (context, state) {
        final skills =
            state.skillDetails.isNotEmpty ? state.skillDetails : skillsList;

        return _FrostedChristmasCard(
          glowColor: ChristmasThemeConfig.icyBlue,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.auto_awesome_rounded,
                eyebrow: 'FROST & GOLD STACK',
                title: 'Skills & Technologies',
                accent: ChristmasThemeConfig.icyBlue,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: skills.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final skill = entry.value;
                  final hasSvg = _supportedSkillSvgs.contains(skill.iconName);
                  return _GlowingSkillBadge(
                    title: skill.title.trim(),
                    svgName: hasSvg ? skill.iconName : null,
                    isGold: idx.isEven,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactSection(BuildContext context, double maxW) {
    final isWide = maxW >= 780;

    return BlocBuilder<ContactDetailsBloc, ContactDetailsState>(
      builder: (context, state) {
        final contacts = state.contactDetailList.isNotEmpty
            ? state.contactDetailList
            : contactDetailsList;

        final wreathWidget = SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(
            painter: ChristmasWreathPainter(
              elapsedSeconds: _elapsedSeconds,
              reducedMotion: _reducedMotion,
            ),
          ),
        );

        final contactBody = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.mark_email_read_rounded,
              eyebrow: 'SEASON\'S GREETINGS',
              title: 'Get In Touch',
              accent: ChristmasThemeConfig.champagneGold,
            ),
            const SizedBox(height: 10),
            Text(
              'Let\'s build something memorable together this holiday season and beyond.',
              style: context.bodySmall.copyWith(
                fontSize: 14.5,
                color: ChristmasThemeConfig.snowWhite.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: contacts.map((ContactDetails item) {
                final title = item.title.trim();
                final detail = item.details.trim().replaceAll('\n', ' ');
                final copied = _copiedContactKey == title;
                final icon = switch (item.type) {
                  'mobile' => Icons.phone_rounded,
                  'email' => Icons.email_rounded,
                  _ => Icons.location_on_rounded,
                };

                return Container(
                  constraints: const BoxConstraints(minWidth: 230),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ChristmasThemeConfig.champagneGold.withValues(alpha: 0.38),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _launchExternal(item.link),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 18,
                                  color: ChristmasThemeConfig.champagneGold,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: context.bodySmall.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: ChristmasThemeConfig.champagneGold,
                                        ),
                                      ),
                                      Text(
                                        detail,
                                        style: context.bodySmall.copyWith(
                                          fontSize: 13,
                                          color: ChristmasThemeConfig.snowWhite,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (item.type == 'email' || item.type == 'mobile') ...[
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Copy $title',
                          onPressed: () => _copyText(title, detail),
                          iconSize: 16,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            copied ? Icons.check_rounded : Icons.copy_rounded,
                            color: copied
                                ? const Color(0xFF34D399)
                                : ChristmasThemeConfig.icyBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _GoldGradientButton(
                  label: 'Send Email',
                  icon: Icons.send_rounded,
                  onTap: () => _launchExternal('mailto:${emailText.trim()}'),
                ),
                _FestiveOutlinedButton(
                  label: 'Resume PDF',
                  icon: Icons.description_rounded,
                  color: ChristmasThemeConfig.icyBlue,
                  onTap: () => _launchExternal(resumeLink),
                ),
                _SocialChip(
                  label: 'GitHub',
                  icon: FontAwesomeIcons.github,
                  onTap: () => _launchExternal(githubLink),
                ),
                _SocialChip(
                  label: 'LinkedIn',
                  icon: FontAwesomeIcons.linkedinIn,
                  onTap: () => _launchExternal(linkedInLink),
                ),
                _SocialChip(
                  label: 'Instagram',
                  icon: FontAwesomeIcons.instagram,
                  onTap: () => _launchExternal(instaLink),
                ),
                _SocialChip(
                  label: 'Facebook',
                  icon: FontAwesomeIcons.facebook,
                  onTap: () => _launchExternal(fbLink),
                ),
              ],
            ),
          ],
        );

        return _FrostedChristmasCard(
          glowColor: ChristmasThemeConfig.pineEmerald,
          padding: const EdgeInsets.all(24),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: contactBody),
                    const SizedBox(width: 24),
                    wreathWidget,
                  ],
                )
              : Column(
                  children: [
                    wreathWidget,
                    const SizedBox(height: 14),
                    contactBody,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Center(
        child: Wrap(
          spacing: 14,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            Text(
              'Merry Christmas & Happy New Year • © ${DateTime.now().year} Sivaprasad NK',
              style: context.bodySmall.copyWith(
                fontSize: 12.5,
                color: ChristmasThemeConfig.snowWhite.withValues(alpha: 0.72),
              ),
            ),
            _FooterLink(label: 'Classic /v4', onTap: _openV4Classic),
            _FooterLink(label: '3D Racer /v2', onTap: _openRacingV2),
            _FooterLink(label: '3D Solar /v3', onTap: _openSolarV3),
            _FooterLink(
              label: 'GitHub',
              onTap: () => _launchExternal(githubLink),
            ),
            _FooterLink(
              label: 'LinkedIn',
              onTap: () => _launchExternal(linkedInLink),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrostedChristmasCard extends StatelessWidget {
  const _FrostedChristmasCard({
    required this.child,
    required this.glowColor,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color glowColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ChristmasThemeConfig.deepNavy.withValues(alpha: 0.72),
                ChristmasThemeConfig.midnightBlue.withValues(alpha: 0.80),
              ],
            ),
            border: Border.all(
              color: glowColor.withValues(alpha: 0.34),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ScrollRevealSection extends StatelessWidget {
  const _ScrollRevealSection({
    required this.revealProgress,
    required this.child,
  });

  final double revealProgress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = revealProgress.clamp(0.0, 1.0);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: 0.25 + 0.75 * p,
      child: Transform.translate(
        offset: Offset(0, (1.0 - p) * 16),
        child: child,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.accent,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: context.bodySmall.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 1.4,
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: context.displaySmall.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ChristmasThemeConfig.snowWhite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChristmasProjectCard extends StatefulWidget {
  const _ChristmasProjectCard({
    required this.project,
    required this.elapsedSeconds,
    required this.reducedMotion,
    required this.hasInternalSnow,
    required this.seed,
    required this.onOpenDetail,
    required this.onLaunch,
  });

  final ProjectDetails project;
  final double elapsedSeconds;
  final bool reducedMotion;
  final bool hasInternalSnow;
  final int seed;
  final VoidCallback onOpenDetail;
  final VoidCallback onLaunch;

  @override
  State<_ChristmasProjectCard> createState() => _ChristmasProjectCardState();
}

class _ChristmasProjectCardState extends State<_ChristmasProjectCard> {
  bool _hovered = false;
  Offset _localHoverNorm = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final hasWeb = p.webUrl.isNotEmpty;
    final actionLabel = hasWeb ? 'Live Demo' : 'Play Store';

    final tiltX = (_hovered && !widget.reducedMotion) ? -_localHoverNorm.dy * 0.05 : 0.0;
    final tiltY = (_hovered && !widget.reducedMotion) ? _localHoverNorm.dx * 0.05 : 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _localHoverNorm = Offset.zero;
      }),
      onHover: (event) {
        if (widget.reducedMotion) return;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || box.size.isEmpty) return;
        final nx = ((event.localPosition.dx / box.size.width) * 2 - 1).clamp(-1.0, 1.0);
        final ny = ((event.localPosition.dy / box.size.height) * 2 - 1).clamp(-1.0, 1.0);
        setState(() => _localHoverNorm = Offset(nx, ny));
      },
      child: GestureDetector(
        onTap: widget.onOpenDetail,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(tiltX)
            ..rotateY(tiltY),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _hovered
                        ? ChristmasThemeConfig.burgundy.withValues(alpha: 0.36)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _hovered
                          ? ChristmasThemeConfig.champagneGold
                          : Colors.white.withValues(alpha: 0.16),
                      width: _hovered ? 1.4 : 1.0,
                    ),
                    boxShadow: _hovered
                        ? [
                            BoxShadow(
                              color: ChristmasThemeConfig.champagneGold
                                  .withValues(alpha: 0.22),
                              blurRadius: 18,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.projName,
                              style: context.bodyLarge.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: ChristmasThemeConfig.snowWhite,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: 17,
                            color: _hovered
                                ? ChristmasThemeConfig.champagneGold
                                : ChristmasThemeConfig.icyBlue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.descList.join(' • ').replaceAll('\n', ' '),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodySmall.copyWith(
                          fontSize: 13,
                          height: 1.4,
                          color: ChristmasThemeConfig.snowWhite
                              .withValues(alpha: 0.80),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: p.techStackList
                            .map((t) => _FestiveBadge(label: t, isGold: false))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onLaunch,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: ChristmasThemeConfig.goldActionGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              actionLabel,
                              style: context.bodySmall.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: ChristmasThemeConfig.midnightBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.hasInternalSnow || _hovered)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: CardSnowfallPainter(
                          elapsedSeconds: widget.elapsedSeconds,
                          seed: widget.seed,
                          reducedMotion: widget.reducedMotion,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowingSkillBadge extends StatefulWidget {
  const _GlowingSkillBadge({
    required this.title,
    required this.svgName,
    required this.isGold,
  });

  final String title;
  final String? svgName;
  final bool isGold;

  @override
  State<_GlowingSkillBadge> createState() => _GlowingSkillBadgeState();
}

class _GlowingSkillBadgeState extends State<_GlowingSkillBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.isGold
        ? ChristmasThemeConfig.champagneGold
        : ChristmasThemeConfig.icyBlue;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 160),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: _hovered ? 0.22 : 0.11),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accent.withValues(alpha: _hovered ? 0.95 : 0.48),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.30),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.svgName != null)
                SvgPicture.asset(
                  'assets/svg/${widget.svgName}.svg',
                  width: 18,
                  height: 18,
                )
              else
                Icon(Icons.code_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: context.bodySmall.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: ChristmasThemeConfig.snowWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavHoverLink extends StatefulWidget {
  const _NavHoverLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_NavHoverLink> createState() => _NavHoverLinkState();
}

class _NavHoverLinkState extends State<_NavHoverLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? ChristmasThemeConfig.champagneGold.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: context.bodySmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: _hovered
                  ? ChristmasThemeConfig.champagneGold
                  : ChristmasThemeConfig.snowWhite.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavPortalPill extends StatelessWidget {
  const _NavPortalPill({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.72)),
          ),
          child: Text(
            label,
            style: context.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldGradientButton extends StatelessWidget {
  const _GoldGradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: ChristmasThemeConfig.goldActionGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ChristmasThemeConfig.champagneGold.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: ChristmasThemeConfig.midnightBlue),
              const SizedBox(width: 7),
              Text(
                label,
                style: context.bodySmall.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: ChristmasThemeConfig.midnightBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FestiveOutlinedButton extends StatelessWidget {
  const _FestiveOutlinedButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.65)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: context.bodySmall.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: ChristmasThemeConfig.snowWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: ChristmasThemeConfig.champagneGold),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.bodySmall.copyWith(
                  fontSize: 11.5,
                  color: ChristmasThemeConfig.snowWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FestiveBadge extends StatelessWidget {
  const _FestiveBadge({required this.label, required this.isGold});

  final String label;
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    final color = isGold
        ? ChristmasThemeConfig.champagneGold
        : ChristmasThemeConfig.icyBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        label,
        style: context.bodySmall.copyWith(
          fontSize: 11.5,
          color: ChristmasThemeConfig.snowWhite.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: context.bodySmall.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: ChristmasThemeConfig.champagneGold,
          ),
        ),
      ),
    );
  }
}
