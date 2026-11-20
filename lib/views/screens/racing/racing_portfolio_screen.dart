import 'dart:convert';
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
import 'package:spnk/views/screens/racing/racing_3d_bridge.dart';
import 'package:spnk/views/screens/racing/racing_car_painter.dart';
import 'package:spnk/views/screens/racing/racing_collision_engine.dart';
import 'package:spnk/views/screens/racing/racing_highway_painter.dart';
import 'package:spnk/views/screens/racing/racing_hologram_overlay.dart';
import 'package:spnk/views/screens/racing/racing_hud_widgets.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';
import 'package:spnk/views/screens/racing/racing_paddock_painter.dart';
import 'package:spnk/views/screens/racing/racing_pit_dossier.dart';
import 'package:spnk/views/screens/racing/racing_track_painter.dart';
import 'package:spnk/views/screens/racing/racing_vehicle_selector.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:url_launcher/url_launcher.dart';

class RacingPortfolioScreen extends StatefulWidget {
  const RacingPortfolioScreen({super.key});

  @override
  State<RacingPortfolioScreen> createState() => _RacingPortfolioScreenState();
}

class _RacingPortfolioScreenState extends State<RacingPortfolioScreen>
    with SingleTickerProviderStateMixin {
  static const double _cruiseTargetSpeed = 148.0;
  static const double _hologramPreviewDuration = 6.0;

  late final Ticker _ticker;
  late final Racing3dBridge _bridge3d;
  final FocusNode _focusNode = FocusNode();
  final math.Random _rng = math.Random();

  // Switchable 3 Gameplay Modes, 4 Visual Themes, 5 Vehicles & 3D Camera
  RacingGameMode _gameMode = RacingGameMode.horizon3d;
  RacingVisualTheme _visualTheme = RacingVisualTheme.nfsMostWanted;
  VehicleType _selectedVehicle = VehicleType.apexGt;
  RacingCameraPreset _cameraPreset = RacingCameraPreset.chase3d;
  bool _isGarageOpen = false;

  // Decoded Driver Portrait for in-world 3D/2D canvas rendering
  ImageStream? _photoStream;
  ImageStreamListener? _photoListener;
  ui.Image? _driverPhoto;

  // Circuit (3D Horizon + Vertical Highway) world state
  List<RoadSegment> _segments = [];
  late final List<TrafficCar> _trafficCars;
  late final List<TrackObstacle> _obstacles;
  late final List<DataCrystalOrb> _orbs;
  final List<ImpactSpark> _sparks = [];

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

  // Race telemetry & collision state
  int _lapCount = 1;
  double _lapTimeSeconds = 0.0;
  double? _bestLapSeconds;
  int _overtakes = 0;
  int _collisionCount = 0;
  int _nearMissCount = 0;
  double _hullIntegrity = 1.0;
  int _lastBoostSegIndex = -1;
  double _collisionFlashTimer = 0.0;
  double _lateralBounceVel = 0.0;
  double _cameraShakeTimer = 0.0;
  double _cameraShakeIntensity = 0.0;
  double _hitVignetteAlpha = 0.0;
  double _paddockMonumentHitCooldown = 0.0;
  int _collisionEventSeq = 0;
  double _lastImpactLaneX = 0.0;
  double _lastImpactPushDir = 1.0;
  Offset? _lastImpactWorldPoint;
  int _arrivalEventSeq = 0;

  // Destination Hologram & HUD banner state
  RaceSectorMeta _activeSector = RaceSectorMeta.sectors.first;
  RaceSectorMeta? _activeHologramSector;
  bool _hologramPinned = false;
  double _hologramAutoHideTimer = 0.0;
  bool _autoPopHolograms = true;
  int _lastHologramTriggeredSectorIdx = 0;
  String? _hudCallout;
  double _hudCalloutTimer = 0.0;

  @override
  void initState() {
    super.initState();
    _bridge3d = createRacing3dBridge();
    _trafficCars = CircuitBuilder.buildInitialTraffic();
    _obstacles = CircuitBuilder.buildInitialObstacles();
    _orbs = CircuitBuilder.buildInitialOrbs();
    _paddockPortals = PaddockWorldBuilder.buildLinkPortals();
    _paddockBoosts = PaddockWorldBuilder.buildBoostStrips(const []);
    _paddockOrbs = PaddockWorldBuilder.buildOrbs();
    _paddockRivals = [
      PaddockRivalState(
        angle: 0.2,
        speedRad: 0.26,
        radiusX: 950.0,
        radiusY: 570.0,
        colorVariant: 0,
        label: 'DART',
        kind: OpponentVehicleKind.coupe,
      ),
      PaddockRivalState(
        angle: 1.8,
        speedRad: 0.21,
        radiusX: 845.0,
        radiusY: 495.0,
        colorVariant: 1,
        label: 'TITAN',
        kind: OpponentVehicleKind.truck,
      ),
      PaddockRivalState(
        angle: 3.5,
        speedRad: 0.29,
        radiusX: 950.0,
        radiusY: 570.0,
        colorVariant: 2,
        label: 'BLOC',
        kind: OpponentVehicleKind.interceptor,
      ),
      PaddockRivalState(
        angle: 5.0,
        speedRad: 0.24,
        radiusX: 845.0,
        radiusY: 495.0,
        colorVariant: 3,
        label: 'IMPEL',
        kind: OpponentVehicleKind.coupe,
      ),
    ];

    _segments = CircuitBuilder.buildCircuit(
      skills: const [],
      experiences: const [],
      projects: const [],
      contacts: const [],
    );

    if (_bridge3d.isSupported) {
      _bridge3d.mountView();
      _pushTrackDataTo3d();
    }

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
    _bridge3d.dispose();
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
    _pushTrackDataTo3d();
  }

  void _pushTrackDataTo3d() {
    if (!_bridge3d.isSupported || _segments.isEmpty) return;
    final payload = jsonEncode({
      'segments': _segments
          .map(
            (s) => {
              'index': s.index,
              'curve': s.curve,
              'y': s.y,
              'isCheckered': s.isCheckered,
              'gantryCode': s.gantryCode,
              'gantryTitle': s.gantryTitle,
              'gantryDest': s.gantryDestinationLabel,
              'boostLane': s.boostLane,
              'hasLightPylon': s.hasLightPylon,
              'isTunnelZone': s.isTunnelZone,
              'leftBillboard': s.leftBillboard == null
                  ? null
                  : {
                      'tag': s.leftBillboard!.tag,
                      'title': s.leftBillboard!.title,
                      'sub': s.leftBillboard!.subtitle,
                      'sec': s.leftBillboard!.useSecondaryAccent,
                      'photo': s.leftBillboard!.showDriverPhoto,
                    },
              'rightBillboard': s.rightBillboard == null
                  ? null
                  : {
                      'tag': s.rightBillboard!.tag,
                      'title': s.rightBillboard!.title,
                      'sub': s.rightBillboard!.subtitle,
                      'sec': s.rightBillboard!.useSecondaryAccent,
                      'photo': s.rightBillboard!.showDriverPhoto,
                    },
            },
          )
          .toList(),
      'sectors': RaceSectorMeta.sectors
          .map(
            (sec) => {
              'code': sec.code,
              'dest': sec.destinationLabel,
              'px': sec.paddockCenter.dx,
              'py': sec.paddockCenter.dy,
            },
          )
          .toList(),
      'portals': _paddockPortals
          .map(
            (p) => {
              'shortCode': p.link.shortCode,
              'label': p.link.label,
              'color': p.link.color.toARGB32(),
              'px': p.center.dx,
              'py': p.center.dy,
              'r': p.radius,
            },
          )
          .toList(),
    });
    _bridge3d.setTrackData(payload);
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

  void _selectVehicle(VehicleType nextVehicle) {
    setState(() {
      _selectedVehicle = nextVehicle;
      _showCallout(
        '🏎️ CHASSIS DEPLOYED: ${nextVehicle.name} (${nextVehicle.shortLabel})',
      );
    });
    GamificationController.instance.addXp(
      15,
      reason: 'Selected Vehicle: ${nextVehicle.name}',
      uniqueKey: 'vehicle_${nextVehicle.name}',
    );
    _focusNode.requestFocus();
  }

  void _cycleVehicle() {
    final nextIdx =
        (_selectedVehicle.index + 1) % VehicleType.values.length;
    _selectVehicle(VehicleType.values[nextIdx]);
  }

  Future<void> _openVehicleGarage() async {
    if (_isModalOpen || !mounted) return;
    final themeState = context.read<ThemeBloc>().state;
    final palette = RacingThemePalette.resolve(themeState, _visualTheme);
    final prevVehicle = _selectedVehicle;
    var deployed = false;
    setState(() {
      _isModalOpen = true;
      _isGarageOpen = true;
      _touchLeft = false;
      _touchRight = false;
      _touchGas = false;
      _touchBrake = false;
      _touchNitro = false;
    });

    await showVehicleSelectorModal(
      context: context,
      currentVehicle: _selectedVehicle,
      palette: palette,
      onPreviewVehicle: (v) {
        if (mounted) {
          setState(() => _selectedVehicle = v);
        }
      },
      onSelectVehicle: (v) {
        deployed = true;
        _selectVehicle(v);
      },
    );

    if (mounted) {
      setState(() {
        _isModalOpen = false;
        _isGarageOpen = false;
        if (!deployed) {
          _selectedVehicle = prevVehicle;
        }
      });
      _focusNode.requestFocus();
    }
  }

  void _cycleCameraPreset() {
    final nextIdx =
        (_cameraPreset.index + 1) % RacingCameraPreset.values.length;
    setState(() {
      _cameraPreset = RacingCameraPreset.values[nextIdx];
      _showCallout('🎥 3D CAMERA: ${_cameraPreset.title.toUpperCase()}');
    });
  }

  void _openDestinationHologram(
    RaceSectorMeta sector, {
    required bool pinned,
  }) {
    if (!_autoPopHolograms && !pinned) return;
    setState(() {
      _activeHologramSector = sector;
      _hologramPinned = pinned;
      _hologramAutoHideTimer = pinned ? 0.0 : _hologramPreviewDuration;
      _lastHologramTriggeredSectorIdx = sector.index;
      _arrivalEventSeq++;
    });
    GamificationController.instance.completeQuest(sector.questId);
  }

  void _dismissHologram() {
    if (_activeHologramSector == null) return;
    setState(() {
      _activeHologramSector = null;
      _hologramPinned = false;
      _hologramAutoHideTimer = 0.0;
    });
    _focusNode.requestFocus();
  }

  void _toggleCurrentHologram() {
    if (_activeHologramSector != null) {
      _dismissHologram();
    } else {
      _openDestinationHologram(_activeSector, pinned: true);
    }
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
      if (key == LogicalKeyboardKey.escape && _activeHologramSector != null) {
        _dismissHologram();
        return KeyEventResult.handled;
      }
      if ((key == LogicalKeyboardKey.keyW ||
              key == LogicalKeyboardKey.arrowUp) &&
          _activeHologramSector != null) {
        _dismissHologram();
      }
      if (key == LogicalKeyboardKey.keyV) {
        _cycleVehicle();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyG) {
        _openVehicleGarage();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyQ) {
        _cycleCameraPreset();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyH) {
        _toggleCurrentHologram();
        return KeyEventResult.handled;
      }
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
    final worldPt = (_bridge3d.isSupported && canvasSize.width > 0 && canvasSize.height > 0)
        ? (_bridge3d.raycastPaddock(
              details.localPosition.dx / canvasSize.width,
              details.localPosition.dy / canvasSize.height,
            ) ??
            RacingPaddockPainter.screenToWorld(
              details.localPosition,
              canvasSize,
              _paddockCameraPos,
            ))
        : RacingPaddockPainter.screenToWorld(
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

  void _spawnCircuitSparks({
    required double laneX,
    required double yOffset,
    required double pushDir,
    int count = 14,
  }) {
    for (int i = 0; i < count; i++) {
      final spreadX = (pushDir * (0.4 + _rng.nextDouble() * 1.4)) +
          (_rng.nextDouble() - 0.5) * 0.9;
      final spreadY = -60.0 - _rng.nextDouble() * 160.0;
      _sparks.add(
        ImpactSpark(
          x: laneX,
          y: yOffset,
          vx: spreadX,
          vy: spreadY,
          life: 0.35 + _rng.nextDouble() * 0.25,
          maxLife: 0.60,
          size: 2.2 + _rng.nextDouble() * 2.8,
          color: i.isEven
              ? const Color(0xFFFBBF24)
              : const Color(0xFFFF3B5C),
        ),
      );
    }
    if (_sparks.length > 90) {
      _sparks.removeRange(0, _sparks.length - 90);
    }
  }

  void _spawnPaddockSparks({
    required Offset worldPoint,
    required Offset normal,
    int count = 14,
  }) {
    for (int i = 0; i < count; i++) {
      final angle = math.atan2(normal.dy, normal.dx) +
          (_rng.nextDouble() - 0.5) * 1.8;
      final speed = 110.0 + _rng.nextDouble() * 220.0;
      _sparks.add(
        ImpactSpark(
          x: worldPoint.dx,
          y: worldPoint.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          life: 0.35 + _rng.nextDouble() * 0.25,
          maxLife: 0.60,
          size: 2.5 + _rng.nextDouble() * 2.5,
          color: i.isEven
              ? const Color(0xFFFBBF24)
              : const Color(0xFFFF3B5C),
        ),
      );
    }
    if (_sparks.length > 90) {
      _sparks.removeRange(0, _sparks.length - 90);
    }
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
    if (_cameraShakeTimer > 0) {
      _cameraShakeTimer = math.max(0.0, _cameraShakeTimer - dt);
    }
    if (_hitVignetteAlpha > 0) {
      _hitVignetteAlpha = math.max(0.0, _hitVignetteAlpha - dt * 1.25);
    }
    if (_paddockMonumentHitCooldown > 0) {
      _paddockMonumentHitCooldown =
          math.max(0.0, _paddockMonumentHitCooldown - dt);
    }
    if (_hullIntegrity < 1.0) {
      _hullIntegrity = (_hullIntegrity + dt * 0.015).clamp(0.0, 1.0);
    }
    if (_activeHologramSector != null && !_hologramPinned) {
      _hologramAutoHideTimer = math.max(0.0, _hologramAutoHideTimer - dt);
      if (_hologramAutoHideTimer == 0.0) {
        _activeHologramSector = null;
      }
    }
    for (int i = _sparks.length - 1; i >= 0; i--) {
      final sp = _sparks[i];
      sp.x += sp.vx * dt;
      sp.y += sp.vy * dt;
      sp.life -= dt;
      if (sp.life <= 0) {
        _sparks.removeAt(i);
      }
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

    _sync3dScene(
      isBraking: !_isModalOpen && brake,
      wantNitro: !_isModalOpen && wantNitro,
    );

    setState(() {});
  }

  void _sync3dScene({
    required bool isBraking,
    required bool wantNitro,
  }) {
    if (!_bridge3d.isSupported || !mounted) return;
    final themeState = context.read<ThemeBloc>().state;
    final palette = RacingThemePalette.resolve(themeState, _visualTheme);
    final nitroActive =
        ((wantNitro && _nitroCharge > 0.04) ||
                _warpTargetSector != null ||
                _paddockGpsTarget != null) &&
            !_isModalOpen;
    final shakeMag = _cameraShakeIntensity *
        (_cameraShakeTimer / 0.28).clamp(0.0, 1.0) *
        11.0;
    final shakeX =
        _cameraShakeTimer > 0 ? math.sin(_timeSeconds * 75) * shakeMag : 0.0;
    final shakeY = _cameraShakeTimer > 0
        ? math.cos(_timeSeconds * 92) * shakeMag * 0.7
        : 0.0;

    final payload = jsonEncode({
      'gameMode': _gameMode.index,
      'visualTheme': _visualTheme.index,
      'themeId': _visualTheme.name,
      'isDark': palette.isDark,
      'vehicleType': _selectedVehicle.index,
      'cameraPreset': _cameraPreset.index,
      'isGarageOpen': _isGarageOpen,
      'playerX': _playerX,
      'playerZ': _playerZ,
      'speedKmh': _speedKmh,
      'steerVisual': _steerVisual,
      'nitroActive': nitroActive,
      'isBraking': isBraking,
      'skyParallax': _skyParallax,
      'timeSeconds': _timeSeconds,
      'collisionFlash': _collisionFlashTimer > 0,
      'accentHex': palette.accent.toARGB32(),
      'secondaryHex': palette.secondary.toARGB32(),
      'skyTopHex': palette.skyTop.toARGB32(),
      'groundNearHex': palette.groundNear.toARGB32(),
      'asphaltAHex': palette.asphaltA.toARGB32(),
      'asphaltBHex': palette.asphaltB.toARGB32(),
      'kerbAHex': palette.kerbA.toARGB32(),
      'kerbBHex': palette.kerbB.toARGB32(),
      'carBodyHex': palette.carBody.toARGB32(),
      'trafficCars': _trafficCars
          .map(
            (c) => {
              'z': c.z,
              'lane': c.effectiveLane,
              'kind': c.kind.index,
              'recoil': c.lateralRecoil,
              'hit': c.hitFlashTimer > 0,
            },
          )
          .toList(),
      'obstacles': _obstacles
          .map(
            (o) => {
              'z': o.z,
              'lane': o.lane,
              'hit': o.hitFlashTimer > 0,
            },
          )
          .toList(),
      'orbs': _orbs
          .map(
            (o) => {
              'z': o.z,
              'lane': o.lane,
              'collected': o.collected,
            },
          )
          .toList(),
      'paddockX': _paddockPos.dx,
      'paddockY': _paddockPos.dy,
      'paddockHeading': _paddockHeading,
      'gpsX': _paddockGpsTarget?.dx,
      'gpsY': _paddockGpsTarget?.dy,
      'paddockRivals': _paddockRivals
          .map(
            (r) => {
              'x': r.position.dx,
              'y': r.position.dy,
              'heading': r.heading,
              'kind': r.kind.index,
              'hit': r.hitFlashTimer > 0,
            },
          )
          .toList(),
      'collisionEventSeq': _collisionEventSeq,
      'impactLaneX': _lastImpactLaneX,
      'impactPushDir': _lastImpactPushDir,
      'impactWorldX': _lastImpactWorldPoint?.dx,
      'impactWorldY': _lastImpactWorldPoint?.dy,
      'arrivalEventSeq': _arrivalEventSeq,
      'shakeX': shakeX,
      'shakeY': shakeY,
    });
    _bridge3d.syncState(payload);
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

    // Advance roaming paddock rivals & decay hit states
    for (final rival in _paddockRivals) {
      rival.angle = (rival.angle + rival.speedRad * dt) % (2 * math.pi);
      if (rival.hitCooldown > 0) {
        rival.hitCooldown = math.max(0.0, rival.hitCooldown - dt);
      }
      if (rival.hitFlashTimer > 0) {
        rival.hitFlashTimer = math.max(0.0, rival.hitFlashTimer - dt);
      }
      rival.staggerOffset = rival.staggerOffset * math.exp(-5.0 * dt);
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
          _openDestinationHologram(arrived, pinned: true);
          _showCallout(
            '📍 ARRIVED: ${arrived.destinationLabel} — HOLOGRAM PROJECTED',
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
      // Smoothly tour the oval Grand Prix Paddock Loop with rival avoidance
      final prevAngle = _paddockCruiseAngle;
      _paddockCruiseAngle += dt * 0.34;
      if (_paddockCruiseAngle >= math.pi && prevAngle < math.pi) {
        if (_bestLapSeconds == null || _lapTimeSeconds < _bestLapSeconds!) {
          _bestLapSeconds = _lapTimeSeconds;
        }
        _lapCount++;
        _lapTimeSeconds = 0.0;
      }
      var targetPt = Offset(
        math.cos(_paddockCruiseAngle) * 900.0,
        math.sin(_paddockCruiseAngle) * 535.0,
      );
      for (final r in _paddockRivals) {
        final dRival = (r.position - _paddockPos).distance;
        if (dRival < 140.0) {
          final away = _paddockPos - r.position;
          if (away.distance > 1.0) {
            targetPt += (away / away.distance) * 140.0;
          }
        }
      }
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

    final topSpeed = nitroActive
        ? _selectedVehicle.nitroMaxSpeed
        : _selectedVehicle.baseMaxSpeed;
    if (!_isModalOpen) {
      if (nitroActive) {
        _paddockSignedSpeed += (_selectedVehicle.acceleration * 1.65) * dt;
      } else if (effectiveGas) {
        _paddockSignedSpeed += _selectedVehicle.acceleration * dt;
      } else if (effectiveBrake) {
        if (_paddockSignedSpeed > 8.0) {
          _paddockSignedSpeed -= _selectedVehicle.braking * dt;
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
      final turnScale = _selectedVehicle.handling / 1.90;
      final turnRate =
          2.45 * turnScale * (0.35 + 0.65 * speedNorm.clamp(0.0, 1.0));
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

    // 2D SAT OBB Collisions with Roaming Rivals & Central Monument
    if (!_isModalOpen) {
      var playerObb = Obb2D(
        center: _paddockPos,
        headingRad: _paddockHeading,
        halfWidth: _selectedVehicle.topDownWidth * 0.48,
        halfLength: _selectedVehicle.topDownLength * 0.48,
      );

      for (final r in _paddockRivals) {
        final rivalObb = Obb2D(
          center: r.position,
          headingRad: r.heading,
          halfWidth: r.kind.topDownWidth * 0.48,
          halfLength: r.kind.topDownLength * 0.48,
        );
        final hit = ObbCollisionDetector.testObbVsObb(playerObb, rivalObb);
        if (hit != null) {
          _paddockPos += hit.mtv;
          r.staggerOffset -= hit.normal * 16.0;
          playerObb = Obb2D(
            center: _paddockPos,
            headingRad: _paddockHeading,
            halfWidth: _selectedVehicle.topDownWidth * 0.48,
            halfLength: _selectedVehicle.topDownLength * 0.48,
          );
          if (r.hitCooldown <= 0) {
            r.hitCooldown = 0.55;
            r.hitFlashTimer = 0.35;
            _collisionFlashTimer = 0.35;
            _collisionCount++;
            _collisionEventSeq++;
            _lastImpactWorldPoint = hit.contactPoint;
            final armor = _selectedVehicle.armorFactor;
            _paddockSignedSpeed = _paddockSignedSpeed * (0.45 + armor * 0.35);
            _hullIntegrity =
                (_hullIntegrity - (0.10 * (1.1 - armor * 0.6))).clamp(0.10, 1.0);
            _cameraShakeTimer = 0.25;
            _cameraShakeIntensity = 0.72;
            _hitVignetteAlpha = 0.36;
            _spawnPaddockSparks(
              worldPoint: hit.contactPoint,
              normal: hit.normal,
            );
            _showCallout('💥 COLLISION WITH ${r.label}!');
          }
        }
      }

      final monumentHit = ObbCollisionDetector.testObbVsCircle(
        playerObb,
        Offset.zero,
        168.0,
      );
      if (monumentHit != null) {
        _paddockPos += monumentHit.mtv;
        if (_paddockMonumentHitCooldown <= 0) {
          _paddockMonumentHitCooldown = 0.50;
          _collisionFlashTimer = 0.30;
          _collisionEventSeq++;
          _lastImpactWorldPoint = monumentHit.contactPoint;
          _paddockSignedSpeed = -_paddockSignedSpeed * 0.35;
          _cameraShakeTimer = 0.22;
          _cameraShakeIntensity = 0.60;
          _hitVignetteAlpha = 0.30;
          _spawnPaddockSparks(
            worldPoint: monumentHit.contactPoint,
            normal: monumentHit.normal,
          );
          _showCallout('⚠️ DRIVER MONUMENT BARRIER');
        }
      }
    }

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
      if (insideZone.index != _lastHologramTriggeredSectorIdx) {
        _openDestinationHologram(insideZone, pinned: false);
      } else {
        GamificationController.instance.completeQuest(insideZone.questId);
      }
      _showCallout(
        '🏁 ENTERED ${insideZone.destinationLabel} — HOLOGRAM PROJECTED',
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
          _paddockSignedSpeed = math.min(
            _selectedVehicle.nitroMaxSpeed,
            _paddockSignedSpeed + 75.0,
          );
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
        _activeSector = arrived;
        context.read<ScreenBloc>().add(UpdateScreen(screen: arrived.screen));
        _openDestinationHologram(arrived, pinned: true);
        _showCallout('📍 ARRIVED: ${arrived.destinationLabel} — HOLOGRAM ACTIVE');
      } else {
        effectiveGas = true;
        effectiveBrake = false;
        effectiveNitro = distForward > 2200.0;
        _nitroCharge = math.max(_nitroCharge, 0.35);
        effectiveSteer = (-_playerX * 2.4).clamp(-1.0, 1.0);
      }
    } else if (_autoPilot && !effectiveBrake) {
      effectiveGas = _speedKmh < _cruiseTargetSpeed;
      final trackLen = CircuitBuilder.trackLength;
      final normZ = ((_playerZ % trackLen) + trackLen) % trackLen;
      final desiredLane = CircuitCollisionDetector.chooseBestAutopilotLane(
        normZ: normZ,
        currentPlayerX: _playerX,
        trackLen: trackLen,
        vehicle: _selectedVehicle,
        trafficCars: _trafficCars,
        obstacles: _obstacles,
      );
      effectiveSteer = ((desiredLane - _playerX) * 2.3).clamp(-0.90, 0.90);
    }

    final nitroActive =
        (effectiveNitro && _nitroCharge > 0.04) || _warpTargetSector != null;
    if (nitroActive && _warpTargetSector == null) {
      _nitroCharge = (_nitroCharge - dt * 0.26).clamp(0.0, 1.0);
    } else {
      _nitroCharge = (_nitroCharge + dt * 0.055).clamp(0.0, 1.0);
    }

    final topSpeed = nitroActive
        ? _selectedVehicle.nitroMaxSpeed
        : _selectedVehicle.baseMaxSpeed;
    if (nitroActive) {
      _speedKmh += (_selectedVehicle.acceleration * 1.65) * dt;
    } else if (effectiveGas) {
      _speedKmh += _selectedVehicle.acceleration * dt;
    } else if (effectiveBrake) {
      _speedKmh -= _selectedVehicle.braking * dt;
    } else {
      _speedKmh -= 48.0 * dt;
    }

    if (_playerX.abs() > 1.06 &&
        _warpTargetSector == null &&
        _selectedVehicle.offRoadDragFactor > 0.0) {
      if (_speedKmh > 135.0) {
        _speedKmh -= (160.0 * _selectedVehicle.offRoadDragFactor) * dt;
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

    // Capture pre-step player coordinates for continuous swept collision checks
    final prevNormZ = ((_playerZ % trackLen) + trackLen) % trackLen;
    final prevPlayerX = _playerX;

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

    final speedFactor =
        (_speedKmh / _selectedVehicle.baseMaxSpeed).clamp(0.0, 1.35);
    final steerAuthority = _speedKmh > 4 ? _selectedVehicle.handling : 0.0;
    _playerX += steerInput * steerAuthority * dt;
    _playerX += _lateralBounceVel * dt;
    _lateralBounceVel *= math.exp(-7.5 * dt);

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
        if (detectedSector.index != _lastHologramTriggeredSectorIdx) {
          _openDestinationHologram(detectedSector, pinned: false);
        } else {
          GamificationController.instance.completeQuest(detectedSector.questId);
        }
        _showCallout(
          '🏁 ${detectedSector.destinationLabel} // ${detectedSector.title}',
        );
      }
    }

    if (currentSeg.boostLane != null && _lastBoostSegIndex != segIndex) {
      if ((_playerX - currentSeg.boostLane!).abs() < 0.34) {
        _lastBoostSegIndex = segIndex;
        _nitroCharge = (_nitroCharge + 0.30).clamp(0.0, 1.0);
        _speedKmh = math.min(_selectedVehicle.nitroMaxSpeed, _speedKmh + 65.0);
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
      if (dz < 220.0 &&
          (_playerX - orb.lane).abs() < _selectedVehicle.roadHalfWidth + 0.14) {
        orb.collected = true;
        _nitroCharge = (_nitroCharge + 0.20).clamp(0.0, 1.0);
        GamificationController.instance.addXp(
          10,
          reason: 'Collected Track Telemetry Crystal (${orb.label})',
        );
      }
    }

    // Continuous Swept Collision Detection & Near-Misses against Traffic Opponents
    for (final car in _trafficCars) {
      if (car.hitCooldown > 0) {
        car.hitCooldown = math.max(0.0, car.hitCooldown - dt);
      }
      if (car.hitFlashTimer > 0) {
        car.hitFlashTimer = math.max(0.0, car.hitFlashTimer - dt);
      }
      car.lateralRecoil *= math.exp(-5.0 * dt);

      final prevOppZ = car.z;
      final prevOppLane = car.effectiveLane;
      car.z = (car.z + car.speed * 18.0 * dt) % trackLen;
      final currOppLane = car.effectiveLane;

      final prevRelZ =
          CircuitCollisionDetector.signedTrackDelta(prevOppZ, prevNormZ, trackLen);
      final currRelZ =
          CircuitCollisionDetector.signedTrackDelta(car.z, normZ, trackLen);

      final (zMin, zMax) = CircuitCollisionDetector.computeLongitudinalBand(
        mode: _gameMode,
        vehicle: _selectedVehicle,
        oppZHalfLength: car.kind.zHalfLength,
        oppTopDownLength: car.kind.topDownLength,
      );

      if (!_isModalOpen &&
          _warpTargetSector == null &&
          car.hitCooldown <= 0) {
        final hit = CircuitCollisionDetector.detectSweptCircuitHit(
          prevNormZ: prevNormZ,
          currNormZ: normZ,
          prevPlayerX: prevPlayerX,
          currPlayerX: _playerX,
          prevOppZ: prevOppZ,
          currOppZ: car.z,
          prevOppLane: prevOppLane,
          currOppLane: currOppLane,
          trackLen: trackLen,
          playerHalfWidth: _selectedVehicle.roadHalfWidth,
          oppHalfWidth: car.kind.roadHalfWidth,
          zBandMin: zMin,
          zBandMax: zMax,
        );

        if (hit != null) {
          final res = CircuitCollisionDetector.resolveCircuitHit(
            hit: hit,
            vehicle: _selectedVehicle,
            playerSpeedKmh: _speedKmh,
            playerX: _playerX,
            currNormZ: normZ,
            oppZ: car.z,
            oppLane: car.lane,
            oppSpeedKmh: car.speed,
            oppMass: car.kind.mass,
            oppHalfWidth: car.kind.roadHalfWidth,
            zBandMin: zMin,
            zBandMax: zMax,
            trackLen: trackLen,
            maxLateral: maxLateral,
          );

          _speedKmh = res.newPlayerSpeedKmh;
          _playerX = res.newPlayerX;
          _lateralBounceVel = res.lateralBounceVelocity;
          car.z = res.newOppZ;
          car.speed = res.newOppSpeedKmh;
          car.lateralRecoil = res.oppLateralRecoil;
          car.hitCooldown = 0.45;
          car.hitFlashTimer = 0.35;
          _collisionFlashTimer = 0.35;
          _collisionCount++;
          _collisionEventSeq++;
          _lastImpactLaneX = hit.impactLaneX;
          _lastImpactPushDir = hit.pushDirection;
          _hullIntegrity =
              (_hullIntegrity - res.hullDamage / 100.0).clamp(0.10, 1.0);
          _cameraShakeTimer = 0.28;
          _cameraShakeIntensity = res.shakeIntensity;
          _hitVignetteAlpha = 0.40;
          _spawnCircuitSparks(
            laneX: hit.impactLaneX -
                hit.pushDirection * _selectedVehicle.roadHalfWidth * 0.6,
            yOffset: hit.kind == CollisionKind.rearEnd ? -34.0 : -10.0,
            pushDir: hit.pushDirection,
          );
          _showCallout(
            hit.kind == CollisionKind.sideswipe
                ? '⚡ SIDESWIPE WITH ${car.label}!'
                : '💥 IMPACT WITH ${car.label}! STEER CLEAR',
          );
          continue;
        }

        if (!car.nearMissAwarded &&
            CircuitCollisionDetector.isNearMiss(
              prevRelZ: prevRelZ,
              currRelZ: currRelZ,
              trackLen: trackLen,
              playerX: _playerX,
              oppLane: currOppLane,
              playerHalfWidth: _selectedVehicle.roadHalfWidth,
              oppHalfWidth: car.kind.roadHalfWidth,
              playerSpeedKmh: _speedKmh,
            )) {
          car.nearMissAwarded = true;
          _nearMissCount++;
          _nitroCharge = (_nitroCharge + 0.14).clamp(0.0, 1.0);
          _showCallout('🔥 NEAR MISS ${car.label}! +14% NITRO');
          if (_nearMissCount % 3 == 0) {
            GamificationController.instance.addXp(
              10,
              reason: '$_nearMissCount Razor-Close Near Misses!',
            );
          }
        }
      }

      if (prevRelZ > 80.0 &&
          currRelZ <= 80.0 &&
          !car.passedRecently &&
          car.hitCooldown <= 0) {
        car.passedRecently = true;
        _overtakes++;
        _nitroCharge = (_nitroCharge + 0.08).clamp(0.0, 1.0);
        if (_overtakes % 4 == 0) {
          GamificationController.instance.addXp(
            15,
            reason: '$_overtakes Clean Overtakes on Circuit!',
          );
        }
      } else if (currRelZ.abs() > 2500.0) {
        car.passedRecently = false;
        car.nearMissAwarded = false;
      }
    }

    // Continuous Swept Collision Detection against Static Track Obstacles
    for (final obs in _obstacles) {
      if (obs.hitCooldown > 0) {
        obs.hitCooldown = math.max(0.0, obs.hitCooldown - dt);
      }
      if (obs.hitFlashTimer > 0) {
        obs.hitFlashTimer = math.max(0.0, obs.hitFlashTimer - dt);
      }

      if (_isModalOpen || _warpTargetSector != null || obs.hitCooldown > 0) {
        continue;
      }

      final (zMin, zMax) = CircuitCollisionDetector.computeLongitudinalBand(
        mode: _gameMode,
        vehicle: _selectedVehicle,
        oppZHalfLength: obs.zHalfLength,
        oppTopDownLength: 20.0,
      );

      final hit = CircuitCollisionDetector.detectSweptCircuitHit(
        prevNormZ: prevNormZ,
        currNormZ: normZ,
        prevPlayerX: prevPlayerX,
        currPlayerX: _playerX,
        prevOppZ: obs.z,
        currOppZ: obs.z,
        prevOppLane: obs.lane,
        currOppLane: obs.lane,
        trackLen: trackLen,
        playerHalfWidth: _selectedVehicle.roadHalfWidth,
        oppHalfWidth: obs.roadHalfWidth,
        zBandMin: zMin,
        zBandMax: zMax,
        isStaticBarrier: true,
      );

      if (hit != null) {
        final res = CircuitCollisionDetector.resolveCircuitHit(
          hit: hit,
          vehicle: _selectedVehicle,
          playerSpeedKmh: _speedKmh,
          playerX: _playerX,
          currNormZ: normZ,
          oppZ: obs.z,
          oppLane: obs.lane,
          oppSpeedKmh: 0.0,
          oppMass: 2.5,
          oppHalfWidth: obs.roadHalfWidth,
          zBandMin: zMin,
          zBandMax: zMax,
          trackLen: trackLen,
          maxLateral: maxLateral,
          isStaticBarrier: true,
        );

        _speedKmh = res.newPlayerSpeedKmh;
        _playerX = res.newPlayerX;
        _lateralBounceVel = res.lateralBounceVelocity;
        obs.hitCooldown = 0.55;
        obs.hitFlashTimer = 0.38;
        _collisionFlashTimer = 0.35;
        _collisionCount++;
        _collisionEventSeq++;
        _lastImpactLaneX = hit.impactLaneX;
        _lastImpactPushDir = hit.pushDirection;
        _hullIntegrity =
            (_hullIntegrity - res.hullDamage / 100.0).clamp(0.10, 1.0);
        _cameraShakeTimer = 0.28;
        _cameraShakeIntensity = res.shakeIntensity;
        _hitVignetteAlpha = 0.42;
        _spawnCircuitSparks(
          laneX: hit.impactLaneX,
          yOffset: -26.0,
          pushDir: hit.pushDirection,
          count: 16,
        );
        _showCallout('⚠️ STRUCK ${obs.label}!');
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
                    final shakeMag = _cameraShakeIntensity *
                        (_cameraShakeTimer / 0.28).clamp(0.0, 1.0) *
                        11.0;
                    final cameraShake = _cameraShakeTimer > 0
                        ? Offset(
                            math.sin(_timeSeconds * 75) * shakeMag,
                            math.cos(_timeSeconds * 92) * shakeMag * 0.7,
                          )
                        : Offset.zero;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. ACTIVE RACING GAMEPLAY CANVAS (TRUE WEBGL 3D OR FALLBACK)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) => _handlePaddockCanvasTap(
                            details,
                            Size(maxW, maxH),
                          ),
                          child: _bridge3d.isSupported
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    IgnorePointer(child: _bridge3d.buildView()),
                                    if (_hitVignetteAlpha > 0.01)
                                      IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: RadialGradient(
                                              radius: 1.05,
                                              colors: [
                                                Colors.transparent,
                                                const Color(0xFFFF1E42)
                                                    .withValues(
                                                  alpha: _hitVignetteAlpha
                                                      .clamp(0.0, 0.45),
                                                ),
                                              ],
                                              stops: const [0.55, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : RepaintBoundary(
                                  child: _buildActiveModeCanvas(
                                    themeState: themeState,
                                    palette: palette,
                                    nitroActive: nitroActive,
                                    isAccelerating: isAccelerating,
                                    isBraking: isBraking,
                                    cameraShake: cameraShake,
                                  ),
                                ),
                        ),

                        // 2. CHASE-CAM PLAYER VEHICLE OVERLAY (2D FALLBACK ONLY)
                        if (!_bridge3d.isSupported &&
                            _gameMode == RacingGameMode.horizon3d)
                          Positioned(
                            left: (maxW - carWidth) / 2 + cameraShake.dx * 0.35,
                            bottom: (isCompact ? 132 : 102) - cameraShake.dy * 0.35,
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
                                  vehicleType: _selectedVehicle,
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

                        // 4.5 DESTINATION 3D HOLOGRAM PROJECTION OVERLAY
                        if (_activeHologramSector != null && !_isModalOpen)
                          Positioned(
                            top: topHudOffset + 8,
                            left: 0,
                            right: 0,
                            bottom: isCompact ? 138 : 118,
                            child: DestinationHologramOverlay(
                              sector: _activeHologramSector!,
                              palette: palette,
                              timeSeconds: _timeSeconds,
                              isPinned: _hologramPinned,
                              autoHideRemainingRatio: _hologramPinned
                                  ? 1.0
                                  : (_hologramAutoHideTimer /
                                          _hologramPreviewDuration)
                                      .clamp(0.0, 1.0),
                              onPin: () {
                                if (!_hologramPinned) {
                                  setState(() => _hologramPinned = true);
                                }
                              },
                              onDismiss: _dismissHologram,
                              onOpenFullDossier: () {
                                final screen = _activeHologramSector!.screen;
                                _dismissHologram();
                                _openPitStop(screen);
                              },
                              onPrevSector: () {
                                final curIdx = _activeHologramSector!.index;
                                final prev = RaceSectorMeta.sectors[
                                    (curIdx - 1 + RaceSectorMeta.sectors.length) %
                                        RaceSectorMeta.sectors.length];
                                _openDestinationHologram(prev, pinned: true);
                              },
                              onNextSector: () {
                                final curIdx = _activeHologramSector!.index;
                                final next = RaceSectorMeta.sectors[
                                    (curIdx + 1) %
                                        RaceSectorMeta.sectors.length];
                                _openDestinationHologram(next, pinned: true);
                              },
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
                            maxSpeedKmh: _selectedVehicle.nitroMaxSpeed,
                            nitroCharge: _nitroCharge,
                            nitroActive: nitroActive,
                            autoPilot: _autoPilot,
                            lapCount: _lapCount,
                            lapTimeSeconds: _lapTimeSeconds,
                            bestLapSeconds: _bestLapSeconds,
                            overtakes: _overtakes,
                            hullIntegrity: _hullIntegrity,
                            collisions: _collisionCount,
                            nearMisses: _nearMissCount,
                            autoPopHolograms: _autoPopHolograms,
                            showTouchPedals: _showTouchPedals,
                            onToggleAutoPilot: () {
                              setState(() {
                                _autoPilot = !_autoPilot;
                                _warpTargetSector = null;
                                _paddockGpsTarget = null;
                              });
                            },
                            onToggleAutoPopHolograms: () {
                              setState(() {
                                _autoPopHolograms = !_autoPopHolograms;
                                if (!_autoPopHolograms && !_hologramPinned) {
                                  _activeHologramSector = null;
                                }
                                _showCallout(
                                  _autoPopHolograms
                                      ? '✨ DESTINATION HOLOGRAMS: AUTO-POP ON'
                                      : '✨ DESTINATION HOLOGRAMS: MANUAL [H]',
                                );
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

                        // 7. TOP TELEMETRY BAR (3 MODES + 3 THEMES + VEHICLE + 6 SECTORS)
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
                              selectedVehicle: _selectedVehicle,
                              cameraPreset: _cameraPreset,
                              palette: palette,
                              lapProgress: lapProgress,
                              isWarping: _warpTargetSector != null ||
                                  _paddockGpsTarget != null,
                              onSelectSector: _engageSectorSelection,
                              onSelectGameMode: _switchGameMode,
                              onSelectVisualTheme: _switchVisualTheme,
                              onOpenGarage: _openVehicleGarage,
                              onCycleCamera: _cycleCameraPreset,
                              onToggleHologram: _toggleCurrentHologram,
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
    required Offset cameraShake,
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
            maxSpeedKmh: _selectedVehicle.nitroMaxSpeed,
            nitroActive: nitroActive,
            skyParallax: _skyParallax,
            timeSeconds: _timeSeconds,
            themeState: themeState,
            palette: palette,
            driverPhoto: _driverPhoto,
            obstacles: _obstacles,
            sparks: _sparks,
            cameraShake: cameraShake,
            hitVignetteAlpha: _hitVignetteAlpha,
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
            vehicleType: _selectedVehicle,
            collisionFlash: _collisionFlashTimer > 0,
            sparks: _sparks,
            cameraShake: cameraShake,
            hitVignetteAlpha: _hitVignetteAlpha,
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
            vehicleType: _selectedVehicle,
            obstacles: _obstacles,
            sparks: _sparks,
            cameraShake: cameraShake,
            collisionFlash: _collisionFlashTimer > 0,
            hitVignetteAlpha: _hitVignetteAlpha,
          ),
        );
    }
  }
}
