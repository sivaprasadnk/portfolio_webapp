import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_bloc.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_state.dart';
import 'package:spnk/views/bloc/experience/exp_details_bloc.dart';
import 'package:spnk/views/bloc/experience/exp_details_state.dart';
import 'package:spnk/views/bloc/project/project_bloc.dart';
import 'package:spnk/views/bloc/project/project_state.dart';
import 'package:spnk/views/bloc/screen_details/screen_bloc.dart';
import 'package:spnk/views/bloc/screen_details/screen_event.dart';
import 'package:spnk/views/bloc/skills/skills_bloc.dart';
import 'package:spnk/views/bloc/skills/skills_state.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/racing/racing_car_painter.dart';
import 'package:spnk/views/screens/racing/racing_highway_painter.dart';
import 'package:spnk/views/screens/racing/racing_hud_widgets.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';
import 'package:spnk/views/screens/racing/racing_paddock_painter.dart';
import 'package:spnk/views/screens/racing/racing_pit_dossier.dart';
import 'package:spnk/views/screens/racing/racing_track_painter.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:url_launcher/url_launcher.dart';

class RacingPortfolioScreen extends StatefulWidget {
  const RacingPortfolioScreen({super.key});

  @override
  State<RacingPortfolioScreen> createState() => _RacingPortfolioScreenState();
}

