import 'dart:math' as math;

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
import 'package:spnk/views/screens/racing/racing_hud_widgets.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';
import 'package:spnk/views/screens/racing/racing_pit_dossier.dart';
import 'package:spnk/views/screens/racing/racing_track_painter.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';

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

  List<RoadSegment> _segments = [];
  late final List<TrafficCar> _trafficCars;
  late final List<DataCrystalOrb> _orbs;

  Duration _lastTick = Duration.zero;
  double _timeSeconds = 0.0;

  // Player vehicle physics state
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

  // Hyper-Warp target state
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _rebuildCircuitFromBlocs();
      _focusNode.requestFocus();
      _showCallout(
          '🏁 LIGHTS OUT! DRIVE WITH WASD / ARROWS OR CLICK ANY SECTOR');
    });

    _segments = CircuitBuilder.buildCircuit(
      skills: const [],
      experiences: const [],
      projects: const [],
      contacts: const [],
    );

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
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
    });
  }

  void _showCallout(String message) {
    _hudCallout = message;
    _hudCalloutTimer = 2.6;
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
        _openPitStop(_activeSector.screen);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyC) {
        setState(() {
          _autoPilot = !_autoPilot;
          _warpTargetSector = null;
          _showCallout(
            _autoPilot
                ? '🤖 CRUISE AUTO-PILOT ENGAGED'
                : '🏎️ MANUAL CONTROL ENGAGED',
          );
        });
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

  void _engageSectorSelection(Screen screen) {
    final target = RaceSectorMeta.forScreen(screen);
    GamificationController.instance.completeQuest('first_scroll');

    // If already inside this sector and not warping, open its Pit-Stop Dossier
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
          _warpTargetSector = target;
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

    // While Pit-Stop modal is open, gently coast at pit-lane speed
    if (_isModalOpen) {
      _speedKmh = _lerpDouble(_speedKmh, 35.0, dt * 3.0);
      _advanceWorld(dt, gas: false, brake: false, nitro: false, steerInput: 0);
      setState(() {});
      return;
    }

    // Poll held keyboard inputs
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

    if (anyManualSteerOrPedal) {
      if (_autoPilot) {
        _autoPilot = false;
      }
      _warpTargetSector = null;
      GamificationController.instance.completeQuest('first_scroll');
    }

    double steerInput = 0.0;
    if (keyLeft || _touchLeft) steerInput -= 1.0;
    if (keyRight || _touchRight) steerInput += 1.0;

    bool gas = keyGas || _touchGas || _wheelGasImpulse > 0;
    bool brake = keyBrake || _touchBrake || _wheelBrakeImpulse > 0;
    bool wantNitro = keyNitro || _touchNitro;

    // Hyper-Warp AI Guidance
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
        gas = true;
        brake = false;
        wantNitro = distForward > 2200.0;
        _nitroCharge = math.max(_nitroCharge, 0.35);
        steerInput = (-_playerX * 2.4).clamp(-1.0, 1.0);
      }
    } else if (_autoPilot && !brake) {
      // Smooth AI Cruise Mode: maintains racing line & dodges slower traffic
      gas = _speedKmh < _cruiseTargetSpeed;
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
      steerInput = ((desiredLane - _playerX) * 2.2).clamp(-0.85, 0.85);
    }

    final nitroActive =
        (wantNitro && _nitroCharge > 0.04) || _warpTargetSector != null;
    if (nitroActive && _warpTargetSector == null) {
      _nitroCharge = (_nitroCharge - dt * 0.26).clamp(0.0, 1.0);
    } else {
      _nitroCharge = (_nitroCharge + dt * 0.055).clamp(0.0, 1.0);
    }

    // Longitudinal acceleration, braking & drag
    final topSpeed = nitroActive ? _nitroMaxSpeed : _baseMaxSpeed;
    if (nitroActive) {
      _speedKmh += 240.0 * dt;
    } else if (gas) {
      _speedKmh += 135.0 * dt;
    } else if (brake) {
      _speedKmh -= 230.0 * dt;
    } else {
      // Natural aerodynamic coasting drag
      _speedKmh -= 48.0 * dt;
    }

    // Off-road kerb/shoulder drag when outside [-1.06, +1.06]
    if (_playerX.abs() > 1.06 && _warpTargetSector == null) {
      if (_speedKmh > 135.0) {
        _speedKmh -= 160.0 * dt;
      }
    }

    _speedKmh = _speedKmh.clamp(0.0, topSpeed);

    if (_speedKmh >= 360.0) {
      GamificationController.instance.completeQuest('bug_hunter');
    }

    _advanceWorld(
      dt,
      gas: gas,
      brake: brake,
      nitro: nitroActive,
      steerInput: steerInput,
    );

    setState(() {});
  }

  void _advanceWorld(
    double dt, {
    required bool gas,
    required bool brake,
    required bool nitro,
    required double steerInput,
  }) {
    final segLen = CircuitBuilder.segmentLength;
    final trackLen = CircuitBuilder.trackLength;
    final totalSegs = _segments.length;

    final prevLapIndex = (_playerZ / trackLen).floor();
    // Convert KM/H into world Z units per second for thrilling visual speed
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

    // Lateral steering + centrifugal cornering force
    final speedFactor = (_speedKmh / _baseMaxSpeed).clamp(0.0, 1.35);
    final steerAuthority = _speedKmh > 4 ? 1.85 : 0.0;
    _playerX += steerInput * steerAuthority * dt;

    if (!_autoPilot && _warpTargetSector == null) {
      _playerX -= currentSeg.curve * 0.22 * speedFactor * speedFactor * dt;
    }
    _playerX = _playerX.clamp(-1.42, 1.42);

    _steerVisual = _lerpDouble(_steerVisual, steerInput, dt * 9.0);
    _skyParallax +=
        (currentSeg.curve * speedFactor * 0.012 + steerInput * 0.004) *
            (dt * 60.0);

    // Check active sector & sync ScreenBloc
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

    // Track Surface Boost Pads
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

    // Collectible Data Crystal Orbs
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

    // Advance Traffic / Rival Cars & check overtakes / bumps
    for (final car in _trafficCars) {
      final prevRel = _signedTrackDelta(car.z, normZ, trackLen);
      car.z = (car.z + car.speed * 18.0 * dt) % trackLen;
      final newRel = _signedTrackDelta(car.z, normZ, trackLen);

      // Player car sits roughly at +100 world units ahead of camera Z
      if (!_isModalOpen &&
          _warpTargetSector == null &&
          newRel > -60.0 &&
          newRel < 190.0 &&
          (_playerX - car.lane).abs() < 0.25) {
        // Gentle arcade bump: flash sparks, match speed & nudge rival ahead
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
          final accent = themeState.accentColor;
          final trackLen = CircuitBuilder.trackLength;
          final lapProgress =
              (((_playerZ % trackLen) + trackLen) % trackLen) / trackLen;

          final nitroActive = (_isKeyHeld(const [
                        LogicalKeyboardKey.space,
                        LogicalKeyboardKey.shiftLeft,
                        LogicalKeyboardKey.shiftRight,
                      ]) ||
                      _touchNitro) &&
                  _nitroCharge > 0.04 ||
              _warpTargetSector != null;

          final isBraking = _isKeyHeld(const [
                LogicalKeyboardKey.keyS,
                LogicalKeyboardKey.arrowDown,
              ]) ||
              _touchBrake ||
              _wheelBrakeImpulse > 0;

          final isAccelerating = _speedKmh > 25 && !isBraking;

          return Scaffold(
            backgroundColor: context.scaffoldColor,
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
                    final topHudOffset = maxW >= 1080 ? 68.0 : 104.0;
                    final carWidth = (maxW * 0.22).clamp(138.0, 236.0);
                    final carHeight = carWidth * 0.62;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. PSEUDO-3D HORIZON RACING CIRCUIT CANVAS
                        RepaintBoundary(
                          child: CustomPaint(
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
                              scaffoldColor: context.scaffoldColor,
                              primaryColor: context.primaryColor,
                            ),
                          ),
                        ),

                        // 2. PLAYER CYBER-GT SUPERCAR (CHASE CAM)
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
                              ),
                            ),
                          ),
                        ),

                        // 3. WINDSHIELD LIVE SECTOR HOLO-CARD (TOP-LEFT)
                        if (maxH > 460)
                          Positioned(
                            top: topHudOffset,
                            left: isCompact ? 10 : 22,
                            child: SectorWindshieldHud(
                              sector: _activeSector,
                              compact: isCompact,
                              onOpenPitStop: () =>
                                  _openPitStop(_activeSector.screen),
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
                            left: 410,
                            right: 320,
                            child: IgnorePointer(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF060A18)
                                        .withValues(alpha: 0.84),
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
                                      color: accent,
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

                        // 7. TOP PIT-WALL TELEMETRY & QUICK-WARP BAR
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            bottom: false,
                            child: RacingTopTelemetryBar(
                              activeSector: _activeSector,
                              lapProgress: lapProgress,
                              isWarping: _warpTargetSector != null,
                              onSelectSector: _engageSectorSelection,
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
}
