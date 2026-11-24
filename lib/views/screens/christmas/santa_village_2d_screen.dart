import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spnk/domain/entity/contact_details.dart';
import 'package:spnk/domain/entity/experience_details.dart';
import 'package:spnk/domain/entity/project_details.dart';
import 'package:spnk/domain/entity/skill_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:spnk/views/bloc/about_me/about_me_bloc.dart';
import 'package:spnk/views/bloc/about_me/about_me_state.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_bloc.dart';
import 'package:spnk/views/bloc/experience/exp_details_bloc.dart';
import 'package:spnk/views/bloc/project/project_bloc.dart';
import 'package:spnk/views/bloc/skills/skills_bloc.dart';
import 'package:spnk/views/screens/arcade/arcade_screen.dart';
import 'package:spnk/views/screens/christmas/christmas_painters.dart';
import 'package:spnk/views/screens/christmas/christmas_portfolio_screen.dart';
import 'package:spnk/views/screens/christmas/christmas_theme_config.dart';
import 'package:spnk/views/screens/christmas/santa_village_2d_painters.dart';
import 'package:spnk/views/screens/christmas/winter_village_widgets.dart';
import 'package:spnk/views/screens/home/grid/interactive_grid_home_screen.dart';
import 'package:spnk/views/screens/qrcode/qr_code_screen.dart';
import 'package:spnk/views/screens/racing/racing_portfolio_screen.dart';
import 'package:spnk/views/screens/solar/solar_system_screen.dart';
import 'package:spnk/views/screens/yt_downloader/yt_downloader_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// 2D Side-Scrolling Realistic Christmas Winter Village where Santa Claus walks
/// forward and backward past carved wooden section boards and smaller detail
/// sub-boards planted along the snowy village trail.
class SantaVillage2dScreen extends StatefulWidget {
  const SantaVillage2dScreen({super.key});

  @override
  State<SantaVillage2dScreen> createState() => _SantaVillage2dScreenState();
}