class _RacingPortfolioScreenState extends State<RacingPortfolioScreen>
    with SingleTickerProviderStateMixin {
  static const double _baseMaxSpeed = 295.0;
  static const double _nitroMaxSpeed = 420.0;
  static const double _cruiseTargetSpeed = 148.0;

  late final Ticker _ticker;
  final FocusNode _focusNode = FocusNode();

  // Switchable 3 Gameplay Modes & 3 Visual Themes
  RacingGameMode _gameMode = RacingGameMode.horizon3d;
  RacingVisualTheme _visualTheme = RacingVisualTheme.neonCyber;

  // Decoded Driver Portrait for in-world 3D/2D canvas rendering
  ImageStream? _photoStream;
  ImageStreamListener? _photoListener;
  ui.Image? _driverPhoto;

  // Circuit (3D Horizon + Vertical Highway) world state
  List<RoadSegment> _segments = [];
  late final List<TrafficCar> _trafficCars;
  late final List<DataCrystalOrb> _orbs;

  // Open-World Top-Down Paddock state
  late final List<PaddockLinkPortal> _paddockPortals;
  List<PaddockBoostStrip> _paddockBoosts = [];
  late final List<PaddockOrb> _paddockOrbs;
  final List<PaddockSkidMark> _paddockSkids = [];
  late final List<PaddockRivalState> _paddockRivals;
  Offset _paddockPos = const Offset(-740, -470);
  Offset _paddockCameraPos = const Offset(-740, -470);
  double _paddockHeading = math.pi * 0.5; // 0 = UP (-Y), pi/2 = RIGHT (+X)
  double _paddockSignedSpeed = 115.0; // KM/H (supports reverse < 0)
  double _paddockCruiseAngle = -2.55;
  Offset? _paddockGpsTarget;
  RaceSectorMeta? _paddockArrivalSector;
  RaceSectorMeta? _hoveredPaddockZone;
  DriverQuickLink? _activePortalLink;
  int _lastPaddockBoostIdx = -1;

  Duration _lastTick = Duration.zero;
  double _timeSeconds = 0.0;

  // Shared longitudinal/lateral vehicle state
  double _playerZ = 0.0;
  double _playerX = 0.0; // -1.5 .. +1.5
  double _speedKmh = 95.0;
  double _steerVisual = 0.0; // -1.0 .. +1.0
  double _skyParallax = 0.0;

  double _nitroCharge = 0.85; // 0.0 .. 1.0
  bool _autoPilot = true;
  bool _showTouchPedals = false;
  bool _isModalOpen = false;

  // Touch & mouse-wheel input state
  bool _touchLeft = false;
  bool _touchRight = false;
  bool _touchGas = false;
  bool _touchBrake = false;
  bool _touchNitro = false;
  double _wheelGasImpulse = 0.0;
  double _wheelBrakeImpulse = 0.0;

  // Hyper-Warp target state (3D Horizon & Highway modes)
  RaceSectorMeta? _warpTargetSector;

  // Race telemetry
  int _lapCount = 1;
  double _lapTimeSeconds = 0.0;
  double? _bestLapSeconds;
  int _overtakes = 0;
  int _lastBoostSegIndex = -1;
  double _collisionFlashTimer = 0.0;

  // Sector & HUD banner state
  RaceSectorMeta _activeSector = RaceSectorMeta.sectors.first;
  String? _hudCallout;
  double _hudCalloutTimer = 0.0;

  @override
  void initState() {
    super.initState();
    _trafficCars = CircuitBuilder.buildInitialTraffic();
    _orbs = CircuitBuilder.buildInitialOrbs();
    _paddockPortals = PaddockWorldBuilder.buildLinkPortals();
    _paddockBoosts = PaddockWorldBuilder.buildBoostStrips(const []);
    _paddockOrbs = PaddockWorldBuilder.buildOrbs();
    _paddockRivals = [
      PaddockRivalState(angle: 0.2, speedRad: 0.26, colorVariant: 0, label: 'DART'),
      PaddockRivalState(angle: 1.8, speedRad: 0.22, colorVariant: 1, label: 'WASM'),
      PaddockRivalState(angle: 3.5, speedRad: 0.28, colorVariant: 2, label: 'BLOC'),
      PaddockRivalState(angle: 5.0, speedRad: 0.24, colorVariant: 3, label: 'IMPEL'),
    ];

    _segments = CircuitBuilder.buildCircuit(
      skills: const [],
      experiences: const [],
      projects: const [],
      contacts: const [],
    );

    _loadDriverPortrait();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _rebuildCircuitFromBlocs();
      _focusNode.requestFocus();
      _showCallout(
        '🏁 LIGHTS OUT! DRIVE WITH WASD / ARROWS OR SWITCH MODES ABOVE',
      );
    });

    _ticker = createTicker(_onTick)..start();
  }

  void _loadDriverPortrait() {
    const provider = AssetImage('assets/images/propic3.png');
    final stream = provider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _driverPhoto = info.image;
          });
        }
      },
      onError: (Object _, StackTrace? __) {},
    );
    _photoStream = stream;
    _photoListener = listener;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    if (_photoStream != null && _photoListener != null) {
      _photoStream!.removeListener(_photoListener!);
    }
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuildCircuitFromBlocs() {
    if (!mounted) return;
    final skills = context.read<SkillDetailsBloc>().state.skillDetails;
    final exps = context.read<ExpDetailsBloc>().state.expList;
    final projects = context.read<ProjectBloc>().state.projectList;
    final contacts = context.read<ContactDetailsBloc>().state.contactDetailList;

    setState(() {
      _segments = CircuitBuilder.buildCircuit(
        skills: skills,
        experiences: exps,
        projects: projects,
        contacts: contacts,
      );
      _paddockBoosts = PaddockWorldBuilder.buildBoostStrips(skills);
    });
  }

  void _showCallout(String message) {
    _hudCallout = message;
    _hudCalloutTimer = 2.6;
  }

  void _switchGameMode(RacingGameMode nextMode) {
    if (_gameMode == nextMode) return;
    setState(() {
      _gameMode = nextMode;
      _warpTargetSector = null;
      _paddockGpsTarget = null;
      _paddockArrivalSector = null;

      if (nextMode == RacingGameMode.openPaddock) {
        // Place car cleanly at active sector's paddock zone
        _paddockPos = _activeSector.paddockCenter + const Offset(0, 70);
        _paddockCameraPos = _paddockPos;
        _paddockSignedSpeed = math.max(95.0, _speedKmh.clamp(80.0, 200.0));
        _paddockCruiseAngle = math.atan2(
          _paddockPos.dy / 535.0,
          _paddockPos.dx / 900.0,
        );
      } else {
        // Sync circuit Z to active sector if coming from Open-World Paddock
        final currentSegSector = RaceSectorMeta.forSegment(
          (((_playerZ % CircuitBuilder.trackLength) +
                      CircuitBuilder.trackLength) %
                  CircuitBuilder.trackLength) ~/
              CircuitBuilder.segmentLength,
        );
        if (currentSegSector.index != _activeSector.index) {
          _playerZ =
              _activeSector.checkpointSegment * CircuitBuilder.segmentLength;
        }
        _playerX = _playerX.clamp(-0.85, 0.85);
      }

      _showCallout('🎮 MODE: ${nextMode.title.toUpperCase()}');
    });
    GamificationController.instance.completeQuest('first_scroll');
  }

  void _switchVisualTheme(RacingVisualTheme nextTheme) {
    if (_visualTheme == nextTheme) return;
    setState(() {
      _visualTheme = nextTheme;
      _showCallout('🎨 THEME: ${nextTheme.title.toUpperCase()}');
    });
    GamificationController.instance.completeQuest('style_shifter');
  }

  Future<void> _launchQuickLink(DriverQuickLink link) async {
    GamificationController.instance.completeQuest('loot_collector');
    GamificationController.instance.addXp(
      15,
      reason: 'Launched ${link.label} Portal!',
      uniqueKey: 'portal_${link.id}',
    );
    try {
      await launchUrl(Uri.parse(link.url));
    } catch (e) {
      debugPrint('## Error launching ${link.url}: $e');
    }
  }

  bool _isKeyHeld(List<LogicalKeyboardKey> keys) {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    for (final k in keys) {
      if (pressed.contains(k)) return true;
    }
    return false;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_isModalOpen) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isNavKey = key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.space;

    if (event is KeyDownEvent) {
      if (key == LogicalKeyboardKey.keyE || key == LogicalKeyboardKey.enter) {
        if (_gameMode == RacingGameMode.openPaddock &&
            _activePortalLink != null) {
          _launchQuickLink(_activePortalLink!);
        } else {
          _openPitStop(_activeSector.screen);
        }
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyC) {
        setState(() {
          _autoPilot = !_autoPilot;
          _warpTargetSector = null;
          _paddockGpsTarget = null;
          _showCallout(
            _autoPilot
                ? '🤖 CRUISE AUTO-PILOT ENGAGED'
                : '🏎️ MANUAL CONTROL ENGAGED',
          );
        });
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit1) {
        _switchGameMode(RacingGameMode.horizon3d);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit2) {
        _switchGameMode(RacingGameMode.openPaddock);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit3) {
        _switchGameMode(RacingGameMode.verticalHighway);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyM) {
        final nextIdx = (_gameMode.index + 1) % RacingGameMode.values.length;
        _switchGameMode(RacingGameMode.values[nextIdx]);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyT) {
        final nextIdx =
            (_visualTheme.index + 1) % RacingVisualTheme.values.length;
        _switchVisualTheme(RacingVisualTheme.values[nextIdx]);
        return KeyEventResult.handled;
      }
    }

    return isNavKey ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (_isModalOpen || event is! PointerScrollEvent) return;
    final dy = event.scrollDelta.dy;
    if (dy.abs() < 2) return;

    GamificationController.instance.completeQuest('first_scroll');
    if (dy > 0) {
      _wheelGasImpulse = 0.36;
      _wheelBrakeImpulse = 0.0;
    } else {
      _wheelBrakeImpulse = 0.30;
      _wheelGasImpulse = 0.0;
    }
  }

  void _handlePaddockCanvasTap(TapUpDetails details, Size canvasSize) {
    if (_gameMode != RacingGameMode.openPaddock || _isModalOpen) return;
    final worldPt = RacingPaddockPainter.screenToWorld(
      details.localPosition,
      canvasSize,
      _paddockCameraPos,
    );

    // 1. Check 7 Social/Dev Link Portal Pads
    for (final portal in _paddockPortals) {
      if ((worldPt - portal.center).distance <= portal.radius + 14) {
        _launchQuickLink(portal.link);
        return;
      }
    }

    // 2. Check Central Driver Photo Monument (0, 0)
    if (worldPt.distance <= 165) {
      _openPitStop(Screen.home);
      return;
    }

    // 3. Check 6 Portfolio Sector Bays
    for (final sector in RaceSectorMeta.sectors) {
      final rect = Rect.fromCenter(
        center: sector.paddockCenter,
        width: PaddockWorldBuilder.zoneWidth,
        height: PaddockWorldBuilder.zoneHeight,
      );
      if (rect.contains(worldPt)) {
        _engageSectorSelection(sector.screen);
        return;
      }
    }

    // 4. Otherwise set a free-roam GPS waypoint to drive there!
    setState(() {
      _paddockGpsTarget = Offset(
        worldPt.dx.clamp(
          -PaddockWorldBuilder.halfWidth + 80,
          PaddockWorldBuilder.halfWidth - 80,
        ),
        worldPt.dy.clamp(
          -PaddockWorldBuilder.halfHeight + 80,
          PaddockWorldBuilder.halfHeight - 80,
        ),
      );
      _paddockArrivalSector = null;
      _autoPilot = false;
      _showCallout('📍 GPS WAYPOINT SET — AUTO-DRIVING TO TARGET');
    });
  }

  void _engageSectorSelection(Screen screen) {
    final target = RaceSectorMeta.forScreen(screen);
    GamificationController.instance.completeQuest('first_scroll');

    if (_gameMode == RacingGameMode.openPaddock) {
      if (_hoveredPaddockZone?.screen == screen && _paddockGpsTarget == null) {
        _openPitStop(screen);
        return;
      }
      setState(() {
        _paddockGpsTarget = target.paddockCenter;
        _paddockArrivalSector = target;
        _nitroCharge = math.max(_nitroCharge, 0.70);
        _showCallout('⚡ GPS WARP TO ${target.code}: ${target.shortLabel}');
      });
      return;
    }

    if (_activeSector.screen == screen && _warpTargetSector == null) {
      _openPitStop(screen);
      return;
    }

    setState(() {
      _warpTargetSector = target;
      _nitroCharge = math.max(_nitroCharge, 0.65);
      _showCallout('⚡ HYPER-WARP TO ${target.code}: ${target.shortLabel}');
    });
  }

  Future<void> _openPitStop(Screen screen) async {
    if (_isModalOpen || !mounted) return;
    setState(() {
      _isModalOpen = true;
      _touchLeft = false;
      _touchRight = false;
      _touchGas = false;
      _touchBrake = false;
      _touchNitro = false;
    });

    await showPitStopDossierModal(
      context: context,
      initialScreen: screen,
      onWarpToSector: (targetScreen) {
        final target = RaceSectorMeta.forScreen(targetScreen);
        setState(() {
          if (_gameMode == RacingGameMode.openPaddock) {
            _paddockGpsTarget = target.paddockCenter;
            _paddockArrivalSector = target;
          } else {
            _warpTargetSector = target;
          }
          _nitroCharge = 1.0;
          _showCallout('⚡ WARPING TO ${target.title}');
        });
      },
    );

    if (mounted) {
      setState(() {
        _isModalOpen = false;
      });
      _focusNode.requestFocus();
    }
  }

  void _triggerNitroChallenge() {
    setState(() {
      _nitroCharge = 1.0;
      _autoPilot = true;
      _speedKmh = math.max(_speedKmh, 375.0);
      _paddockSignedSpeed = math.max(_paddockSignedSpeed, 375.0);
      _showCallout('🔥 NITRO OVERDRIVE ENGAGED — 375+ KM/H!');
    });
    GamificationController.instance.completeQuest('bug_hunter');
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt =
        ((elapsed - _lastTick).inMicroseconds / 1000000.0).clamp(0.0, 0.05);
    _lastTick = elapsed;
    _timeSeconds += dt;

    if (_hudCalloutTimer > 0) {
      _hudCalloutTimer = math.max(0.0, _hudCalloutTimer - dt);
      if (_hudCalloutTimer == 0) {
        _hudCallout = null;
      }
    }
    if (_collisionFlashTimer > 0) {
      _collisionFlashTimer = math.max(0.0, _collisionFlashTimer - dt);
    }
    if (_wheelGasImpulse > 0) {
      _wheelGasImpulse = math.max(0.0, _wheelGasImpulse - dt);
    }
    if (_wheelBrakeImpulse > 0) {
      _wheelBrakeImpulse = math.max(0.0, _wheelBrakeImpulse - dt);
    }

    if (_segments.isEmpty) return;

    final keyGas = _isKeyHeld(const [
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.arrowUp,
    ]);
    final keyBrake = _isKeyHeld(const [
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.arrowDown,
    ]);
    final keyLeft = _isKeyHeld(const [
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.arrowLeft,
    ]);
    final keyRight = _isKeyHeld(const [
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.arrowRight,
    ]);
    final keyNitro = _isKeyHeld(const [
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    ]);

    final anyManualSteerOrPedal = keyGas ||
        keyBrake ||
        keyLeft ||
        keyRight ||
        keyNitro ||
        _touchGas ||
        _touchBrake ||
        _touchLeft ||
        _touchRight ||
        _touchNitro;

    if (!_isModalOpen && anyManualSteerOrPedal) {
      _autoPilot = false;
      _warpTargetSector = null;
      _paddockGpsTarget = null;
      _paddockArrivalSector = null;
      GamificationController.instance.completeQuest('first_scroll');
    }

    double steerInput = 0.0;
    if (keyLeft || _touchLeft) steerInput -= 1.0;
    if (keyRight || _touchRight) steerInput += 1.0;

    final gas = keyGas || _touchGas || _wheelGasImpulse > 0;
    final brake = keyBrake || _touchBrake || _wheelBrakeImpulse > 0;
    final wantNitro = keyNitro || _touchNitro;

    if (_gameMode == RacingGameMode.openPaddock) {
      _tickOpenPaddock(
        dt,
        gas: !_isModalOpen && gas,
        brake: !_isModalOpen && brake,
        wantNitro: !_isModalOpen && wantNitro,
        steerInput: _isModalOpen ? 0.0 : steerInput,
      );
    } else {
      _tickCircuitModes(
        dt,
        gas: !_isModalOpen && gas,
        brake: !_isModalOpen && brake,
        wantNitro: !_isModalOpen && wantNitro,
        steerInput: _isModalOpen ? 0.0 : steerInput,
      );
    }

    setState(() {});
  }

  // ===========================================================================
  // OPEN-WORLD TOP-DOWN PADDOCK PHYSICS & INTERACTION LOOP (MODE 2)
  // ===========================================================================
  void _tickOpenPaddock(
    double dt, {
    required bool gas,
    required bool brake,
    required bool wantNitro,
    required double steerInput,
  }) {
    _lapTimeSeconds += dt;

    // Fade drift tire skid marks
    for (int i = _paddockSkids.length - 1; i >= 0; i--) {
      _paddockSkids[i].life -= dt * 0.22;
      if (_paddockSkids[i].life <= 0) {
        _paddockSkids.removeAt(i);
      }
    }

    // Advance roaming paddock rivals
    for (final rival in _paddockRivals) {
      rival.angle = (rival.angle + rival.speedRad * dt) % (2 * math.pi);
    }

    bool effectiveGas = gas;
    bool effectiveBrake = brake;
    bool effectiveNitro = wantNitro;
    double effectiveSteer = steerInput;

    if (_isModalOpen) {
      _paddockSignedSpeed = _lerpDouble(_paddockSignedSpeed, 0.0, dt * 4.0);
    } else if (_paddockGpsTarget != null) {
      final toTarget = _paddockGpsTarget! - _paddockPos;
      final dist = toTarget.distance;
      if (dist < 62.0) {
        final arrived = _paddockArrivalSector;
        _paddockGpsTarget = null;
        _paddockArrivalSector = null;
        _paddockSignedSpeed = 0.0;
        if (arrived != null) {
          _activeSector = arrived;
          context.read<ScreenBloc>().add(UpdateScreen(screen: arrived.screen));
          GamificationController.instance.completeQuest(arrived.questId);
          _showCallout(
            '📍 PARKED AT ${arrived.shortLabel} BAY — PRESS [E] FOR DOSSIER',
          );
        } else {
          _showCallout('📍 DESTINATION REACHED');
        }
      } else {
        // Heading 0 = UP (0, -1) -> targetHeading = atan2(dx, -dy)
        final desiredHeading = math.atan2(toTarget.dx, -toTarget.dy);
        final angleDiff = _wrapAngle(desiredHeading - _paddockHeading);
        effectiveSteer = (angleDiff * 2.4).clamp(-1.0, 1.0);
        effectiveGas = true;
        effectiveNitro = dist > 260.0;
        _nitroCharge = math.max(_nitroCharge, 0.40);
      }
    } else if (_autoPilot) {
      // Smoothly tour the oval Grand Prix Paddock Loop
      final prevAngle = _paddockCruiseAngle;
      _paddockCruiseAngle += dt * 0.34;
      if (_paddockCruiseAngle >= math.pi && prevAngle < math.pi) {
        if (_bestLapSeconds == null || _lapTimeSeconds < _bestLapSeconds!) {
          _bestLapSeconds = _lapTimeSeconds;
        }
        _lapCount++;
        _lapTimeSeconds = 0.0;
      }
      final targetPt = Offset(
        math.cos(_paddockCruiseAngle) * 900.0,
        math.sin(_paddockCruiseAngle) * 535.0,
      );
      final toTarget = targetPt - _paddockPos;
      final desiredHeading = math.atan2(toTarget.dx, -toTarget.dy);
      final angleDiff = _wrapAngle(desiredHeading - _paddockHeading);
      effectiveSteer = (angleDiff * 2.0).clamp(-0.9, 0.9);
      effectiveGas = _paddockSignedSpeed < _cruiseTargetSpeed;
    }

    final nitroActive =
        (effectiveNitro && _nitroCharge > 0.04) || _paddockGpsTarget != null;
    if (nitroActive && _paddockGpsTarget == null) {
      _nitroCharge = (_nitroCharge - dt * 0.25).clamp(0.0, 1.0);
    } else {
      _nitroCharge = (_nitroCharge + dt * 0.06).clamp(0.0, 1.0);
    }

    final topSpeed = nitroActive ? _nitroMaxSpeed : _baseMaxSpeed;
    if (!_isModalOpen) {
      if (nitroActive) {
        _paddockSignedSpeed += 260.0 * dt;
      } else if (effectiveGas) {
        _paddockSignedSpeed += 165.0 * dt;
      } else if (effectiveBrake) {
        if (_paddockSignedSpeed > 8.0) {
          _paddockSignedSpeed -= 260.0 * dt;
        } else {
          // Reverse gear in Open-World Paddock!
          _paddockSignedSpeed -= 110.0 * dt;
        }
      } else {
        // Natural rolling drag toward stop
        if (_paddockSignedSpeed.abs() < 4.0) {
          _paddockSignedSpeed = 0.0;
        } else {
          _paddockSignedSpeed -= _paddockSignedSpeed.sign * 78.0 * dt;
        }
      }
    }

    _paddockSignedSpeed = _paddockSignedSpeed.clamp(-95.0, topSpeed);
    _speedKmh = _paddockSignedSpeed.abs();
    if (_speedKmh >= 360.0) {
      GamificationController.instance.completeQuest('bug_hunter');
    }

    // Steering rotation & drift tire skid marks
    final speedNorm = (_speedKmh / 160.0).clamp(0.0, 1.25);
    if (_speedKmh > 3.0) {
      final reverseSign = _paddockSignedSpeed >= 0 ? 1.0 : -1.0;
      final turnRate = 2.45 * (0.35 + 0.65 * speedNorm.clamp(0.0, 1.0));
      _paddockHeading = _wrapAngle(
        _paddockHeading + effectiveSteer * turnRate * reverseSign * dt,
      );
    }
    _steerVisual = _lerpDouble(_steerVisual, effectiveSteer, dt * 10.0);

    final forward = Offset(
      math.sin(_paddockHeading),
      -math.cos(_paddockHeading),
    );
    final right = Offset(
      math.cos(_paddockHeading),
      math.sin(_paddockHeading),
    );

    final prevPos = _paddockPos;
    final worldPxPerSec = _paddockSignedSpeed * 2.05;
    _paddockPos += forward * (worldPxPerSec * dt);

    // Keep within Paddock Arena Fence
    const maxX = PaddockWorldBuilder.halfWidth - 45;
    const maxY = PaddockWorldBuilder.halfHeight - 45;
    _paddockPos = Offset(
      _paddockPos.dx.clamp(-maxX, maxX),
      _paddockPos.dy.clamp(-maxY, maxY),
    );

    // Spawn twin rear tire drift marks when cornering hard at speed
    if (effectiveSteer.abs() > 0.45 && _speedKmh > 110.0) {
      for (final side in const [-12.0, 12.0]) {
        final rearOffset = -forward * 24.0 + right * side;
        _paddockSkids.add(
          PaddockSkidMark(
            a: prevPos + rearOffset,
            b: _paddockPos + rearOffset,
          ),
        );
      }
      if (_paddockSkids.length > 160) {
        _paddockSkids.removeRange(0, _paddockSkids.length - 160);
      }
    }

    // Smooth camera follow with subtle velocity lookahead
    final camTarget =
        _paddockPos + forward * (_paddockSignedSpeed.clamp(-40.0, 240.0) * 0.32);
    _paddockCameraPos = Offset(
      _lerpDouble(_paddockCameraPos.dx, camTarget.dx, dt * 6.5),
      _lerpDouble(_paddockCameraPos.dy, camTarget.dy, dt * 6.5),
    );

    // Check Link Portal proximity
    DriverQuickLink? matchedPortal;
    for (final portal in _paddockPortals) {
      if ((_paddockPos - portal.center).distance <= portal.radius + 18) {
        matchedPortal = portal.link;
        break;
      }
    }
    if (matchedPortal?.id != _activePortalLink?.id) {
      _activePortalLink = matchedPortal;
      if (matchedPortal != null) {
        _showCallout(
          '🔗 ${matchedPortal.label.toUpperCase()} PORTAL — PRESS [E] OR TAP TO OPEN',
        );
      }
    }

    // Check 6 Portfolio Sector Bays
    RaceSectorMeta? insideZone;
    for (final sector in RaceSectorMeta.sectors) {
      final rect = Rect.fromCenter(
        center: sector.paddockCenter,
        width: PaddockWorldBuilder.zoneWidth,
        height: PaddockWorldBuilder.zoneHeight,
      );
      if (rect.contains(_paddockPos)) {
        insideZone = sector;
        break;
      }
    }
    _hoveredPaddockZone = insideZone;
    if (insideZone != null && insideZone.index != _activeSector.index) {
      _activeSector = insideZone;
      context
          .read<ScreenBloc>()
          .add(UpdateScreen(screen: insideZone.screen));
      GamificationController.instance.completeQuest(insideZone.questId);
      _showCallout(
        '🏁 ENTERED ${insideZone.shortLabel} BAY — PRESS [E] FOR DOSSIER',
      );
    }

    // Check ECU Skill Boost Strips
    bool onAnyBoost = false;
    for (int i = 0; i < _paddockBoosts.length; i++) {
      final b = _paddockBoosts[i];
      if ((_paddockPos - b.center).distance < 58.0) {
        onAnyBoost = true;
        if (_lastPaddockBoostIdx != i) {
          _lastPaddockBoostIdx = i;
          _nitroCharge = (_nitroCharge + 0.30).clamp(0.0, 1.0);
          _paddockSignedSpeed =
              math.min(_nitroMaxSpeed, _paddockSignedSpeed + 75.0);
          if (b.skillName != null) {
            GamificationController.instance.boostSkill(b.skillName!);
          }
          _showCallout('⚡ ${b.label} +75 KM/H!');
        }
        break;
      }
    }
    if (!onAnyBoost) {
      _lastPaddockBoostIdx = -1;
    }

    // Collect Paddock Data Crystals
    for (final orb in _paddockOrbs) {
      if (orb.collected) continue;
      if ((_paddockPos - orb.pos).distance < 36.0) {
        orb.collected = true;
        _nitroCharge = (_nitroCharge + 0.20).clamp(0.0, 1.0);
        GamificationController.instance.addXp(
          10,
          reason: 'Collected Paddock Crystal (${orb.label})',
        );
      }
    }
  }

  // ===========================================================================
  // CIRCUIT PHYSICS LOOP (MODE 1: 3D HORIZON & MODE 3: VERTICAL HIGHWAY)
  // ===========================================================================
  void _tickCircuitModes(
    double dt, {
    required bool gas,
    required bool brake,
    required bool wantNitro,
    required double steerInput,
  }) {
    if (_isModalOpen) {
      _speedKmh = _lerpDouble(_speedKmh, 35.0, dt * 3.0);
      _advanceCircuitWorld(dt, steerInput: 0);
      return;
    }

    bool effectiveGas = gas;
    bool effectiveBrake = brake;
    bool effectiveNitro = wantNitro;
    double effectiveSteer = steerInput;

    if (_warpTargetSector != null) {
      final targetSeg = (_warpTargetSector!.checkpointSegment -
              2 +
              CircuitBuilder.totalSegments) %
          CircuitBuilder.totalSegments;
      final targetZ = targetSeg * CircuitBuilder.segmentLength;
      final trackLen = CircuitBuilder.trackLength;
      final normZ = ((_playerZ % trackLen) + trackLen) % trackLen;
      double distForward = targetZ - normZ;
      if (distForward < 0) distForward += trackLen;

      if (distForward < 900.0) {
        final arrived = _warpTargetSector!;
        _warpTargetSector = null;
        _autoPilot = true;
        _speedKmh = _cruiseTargetSpeed;
        GamificationController.instance.completeQuest(arrived.questId);
        _showCallout('📍 ARRIVED: ${arrived.title} — PRESS [E] FOR PIT-STOP');
      } else {
        effectiveGas = true;
        effectiveBrake = false;
        effectiveNitro = distForward > 2200.0;
        _nitroCharge = math.max(_nitroCharge, 0.35);
        effectiveSteer = (-_playerX * 2.4).clamp(-1.0, 1.0);
      }
    } else if (_autoPilot && !effectiveBrake) {
      effectiveGas = _speedKmh < _cruiseTargetSpeed;
      double desiredLane = 0.0;
      final trackLen = CircuitBuilder.trackLength;
      final normZ = ((_playerZ % trackLen) + trackLen) % trackLen;
      for (final car in _trafficCars) {
        double dz = car.z - normZ;
        if (dz < 0) dz += trackLen;
        if (dz > 0 && dz < 2600 && (car.lane - desiredLane).abs() < 0.38) {
          desiredLane = car.lane >= 0 ? -0.64 : 0.64;
          break;
        }
      }
      effectiveSteer = ((desiredLane - _playerX) * 2.2).clamp(-0.85, 0.85);
    }

    final nitroActive =
        (effectiveNitro && _nitroCharge > 0.04) || _warpTargetSector != null;
    if (nitroActive && _warpTargetSector == null) {
      _nitroCharge = (_nitroCharge - dt * 0.26).clamp(0.0, 1.0);
    } else {
      _nitroCharge = (_nitroCharge + dt * 0.055).clamp(0.0, 1.0);
    }

    final topSpeed = nitroActive ? _nitroMaxSpeed : _baseMaxSpeed;
    if (nitroActive) {
      _speedKmh += 240.0 * dt;
    } else if (effectiveGas) {
      _speedKmh += 135.0 * dt;
    } else if (effectiveBrake) {
      _speedKmh -= 230.0 * dt;
    } else {
      _speedKmh -= 48.0 * dt;
    }

    if (_playerX.abs() > 1.06 && _warpTargetSector == null) {
      if (_speedKmh > 135.0) {
        _speedKmh -= 160.0 * dt;
      }
    }

    _speedKmh = _speedKmh.clamp(0.0, topSpeed);
    if (_speedKmh >= 360.0) {
      GamificationController.instance.completeQuest('bug_hunter');
    }

    _advanceCircuitWorld(dt, steerInput: effectiveSteer);
  }

  void _advanceCircuitWorld(double dt, {required double steerInput}) {
    final segLen = CircuitBuilder.segmentLength;
    final trackLen = CircuitBuilder.trackLength;
    final totalSegs = _segments.length;

    final prevLapIndex = (_playerZ / trackLen).floor();
    final worldUnitsPerSec = _speedKmh * 24.5;
    _playerZ += worldUnitsPerSec * dt;
    _lapTimeSeconds += dt;

    final newLapIndex = (_playerZ / trackLen).floor();
    if (newLapIndex > prevLapIndex) {
      if (_bestLapSeconds == null || _lapTimeSeconds < _bestLapSeconds!) {
        _bestLapSeconds = _lapTimeSeconds;
      }
      _lapCount++;
      _lapTimeSeconds = 0.0;
      for (final orb in _orbs) {
        orb.collected = false;
      }
      GamificationController.instance.completeQuest('bug_hunter');
      GamificationController.instance.addXp(
        40,
        reason: 'Completed Lap ${_lapCount - 1} of SPNK Grand Prix!',
      );
      _showCallout('🏆 LAP ${_lapCount - 1} COMPLETE! STARTING LAP $_lapCount');
    }

    final normZ = ((_playerZ % trackLen) + trackLen) % trackLen;
    final segIndex = (normZ ~/ segLen) % totalSegs;
    final currentSeg = _segments[segIndex];

    final speedFactor = (_speedKmh / _baseMaxSpeed).clamp(0.0, 1.35);
    final steerAuthority = _speedKmh > 4 ? 1.85 : 0.0;
    _playerX += steerInput * steerAuthority * dt;

    // Centrifugal force applies in 3D curving highway mode
    if (_gameMode == RacingGameMode.horizon3d &&
        !_autoPilot &&
        _warpTargetSector == null) {
      _playerX -= currentSeg.curve * 0.22 * speedFactor * speedFactor * dt;
    }
    final maxLateral =
        _gameMode == RacingGameMode.verticalHighway ? 1.12 : 1.42;
    _playerX = _playerX.clamp(-maxLateral, maxLateral);

    _steerVisual = _lerpDouble(_steerVisual, steerInput, dt * 9.0);
    _skyParallax +=
        (currentSeg.curve * speedFactor * 0.012 + steerInput * 0.004) *
            (dt * 60.0);

    final detectedSector = RaceSectorMeta.forSegment(segIndex);
    if (detectedSector.index != _activeSector.index) {
      _activeSector = detectedSector;
      context
          .read<ScreenBloc>()
          .add(UpdateScreen(screen: detectedSector.screen));
      if (_warpTargetSector == null) {
        GamificationController.instance.completeQuest(detectedSector.questId);
        _showCallout('🏁 ${detectedSector.code} // ${detectedSector.title}');
      }
    }

    if (currentSeg.boostLane != null && _lastBoostSegIndex != segIndex) {
      if ((_playerX - currentSeg.boostLane!).abs() < 0.34) {
        _lastBoostSegIndex = segIndex;
        _nitroCharge = (_nitroCharge + 0.30).clamp(0.0, 1.0);
        _speedKmh = math.min(_nitroMaxSpeed, _speedKmh + 65.0);
        if (currentSeg.boostSkillName != null) {
          GamificationController.instance
              .boostSkill(currentSeg.boostSkillName!);
          _showCallout(
            '⚡ ${currentSeg.boostSkillName!.toUpperCase()} ECU BOOST PAD!',
          );
        } else {
          _showCallout('⚡ NITRO BOOST PAD +65 KM/H!');
        }
      }
    } else if (currentSeg.boostLane == null &&
        (_lastBoostSegIndex - segIndex).abs() > 3) {
      _lastBoostSegIndex = -1;
    }

    for (final orb in _orbs) {
      if (orb.collected) continue;
      double dz = (orb.z - normZ).abs();
      if (dz > trackLen * 0.5) dz = trackLen - dz;
      if (dz < 220.0 && (_playerX - orb.lane).abs() < 0.30) {
        orb.collected = true;
        _nitroCharge = (_nitroCharge + 0.20).clamp(0.0, 1.0);
        GamificationController.instance.addXp(
          10,
          reason: 'Collected Track Telemetry Crystal (${orb.label})',
        );
      }
    }

    for (final car in _trafficCars) {
      final prevRel = _signedTrackDelta(car.z, normZ, trackLen);
      car.z = (car.z + car.speed * 18.0 * dt) % trackLen;
      final newRel = _signedTrackDelta(car.z, normZ, trackLen);

      if (!_isModalOpen &&
          _warpTargetSector == null &&
          newRel > -60.0 &&
          newRel < 190.0 &&
          (_playerX - car.lane).abs() < 0.25) {
        _collisionFlashTimer = 0.32;
        _speedKmh = math.max(85.0, car.speed * 0.92);
        car.z = (normZ + 280.0) % trackLen;
        _showCallout('💥 RUBBING IS RACING! STEER AROUND TRAFFIC');
      } else if (prevRel > 80.0 && newRel <= 80.0 && !car.passedRecently) {
        car.passedRecently = true;
        _overtakes++;
        _nitroCharge = (_nitroCharge + 0.08).clamp(0.0, 1.0);
        if (_overtakes % 4 == 0) {
          GamificationController.instance.addXp(
            15,
            reason: '$_overtakes Clean Overtakes on Circuit!',
          );
        }
      } else if (newRel.abs() > 2500.0) {
        car.passedRecently = false;
      }
    }
  }

  double _wrapAngle(double rad) {
    while (rad > math.pi) {
      rad -= 2 * math.pi;
    }
    while (rad < -math.pi) {
      rad += 2 * math.pi;
    }
    return rad;
  }

  double _signedTrackDelta(double targetZ, double baseZ, double trackLen) {
    double d = targetZ - baseZ;
    while (d > trackLen * 0.5) {
      d -= trackLen;
    }
    while (d < -trackLen * 0.5) {
      d += trackLen;
    }
    return d;
  }

  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SkillDetailsBloc, SkillsState>(
          listener: (_, __) => _rebuildCircuitFromBlocs(),
        ),
        BlocListener<ExpDetailsBloc, ExpDetailsState>(
          listener: (_, __) => _rebuildCircuitFromBlocs(),
        ),
        BlocListener<ProjectBloc, ProjectState>(
          listener: (_, __) => _rebuildCircuitFromBlocs(),
        ),
        BlocListener<ContactDetailsBloc, ContactDetailsState>(
          listener: (_, __) => _rebuildCircuitFromBlocs(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final palette = RacingThemePalette.resolve(themeState, _visualTheme);
          final accent = palette.accent;
          final trackLen = CircuitBuilder.trackLength;
          final lapProgress = _gameMode == RacingGameMode.openPaddock
              ? (_activeSector.index + 0.5) / RaceSectorMeta.sectors.length
              : (((_playerZ % trackLen) + trackLen) % trackLen) / trackLen;

          final nitroActive = ((_isKeyHeld(const [
                        LogicalKeyboardKey.space,
                        LogicalKeyboardKey.shiftLeft,
                        LogicalKeyboardKey.shiftRight,
                      ]) ||
                      _touchNitro) &&
                  _nitroCharge > 0.04) ||
              _warpTargetSector != null ||
              _paddockGpsTarget != null;

          final isBraking = _isKeyHeld(const [
                LogicalKeyboardKey.keyS,
                LogicalKeyboardKey.arrowDown,
              ]) ||
              _touchBrake ||
              _wheelBrakeImpulse > 0;

          final isAccelerating = _speedKmh > 25 && !isBraking;

          return Scaffold(
            backgroundColor: palette.groundNear,
            body: Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: Listener(
                onPointerDown: (_) {
                  if (!_isModalOpen && !_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                  }
                },
                onPointerSignal: _handlePointerSignal,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = constraints.maxWidth;
                    final maxH = constraints.maxHeight;
                    final isCompact = maxW < 760;
                    const topHudOffset = 104.0;
                    final carWidth = (maxW * 0.22).clamp(138.0, 236.0);
                    final carHeight = carWidth * 0.62;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. ACTIVE RACING GAMEPLAY CANVAS (3 SWITCHABLE MODES!)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) => _handlePaddockCanvasTap(
                            details,
                            Size(maxW, maxH),
                          ),
                          child: RepaintBoundary(
                            child: _buildActiveModeCanvas(
                              themeState: themeState,
                              palette: palette,
                              nitroActive: nitroActive,
                              isAccelerating: isAccelerating,
                              isBraking: isBraking,
                            ),
                          ),
                        ),

                        // 2. CHASE-CAM SUPERCAR OVERLAY (ONLY IN 3D HORIZON MODE)
                        if (_gameMode == RacingGameMode.horizon3d)
                          Positioned(
                            left: (maxW - carWidth) / 2,
                            bottom: isCompact ? 132 : 102,
                            width: carWidth,
                            height: carHeight,
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: RacingCarPainter(
                                  steer: _steerVisual,
                                  speedKmh: _speedKmh,
                                  isAccelerating: isAccelerating,
                                  isBraking: isBraking,
                                  nitroActive: nitroActive,
                                  collisionFlash: _collisionFlashTimer > 0,
                                  timeSeconds: _timeSeconds,
                                  themeState: themeState,
                                  palette: palette,
                                ),
                              ),
                            ),
                          ),

                        // 3. WINDSHIELD DRIVER PHOTO, LIVE LINKS & SECTOR HUD
                        if (maxH > 460)
                          Positioned(
                            top: topHudOffset,
                            left: isCompact ? 10 : 22,
                            child: SectorWindshieldHud(
                              sector: _activeSector,
                              palette: palette,
                              compact: isCompact,
                              activePortalLink:
                                  _gameMode == RacingGameMode.openPaddock
                                      ? _activePortalLink
                                      : null,
                              onOpenPitStop: () =>
                                  _openPitStop(_activeSector.screen),
                              onOpenDriverProfile: () =>
                                  _openPitStop(Screen.home),
                              onWarpNextSector: () {
                                final nextIdx = (_activeSector.index + 1) %
                                    RaceSectorMeta.sectors.length;
                                _engageSectorSelection(
                                  RaceSectorMeta.sectors[nextIdx].screen,
                                );
                              },
                            ),
                          ),

                        // 4. TRANSIENT RACE CALLOUT BANNER (TOP-CENTER)
                        if (_hudCallout != null && maxW >= 980)
                          Positioned(
                            top: topHudOffset + 4,
                            left: 425,
                            right: 220,
                            child: IgnorePointer(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.hudSurface
                                        .withValues(alpha: 0.86),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.65),
                                    ),
                                  ),
                                  child: Text(
                                    _hudCallout!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.bodySmall.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.3,
                                      color: palette.secondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // 5. BOTTOM DIGITAL SPEEDOMETER & TOUCH PEDALS
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: RacingBottomCockpitHud(
                            gameMode: _gameMode,
                            palette: palette,
                            speedKmh: _speedKmh,
                            maxSpeedKmh: _nitroMaxSpeed,
                            nitroCharge: _nitroCharge,
                            nitroActive: nitroActive,
                            autoPilot: _autoPilot,
                            lapCount: _lapCount,
                            lapTimeSeconds: _lapTimeSeconds,
                            bestLapSeconds: _bestLapSeconds,
                            overtakes: _overtakes,
                            showTouchPedals: _showTouchPedals,
                            onToggleAutoPilot: () {
                              setState(() {
                                _autoPilot = !_autoPilot;
                                _warpTargetSector = null;
                                _paddockGpsTarget = null;
                              });
                            },
                            onToggleTouchPedals: () {
                              setState(() {
                                _showTouchPedals = !_showTouchPedals;
                              });
                            },
                            onSteerLeftChanged: (v) => _touchLeft = v,
                            onSteerRightChanged: (v) => _touchRight = v,
                            onGasChanged: (v) => _touchGas = v,
                            onBrakeChanged: (v) => _touchBrake = v,
                            onNitroChanged: (v) => _touchNitro = v,
                          ),
                        ),

                        // 6. FLOATING TROPHY & +XP TOAST BANNER
                        const AchievementToastBanner(),

                        // 7. TOP TELEMETRY BAR (3 MODES + 3 THEMES + 6 SECTORS)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            bottom: false,
                            child: RacingTopTelemetryBar(
                              activeSector: _activeSector,
                              gameMode: _gameMode,
                              visualTheme: _visualTheme,
                              palette: palette,
                              lapProgress: lapProgress,
                              isWarping: _warpTargetSector != null ||
                                  _paddockGpsTarget != null,
                              onSelectSector: _engageSectorSelection,
                              onSelectGameMode: _switchGameMode,
                              onSelectVisualTheme: _switchVisualTheme,
                              onOpenPitWall: () =>
                                  _openPitStop(_activeSector.screen),
                              onTriggerNitroQuest: _triggerNitroChallenge,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveModeCanvas({
    required ThemeState themeState,
    required RacingThemePalette palette,
    required bool nitroActive,
    required bool isAccelerating,
    required bool isBraking,
  }) {
    switch (_gameMode) {
      case RacingGameMode.horizon3d:
        return CustomPaint(
          painter: RacingTrackPainter(
            segments: _segments,
            trafficCars: _trafficCars,
            orbs: _orbs,
            playerZ: _playerZ,
            playerX: _playerX,
            speedKmh: _speedKmh,
            maxSpeedKmh: _nitroMaxSpeed,
            nitroActive: nitroActive,
            skyParallax: _skyParallax,
            timeSeconds: _timeSeconds,
            themeState: themeState,
            palette: palette,
            driverPhoto: _driverPhoto,
          ),
        );

      case RacingGameMode.openPaddock:
        return CustomPaint(
          painter: RacingPaddockPainter(
            playerPos: _paddockPos,
            cameraPos: _paddockCameraPos,
            playerHeading: _paddockHeading,
            steerVisual: _steerVisual,
            speedKmh: _speedKmh,
            isAccelerating: isAccelerating,
            isBraking: isBraking,
            nitroActive: nitroActive,
            timeSeconds: _timeSeconds,
            palette: palette,
            activeSector: _activeSector,
            hoveredZone: _hoveredPaddockZone,
            activePortalLink: _activePortalLink,
            gpsTarget: _paddockGpsTarget,
            linkPortals: _paddockPortals,
            boostStrips: _paddockBoosts,
            orbs: _paddockOrbs,
            skidMarks: _paddockSkids,
            rivals: _paddockRivals,
            driverPhoto: _driverPhoto,
          ),
        );

      case RacingGameMode.verticalHighway:
        return CustomPaint(
          painter: RacingHighwayPainter(
            segments: _segments,
            trafficCars: _trafficCars,
            orbs: _orbs,
            playerZ: _playerZ,
            playerX: _playerX,
            steerVisual: _steerVisual,
            speedKmh: _speedKmh,
            isAccelerating: isAccelerating,
            isBraking: isBraking,
            nitroActive: nitroActive,
            timeSeconds: _timeSeconds,
            palette: palette,
            driverPhoto: _driverPhoto,
          ),
        );
    }
  }
}
