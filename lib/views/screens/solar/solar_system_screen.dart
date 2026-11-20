import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:spnk/views/screens/home/home_screen.dart';
import 'package:spnk/views/screens/qrcode/qr_code_screen.dart';
import 'package:spnk/views/screens/racing/racing_portfolio_screen.dart';
import 'package:spnk/views/screens/solar/solar_2d_fallback_painter.dart';
import 'package:spnk/views/screens/solar/solar_3d_bridge.dart';
import 'package:spnk/views/screens/solar/solar_hud_widgets.dart';
import 'package:spnk/views/screens/solar/solar_models.dart';
import 'package:spnk/views/screens/yt_downloader/yt_downloader_screen.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:url_launcher/url_launcher.dart';

/// `/v3` 3D Solar System Portfolio where Sivaprasad NK is the Central Star,
/// portfolio sections are Planets, and sub-sections are Orbiting Moons.
class SolarSystemPortfolioScreen extends StatefulWidget {
  const SolarSystemPortfolioScreen({super.key});

  static const routeName = '/v3';

  @override
  State<SolarSystemPortfolioScreen> createState() =>
      _SolarSystemPortfolioScreenState();
}

class _SolarSystemPortfolioScreenState extends State<SolarSystemPortfolioScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final Solar3dBridge _bridge3d;
  final SolarOrbitPhysics _physics = SolarOrbitPhysics();
  final FocusNode _focusNode = FocusNode();

  List<SolarPlanetData> _planets = const [];
  double _lastTickSec = 0.0;
  double _elapsedSeconds = 0.0;

  double _yaw = 0.62;
  double _pitch = 0.44;
  double _zoomOffset = 0.0;
  bool _isPaused = false;
  bool _isDragging = false;
  String? _copiedValue;

  @override
  void initState() {
    super.initState();
    _bridge3d = createSolar3dBridge();
    _rebuildSystemFromBlocs(initial: true);

    if (_bridge3d.isSupported) {
      _bridge3d.mountView();
      _pushSystemTo3d();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _rebuildSystemFromBlocs();
      _focusNode.requestFocus();
    });

    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final now = elapsed.inMicroseconds / 1000000.0;
    final dt = (_lastTickSec == 0.0) ? 0.016 : (now - _lastTickSec).clamp(0.0, 0.05);
    _lastTickSec = now;
    _elapsedSeconds = now;

    if (!_isDragging && _physics.focusKind == SolarFocusKind.overview && !_isPaused) {
      _yaw += dt * 0.045;
    }

    _physics.step(dt, _planets, paused: _isPaused);
    setState(() {});
    _sync3dScene();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _bridge3d.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuildSystemFromBlocs({bool initial = false}) {
    final nextPlanets = initial
        ? SolarSystemBuilder.build(
            aboutBio: '',
            skills: const [],
            experiences: const [],
            projects: const [],
            contacts: const [],
          )
        : SolarSystemBuilder.build(
            aboutBio: context.read<AboutMeBloc>().state.content,
            skills: context.read<SkillDetailsBloc>().state.skillDetails,
            experiences: context.read<ExpDetailsBloc>().state.expList,
            projects: context.read<ProjectBloc>().state.projectList,
            contacts: context.read<ContactDetailsBloc>().state.contactDetailList,
          );

    if (initial) {
      _planets = nextPlanets;
    } else if (mounted) {
      setState(() {
        _planets = nextPlanets;
      });
      _pushSystemTo3d();
    }
  }

  void _pushSystemTo3d() {
    if (!_bridge3d.isSupported || _planets.isEmpty) return;
    final payload = jsonEncode({
      'star': {
        'title': 'SIVAPRASAD NK',
        'subtitle': 'CENTRAL STAR',
      },
      'planets': _planets
          .map(
            (p) => {
              'id': p.id,
              'shortLabel': p.shortLabel,
              'orbitRadius': p.orbitRadius,
              'inclination': p.inclination,
              'radius': p.radius,
              'hasRing': p.hasRing,
              'textureStyle': p.textureStyle,
              'color': p.color.toARGB32() & 0xffffff,
              'secondaryColor': p.secondaryColor.toARGB32() & 0xffffff,
              'moons': p.moons
                  .map(
                    (m) => {
                      'id': m.id,
                      'title': m.title,
                      'badge': m.badge,
                      'orbitRadius': m.orbitRadius,
                      'inclination': m.inclination,
                      'radius': m.radius,
                      'color': m.color.toARGB32() & 0xffffff,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    });
    _bridge3d.setSystemData(payload);
  }

  void _sync3dScene() {
    if (!_bridge3d.isSupported || _planets.isEmpty) return;
    final isDark = context.read<ThemeBloc>().state.isDark;
    final payload = jsonEncode({
      'isDark': isDark,
      'focusedPlanetId': _physics.focusedPlanetId,
      'focusedMoonId': _physics.focusedMoonId,
      'yaw': _yaw,
      'pitch': _pitch,
      'distance': (_physics.cameraDistance + _zoomOffset).clamp(4.0, 120.0),
      'lookAt': {
        'x': _physics.cameraLookAt.x,
        'y': _physics.cameraLookAt.y,
        'z': _physics.cameraLookAt.z,
      },
      'planets': _planets.map((p) {
        final pp = _physics.planetPosition(p);
        final isFocused = _physics.focusedPlanetId == p.id;
        return {
          'id': p.id,
          'x': pp.x,
          'y': pp.y,
          'z': pp.z,
          'moons': p.moons.map((m) {
            final mp = _physics.moonPosition(p, m, isParentFocused: isFocused);
            return {
              'id': m.id,
              'x': mp.x,
              'y': mp.y,
              'z': mp.z,
            };
          }).toList(),
        };
      }).toList(),
    });
    _bridge3d.syncState(payload);
  }

  void _selectOverview() {
    setState(() {
      _zoomOffset = 0.0;
      _physics.focusOverview();
    });
  }

  void _selectStar() {
    setState(() {
      _zoomOffset = 0.0;
      _physics.focusStar();
    });
    GamificationController.instance.addXp(
      15,
      reason: 'Centered on Central Star: Sivaprasad NK!',
      uniqueKey: 'solar_star_focus',
    );
  }

  void _selectPlanet(String planetId) {
    final planet = _physics.findPlanet(_planets, planetId);
    if (planet == null) return;
    setState(() {
      _zoomOffset = 0.0;
      _physics.focusPlanet(planetId);
    });
    GamificationController.instance.addXp(
      15,
      reason: 'Centered Planet: ${planet.shortLabel}!',
      uniqueKey: 'solar_planet_$planetId',
    );
  }

  void _selectMoon(String planetId, String moonId) {
    final planet = _physics.findPlanet(_planets, planetId);
    final moon = _physics.findMoon(planet, moonId);
    if (planet == null || moon == null) return;
    setState(() {
      _zoomOffset = 0.0;
      _physics.focusMoon(planetId, moonId);
    });
    GamificationController.instance.addXp(
      15,
      reason: 'Focused Moon: ${moon.title}!',
      uniqueKey: 'solar_moon_$moonId',
    );
  }

  void _stepBody(int delta) {
    if (_planets.isEmpty) return;
    if (_physics.focusKind == SolarFocusKind.moon &&
        _physics.focusedPlanetId != null) {
      final p = _physics.findPlanet(_planets, _physics.focusedPlanetId);
      if (p != null && p.moons.isNotEmpty) {
        final curIdx = p.moons.indexWhere((m) => m.id == _physics.focusedMoonId);
        final nextIdx = ((curIdx < 0 ? 0 : curIdx) + delta) % p.moons.length;
        final wrapped = nextIdx < 0 ? nextIdx + p.moons.length : nextIdx;
        _selectMoon(p.id, p.moons[wrapped].id);
        return;
      }
    }

    final curIdx = _planets.indexWhere((p) => p.id == _physics.focusedPlanetId);
    final nextIdx = ((curIdx < 0 ? 0 : curIdx) + delta) % _planets.length;
    final wrapped = nextIdx < 0 ? nextIdx + _planets.length : nextIdx;
    _selectPlanet(_planets[wrapped].id);
  }

  void _handleCanvasTap(Offset localPos, Size viewportSize) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;

    if (_bridge3d.isSupported) {
      final normX = (localPos.dx / viewportSize.width).clamp(0.0, 1.0);
      final normY = (localPos.dy / viewportSize.height).clamp(0.0, 1.0);
      final raw = _bridge3d.raycast(normX, normY);
      if (raw.isNotEmpty) {
        try {
          final parsed = jsonDecode(raw) as Map<String, dynamic>;
          final kind = parsed['kind'] as String?;
          if (kind == 'star') {
            _selectStar();
            return;
          } else if (kind == 'planet') {
            final pid = parsed['planetId'] as String?;
            if (pid != null) {
              _selectPlanet(pid);
              return;
            }
          } else if (kind == 'moon') {
            final pid = parsed['planetId'] as String?;
            final mid = parsed['moonId'] as String?;
            if (pid != null && mid != null) {
              _selectMoon(pid, mid);
              return;
            }
          }
        } catch (_) {}
      }
      return;
    }

    final hit = Solar2dFallbackPainter.hitTestBodies(
      tapPos: localPos,
      size: viewportSize,
      planets: _planets,
      physics: _physics,
      yaw: _yaw,
      pitch: _pitch,
      zoomOffset: _zoomOffset,
    );
    if (hit == null) return;
    switch (hit.kind) {
      case SolarFocusKind.star:
        _selectStar();
        break;
      case SolarFocusKind.planet:
        if (hit.planetId != null) _selectPlanet(hit.planetId!);
        break;
      case SolarFocusKind.moon:
        if (hit.planetId != null && hit.moonId != null) {
          _selectMoon(hit.planetId!, hit.moonId!);
        }
        break;
      case SolarFocusKind.overview:
        _selectOverview();
        break;
    }
  }

  void _goHome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    }
  }

  void _openV2() {
    Navigator.of(context).pushNamed(RacingPortfolioScreen.routeName);
  }

  Future<void> _launchActionUrl(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed == qrCodeToolLink) {
      Navigator.of(context).pushNamed(QrCodeScreen.routeName);
      return;
    }
    if (trimmed == arcadeHubLink) {
      Navigator.of(context).pushNamed(ArcadeScreen.routeName);
      return;
    }
    if (trimmed == ytDownloaderLink) {
      Navigator.of(context).pushNamed(YtDownloaderScreen.routeName);
      return;
    }
    if (trimmed == racingGameV2Link) {
      _openV2();
      return;
    }
    try {
      await launchUrl(Uri.parse(trimmed));
    } catch (e) {
      debugPrint('## Error launching $trimmed: $e');
    }
  }

  Future<void> _copyText(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    setState(() => _copiedValue = value);
    GamificationController.instance.addXp(
      10,
      reason: 'Copied contact info!',
      uniqueKey: 'solar_copy_$value',
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      setState(() => _isPaused = !_isPaused);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.digit0) {
      _selectOverview();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _stepBody(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _stepBody(1);
      return KeyEventResult.handled;
    }
    final digitMap = <LogicalKeyboardKey, int>{
      LogicalKeyboardKey.digit1: 0,
      LogicalKeyboardKey.digit2: 1,
      LogicalKeyboardKey.digit3: 2,
      LogicalKeyboardKey.digit4: 3,
      LogicalKeyboardKey.digit5: 4,
    };
    final idx = digitMap[key];
    if (idx != null && idx < _planets.length) {
      _selectPlanet(_planets[idx].id);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AboutMeBloc, AboutMeState>(
          listener: (_, __) => _rebuildSystemFromBlocs(),
        ),
        BlocListener<SkillDetailsBloc, SkillsState>(
          listener: (_, __) => _rebuildSystemFromBlocs(),
        ),
        BlocListener<ExpDetailsBloc, ExpDetailsState>(
          listener: (_, __) => _rebuildSystemFromBlocs(),
        ),
        BlocListener<ProjectBloc, ProjectState>(
          listener: (_, __) => _rebuildSystemFromBlocs(),
        ),
        BlocListener<ContactDetailsBloc, ContactDetailsState>(
          listener: (_, __) => _rebuildSystemFromBlocs(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final focusedPlanet =
              _physics.findPlanet(_planets, _physics.focusedPlanetId);
          final focusedMoon =
              _physics.findMoon(focusedPlanet, _physics.focusedMoonId);

          return Focus(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: Scaffold(
              backgroundColor: const Color(0xFF040711),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final viewSize =
                      Size(constraints.maxWidth, constraints.maxHeight);

                  return Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        setState(() {
                          _zoomOffset = (_zoomOffset + event.scrollDelta.dy * 0.03)
                              .clamp(-12.0, 35.0);
                        });
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Layer 1: 3D WebGL Solar Canvas or 2D Projected Fallback
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) =>
                                _handleCanvasTap(details.localPosition, viewSize),
                            onScaleStart: (_) => _isDragging = true,
                            onScaleEnd: (_) => _isDragging = false,
                            onScaleUpdate: (details) {
                              setState(() {
                                _yaw -= details.focalPointDelta.dx * 0.008;
                                _pitch = (_pitch + details.focalPointDelta.dy * 0.006)
                                    .clamp(-1.15, 1.35);
                                if ((details.scale - 1.0).abs() > 0.01) {
                                  _zoomOffset = (_zoomOffset -
                                          (details.scale - 1.0) * 1.6)
                                      .clamp(-12.0, 35.0);
                                }
                              });
                            },
                            child: _bridge3d.isSupported
                                ? IgnorePointer(child: _bridge3d.buildView())
                                : RepaintBoundary(
                                    child: CustomPaint(
                                      painter: Solar2dFallbackPainter(
                                        planets: _planets,
                                        physics: _physics,
                                        yaw: _yaw,
                                        pitch: _pitch,
                                        zoomOffset: _zoomOffset,
                                        elapsedSeconds: _elapsedSeconds,
                                        isDark: themeState.isDark,
                                      ),
                                    ),
                                  ),
                          ),
                        ),

                        // Layer 2: Top Navigation Bar
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SolarTopNavBar(
                            planets: _planets,
                            focusKind: _physics.focusKind,
                            focusedPlanetId: _physics.focusedPlanetId,
                            isPaused: _isPaused,
                            themeState: themeState,
                            onGoHome: _goHome,
                            onOpenV2: _openV2,
                            onFocusOverview: _selectOverview,
                            onFocusStar: _selectStar,
                            onFocusPlanet: _selectPlanet,
                            onTogglePause: () =>
                                setState(() => _isPaused = !_isPaused),
                          ),
                        ),

                        // Layer 3: Floating Bottom Focus Inspector Card
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 14,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SolarFocusInspectorCard(
                              planets: _planets,
                              focusKind: _physics.focusKind,
                              focusedPlanet: focusedPlanet,
                              focusedMoon: focusedMoon,
                              themeState: themeState,
                              copiedValue: _copiedValue,
                              onFocusOverview: _selectOverview,
                              onFocusStar: _selectStar,
                              onFocusPlanet: _selectPlanet,
                              onFocusMoon: _selectMoon,
                              onStepPrev: () => _stepBody(-1),
                              onStepNext: () => _stepBody(1),
                              onLaunchUrl: _launchActionUrl,
                              onCopyText: _copyText,
                              onBoostSkill: (title) =>
                                  GamificationController.instance.boostSkill(title),
                            ),
                          ),
                        ),

                        // Layer 4: Achievement Toast Overlay
                        const AchievementToastBanner(),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