class _SantaVillage2dScreenState extends State<SantaVillage2dScreen>
    with TickerProviderStateMixin {
  static const double _groundYFrac = 0.80;
  static const Set<String> _supportedSkillSvgs = {
    'dart',
    'flutter',
    'firebase2',
    'html',
    'css',
  };

  /// Remembers user's manual Day/Night choice during the browser session.
  static bool? _sessionDayPreference;

  late final Ticker _ticker;
  late final AnimationController _dayNightController;
  final ScrollController _scrollController = ScrollController();
  final SnowfallSimulation _snowSim = SnowfallSimulation();
  final FocusNode _keyboardFocus = FocusNode();

  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _experienceKey = GlobalKey();
  final GlobalKey _projectsKey = GlobalKey();
  final GlobalKey _skillsKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  double _elapsedSeconds = 0.0;
  double _lastTickSeconds = 0.0;
  double _scrollOffset = 0.0;
  double _lastScrollOffset = 0.0;
  double _walkPhase = 0.0;
  double _movingDecay = 0.0;
  bool _facingRight = true;
  bool _snowEnabled = true;
  bool _reducedMotion = false;
  late bool _isDayMode;
  String _activeSectionId = 'home';
  String? _copiedContactKey;

  bool _holdingLeft = false;
  bool _holdingRight = false;

  @override
  void initState() {
    super.initState();
    _isDayMode =
        _sessionDayPreference ?? ChristmasThemeConfig.isDayTime(DateTime.now());
    _dayNightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      value: _isDayMode ? 1.0 : 0.0,
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _snowSim.ensureInitialized();
    _scrollController.addListener(_onScrollChanged);
    _ticker = createTicker(_onTick)..start();
  }

  void _onScrollChanged() {
    if (!mounted || !_scrollController.hasClients) return;
    final current = _scrollController.offset;
    final delta = current - _lastScrollOffset;
    _lastScrollOffset = current;

    if (delta.abs() > 0.25) {
      _facingRight = delta >= 0;
      _walkPhase += delta.abs() * 0.085;
      _movingDecay = 0.28;
    }

    final pos = _scrollController.position;
    final maxScroll = pos.maxScrollExtent > 0 ? pos.maxScrollExtent : 1.0;
    final frac = (current / maxScroll).clamp(0.0, 1.0);

    setState(() {
      _scrollOffset = current;
      _activeSectionId = _detectSection(frac);
    });
  }

  String _detectSection(double fraction) {
    if (fraction < 0.14) return 'home';
    if (fraction < 0.31) return 'about';
    if (fraction < 0.50) return 'experience';
    if (fraction < 0.72) return 'projects';
    if (fraction < 0.86) return 'skills';
    return 'contact';
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final now = elapsed.inMicroseconds / 1000000.0;
    final dt = (now - _lastTickSeconds).clamp(0.0, 0.05);
    _lastTickSeconds = now;

    // Continuous keyboard walking support
    if ((_holdingLeft || _holdingRight) && _scrollController.hasClients) {
      final dir = _holdingRight ? 1.0 : -1.0;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final target = (_scrollController.offset + dir * 480.0 * dt)
          .clamp(0.0, maxExtent);
      _scrollController.jumpTo(target);
    }

    if (_reducedMotion) return;

    setState(() {
      _elapsedSeconds = now;
      if (_movingDecay > 0) {
        _movingDecay = (_movingDecay - dt).clamp(0.0, 0.4);
      }
      if (_snowEnabled) {
        _snowSim.step(dt, now);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _dayNightController.dispose();
    _scrollController.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  void _toggleDayNight() {
    final nextDay = !_isDayMode;
    setState(() {
      _isDayMode = nextDay;
      _sessionDayPreference = nextDay;
    });
    if (_reducedMotion) {
      _dayNightController.value = nextDay ? 1.0 : 0.0;
    } else if (nextDay) {
      _dayNightController.forward();
    } else {
      _dayNightController.reverse();
    }
  }

  void _toggleSnow() {
    setState(() => _snowEnabled = !_snowEnabled);
  }

  void _stepSanta(double deltaPx) {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final next = (_scrollController.offset + deltaPx).clamp(0.0, maxExtent);
    setState(() => _facingRight = deltaPx >= 0);
    _scrollController.animateTo(
      next,
      duration:
          _reducedMotion ? Duration.zero : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
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
        alignment: 0.14,
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      _holdingRight = isDown;
      if (isDown) _facingRight = true;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _holdingLeft = isDown;
      if (isDown) _facingRight = false;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handlePointerSignal(PointerSignalEvent signal) {
    if (signal is PointerScrollEvent && _scrollController.hasClients) {
      final delta =
          signal.scrollDelta.dx.abs() > signal.scrollDelta.dy.abs()
              ? signal.scrollDelta.dx
              : signal.scrollDelta.dy;
      if (delta.abs() < 0.1) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final next = (_scrollController.offset + delta * 1.15).clamp(0.0, maxExtent);
      setState(() => _facingRight = delta >= 0);
      _scrollController.jumpTo(next);
    }
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

  void _openClassicV4() {
    Navigator.of(context).pushNamed(InteractiveGridHomeScreen.routeName);
  }

  void _openVillage3dV5() {
    Navigator.of(context).pushNamed(ChristmasPortfolioScreen.routeName);
  }

  void _openRacingV2() {
    Navigator.of(context).pushNamed(RacingPortfolioScreen.routeName);
  }

  void _openSolarV3() {
    Navigator.of(context).pushNamed(SolarSystemPortfolioScreen.routeName);
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
          constraints: const BoxConstraints(maxWidth: 540),
          child: VillageFrostPanel(
            dayFactor: dayFactor,
            woodenAccent: true,
            padding: const EdgeInsets.all(22),
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
                          fontSize: 21,
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
                        (tech) => _BoardBadge(
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
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (project.webUrl.isNotEmpty ||
                        project.playStoreUrl.isNotEmpty)
                      _ActionPillButton(
                        label: 'Open Project',
                        icon: Icons.open_in_new_rounded,
                        isPrimary: true,
                        dayFactor: dayFactor,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _openProjectAction(project);
                        },
                      ),
                    if (project.playStoreUrl.isNotEmpty &&
                        project.webUrl.isNotEmpty)
                      _ActionPillButton(
                        label: 'Play Store',
                        icon: Icons.shop_rounded,
                        isPrimary: false,
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
    final groundY = size.height * _groundYFrac;
    final topReserved = isMobile ? 162.0 : (isCompact ? 124.0 : 108.0);
    final boardBandMaxHeight = (groundY - topReserved).clamp(240.0, 560.0);
    final santaBottomOffset = (size.height - groundY - 40.0).clamp(54.0, 220.0);

    return Scaffold(
      backgroundColor: ChristmasThemeConfig.skyTop(dayFactor),
      body: Focus(
        focusNode: _keyboardFocus,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Listener(
          onPointerSignal: _handlePointerSignal,
          child: Stack(
            children: [
              // Layer 1: Parallax 2D Realistic Christmas Winter Village World
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: SantaVillage2dBackdropPainter(
                      dayFactor: dayFactor,
                      elapsed: _elapsedSeconds,
                      scrollOffset: _scrollOffset,
                      worldWidth: 6400.0,
                      snowEnabled: _snowEnabled,
                      reducedMotion: _reducedMotion,
                      snowSim: _snowSim,
                      groundYFrac: _groundYFrac,
                    ),
                  ),
                ),
              ),

              // Layer 2: Horizontal Scrolling Timber Boards & Smaller Sub-Boards
              Positioned(
                top: topReserved,
                left: 0,
                right: 0,
                height: boardBandMaxHeight,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isMobile ? 110 : 190,
                      right: isMobile ? 140 : 280,
                    ),
                    child: _buildVillageTrailBoards(
                      dayFactor: dayFactor,
                      isMobile: isMobile,
                      maxBoardHeight: boardBandMaxHeight,
                    ),
                  ),
                ),
              ),

              // Layer 3: Main Character Santa Claus walking Forward / Backward on the snow path
              Positioned(
                left: isMobile ? 18 : 74,
                bottom: santaBottomOffset,
                child: IgnorePointer(
                  child: SizedBox(
                    key: const ValueKey('santa_character'),
                    width: 96,
                    height: 112,
                    child: CustomPaint(
                      painter: SantaCharacterPainter(
                        walkPhase: _walkPhase,
                        isMoving: _movingDecay > 0.02,
                        facingRight: _facingRight,
                        dayFactor: dayFactor,
                        elapsed: _elapsedSeconds,
                      ),
                    ),
                  ),
                ),
              ),

              // Layer 4: Bottom Forward / Backward Walk Bar & Portal Switcher
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _TrailStepButton(
                        key: const ValueKey('santa_walk_back'),
                        icon: Icons.arrow_back_rounded,
                        label: isMobile ? 'Back' : 'Walk Back',
                        dayFactor: dayFactor,
                        onTap: () => _stepSanta(-340),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: ChristmasThemeConfig.cardSurface(dayFactor),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ChristmasThemeConfig.cardBorder(dayFactor),
                          ),
                        ),
                        child: Text(
                          isMobile
                              ? 'Santa • ${_activeSectionId.toUpperCase()}'
                              : 'Santa Trail • ${_activeSectionId.toUpperCase()}  (Scroll, Arrows, or Drag)',
                          style: TextStyle(
                            color: ChristmasThemeConfig.primaryText(dayFactor),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _TrailStepButton(
                        key: const ValueKey('santa_walk_forward'),
                        icon: Icons.arrow_forward_rounded,
                        label: isMobile ? 'Walk' : 'Walk Forward',
                        trailingIcon: true,
                        dayFactor: dayFactor,
                        onTap: () => _stepSanta(340),
                      ),
                      if (!isMobile)
                        _TrailStepButton(
                          key: const ValueKey('village_3d_v5_btn'),
                          icon: Icons.view_in_ar_rounded,
                          label: '3D VILLAGE /v5',
                          dayFactor: dayFactor,
                          onTap: _openVillage3dV5,
                        ),
                    ],
                  ),
                ),
              ),

              // Layer 5: Floating Cloud Navigation & Environment Controls
              Positioned(
                top: MediaQuery.paddingOf(context).top + (isMobile ? 8 : 14),
                left: isMobile ? 82 : 104,
                right: isMobile ? 10 : 20,
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 6,
                            runSpacing: 6,
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
                              _TrailStepButton(
                                key: const ValueKey('village_3d_v5_mobile_btn'),
                                icon: Icons.view_in_ar_rounded,
                                label: '3D /v5',
                                dayFactor: dayFactor,
                                onTap: _openVillage3dV5,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
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
                    : Row(
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
              ),

              // Layer 6: Fixed Top-Left SP Glass Snow Globe
              Positioned(
                top: MediaQuery.paddingOf(context).top + (isMobile ? 8 : 14),
                left: isMobile ? 10 : 18,
                child: SpGlassSnowGlobe(
                  elapsed: _elapsedSeconds,
                  dayFactor: dayFactor,
                  reducedMotion: _reducedMotion,
                  size: isMobile ? 54 : 64,
                  onTap: () => _scrollToSection('home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVillageTrailBoards({
    required double dayFactor,
    required bool isMobile,
    required double maxBoardHeight,
  }) {
    final countdown = ChristmasThemeConfig.countdownLabel(DateTime.now());
    final boardGap = isMobile ? 18.0 : 28.0;
    final zoneGap = isMobile ? 42.0 : 68.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ============================================================
        // ZONE 1: HERO / WELCOME MAIN BOARD + SUB BOARDS
        // ============================================================
        _MainTimberSectionBoard(
          sectionKey: _heroKey,
          title: 'Sivaprasad NK',
          subtitle: 'Merry Christmas & Happy New Year!',
          badgeText: countdown,
          icon: Icons.park_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 255 : 310,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Senior Software Engineer (5 Years) • AI Coding, Flutter & Interactive Web',
                style: TextStyle(
                  color: ChristmasThemeConfig.primaryText(dayFactor),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.38,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionPillButton(
                    label: 'Projects',
                    icon: Icons.explore_rounded,
                    isPrimary: true,
                    dayFactor: dayFactor,
                    compact: true,
                    onTap: () => _scrollToSection('projects'),
                  ),
                  _ActionPillButton(
                    label: 'Resume',
                    icon: Icons.description_outlined,
                    isPrimary: false,
                    dayFactor: dayFactor,
                    compact: true,
                    onTap: () => _launchExternal(resumeLink),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: boardGap),
        _SubDetailBoard(
          title: 'Ernakulam Base',
          icon: Icons.location_on_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 225 : 245,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ChristmasThemeConfig.goldActionGradient,
                ),
                child: ClipOval(
                  child: Image.asset('assets/images/propic3.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ernakulam, Kerala • India',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ChristmasThemeConfig.primaryText(dayFactor),
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  _BoardBadge(
                    label: 'Arcade',
                    dayFactor: dayFactor,
                    isGold: false,
                    onTap: () =>
                        Navigator.of(context).pushNamed(ArcadeScreen.routeName),
                  ),
                  _BoardBadge(
                    label: 'QR Tool',
                    dayFactor: dayFactor,
                    isGold: false,
                    onTap: () =>
                        Navigator.of(context).pushNamed(QrCodeScreen.routeName),
                  ),
                  _BoardBadge(
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
        ),
        SizedBox(width: zoneGap),

        // ============================================================
        // ZONE 2: ABOUT ME MAIN BOARD + SUB BOARDS
        // ============================================================
        _MainTimberSectionBoard(
          sectionKey: _aboutKey,
          title: 'About Me',
          subtitle: '5 Years Exp • AI Coding',
          badgeText: 'ERNAKULAM',
          icon: Icons.cottage_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 250 : 285,
          child: BlocBuilder<AboutMeBloc, AboutMeState>(
            builder: (context, state) {
              return Text(
                state.content.trim(),
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ChristmasThemeConfig.secondaryText(dayFactor),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              );
            },
          ),
        ),
        SizedBox(width: boardGap),
        _SubDetailBoard(
          title: 'AI Coding & Craft',
          icon: Icons.auto_awesome_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 225 : 245,
          child: Text(
            '5 years engineering Flutter mobile & WebAssembly apps, now actively focused on AI coding, agentic workflows, and Clean Architecture.',
            style: TextStyle(
              color: ChristmasThemeConfig.secondaryText(dayFactor),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ),
        SizedBox(width: boardGap),
        _SubDetailBoard(
          title: 'Endurance Athlete',
          icon: Icons.directions_run_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 225 : 245,
          child: Text(
            'Regular gym strength training, consistent running, and endurance discipline fueling calm, focused software engineering.',
            style: TextStyle(
              color: ChristmasThemeConfig.secondaryText(dayFactor),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ),
        SizedBox(width: zoneGap),

        // ============================================================
        // ZONE 3: EXPERIENCE MAIN BOARD + PER-ROLE SUB BOARDS
        // ============================================================
        _MainTimberSectionBoard(
          sectionKey: _experienceKey,
          title: 'Experience',
          subtitle: 'Career Trail Milestones',
          badgeText: '5 YEARS',
          icon: Icons.alt_route_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 220 : 245,
          child: Text(
            'Walk along the path to read each engineering chapter from Bayasys to Indbytes and Invenics.',
            style: TextStyle(
              color: ChristmasThemeConfig.secondaryText(dayFactor),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ),
        ..._buildExperienceSubBoards(dayFactor, isMobile, boardGap, maxBoardHeight),
        SizedBox(width: zoneGap),

        // ============================================================
        // ZONE 4: PROJECTS MAIN BOARD + PER-PROJECT SUB BOARDS
        // ============================================================
        _MainTimberSectionBoard(
          sectionKey: _projectsKey,
          title: 'Projects',
          subtitle: 'Shipped Craft & Tools',
          badgeText: 'SHOWCASE',
          icon: Icons.storefront_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 220 : 245,
          child: Text(
            'Inspect any village project board for live launches, Flutter WebAssembly tools, and mobile releases.',
            style: TextStyle(
              color: ChristmasThemeConfig.secondaryText(dayFactor),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ),
        ..._buildProjectSubBoards(dayFactor, isMobile, boardGap, maxBoardHeight),
        SizedBox(width: zoneGap),

        // ============================================================
        // ZONE 5: SKILLS MAIN BOARD + INDIVIDUAL SKILL SUB BOARDS
        // ============================================================
        _MainTimberSectionBoard(
          sectionKey: _skillsKey,
          title: 'Skills & Technologies',
          subtitle: 'Core Engineering Stack',
          badgeText: 'STACK',
          icon: Icons.ac_unit_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 235 : 265,
          child: Text(
            'Dart, Flutter, Firebase, Web, Clean Architecture, BLoC, Three.js, and AI-assisted development.',
            style: TextStyle(
              color: ChristmasThemeConfig.secondaryText(dayFactor),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ),
        ..._buildSkillSubBoards(dayFactor, isMobile, boardGap, maxBoardHeight),
        SizedBox(width: zoneGap),

        // ============================================================
        // ZONE 6: CONTACT MAIN BOARD + CHANNELS & FOOTER SUB BOARDS
        // ============================================================
        _MainTimberSectionBoard(
          sectionKey: _contactKey,
          title: 'Get In Touch',
          subtitle: 'Ernakulam Hearth & Links',
          badgeText: 'CONNECT',
          icon: Icons.mark_email_read_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 235 : 265,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Open to senior Flutter & AI engineering roles, architecture consulting, and product collaborations.',
                style: TextStyle(
                  color: ChristmasThemeConfig.secondaryText(dayFactor),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              _ActionPillButton(
                label: 'Email Me',
                icon: Icons.send_rounded,
                isPrimary: true,
                dayFactor: dayFactor,
                compact: true,
                onTap: () => _launchExternal('mailto:$emailText'),
              ),
            ],
          ),
        ),
        SizedBox(width: boardGap),
        _buildContactChannelsSubBoard(dayFactor, isMobile, maxBoardHeight),
        SizedBox(width: boardGap),
        _SubDetailBoard(
          title: 'More Editions',
          icon: Icons.explore_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 230 : 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _BoardBadge(
                    label: '3D Village /v5',
                    dayFactor: dayFactor,
                    isGold: true,
                    onTap: _openVillage3dV5,
                  ),
                  _BoardBadge(
                    label: 'Classic /v4',
                    dayFactor: dayFactor,
                    isGold: false,
                    onTap: _openClassicV4,
                  ),
                  _BoardBadge(
                    label: '3D Solar /v3',
                    dayFactor: dayFactor,
                    isGold: false,
                    onTap: _openSolarV3,
                  ),
                  _BoardBadge(
                    label: '3D Racer /v2',
                    dayFactor: dayFactor,
                    isGold: false,
                    onTap: _openRacingV2,
                  ),
                  _BoardBadge(
                    label: 'GitHub',
                    dayFactor: dayFactor,
                    isGold: false,
                    onTap: () => _launchExternal(githubLink),
                  ),
                  _BoardBadge(
                    label: 'LinkedIn',
                    dayFactor: dayFactor,
                    isGold: false,
                    onTap: () => _launchExternal(linkedInLink),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '© ${DateTime.now().year} Sivaprasad NK',
                style: TextStyle(
                  color: ChristmasThemeConfig.secondaryText(dayFactor),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildExperienceSubBoards(
    double dayFactor,
    bool isMobile,
    double boardGap,
    double maxBoardHeight,
  ) {
    final expState = context.watch<ExpDetailsBloc>().state;
    final sorted = List<ExperienceDetails>.from(expState.expList)
      ..sort((a, b) => b.order.compareTo(a.order));
    final list = <Widget>[];
    for (final exp in sorted) {
      list.add(SizedBox(width: boardGap));
      list.add(
        _SubDetailBoard(
          title: exp.orgName,
          subtitle: '${exp.title} (${exp.startDate} — ${exp.endDate})',
          icon: Icons.work_history_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 235 : 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: exp.detailsList
                .map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: ChristmasThemeConfig.accentGold(dayFactor),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            bullet,
                            style: TextStyle(
                              color: ChristmasThemeConfig.secondaryText(
                                dayFactor,
                              ),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }
    return list;
  }

  List<Widget> _buildProjectSubBoards(
    double dayFactor,
    bool isMobile,
    double boardGap,
    double maxBoardHeight,
  ) {
    final projState = context.watch<ProjectBloc>().state;
    final list = <Widget>[];
    for (final proj in projState.projectList) {
      list.add(SizedBox(width: boardGap));
      list.add(
        _SubDetailBoard(
          title: proj.projName,
          icon: Icons.layers_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 245 : 272,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                proj.descList.join(' • ').replaceAll('\n', ' '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ChristmasThemeConfig.secondaryText(dayFactor),
                  fontSize: 12,
                  height: 1.38,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: proj.techStackList
                    .take(3)
                    .map(
                      (t) => _BoardBadge(
                        label: t,
                        dayFactor: dayFactor,
                        isGold: false,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ActionPillButton(
                    label: 'Open',
                    icon: Icons.launch_rounded,
                    isPrimary: true,
                    dayFactor: dayFactor,
                    compact: true,
                    onTap: () => _openProjectAction(proj),
                  ),
                  const SizedBox(width: 8),
                  _ActionPillButton(
                    label: 'Details',
                    isPrimary: false,
                    dayFactor: dayFactor,
                    compact: true,
                    onTap: () => _showProjectDialog(proj),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return list;
  }

  List<Widget> _buildSkillSubBoards(
    double dayFactor,
    bool isMobile,
    double boardGap,
    double maxBoardHeight,
  ) {
    final skillsState = context.watch<SkillDetailsBloc>().state;
    final sorted = List<SkillDetails>.from(skillsState.skillDetails)
      ..sort((a, b) => a.index.compareTo(b.index));
    final list = <Widget>[];
    for (final s in sorted) {
      final hasSvg = _supportedSkillSvgs.contains(s.iconName);
      list.add(SizedBox(width: boardGap * 0.72));
      list.add(
        _SubDetailBoard(
          title: s.title.trim(),
          icon: Icons.code_rounded,
          dayFactor: dayFactor,
          maxHeight: maxBoardHeight,
          width: isMobile ? 160 : 176,
          customIcon: hasSvg
              ? SvgPicture.asset(
                  'assets/svg/${s.iconName}.svg',
                  width: 24,
                  height: 24,
                )
              : null,
          child: Text(
            'Production Experience',
            style: TextStyle(
              color: ChristmasThemeConfig.secondaryText(dayFactor),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return list;
  }

  Widget _buildContactChannelsSubBoard(
    double dayFactor,
    bool isMobile,
    double maxBoardHeight,
  ) {
    final contactsState = context.watch<ContactDetailsBloc>().state;
    final contacts = List<ContactDetails>.from(contactsState.contactDetailList)
      ..sort((a, b) => a.index.compareTo(b.index));

    return _SubDetailBoard(
      title: 'Direct Contact',
      icon: Icons.contact_mail_rounded,
      dayFactor: dayFactor,
      maxHeight: maxBoardHeight,
      width: isMobile ? 255 : 290,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: contacts.map((c) {
          final copied = _copiedContactKey == c.title;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              onTap: () => c.link.isNotEmpty
                  ? _launchExternal(c.link)
                  : _copyText(c.title, c.details),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ChristmasThemeConfig.cardSurface(dayFactor)
                      .withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: ChristmasThemeConfig.cardBorder(dayFactor),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        copied
                            ? '${c.title}: Copied!'
                            : c.details.trim().replaceAll('\n', ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ChristmasThemeConfig.primaryText(dayFactor),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _copyText(c.title, c.details),
                      child: Icon(
                        copied ? Icons.check_circle : Icons.copy_rounded,
                        size: 14,
                        color: ChristmasThemeConfig.accentGold(dayFactor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Prominent Main Wooden Village Section Board with snow crest, brass corner pins,
/// and twin timber posts planted neatly into the snow path.
class _MainTimberSectionBoard extends StatelessWidget {
  const _MainTimberSectionBoard({
    required this.sectionKey,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.dayFactor,
    required this.maxHeight,
    required this.width,
    required this.child,
  });

  final GlobalKey sectionKey;
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final double dayFactor;
  final double maxHeight;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gold = ChristmasThemeConfig.accentGold(dayFactor);
    final boardBg = Color.lerp(
      const Color(0xEC0C1D38),
      const Color(0xEEF5FAFF),
      dayFactor,
    )!;
    final woodFrame = Color.lerp(
      const Color(0xFF7D5031),
      const Color(0xFF8C5835),
      dayFactor,
    )!;

    return Container(
      key: sectionKey,
      width: width,
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: boardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: woodFrame, width: 3.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x45020817),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: gold.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: gold.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Icon(icon, size: 17, color: gold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                badgeText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: gold,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: context.displaySmall.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: ChristmasThemeConfig.primaryText(dayFactor),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        child,
                      ],
                    ),
                  ),
                ),
                // Top snow drift cap resting along upper edge of main board
                Positioned(
                  top: -4,
                  left: 14,
                  right: 14,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFFD6E9FA),
                        Colors.white,
                        dayFactor,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Twin wooden legs anchored into the snow path
          SizedBox(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TimberPost(woodColor: woodFrame, height: 36),
                _TimberPost(woodColor: woodFrame, height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Smaller Village Detail / List Item Sub-Board planted into the snow alongside
/// each main section board.
class _SubDetailBoard extends StatelessWidget {
  const _SubDetailBoard({
    required this.title,
    required this.icon,
    required this.dayFactor,
    required this.maxHeight,
    required this.width,
    required this.child,
    this.subtitle,
    this.customIcon,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? customIcon;
  final double dayFactor;
  final double maxHeight;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gold = ChristmasThemeConfig.accentGold(dayFactor);
    final boardBg = ChristmasThemeConfig.cardSurface(dayFactor);
    final woodFrame = Color.lerp(
      const Color(0xFF6B4328),
      const Color(0xFF7D4F30),
      dayFactor,
    )!;

    return Container(
      width: width,
      constraints: BoxConstraints(maxHeight: (maxHeight - 24).clamp(180, 440)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: boardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: woodFrame, width: 2.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x36020817),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(13, 14, 13, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (customIcon != null) ...[
                              customIcon!,
                              const SizedBox(width: 8),
                            ] else ...[
                              Icon(icon, size: 15, color: gold),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ChristmasThemeConfig.primaryText(
                                    dayFactor,
                                  ),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: gold,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        child,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -3,
                  left: 12,
                  right: 12,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFFD0E6F9),
                        Colors.white,
                        dayFactor,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Single sturdy timber post planted into snow
          _TimberPost(woodColor: woodFrame, height: 24, width: 9),
        ],
      ),
    );
  }
}

class _TimberPost extends StatelessWidget {
  const _TimberPost({
    required this.woodColor,
    required this.height,
    this.width = 10,
  });

  final Color woodColor;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: woodColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
    );
  }
}

class _BoardBadge extends StatelessWidget {
  const _BoardBadge({
    required this.label,
    required this.dayFactor,
    required this.isGold,
    this.onTap,
  });

  final String label;
  final double dayFactor;
  final bool isGold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isGold
        ? ChristmasThemeConfig.accentGold(dayFactor)
        : ChristmasThemeConfig.accentIce(dayFactor);

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ChristmasThemeConfig.primaryText(dayFactor),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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

class _ActionPillButton extends StatelessWidget {
  const _ActionPillButton({
    required this.label,
    required this.isPrimary,
    required this.dayFactor,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final bool isPrimary;
  final double dayFactor;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 6 : 9,
        ),
        decoration: BoxDecoration(
          gradient: isPrimary ? ChristmasThemeConfig.goldActionGradient : null,
          color: isPrimary
              ? null
              : ChristmasThemeConfig.cardSurface(dayFactor)
                  .withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(10),
          border: isPrimary
              ? null
              : Border.all(color: ChristmasThemeConfig.cardBorder(dayFactor)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13.5,
                color: isPrimary
                    ? ChristmasThemeConfig.midnightBlue
                    : ChristmasThemeConfig.accentGold(dayFactor),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isPrimary
                    ? ChristmasThemeConfig.midnightBlue
                    : ChristmasThemeConfig.primaryText(dayFactor),
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailStepButton extends StatelessWidget {
  const _TrailStepButton({
    super.key,
    required this.icon,
    required this.label,
    required this.dayFactor,
    required this.onTap,
    this.trailingIcon = false,
  });

  final IconData icon;
  final String label;
  final double dayFactor;
  final VoidCallback onTap;
  final bool trailingIcon;

  @override
  Widget build(BuildContext context) {
    final gold = ChristmasThemeConfig.accentGold(dayFactor);
    final textColor = ChristmasThemeConfig.primaryText(dayFactor);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: ChristmasThemeConfig.cardSurface(dayFactor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gold.withValues(alpha: 0.5)),
          boxShadow: const [
            BoxShadow(color: Color(0x28000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!trailingIcon) ...[
              Icon(icon, size: 15, color: gold),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (trailingIcon) ...[
              const SizedBox(width: 5),
              Icon(icon, size: 15, color: gold),
            ],
          ],
        ),
      ),
    );
  }
}
