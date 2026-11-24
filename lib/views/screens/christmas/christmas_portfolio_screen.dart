import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spnk/domain/entity/contact_details.dart';
import 'package:spnk/domain/entity/experience_details.dart';
import 'package:spnk/domain/entity/project_details.dart';
import 'package:spnk/domain/entity/skill_details.dart';
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
import 'package:spnk/views/screens/christmas/winter_3d_bridge.dart';
import 'package:spnk/views/screens/christmas/winter_village_widgets.dart';
import 'package:spnk/views/screens/home/grid/interactive_grid_home_screen.dart';
import 'package:spnk/views/screens/qrcode/qr_code_screen.dart';
import 'package:spnk/views/screens/racing/racing_portfolio_screen.dart';
import 'package:spnk/views/screens/solar/solar_system_screen.dart';
import 'package:spnk/views/screens/yt_downloader/yt_downloader_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Interactive 3D Christmas Winter Village portfolio screen for sivaprasadnk.dev.
class ChristmasPortfolioScreen extends StatefulWidget {
  const ChristmasPortfolioScreen({super.key});

  @override
  State<ChristmasPortfolioScreen> createState() =>
      _ChristmasPortfolioScreenState();
}

class _ChristmasPortfolioScreenState extends State<ChristmasPortfolioScreen>
    with TickerProviderStateMixin {
  static const Set<String> _supportedSkillSvgs = {
    'dart',
    'flutter',
    'firebase2',
    'html',
    'css',
  };

  /// Remembers user's manual Day/Night choice across route transitions in session.
  static bool? _sessionDayPreference;

  late final Ticker _ticker;
  late final AnimationController _dayNightController;
  late final Winter3dBridge _winterBridge;
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
  double _scrollFraction = 0.0;
  Offset _pointerNorm = Offset.zero;
  bool _snowEnabled = true;
  bool _reducedMotion = false;
  late bool _isDayMode;
  String _activeSectionId = 'home';
  int _selectedExpIndex = 0;
  String? _copiedContactKey;

  @override
  void initState() {
    super.initState();
    _isDayMode =
        _sessionDayPreference ?? ChristmasThemeConfig.isDayTime(DateTime.now());
    _dayNightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      value: _isDayMode ? 1.0 : 0.0,
    )..addListener(_onDayNightAnimationTick);

    _winterBridge = createWinter3dBridge();
    if (_winterBridge.isSupported) {
      _winterBridge.mountView();
      _sync3dEngine();
    }

    _snowSim.ensureInitialized();
    _scrollController.addListener(_onScroll);
    _ticker = createTicker(_onTick)..start();
  }

  void _onDayNightAnimationTick() {
    if (!mounted) return;
    _sync3dEngine();
    setState(() {});
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final maxScroll = pos.maxScrollExtent > 0 ? pos.maxScrollExtent : 1.0;
    final fraction = (pos.pixels / maxScroll).clamp(0.0, 1.0);
    setState(() {
      _scrollOffset = pos.pixels;
      _scrollFraction = fraction;
      _activeSectionId = _detectActiveSection(fraction);
    });
    _sync3dEngine();
  }

  String _detectActiveSection(double fraction) {
    if (fraction < 0.14) return 'home';
    if (fraction < 0.30) return 'about';
    if (fraction < 0.48) return 'experience';
    if (fraction < 0.70) return 'projects';
    if (fraction < 0.86) return 'skills';
    return 'contact';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion != disable) {
      _reducedMotion = disable;
      _sync3dEngine();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _dayNightController.dispose();
    _scrollController.dispose();
    _winterBridge.dispose();
    super.dispose();
  }

  void _sync3dEngine() {
    if (!_winterBridge.isSupported) return;
    _winterBridge.syncState(
      jsonEncode({
        'dayFactor': _dayNightController.value,
        'scrollFraction': _scrollFraction,
        'pointerX': _pointerNorm.dx,
        'pointerY': _pointerNorm.dy,
        'snowEnabled': _snowEnabled,
        'reducedMotion': _reducedMotion,
      }),
    );
  }

  void _toggleDayNight() {
    final nextDay = !_isDayMode;
    setState(() {
      _isDayMode = nextDay;
      _sessionDayPreference = nextDay;
    });
    if (_reducedMotion) {
      _dayNightController.value = nextDay ? 1.0 : 0.0;
      _sync3dEngine();
    } else if (nextDay) {
      _dayNightController.forward();
    } else {
      _dayNightController.reverse();
    }
  }

  void _toggleSnow() {
    setState(() => _snowEnabled = !_snowEnabled);
    _sync3dEngine();
  }

  void _scrollToSection(String sectionId) {
    setState(() => _activeSectionId = sectionId);
    final key = switch (sectionId) {
      'home' => _heroKey,
      'about' => _aboutKey,
      'experience' => _experienceKey,
      'projects' => _projectsKey,
      'skills' => _skillsKey,
      'contact' => _contactKey,
      _ => _heroKey,
    };
    final targetContext = key.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: _reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 680),
        curve: Curves.easeInOutCubic,
        alignment: 0.06,
      );
    }
  }

  void _handleBackgroundTap(TapDownDetails details, Size viewport) {
    if (!_winterBridge.isSupported ||
        viewport.width <= 0 ||
        viewport.height <= 0) {
      return;
    }
    final nx = (details.localPosition.dx / viewport.width) * 2.0 - 1.0;
    final ny = -(details.localPosition.dy / viewport.height) * 2.0 + 1.0;
    final hitSection = _winterBridge.raycast(nx, ny);
    if (hitSection.isNotEmpty) {
      _scrollToSection(hitSection);
    }
  }

  void _openClassicV4() {
    Navigator.of(context).pushNamed(InteractiveGridHomeScreen.routeName);
  }

  void _openRacingV2() {
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
      debugPrint('Error launching $trimmed: $e');
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
    final dayFactor = _dayNightController.value;
    final primaryText = ChristmasThemeConfig.primaryText(dayFactor);
    final secondaryText = ChristmasThemeConfig.secondaryText(dayFactor);
    final goldAccent = ChristmasThemeConfig.accentGold(dayFactor);

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: VillageFrostPanel(
            dayFactor: dayFactor,
            woodenAccent: true,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.ac_unit_rounded, color: goldAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        project.projName,
                        style: context.displaySmall.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close_rounded, color: goldAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: project.techStackList
                      .map(
                        (tech) => _OrnamentChip(
                          label: tech,
                          dayFactor: dayFactor,
                          isGold: true,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                ...project.descList.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•  ',
                          style: TextStyle(
                            color: goldAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            d.replaceAll('\n', ' ').trim(),
                            style: context.bodySmall.copyWith(
                              fontSize: 13.5,
                              height: 1.45,
                              color: secondaryText,
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
                    if (project.webUrl.isNotEmpty ||
                        project.playStoreUrl.isNotEmpty)
                      _GoldVillageButton(
                        label: 'Open Project',
                        icon: Icons.open_in_new_rounded,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _openProjectAction(project);
                        },
                      ),
                    if (project.playStoreUrl.isNotEmpty &&
                        project.webUrl.isNotEmpty)
                      _FrostOutlineButton(
                        label: 'Play Store / APK',
                        dayFactor: dayFactor,
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
    final dayFactor = _dayNightController.value;
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 680;
    final isCompact = size.width < 920;

    return Scaffold(
      backgroundColor: ChristmasThemeConfig.skyTop(dayFactor),
      body: MouseRegion(
        onHover: (event) {
          if (size.width <= 0 || size.height <= 0) return;
          _pointerNorm = Offset(
            ((event.position.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
            ((event.position.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
          );
          if (_snowEnabled && !_reducedMotion && !_winterBridge.isSupported) {
            _snowSim.addCursorFlake(event.position, _elapsedSeconds);
          }
          _sync3dEngine();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (d) => _handleBackgroundTap(d, size),
          child: Stack(
            children: [
              // Layer 1: Living 3D Winter Village (Three.js on Web, graceful 2D fallback otherwise)
              Positioned.fill(
                child: IgnorePointer(
                  child: _winterBridge.isSupported
                      ? _winterBridge.buildView()
                      : CustomPaint(
                          painter: WinterVillageFallbackPainter(
                            dayFactor: dayFactor,
                            elapsed: _elapsedSeconds,
                            scrollOffset: _scrollOffset,
                            pointerNorm: _pointerNorm,
                            snowEnabled: _snowEnabled,
                            reducedMotion: _reducedMotion,
                            snowSim: _snowSim,
                            renderEnvironment: true,
                          ),
                        ),
                ),
              ),

              // Layer 2: Soft ambient foreground snow veil on Web (keeps depth crisp)
              if (_winterBridge.isSupported && _snowEnabled && !kIsWeb)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: WinterVillageFallbackPainter(
                        dayFactor: dayFactor,
                        elapsed: _elapsedSeconds,
                        scrollOffset: _scrollOffset,
                        pointerNorm: _pointerNorm,
                        snowEnabled: _snowEnabled,
                        reducedMotion: _reducedMotion,
                        snowSim: _snowSim,
                        renderEnvironment: false,
                      ),
                    ),
                  ),
                ),

              // Layer 3: Scrollable Environmental Portfolio Content
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isMobile ? 168 : (isCompact ? 132 : 112),
                      bottom: 40,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 14 : 28,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeroVillageSignboard(
                                dayFactor: dayFactor,
                                isMobile: isMobile,
                                isCompact: isCompact,
                              ),
                              SizedBox(height: isMobile ? 42 : 76),
                              _buildAboutCabinSection(
                                dayFactor: dayFactor,
                                isMobile: isMobile,
                              ),
                              SizedBox(height: isMobile ? 42 : 76),
                              _buildExperiencePathwaySection(
                                dayFactor: dayFactor,
                                isMobile: isMobile,
                              ),
                              SizedBox(height: isMobile ? 42 : 76),
                              _buildProjectsPavilionsSection(
                                dayFactor: dayFactor,
                                isMobile: isMobile,
                                isCompact: isCompact,
                              ),
                              SizedBox(height: isMobile ? 42 : 76),
                              _buildSkillsCrystalSection(
                                dayFactor: dayFactor,
                                isMobile: isMobile,
                              ),
                              SizedBox(height: isMobile ? 42 : 76),
                              _buildContactHearthSection(
                                dayFactor: dayFactor,
                                isMobile: isMobile,
                              ),
                              SizedBox(height: isMobile ? 32 : 52),
                              _buildHorizonFooter(dayFactor: dayFactor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Layer 4: Top Floating Clouds Navigation & Controls (NO rectangular navbar)
              Positioned(
                top: MediaQuery.paddingOf(context).top + (isMobile ? 10 : 14),
                left: isMobile ? 84 : 106,
                right: isMobile ? 10 : 20,
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WinterControlCluster(
                            isDayMode: _isDayMode,
                            dayFactor: dayFactor,
                            snowEnabled: _snowEnabled,
                            compact: true,
                            onToggleDayNight: _toggleDayNight,
                            onToggleSnow: _toggleSnow,
                            onOpenClassicV4: _openClassicV4,
                            onOpenRacerV2: _openRacingV2,
                            onOpenSolarV3: _openSolarV3,
                          ),
                          const SizedBox(height: 8),
                          FloatingCloudNavigation(
                            items: kWinterCloudNavItems,
                            activeSectionId: _activeSectionId,
                            elapsed: _elapsedSeconds,
                            dayFactor: dayFactor,
                            reducedMotion: _reducedMotion,
                            onSelect: _scrollToSection,
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FloatingCloudNavigation(
                                    items: kWinterCloudNavItems,
                                    activeSectionId: _activeSectionId,
                                    elapsed: _elapsedSeconds,
                                    dayFactor: dayFactor,
                                    reducedMotion: _reducedMotion,
                                    onSelect: _scrollToSection,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              WinterControlCluster(
                                isDayMode: _isDayMode,
                                dayFactor: dayFactor,
                                snowEnabled: _snowEnabled,
                                compact: isCompact,
                                onToggleDayNight: _toggleDayNight,
                                onToggleSnow: _toggleSnow,
                                onOpenClassicV4: _openClassicV4,
                                onOpenRacerV2: _openRacingV2,
                                onOpenSolarV3: _openSolarV3,
                              ),
                            ],
                          ),
                        ],
                      ),
              ),

              // Layer 5: Fixed Top-Left SP Glass Snow Globe
              Positioned(
                top: MediaQuery.paddingOf(context).top + (isMobile ? 10 : 14),
                left: isMobile ? 10 : 18,
                child: SpGlassSnowGlobe(
                  elapsed: _elapsedSeconds,
                  dayFactor: dayFactor,
                  reducedMotion: _reducedMotion,
                  size: isMobile ? 54 : 66,
                  onTap: () => _scrollToSection('home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroVillageSignboard({
    required double dayFactor,
    required bool isMobile,
    required bool isCompact,
  }) {
    final countdown = ChristmasThemeConfig.countdownLabel(DateTime.now());
    final primaryText = ChristmasThemeConfig.primaryText(dayFactor);
    final secondaryText = ChristmasThemeConfig.secondaryText(dayFactor);
    final goldAccent = ChristmasThemeConfig.accentGold(dayFactor);

    final introBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _OrnamentChip(
              label: 'Merry Christmas & Happy New Year!',
              dayFactor: dayFactor,
              isGold: true,
              leadingIcon: Icons.park_rounded,
            ),
            _OrnamentChip(
              label: countdown,
              dayFactor: dayFactor,
              isGold: false,
              leadingIcon: Icons.celebration_rounded,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Sivaprasad NK',
          style: context.displaySmall.copyWith(
            fontSize: isMobile ? 34 : 52,
            fontWeight: FontWeight.w900,
            height: 1.06,
            letterSpacing: -0.6,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Senior Software Engineer (5 Years)  •  AI Coding, Flutter & Interactive 3D Web',
          style: context.bodyLarge.copyWith(
            fontSize: isMobile ? 15.5 : 18.5,
            fontWeight: FontWeight.w700,
            color: goldAccent,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Welcome to my living Winter Wonderland portfolio. Wander through snow-covered cabins, lit pine groves, igloos, roaming reindeer, and festive showcases of my mobile and web engineering work.',
          style: context.bodyMedium.copyWith(
            fontSize: isMobile ? 14 : 15.5,
            height: 1.55,
            color: secondaryText,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _GoldVillageButton(
              label: 'Explore Projects',
              icon: Icons.explore_rounded,
              onTap: () => _scrollToSection('projects'),
            ),
            _FrostOutlineButton(
              label: 'Get In Touch',
              dayFactor: dayFactor,
              icon: Icons.mail_outline_rounded,
              onTap: () => _scrollToSection('contact'),
            ),
            _FrostOutlineButton(
              label: 'Download Resume',
              dayFactor: dayFactor,
              icon: Icons.description_outlined,
              onTap: () => _launchExternal(resumeLink),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Tip: Tap the floating sky clouds, SP snow globe, or village buildings in the 3D scene to travel.',
          style: context.bodySmall.copyWith(
            fontSize: 12,
            color: secondaryText.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );

    final profileCard = VillageFrostPanel(
      dayFactor: dayFactor,
      woodenAccent: true,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      child: Column(
        children: [
          Container(
            width: isMobile ? 108 : 132,
            height: isMobile ? 108 : 132,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ChristmasThemeConfig.champagneGold,
                  ChristmasThemeConfig.icyBlue,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: goldAccent.withValues(alpha: 0.32),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/propic3.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ernakulam, Kerala • India',
            textAlign: TextAlign.center,
            style: context.bodySmall.copyWith(
              color: secondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _OrnamentChip(
                label: 'Arcade Hub',
                dayFactor: dayFactor,
                isGold: false,
                onTap: () =>
                    Navigator.of(context).pushNamed(ArcadeScreen.routeName),
              ),
              _OrnamentChip(
                label: 'QR Tool',
                dayFactor: dayFactor,
                isGold: false,
                onTap: () =>
                    Navigator.of(context).pushNamed(QrCodeScreen.routeName),
              ),
              _OrnamentChip(
                label: 'YT Downloader',
                dayFactor: dayFactor,
                isGold: false,
                onTap: () => Navigator.of(context)
                    .pushNamed(YtDownloaderScreen.routeName),
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      key: _heroKey,
      child: VillageFrostPanel(
        dayFactor: dayFactor,
        woodenAccent: true,
        padding: EdgeInsets.all(isMobile ? 20 : 34),
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  introBlock,
                  const SizedBox(height: 24),
                  profileCard,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 7, child: introBlock),
                  const SizedBox(width: 28),
                  Expanded(flex: 4, child: profileCard),
                ],
              ),
      ),
    );
  }

  Widget _buildAboutCabinSection({
    required double dayFactor,
    required bool isMobile,
  }) {
    final primaryText = ChristmasThemeConfig.primaryText(dayFactor);
    final secondaryText = ChristmasThemeConfig.secondaryText(dayFactor);
    final goldAccent = ChristmasThemeConfig.accentGold(dayFactor);

    return Container(
      key: _aboutKey,
      child: VillageFrostPanel(
        dayFactor: dayFactor,
        padding: EdgeInsets.all(isMobile ? 20 : 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VillageSectionHeader(
              title: 'About Me',
              subtitle: 'Warm Winter Cabin Sanctuary',
              icon: Icons.cottage_rounded,
              dayFactor: dayFactor,
            ),
            const SizedBox(height: 18),
            BlocBuilder<AboutMeBloc, AboutMeState>(
              builder: (context, state) {
                return Text(
                  state.content,
                  style: context.bodyMedium.copyWith(
                    fontSize: isMobile ? 14.5 : 16,
                    height: 1.68,
                    color: primaryText,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CabinHighlightCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI Coding & Architecture',
                  subtitle: '5 Years Experience • Agentic AI Workflows & Clean BLoC Systems',
                  dayFactor: dayFactor,
                  accent: goldAccent,
                ),
                _CabinHighlightCard(
                  icon: Icons.devices_rounded,
                  title: 'Multi-Platform Craft',
                  subtitle: 'Flutter Android, iOS, macOS, WebAssembly & 3D Web',
                  dayFactor: dayFactor,
                  accent: ChristmasThemeConfig.accentIce(dayFactor),
                ),
                _CabinHighlightCard(
                  icon: Icons.directions_run_rounded,
                  title: 'Endurance Athlete',
                  subtitle: 'Regular Gym Training, Distance Running & Daily Discipline',
                  dayFactor: dayFactor,
                  accent: goldAccent,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Building reliable, memorable software crafted with attention to performance and delight.',
              style: context.bodySmall.copyWith(
                fontSize: 12.5,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperiencePathwaySection({
    required double dayFactor,
    required bool isMobile,
  }) {
    final primaryText = ChristmasThemeConfig.primaryText(dayFactor);
    final secondaryText = ChristmasThemeConfig.secondaryText(dayFactor);
    final goldAccent = ChristmasThemeConfig.accentGold(dayFactor);

    return Container(
      key: _experienceKey,
      child: VillageFrostPanel(
        dayFactor: dayFactor,
        padding: EdgeInsets.all(isMobile ? 20 : 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VillageSectionHeader(
              title: 'Experience',
              subtitle: 'Golden Lantern Trail Through Past Roles',
              icon: Icons.alt_route_rounded,
              dayFactor: dayFactor,
            ),
            const SizedBox(height: 20),
            BlocBuilder<ExpDetailsBloc, ExpDetailsState>(
              builder: (context, state) {
                final sorted = List<ExperienceDetails>.from(state.expList)
                  ..sort((a, b) => b.order.compareTo(a.order));
                if (sorted.isEmpty) {
                  return const SizedBox.shrink();
                }
                final safeIdx = _selectedExpIndex.clamp(0, sorted.length - 1);
                final selected = sorted[safeIdx];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Golden Pathway Stepper
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < sorted.length; i++) ...[
                            InkWell(
                              onTap: () =>
                                  setState(() => _selectedExpIndex = i),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: i == safeIdx
                                      ? goldAccent.withValues(alpha: 0.18)
                                      : ChristmasThemeConfig.cardSurface(
                                              dayFactor)
                                          .withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: i == safeIdx
                                        ? goldAccent
                                        : ChristmasThemeConfig.cardBorder(
                                            dayFactor),
                                    width: i == safeIdx ? 1.6 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: i == safeIdx
                                            ? goldAccent
                                            : secondaryText.withValues(
                                                alpha: 0.45),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      sorted[i].orgName,
                                      style: TextStyle(
                                        color: primaryText,
                                        fontWeight: i == safeIdx
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (i < sorted.length - 1)
                              Container(
                                width: 22,
                                height: 2,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                color: goldAccent.withValues(alpha: 0.65),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Selected Milestone Details
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: ChristmasThemeConfig.cardSurface(dayFactor)
                            .withValues(alpha: 0.72),
                        border: Border.all(
                          color: goldAccent.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              Text(
                                selected.title,
                                style: context.displaySmall.copyWith(
                                  fontSize: isMobile ? 18 : 21,
                                  fontWeight: FontWeight.w800,
                                  color: primaryText,
                                ),
                              ),
                              _OrnamentChip(
                                label:
                                    '${selected.startDate} — ${selected.endDate}',
                                dayFactor: dayFactor,
                                isGold: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selected.orgName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: goldAccent,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...selected.detailsList.map(
                            (bullet) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: goldAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      bullet,
                                      style: context.bodySmall.copyWith(
                                        fontSize: 13.5,
                                        height: 1.5,
                                        color: secondaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsPavilionsSection({
    required double dayFactor,
    required bool isMobile,
    required bool isCompact,
  }) {
    return Container(
      key: _projectsKey,
      child: VillageFrostPanel(
        dayFactor: dayFactor,
        padding: EdgeInsets.all(isMobile ? 20 : 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VillageSectionHeader(
              title: 'Projects',
              subtitle: 'Snow-Capped Village Showcase Pavilions',
              icon: Icons.storefront_rounded,
              dayFactor: dayFactor,
            ),
            const SizedBox(height: 20),
            BlocBuilder<ProjectBloc, ProjectState>(
              builder: (context, state) {
                final list = state.projectList;
                final cols = isMobile ? 1 : (isCompact ? 2 : 3);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 16.0;
                    final cardWidth =
                        (constraints.maxWidth - spacing * (cols - 1)) / cols;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (int i = 0; i < list.length; i++)
                          SizedBox(
                            width: cardWidth,
                            child: _ProjectPavilionCard(
                              project: list[i],
                              index: i,
                              dayFactor: dayFactor,
                              onDetails: () => _showProjectDialog(list[i]),
                              onLaunch: () => _openProjectAction(list[i]),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsCrystalSection({
    required double dayFactor,
    required bool isMobile,
  }) {
    return Container(
      key: _skillsKey,
      child: VillageFrostPanel(
        dayFactor: dayFactor,
        padding: EdgeInsets.all(isMobile ? 20 : 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VillageSectionHeader(
              title: 'Skills & Technologies',
              subtitle: 'Crystal Ornaments & Technical Craft',
              icon: Icons.ac_unit_rounded,
              dayFactor: dayFactor,
            ),
            const SizedBox(height: 18),
            BlocBuilder<SkillDetailsBloc, SkillsState>(
              builder: (context, state) {
                final skills = List<SkillDetails>.from(state.skillDetails)
                  ..sort((a, b) => a.index.compareTo(b.index));
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (int i = 0; i < skills.length; i++)
                      _CrystalSkillTile(
                        skill: skills[i],
                        hasSvg: _supportedSkillSvgs.contains(skills[i].iconName),
                        dayFactor: dayFactor,
                        isGold: i.isEven,
                        onTap: skills[i].link.isNotEmpty
                            ? () => _launchExternal(skills[i].link)
                            : null,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactHearthSection({
    required double dayFactor,
    required bool isMobile,
  }) {
    final primaryText = ChristmasThemeConfig.primaryText(dayFactor);
    final secondaryText = ChristmasThemeConfig.secondaryText(dayFactor);
    final goldAccent = ChristmasThemeConfig.accentGold(dayFactor);

    return Container(
      key: _contactKey,
      child: VillageFrostPanel(
        dayFactor: dayFactor,
        woodenAccent: true,
        padding: EdgeInsets.all(isMobile ? 20 : 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VillageSectionHeader(
              title: 'Get In Touch',
              subtitle: 'Warm Village Hearth & Direct Contact',
              icon: Icons.mark_email_read_rounded,
              dayFactor: dayFactor,
            ),
            const SizedBox(height: 16),
            Text(
              'Open to senior Flutter & cross-platform roles, architecture consulting, and creative web builds.',
              style: context.bodyMedium.copyWith(
                fontSize: 15,
                height: 1.5,
                color: secondaryText,
              ),
            ),
            const SizedBox(height: 18),
            BlocBuilder<ContactDetailsBloc, ContactDetailsState>(
              builder: (context, state) {
                final contacts =
                    List<ContactDetails>.from(state.contactDetailList)
                      ..sort((a, b) => a.index.compareTo(b.index));
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: contacts.map((c) {
                    final copied = _copiedContactKey == c.title;
                    return InkWell(
                      onTap: () {
                        if (c.link.isNotEmpty) {
                          _launchExternal(c.link);
                        } else {
                          _copyText(c.title, c.details);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: isMobile ? 240 : 250,
                          maxWidth: 340,
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: ChristmasThemeConfig.cardSurface(dayFactor)
                              .withValues(alpha: 0.72),
                          border: Border.all(
                            color: ChristmasThemeConfig.cardBorder(dayFactor),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.alternate_email_rounded,
                              size: 18,
                              color: goldAccent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title,
                                    style: TextStyle(
                                      color: goldAccent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    copied ? 'Copied!' : c.details,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: primaryText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copy',
                              iconSize: 16,
                              onPressed: () => _copyText(c.title, c.details),
                              icon: Icon(
                                copied
                                    ? Icons.check_circle_rounded
                                    : Icons.copy_rounded,
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _GoldVillageButton(
                  label: 'Email Me',
                  icon: Icons.send_rounded,
                  onTap: () => _launchExternal('mailto:$emailText'),
                ),
                _FrostOutlineButton(
                  label: 'WhatsApp',
                  dayFactor: dayFactor,
                  icon: FontAwesomeIcons.whatsapp,
                  onTap: () => _launchExternal(whatsappWebLink),
                ),
                _FrostOutlineButton(
                  label: 'GitHub',
                  dayFactor: dayFactor,
                  icon: FontAwesomeIcons.github,
                  onTap: () => _launchExternal(githubLink),
                ),
                _FrostOutlineButton(
                  label: 'LinkedIn',
                  dayFactor: dayFactor,
                  icon: FontAwesomeIcons.linkedinIn,
                  onTap: () => _launchExternal(linkedInLink),
                ),
                _FrostOutlineButton(
                  label: 'pub.dev',
                  dayFactor: dayFactor,
                  icon: Icons.inventory_2_outlined,
                  onTap: () => _launchExternal(pubDevLink),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizonFooter({required double dayFactor}) {
    final secondaryText = ChristmasThemeConfig.secondaryText(dayFactor);
    final goldAccent = ChristmasThemeConfig.accentGold(dayFactor);

    return VillageFrostPanel(
      dayFactor: dayFactor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      borderRadius: 20,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          Text(
            '© ${DateTime.now().year} Sivaprasad NK  •  3D Winter Village Edition',
            style: TextStyle(
              color: secondaryText,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _FooterLinkChip(
                label: 'Classic /v4',
                color: goldAccent,
                onTap: _openClassicV4,
              ),
              _FooterLinkChip(
                label: '3D Racer /v2',
                color: goldAccent,
                onTap: _openRacingV2,
              ),
              _FooterLinkChip(
                label: '3D Solar /v3',
                color: goldAccent,
                onTap: _openSolarV3,
              ),
              _FooterLinkChip(
                label: 'Arcade',
                color: goldAccent,
                onTap: () =>
                    Navigator.of(context).pushNamed(ArcadeScreen.routeName),
              ),
              _FooterLinkChip(
                label: 'GitHub',
                color: goldAccent,
                onTap: () => _launchExternal(githubLink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VillageSectionHeader extends StatelessWidget {
  const _VillageSectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.dayFactor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double dayFactor;

  @override
  Widget build(BuildContext context) {
    final primaryText = ChristmasThemeConfig.primaryText(dayFactor);
    final goldAccent = ChristmasThemeConfig.accentGold(dayFactor);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: goldAccent.withValues(alpha: 0.16),
            border: Border.all(color: goldAccent.withValues(alpha: 0.45)),
          ),
          child: Icon(icon, color: goldAccent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.displaySmall.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: goldAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CabinHighlightCard extends StatelessWidget {
  const _CabinHighlightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.dayFactor,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double dayFactor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: ChristmasThemeConfig.cardSurface(dayFactor)
            .withValues(alpha: 0.65),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ChristmasThemeConfig.primaryText(dayFactor),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: ChristmasThemeConfig.secondaryText(dayFactor),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectPavilionCard extends StatefulWidget {
  const _ProjectPavilionCard({
    required this.project,
    required this.index,
    required this.dayFactor,
    required this.onDetails,
    required this.onLaunch,
  });

  final ProjectDetails project;
  final int index;
  final double dayFactor;
  final VoidCallback onDetails;
  final VoidCallback onLaunch;

  @override
  State<_ProjectPavilionCard> createState() => _ProjectPavilionCardState();
}

class _ProjectPavilionCardState extends State<_ProjectPavilionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final dayFactor = widget.dayFactor;
    final primaryText = ChristmasThemeConfig.primaryText(dayFactor);
    final secondaryText = ChristmasThemeConfig.secondaryText(dayFactor);
    final goldAccent = ChristmasThemeConfig.accentGold(dayFactor);
    final iceAccent = ChristmasThemeConfig.accentIce(dayFactor);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onDetails,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: ChristmasThemeConfig.cardSurface(dayFactor)
                .withValues(alpha: _hovered ? 0.92 : 0.74),
            border: Border.all(
              color: _hovered
                  ? goldAccent
                  : ChristmasThemeConfig.cardBorder(dayFactor),
              width: _hovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (_hovered)
                BoxShadow(
                  color: goldAccent.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Snow-capped roof accent bar
              Container(
                height: 4,
                width: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(colors: [goldAccent, iceAccent]),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.projName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: _hovered ? goldAccent : iceAccent,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p.descList.join(' • ').replaceAll('\n', ' '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 12.8,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: p.techStackList
                    .take(4)
                    .map(
                      (tech) => _OrnamentChip(
                        label: tech,
                        dayFactor: dayFactor,
                        isGold: false,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _GoldVillageButton(
                    label: 'Open',
                    icon: Icons.launch_rounded,
                    compact: true,
                    onTap: widget.onLaunch,
                  ),
                  const SizedBox(width: 8),
                  _FrostOutlineButton(
                    label: 'Details',
                    dayFactor: dayFactor,
                    compact: true,
                    onTap: widget.onDetails,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrystalSkillTile extends StatefulWidget {
  const _CrystalSkillTile({
    required this.skill,
    required this.hasSvg,
    required this.dayFactor,
    required this.isGold,
    this.onTap,
  });

  final SkillDetails skill;
  final bool hasSvg;
  final double dayFactor;
  final bool isGold;
  final VoidCallback? onTap;

  @override
  State<_CrystalSkillTile> createState() => _CrystalSkillTileState();
}

class _CrystalSkillTileState extends State<_CrystalSkillTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.isGold
        ? ChristmasThemeConfig.accentGold(widget.dayFactor)
        : ChristmasThemeConfig.accentIce(widget.dayFactor);

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: ChristmasThemeConfig.cardSurface(widget.dayFactor)
                .withValues(alpha: _hovered ? 0.92 : 0.72),
            border: Border.all(
              color: _hovered
                  ? accent
                  : accent.withValues(alpha: 0.42),
              width: _hovered ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.hasSvg) ...[
                SvgPicture.asset(
                  'assets/svg/${widget.skill.iconName}.svg',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 8),
              ] else ...[
                Icon(Icons.ac_unit_rounded, size: 15, color: accent),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.skill.title,
                  style: TextStyle(
                    color: ChristmasThemeConfig.primaryText(widget.dayFactor),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrnamentChip extends StatelessWidget {
  const _OrnamentChip({
    required this.label,
    required this.dayFactor,
    required this.isGold,
    this.leadingIcon,
    this.onTap,
  });

  final String label;
  final double dayFactor;
  final bool isGold;
  final IconData? leadingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isGold
        ? ChristmasThemeConfig.accentGold(dayFactor)
        : ChristmasThemeConfig.accentIce(dayFactor);

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 13.5, color: accent),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: ChristmasThemeConfig.primaryText(dayFactor),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: chip,
    );
  }
}

class _GoldVillageButton extends StatelessWidget {
  const _GoldVillageButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 7 : 11,
        ),
        decoration: BoxDecoration(
          gradient: ChristmasThemeConfig.goldActionGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40D4A039),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 14 : 16,
              color: ChristmasThemeConfig.midnightBlue,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: ChristmasThemeConfig.midnightBlue,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 12 : 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrostOutlineButton extends StatelessWidget {
  const _FrostOutlineButton({
    required this.label,
    required this.dayFactor,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  final String label;
  final double dayFactor;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 15,
          vertical: compact ? 7 : 11,
        ),
        decoration: BoxDecoration(
          color: ChristmasThemeConfig.cardSurface(dayFactor)
              .withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChristmasThemeConfig.cardBorder(dayFactor),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: compact ? 14 : 15,
                color: ChristmasThemeConfig.accentGold(dayFactor),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: ChristmasThemeConfig.primaryText(dayFactor),
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLinkChip extends StatelessWidget {
  const _FooterLinkChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
