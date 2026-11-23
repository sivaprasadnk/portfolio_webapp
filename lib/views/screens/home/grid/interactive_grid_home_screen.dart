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
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/arcade/arcade_screen.dart';
import 'package:spnk/views/screens/home/grid/animated_characters.dart';
import 'package:spnk/views/screens/home/grid/interactive_grid_backdrop.dart';
import 'package:spnk/views/screens/home/grid/roaming_creatures_overlay.dart';
import 'package:spnk/views/screens/home/widgets/logo_text.dart';
import 'package:spnk/views/screens/qrcode/qr_code_screen.dart';
import 'package:spnk/views/screens/racing/racing_portfolio_screen.dart';
import 'package:spnk/views/screens/solar/solar_system_screen.dart';
import 'package:spnk/views/screens/yt_downloader/yt_downloader_screen.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

enum _GridCategory {
  all('ALL'),
  about('ABOUT'),
  skills('SKILLS'),
  work('WORK'),
  projects('PROJECTS'),
  play('PLAY');

  const _GridCategory(this.label);
  final String label;
}

/// Interactive architectural Bento Grid home screen with pointer-warped grid
/// backdrop, interactive tilt tiles, and 5 animating vector characters.
class InteractiveGridHomeScreen extends StatefulWidget {
  const InteractiveGridHomeScreen({super.key});

  @override
  State<InteractiveGridHomeScreen> createState() =>
      _InteractiveGridHomeScreenState();
}

class _InteractiveGridHomeScreenState extends State<InteractiveGridHomeScreen>
    with SingleTickerProviderStateMixin {
  static const double _gridSpacing = 44.0;
  static const Set<String> _supportedSkillSvgs = {
    'dart',
    'flutter',
    'firebase2',
    'html',
    'css',
  };

  late final Ticker _ticker;
  double _elapsedSeconds = 0.0;
  double _lastTickSeconds = 0.0;

  Offset? _pointerPos;
  Offset _pointerNorm = Offset.zero;
  Size _lastViewportSize = Size.zero;
  final List<GridTrailCell> _trailCells = [];
  final List<GridRipple> _ripples = [];
  final RoamingCreaturesSimulation _roamingSim = RoamingCreaturesSimulation();
  bool _showRoamingCreatures = true;

  _GridCategory _activeFilter = _GridCategory.all;
  int _selectedExpIndex = 0;
  String? _copiedContactKey;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final now = elapsed.inMicroseconds / 1000000.0;
    final dt = (now - _lastTickSeconds).clamp(0.0, 0.05);
    _lastTickSeconds = now;
    setState(() {
      _elapsedSeconds = now;
      _trailCells.removeWhere((c) => now - c.lastTouchedTime > 2.2);
      _ripples.removeWhere((r) => now - r.birthTime > 1.4);
      if (_showRoamingCreatures && _lastViewportSize != Size.zero) {
        _roamingSim.step(dt, _lastViewportSize, _pointerPos);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _recordPointerMove(Offset localPos, Size viewport) {
    final nx = viewport.width > 0
        ? ((localPos.dx / viewport.width) * 2.0 - 1.0).clamp(-1.0, 1.0)
        : 0.0;
    final ny = viewport.height > 0
        ? ((localPos.dy / viewport.height) * 2.0 - 1.0).clamp(-1.0, 1.0)
        : 0.0;
    final col = (localPos.dx / _gridSpacing).floor();
    final row = (localPos.dy / _gridSpacing).floor();

    setState(() {
      _pointerPos = localPos;
      _pointerNorm = Offset(nx, ny);
      final existingIdx =
          _trailCells.indexWhere((c) => c.col == col && c.row == row);
      if (existingIdx >= 0) {
        _trailCells[existingIdx] = GridTrailCell(
          col: col,
          row: row,
          lastTouchedTime: _elapsedSeconds,
        );
      } else {
        _trailCells.add(
          GridTrailCell(
            col: col,
            row: row,
            lastTouchedTime: _elapsedSeconds,
          ),
        );
        if (_trailCells.length > 14) {
          _trailCells.removeAt(0);
        }
      }
    });
  }

  void _recordPointerRipple(Offset localPos, Color color) {
    setState(() {
      _ripples.add(
        GridRipple(
          origin: localPos,
          birthTime: _elapsedSeconds,
          color: color,
        ),
      );
      if (_ripples.length > 8) {
        _ripples.removeAt(0);
      }
    });
  }

  bool _isHighlighted(_GridCategory cat) =>
      _activeFilter != _GridCategory.all && _activeFilter == cat;

  bool _isDimmed(_GridCategory cat) =>
      _activeFilter != _GridCategory.all && _activeFilter != cat;

  void _openRacingV2() {
    GamificationController.instance.completeQuest('first_scroll');
    if (kIsWeb) {
      launchUrl(Uri.parse('/v2/'), webOnlyWindowName: '_self');
      return;
    }
    Navigator.of(context).pushNamed(RacingPortfolioScreen.routeName);
  }

  void _openSolarV3() {
    GamificationController.instance.completeQuest('first_scroll');
    Navigator.of(context).pushNamed(SolarSystemPortfolioScreen.routeName);
  }

  Future<void> _launchExternal(String rawUrl, {String? xpReason, String? key}) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;
    if (xpReason != null) {
      GamificationController.instance.addXp(
        15,
        reason: xpReason,
        uniqueKey: key,
      );
    }
    try {
      await launchUrl(Uri.parse(trimmed));
    } catch (e) {
      debugPrint('## Error launching $trimmed: $e');
    }
  }

  Future<void> _copyText(String key, String value) async {
    await Clipboard.setData(ClipboardData(text: value.trim()));
    if (!mounted) return;
    setState(() {
      _copiedContactKey = key;
    });
    GamificationController.instance.addXp(
      10,
      reason: 'Copied $key to clipboard!',
      uniqueKey: 'copy_$key',
    );
  }

  void _openProjectAction(ProjectDetails project) {
    GamificationController.instance.completeQuest('boss_raider');
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
      _launchExternal(
        project.webUrl,
        xpReason: 'Launched ${project.projName}',
        key: 'proj_${project.projName}',
      );
      return;
    }
    if (project.playStoreUrl.isNotEmpty) {
      _launchExternal(
        project.playStoreUrl,
        xpReason: 'Viewed ${project.projName} on Play Store',
        key: 'proj_${project.projName}',
      );
    }
  }

  void _showFullBioDialog(String bio, Color accent, Color secondary) {
    GamificationController.instance.completeQuest('lore_reader');
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.scaffoldColor.withValues(alpha: 0.92),
                  ),
                  child: PortfolioStyledCard(
                    cyberHeader: 'ABOUT ME // COMMANDER BIO',
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AnimatedPortfolioCharacter(
                              kind: GridCharacterKind.nekoCat,
                              elapsedSeconds: _elapsedSeconds,
                              pointerNorm: _pointerNorm,
                              size: 64,
                              showSpeechOnTap: false,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sivaprasad NK',
                                    style: context.displaySmall.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Senior Flutter Architect • Tripunithura, Kerala',
                                    style: context.bodySmall.copyWith(
                                      fontSize: 13,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: Icon(Icons.close_rounded, color: accent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          bio,
                          style: context.bodySmall.copyWith(
                            fontSize: 15,
                            height: 1.55,
                            color: context.primaryColor.withValues(alpha: 0.88),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OpenAirActionTrigger(
                              label: 'Open 3D Racer /v2',
                              icon: Icons.sports_motorsports_rounded,
                              color: accent,
                              isPrimary: true,
                              onTap: () {
                                Navigator.of(ctx).pop();
                                _openRacingV2();
                              },
                            ),
                            OpenAirActionTrigger(
                              label: 'Download CV',
                              icon: Icons.download_rounded,
                              color: secondary,
                              onTap: () => _launchExternal(
                                resumeLink,
                                xpReason: 'Downloaded CV',
                                key: 'cv_dialog',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProjectDetailDialog(
    ProjectDetails project,
    Color accent,
    Color secondary,
  ) {
    GamificationController.instance.completeQuest('boss_raider');
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.scaffoldColor.withValues(alpha: 0.92),
                  ),
                  child: PortfolioStyledCard(
                    cyberHeader: 'PROJECT SHOWCASE // SPNK LABS',
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                project.projName,
                                style: context.displaySmall.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: Icon(Icons.close_rounded, color: accent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: project.techStackList.map((tech) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Text(
                                tech,
                                style: context.bodySmall.copyWith(
                                  fontSize: 11.5,
                                  color: accent,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        ...project.descList.map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.bolt_rounded, size: 16, color: secondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    d,
                                    style: context.bodySmall.copyWith(
                                      fontSize: 14,
                                      color: context.primaryColor
                                          .withValues(alpha: 0.88),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            if (project.webUrl.isNotEmpty)
                              OpenAirActionTrigger(
                                label: 'Launch Web App',
                                icon: Icons.open_in_new_rounded,
                                color: accent,
                                isPrimary: true,
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _openProjectAction(project);
                                },
                              ),
                            if (project.playStoreUrl.isNotEmpty)
                              OpenAirActionTrigger(
                                label: 'Play Store',
                                icon: Icons.shop_rounded,
                                color: secondary,
                                onTap: () => _launchExternal(
                                  project.playStoreUrl,
                                  xpReason:
                                      'Opened ${project.projName} Play Store',
                                  key: 'play_${project.projName}',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;

        return Scaffold(
          backgroundColor: themeState.themeData.scaffoldBackgroundColor,
          body: LayoutBuilder(
            builder: (context, viewport) {
              final maxW = viewport.maxWidth;
              final viewSize = Size(viewport.maxWidth, viewport.maxHeight);
              _lastViewportSize = viewSize;
              _roamingSim.ensureInitialized(viewSize, compact: maxW < 700);

              return Listener(
                onPointerHover: (e) => _recordPointerMove(e.localPosition, viewSize),
                onPointerMove: (e) => _recordPointerMove(e.localPosition, viewSize),
                onPointerDown: (e) {
                  _recordPointerMove(e.localPosition, viewSize);
                  _recordPointerRipple(e.localPosition, accent);
                  if (_showRoamingCreatures) {
                    _roamingSim.handlePointerDown(
                      e.localPosition,
                      onCreatureTapped: (creature) {
                        GamificationController.instance.addXp(
                          10,
                          reason: 'Interacted with roaming ${creature.type.label}!',
                          uniqueKey: 'roam_${creature.type.name}',
                        );
                      },
                    );
                  }
                },
                child: Stack(
                  children: [
                    // Layer 1: Pointer-reactive architectural coordinate grid backdrop
                    Positioned.fill(
                      child: InteractiveGridBackdrop(
                        pointerLocal: _pointerPos,
                        trailCells: _trailCells,
                        ripples: _ripples,
                        elapsedSeconds: _elapsedSeconds,
                        themeState: themeState,
                        cellSize: _gridSpacing,
                      ),
                    ),

                    // Layer 2: Sticky top navigation + scrollable responsive Bento Grid
                    Column(
                      children: [
                        _buildTopNavBar(context, themeState, maxW),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: maxW >= 1200
                                  ? 40
                                  : (maxW >= 700 ? 22 : 12),
                              vertical: maxW >= 700 ? 22 : 14,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1360),
                                child: _buildResponsiveBentoLayout(
                                  context,
                                  themeState,
                                  maxW,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Layer 2.5: Continuously moving mouse-interactive birds, cats, dogs & bots
                    if (_showRoamingCreatures)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RoamingCreaturesOverlay(
                            simulation: _roamingSim,
                            elapsedSeconds: _elapsedSeconds,
                            pointerPos: _pointerPos,
                            isDark: themeState.isDark,
                            accent: accent,
                            secondary: themeState.secondaryAccent,
                          ),
                        ),
                      ),

                    // Layer 3: Achievement toast overlay
                    const AchievementToastBanner(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTopNavBar(
    BuildContext context,
    ThemeState themeState,
    double maxW,
  ) {
    final accent = themeState.accentColor;
    final isCompact = maxW < 680;
    const racerAmber = Color(0xFFF59E0B);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          key: const ValueKey('home_grid_header_bar'),
          decoration: BoxDecoration(
            color: themeState.themeData.scaffoldBackgroundColor.withValues(
              alpha: themeState.isDark ? 0.80 : 0.90,
            ),
            border: Border(
              bottom: BorderSide(
                color: themeState.cardBorderColor,
                width: 1.1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: themeState.isDark ? 0.25 : 0.06,
                ),
                blurRadius: 14,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: maxW >= 1200 ? 40 : (maxW >= 700 ? 22 : 12),
            vertical: 8,
          ),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1360),
                child: Row(
                  children: [
                    LogoText(
                      onTap: () =>
                          setState(() => _activeFilter = _GridCategory.all),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: themeState.cardSurfaceColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: themeState.cardBorderColor,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: _GridCategory.values.map((cat) {
                                  final selected = _activeFilter == cat;
                                  return MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _activeFilter = cat),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? accent.withValues(alpha: 0.20)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(7),
                                          border: Border.all(
                                            color: selected
                                                ? accent
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Text(
                                          cat.label,
                                          style: context.bodySmall.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                            color: selected
                                                ? accent
                                                : context.primaryColor
                                                    .withValues(alpha: 0.78),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: _showRoamingCreatures
                                  ? 'Hide roaming birds, cats, dogs & bots'
                                  : 'Show roaming birds, cats, dogs & bots',
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  key: const ValueKey('toggle_roaming_creatures'),
                                  onTap: () => setState(
                                    () => _showRoamingCreatures =
                                        !_showRoamingCreatures,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _showRoamingCreatures
                                          ? accent.withValues(alpha: 0.16)
                                          : themeState.cardSurfaceColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _showRoamingCreatures
                                            ? accent.withValues(alpha: 0.7)
                                            : themeState.cardBorderColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.pets_rounded,
                                          size: 13,
                                          color: _showRoamingCreatures
                                              ? accent
                                              : context.primaryColor
                                                  .withValues(alpha: 0.65),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _showRoamingCreatures
                                              ? 'PETS: ON'
                                              : 'PETS: OFF',
                                          style: context.bodySmall.copyWith(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                            color: _showRoamingCreatures
                                                ? accent
                                                : context.primaryColor
                                                    .withValues(alpha: 0.72),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (maxW >= 1040) ...[
                              const SizedBox(width: 10),
                              const StyleSwitcherBar(compact: true),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _openRacingV2,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 9 : 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: racerAmber.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: racerAmber.withValues(alpha: 0.75),
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.sports_motorsports_rounded,
                                size: 14,
                                color: racerAmber,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '3D RACER /v2',
                                style: context.bodySmall.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.9,
                                  color: context.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (maxW >= 740) ...[
                      const SizedBox(width: 10),
                      GamificationHudPill(
                        compact: true,
                        onOpenQuests: () => showQuestLogModal(
                          context,
                          onJumpToArcade: _openRacingV2,
                        ),
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

  Widget _buildResponsiveBentoLayout(
    BuildContext context,
    ThemeState themeState,
    double maxW,
  ) {
    final heroTile = _buildCommanderHeroTile(context, themeState, maxW);
    final racerV2Tile = _buildRacerV2PortalTile(context, themeState);
    final stageTile = _buildCharacterStageTile(context, themeState);
    final aboutTile = _buildAboutMeTile(context, themeState);
    final labsTile = _buildWebLabsStatsTile(context, themeState);
    final skillsTile = _buildSkillsMatrixTile(context, themeState);
    final expTile = _buildExperienceTile(context, themeState);
    final projectsTile = _buildProjectsGridTile(context, themeState);
    final contactTile = _buildContactTile(context, themeState);

    if (maxW >= 1100) {
      // Desktop 12-column weighted bento rows
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 8, child: heroTile),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: racerV2Tile),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: stageTile),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: aboutTile),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: labsTile),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: skillsTile),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: expTile),
            ],
          ),
          const SizedBox(height: 16),
          projectsTile,
          const SizedBox(height: 16),
          contactTile,
          const SizedBox(height: 20),
          _buildGridFooter(context, themeState),
        ],
      );
    }

    if (maxW >= 700) {
      // Tablet 2-column grid
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heroTile,
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: racerV2Tile),
              const SizedBox(width: 14),
              Expanded(child: labsTile),
            ],
          ),
          const SizedBox(height: 14),
          stageTile,
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: aboutTile),
              const SizedBox(width: 14),
              Expanded(child: skillsTile),
            ],
          ),
          const SizedBox(height: 14),
          expTile,
          const SizedBox(height: 14),
          projectsTile,
          const SizedBox(height: 14),
          contactTile,
          const SizedBox(height: 18),
          _buildGridFooter(context, themeState),
        ],
      );
    }

    // Mobile single-column stack
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heroTile,
        const SizedBox(height: 12),
        racerV2Tile,
        const SizedBox(height: 12),
        stageTile,
        const SizedBox(height: 12),
        aboutTile,
        const SizedBox(height: 12),
        labsTile,
        const SizedBox(height: 12),
        skillsTile,
        const SizedBox(height: 12),
        expTile,
        const SizedBox(height: 12),
        projectsTile,
        const SizedBox(height: 12),
        contactTile,
        const SizedBox(height: 16),
        _buildGridFooter(context, themeState),
      ],
    );
  }

  // TILE 1: 01 // COMMANDER
  Widget _buildCommanderHeroTile(
    BuildContext context,
    ThemeState themeState,
    double maxW,
  ) {
    final accent = themeState.accentColor;
    final secondary = themeState.secondaryAccent;
    final isMobile = maxW < 560;

    return InteractiveGridTile(
      gridCode: '01 // COMMANDER',
      badge: 'ONLINE • KERALA, INDIA',
      isHighlighted: _isHighlighted(_GridCategory.about),
      isDimmed: _isDimmed(_GridCategory.about),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [accent, secondary]),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/propic3.png',
                          width: isMobile ? 54 : 66,
                          height: isMobile ? 54 : 66,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sivaprasad NK',
                            style: context.displayMedium.copyWith(
                              fontSize: isMobile ? 28 : 38,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Senior Flutter Architect • 3.7+ Years',
                            style: context.bodySmall.copyWith(
                              fontSize: isMobile ? 13 : 15,
                              color: accent,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Crafting responsive cross-platform Flutter, Clean Architecture, and interactive WebGL experiences from Tripunithura, Kerala.',
                  style: context.bodySmall.copyWith(
                    fontSize: 13.5,
                    height: 1.45,
                    color: context.primaryColor.withValues(alpha: 0.80),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GridActionPill(
                      label: 'Download CV',
                      icon: Icons.download_rounded,
                      color: accent,
                      filled: true,
                      onTap: () {
                        GamificationController.instance
                            .completeQuest('loot_collector');
                        _launchExternal(
                          resumeLink,
                          xpReason: 'Downloaded Resume PDF',
                          key: 'cv_hero',
                        );
                      },
                    ),
                    _GridActionPill(
                      label: 'Play 3D Racer /v2',
                      icon: Icons.sports_motorsports_rounded,
                      color: const Color(0xFFF59E0B),
                      filled: true,
                      onTap: _openRacingV2,
                    ),
                    _GridActionPill(
                      label: '3D Solar /v3',
                      icon: Icons.public_rounded,
                      color: const Color(0xFFA855F7),
                      filled: true,
                      onTap: _openSolarV3,
                    ),
                    _GridActionPill(
                      label: 'GitHub',
                      icon: FontAwesomeIcons.github,
                      color: context.primaryColor,
                      onTap: () => _launchExternal(
                        githubLink,
                        xpReason: 'Opened GitHub profile',
                        key: 'gh_hero',
                      ),
                    ),
                    _GridActionPill(
                      label: 'LinkedIn',
                      icon: FontAwesomeIcons.linkedinIn,
                      color: secondary,
                      onTap: () => _launchExternal(
                        linkedInLink,
                        xpReason: 'Opened LinkedIn profile',
                        key: 'li_hero',
                      ),
                    ),
                    _GridActionPill(
                      label: 'Pub.dev',
                      icon: Icons.widgets_rounded,
                      color: const Color(0xFF0EA5E9),
                      onTap: () => _launchExternal(
                        pubDevLink,
                        xpReason: 'Explored Pub.dev packages',
                        key: 'pub_hero',
                      ),
                    ),
                    _GridActionPill(
                      label: 'VS Code',
                      icon: Icons.palette_rounded,
                      color: const Color(0xFFA855F7),
                      onTap: () => _launchExternal(
                        vsCodeThemesLink,
                        xpReason: 'Viewed VS Code themes',
                        key: 'vsc_hero',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 14),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedPortfolioCharacter(
                  kind: GridCharacterKind.spnkBot,
                  elapsedSeconds: _elapsedSeconds,
                  pointerNorm: _pointerNorm,
                  size: 102,
                ),
                const SizedBox(height: 4),
                Text(
                  GridCharacterKind.spnkBot.label,
                  style: context.bodySmall.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    color: accent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // TILE 2: 02 // V2 3D RACER
  Widget _buildRacerV2PortalTile(BuildContext context, ThemeState themeState) {
    const amber = Color(0xFFF59E0B);

    return InteractiveGridTile(
      gridCode: '02 // V2 3D RACER',
      badge: 'WEBGL /V2',
      accentOverride: amber,
      isHighlighted: _isHighlighted(_GridCategory.play),
      isDimmed: _isDimmed(_GridCategory.play),
      onTap: _openRacingV2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NFS 3D Racing Portfolio',
                  style: context.displaySmall.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rockport 3D WebGL • 5 Vehicles • Destination Holograms',
                  style: context.bodySmall.copyWith(
                    fontSize: 13,
                    height: 1.4,
                    color: context.primaryColor.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 14),
                _GridActionPill(
                  label: 'PLAY /v2',
                  icon: Icons.play_arrow_rounded,
                  color: amber,
                  filled: true,
                  onTap: _openRacingV2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AnimatedPortfolioCharacter(
            kind: GridCharacterKind.m3Racer,
            elapsedSeconds: _elapsedSeconds,
            pointerNorm: _pointerNorm,
            size: 88,
          ),
        ],
      ),
    );
  }

  // TILE 3: 03 // LIVE GRID STAGE
  Widget _buildCharacterStageTile(BuildContext context, ThemeState themeState) {
    return InteractiveGridTile(
      gridCode: '03 // LIVE GRID STAGE',
      badge: 'PLAYABLE 6X3',
      accentOverride: themeState.secondaryAccent,
      isHighlighted: _isHighlighted(_GridCategory.play),
      isDimmed: _isDimmed(_GridCategory.play),
      child: InteractiveCharacterGridStage(
        elapsedSeconds: _elapsedSeconds,
        pointerNorm: _pointerNorm,
        accent: themeState.accentColor,
        secondary: themeState.secondaryAccent,
        isDark: themeState.isDark,
      ),
    );
  }

  // TILE 4: 04 // ABOUT ME
  Widget _buildAboutMeTile(BuildContext context, ThemeState themeState) {
    final accent = themeState.accentColor;
    final secondary = themeState.secondaryAccent;

    return BlocBuilder<AboutMeBloc, AboutMeState>(
      builder: (context, state) {
        final bio = state.content.trim().isNotEmpty
            ? state.content.trim()
            : aboutMeDetailsContent.content.trim();

        return InteractiveGridTile(
          gridCode: '04 // ABOUT ME',
          badge: 'PROFILE',
          isHighlighted: _isHighlighted(_GridCategory.about),
          isDimmed: _isDimmed(_GridCategory.about),
          onTap: () => _showFullBioDialog(bio, accent, secondary),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Behind the Code',
                          style: context.displaySmall.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bio,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: context.bodySmall.copyWith(
                            fontSize: 13,
                            height: 1.45,
                            color: context.primaryColor.withValues(alpha: 0.80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedPortfolioCharacter(
                    kind: GridCharacterKind.nekoCat,
                    elapsedSeconds: _elapsedSeconds,
                    pointerNorm: _pointerNorm,
                    size: 78,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MiniTagChip(label: 'Flutter Architect', color: accent),
                  _MiniTagChip(label: 'Fitness Enthusiast', color: secondary),
                  const _MiniTagChip(
                    label: 'Felintrovert',
                    color: Color(0xFFF472B6),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // TILE 5: 05 // WEB LABS & STATS
  Widget _buildWebLabsStatsTile(BuildContext context, ThemeState themeState) {
    final accent = themeState.accentColor;
    final secondary = themeState.secondaryAccent;

    return InteractiveGridTile(
      gridCode: '05 // WEB LABS & STATS',
      badge: 'INTERACTIVE',
      isHighlighted: _isHighlighted(_GridCategory.play),
      isDimmed: _isDimmed(_GridCategory.play),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatMiniBlock(
                  value: '3.7+ YRS',
                  caption: 'FLUTTER EXP',
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatMiniBlock(
                  value: '6+ APPS',
                  caption: 'SHIPPED',
                  color: secondary,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _StatMiniBlock(
                  value: '98% DART',
                  caption: 'CLEAN ARCH',
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Built-in Flutter Web Tools',
            style: context.bodySmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: context.primaryColor.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GridActionPill(
                label: 'Arcade Hub',
                icon: Icons.sports_esports_rounded,
                color: accent,
                onTap: () =>
                    Navigator.of(context).pushNamed(ArcadeScreen.routeName),
              ),
              _GridActionPill(
                label: 'QR Studio',
                icon: Icons.qr_code_2_rounded,
                color: secondary,
                onTap: () =>
                    Navigator.of(context).pushNamed(QrCodeScreen.routeName),
              ),
              _GridActionPill(
                label: 'YT Downloader',
                icon: Icons.video_library_rounded,
                color: const Color(0xFFEF4444),
                onTap: () => Navigator.of(context)
                    .pushNamed(YtDownloaderScreen.routeName),
              ),
              _GridActionPill(
                label: '3D Solar /v3',
                icon: Icons.public_rounded,
                color: const Color(0xFFA855F7),
                onTap: _openSolarV3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TILE 6: 06 // SKILLS MATRIX
  Widget _buildSkillsMatrixTile(BuildContext context, ThemeState themeState) {
    final accent = themeState.accentColor;

    return BlocBuilder<SkillDetailsBloc, SkillsState>(
      builder: (context, state) {
        final skills =
            state.skillDetails.isNotEmpty ? state.skillDetails : skillsList;

        return InteractiveGridTile(
          gridCode: '06 // SKILLS MATRIX',
          badge: 'ECU MATRIX',
          isHighlighted: _isHighlighted(_GridCategory.skills),
          isDimmed: _isDimmed(_GridCategory.skills),
          child: ListenableBuilder(
            listenable: GamificationController.instance,
            builder: (context, _) {
              final game = GamificationController.instance;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Core Stack',
                              style: context.displaySmall.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tap any skill node to overclock +15 XP',
                              style: context.bodySmall.copyWith(
                                fontSize: 12,
                                color: context.primaryColor
                                    .withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedPortfolioCharacter(
                        kind: GridCharacterKind.flutterDash,
                        elapsedSeconds: _elapsedSeconds,
                        pointerNorm: _pointerNorm,
                        size: 70,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.map((SkillDetails skill) {
                      final title = skill.title.trim();
                      final boost = game.getSkillBoost(title);
                      final hasSvg = _supportedSkillSvgs.contains(skill.iconName);

                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => game.boostSkill(title),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: boost > 0
                                  ? accent.withValues(alpha: 0.18)
                                  : context.primaryColor
                                      .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: boost > 0
                                    ? accent
                                    : context.primaryColor
                                        .withValues(alpha: 0.16),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasSvg)
                                  SvgPicture.asset(
                                    'assets/svg/${skill.iconName}.svg',
                                    width: 16,
                                    height: 16,
                                  )
                                else
                                  Icon(
                                    Icons.code_rounded,
                                    size: 16,
                                    color: accent,
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  title,
                                  style: context.bodySmall.copyWith(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (boost > 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    'LVL $boost/5',
                                    style: context.bodySmall.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // TILE 7: 07 // EXPERIENCE
  Widget _buildExperienceTile(BuildContext context, ThemeState themeState) {
    final accent = themeState.accentColor;

    return BlocBuilder<ExpDetailsBloc, ExpDetailsState>(
      builder: (context, state) {
        final exps = state.expList.isNotEmpty ? state.expList : expDetailsList;
        final ordered = List<ExperienceDetails>.of(exps)
          ..sort((a, b) => b.order.compareTo(a.order));
        final activeIdx = _selectedExpIndex.clamp(0, ordered.length - 1);

        return InteractiveGridTile(
          gridCode: '07 // EXPERIENCE',
          badge: 'CAREER LOG',
          isHighlighted: _isHighlighted(_GridCategory.work),
          isDimmed: _isDimmed(_GridCategory.work),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: ordered.asMap().entries.map((entry) {
              final idx = entry.key;
              final exp = entry.value;
              final selected = idx == activeIdx;

              return Padding(
                padding: EdgeInsets.only(bottom: idx < ordered.length - 1 ? 8 : 0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedExpIndex = idx);
                      GamificationController.instance
                          .completeQuest('career_chronicler');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected
                            ? accent.withValues(alpha: 0.14)
                            : context.primaryColor.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? accent.withValues(alpha: 0.75)
                              : context.primaryColor.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  exp.orgName,
                                  style: context.bodySmall.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? accent
                                        : context.primaryColor,
                                  ),
                                ),
                              ),
                              Text(
                                '${exp.startDate} — ${exp.endDate}',
                                style: context.bodySmall.copyWith(
                                  fontSize: 10.5,
                                  color: context.primaryColor
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            exp.title,
                            style: context.bodySmall.copyWith(
                              fontSize: 12,
                              color:
                                  context.primaryColor.withValues(alpha: 0.8),
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: exp.detailsList
                                  .map(
                                    (d) => _MiniTagChip(
                                      label: d,
                                      color: accent,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // TILE 8: 08 // PROJECTS GRID
  Widget _buildProjectsGridTile(BuildContext context, ThemeState themeState) {
    final accent = themeState.accentColor;
    final secondary = themeState.secondaryAccent;

    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        final projects =
            state.projectList.isNotEmpty ? state.projectList : projectList;

        return InteractiveGridTile(
          gridCode: '08 // PROJECTS GRID',
          badge: '${projects.length} LAUNCHES',
          isHighlighted: _isHighlighted(_GridCategory.projects),
          isDimmed: _isDimmed(_GridCategory.projects),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 860 ? 3 : (w >= 520 ? 2 : 1);
              final spacing = 12.0;
              final itemWidth = (w - spacing * (cols - 1)) / cols;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: projects.map((project) {
                  return SizedBox(
                    width: math.max(180, itemWidth),
                    child: _ProjectGridSubTile(
                      project: project,
                      accent: accent,
                      secondary: secondary,
                      isDark: themeState.isDark,
                      onOpenDetail: () =>
                          _showProjectDetailDialog(project, accent, secondary),
                      onLaunch: () => _openProjectAction(project),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  // TILE 9: 09 // CONTACT & COMMS
  Widget _buildContactTile(BuildContext context, ThemeState themeState) {
    final accent = themeState.accentColor;
    final secondary = themeState.secondaryAccent;

    return BlocBuilder<ContactDetailsBloc, ContactDetailsState>(
      builder: (context, state) {
        final contacts = state.contactDetailList.isNotEmpty
            ? state.contactDetailList
            : contactDetailsList;

        return InteractiveGridTile(
          gridCode: '09 // CONTACT & COMMS',
          badge: 'UPLINK',
          accentOverride: const Color(0xFF10B981),
          isHighlighted: _isHighlighted(_GridCategory.about),
          isDimmed: _isDimmed(_GridCategory.about),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start a Transmission',
                          style: context.displaySmall.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Click any channel to launch, or copy email & phone in one tap.',
                          style: context.bodySmall.copyWith(
                            fontSize: 13,
                            color:
                                context.primaryColor.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedPortfolioCharacter(
                    kind: GridCharacterKind.commsDrone,
                    elapsedSeconds: _elapsedSeconds,
                    pointerNorm: _pointerNorm,
                    size: 76,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 10,
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
                    constraints: const BoxConstraints(minWidth: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _launchExternal(
                                item.link,
                                xpReason: 'Opened $title contact channel',
                                key: 'contact_$title',
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: 18,
                                    color: const Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          title,
                                          style: context.bodySmall.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF10B981),
                                          ),
                                        ),
                                        Text(
                                          detail,
                                          softWrap: true,
                                          style: context.bodySmall.copyWith(
                                            fontSize: 12.5,
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
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Copy $title',
                            onPressed: () => _copyText(title, detail),
                            iconSize: 16,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              copied ? Icons.check_rounded : Icons.copy_rounded,
                              color: copied
                                  ? const Color(0xFF10B981)
                                  : accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _GridActionPill(
                    label: 'GitHub',
                    icon: FontAwesomeIcons.github,
                    color: accent,
                    onTap: () => _launchExternal(githubLink),
                  ),
                  _GridActionPill(
                    label: 'LinkedIn',
                    icon: FontAwesomeIcons.linkedinIn,
                    color: secondary,
                    onTap: () => _launchExternal(linkedInLink),
                  ),
                  _GridActionPill(
                    label: 'Instagram',
                    icon: FontAwesomeIcons.instagram,
                    color: const Color(0xFFF472B6),
                    onTap: () => _launchExternal(instaLink),
                  ),
                  _GridActionPill(
                    label: 'Facebook',
                    icon: FontAwesomeIcons.facebook,
                    color: const Color(0xFF38BDF8),
                    onTap: () => _launchExternal(fbLink),
                  ),
                  _GridActionPill(
                    label: 'Resume',
                    icon: Icons.description_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => _launchExternal(resumeLink),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridFooter(BuildContext context, ThemeState themeState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            Text(
              '© ${DateTime.now().year} Sivaprasad NK • Interactive Grid Architecture',
              style: context.bodySmall.copyWith(
                fontSize: 12,
                color: context.primaryColor.withValues(alpha: 0.65),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _openRacingV2,
                child: Text(
                  'Launch /v2 3D Racer →',
                  style: context.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: themeState.accentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridActionPill extends StatelessWidget {
  const _GridActionPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: filled
                ? color.withValues(alpha: 0.22)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: filled ? 0.85 : 0.40),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTagChip extends StatelessWidget {
  const _MiniTagChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: context.bodySmall.copyWith(
          fontSize: 11,
          color: context.primaryColor.withValues(alpha: 0.88),
        ),
      ),
    );
  }
}

class _StatMiniBlock extends StatelessWidget {
  const _StatMiniBlock({
    required this.value,
    required this.caption,
    required this.color,
  });

  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: context.bodyMedium.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            overflow: TextOverflow.ellipsis,
            style: context.bodySmall.copyWith(
              fontSize: 9.5,
              letterSpacing: 0.8,
              color: context.primaryColor.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectGridSubTile extends StatefulWidget {
  const _ProjectGridSubTile({
    required this.project,
    required this.accent,
    required this.secondary,
    required this.isDark,
    required this.onOpenDetail,
    required this.onLaunch,
  });

  final ProjectDetails project;
  final Color accent;
  final Color secondary;
  final bool isDark;
  final VoidCallback onOpenDetail;
  final VoidCallback onLaunch;

  @override
  State<_ProjectGridSubTile> createState() => _ProjectGridSubTileState();
}

class _ProjectGridSubTileState extends State<_ProjectGridSubTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final hasWeb = p.webUrl.isNotEmpty;
    final actionLabel = hasWeb ? 'LAUNCH WEB' : 'PLAY STORE';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onOpenDetail,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.accent.withValues(alpha: widget.isDark ? 0.14 : 0.08)
                : context.primaryColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? widget.accent
                  : context.primaryColor.withValues(alpha: 0.14),
            ),
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
                      style: context.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: _hovered
                        ? widget.accent
                        : context.primaryColor.withValues(alpha: 0.55),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                p.descList.join(' • ').replaceAll('\n', ' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.bodySmall.copyWith(
                  fontSize: 12.5,
                  height: 1.35,
                  color: context.primaryColor.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: p.techStackList
                    .map(
                      (tech) => _MiniTagChip(
                        label: tech,
                        color: widget.secondary,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onLaunch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.accent.withValues(alpha: 0.60),
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: context.bodySmall.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.9,
                        color: widget.accent,
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
  }
}
