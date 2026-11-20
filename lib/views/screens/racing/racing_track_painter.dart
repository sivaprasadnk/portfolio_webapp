import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';

class _ProjectedSlice {
  double x = 0;
  double y = 0;
  double w = 0;
  double scale = 0;
  double clipY = 0;
  bool drawRoad = false;
}

class RacingTrackPainter extends CustomPainter {
  final List<RoadSegment> segments;
  final List<TrafficCar> trafficCars;
  final List<DataCrystalOrb> orbs;
  final double playerZ;
  final double playerX; // -1.6 .. +1.6 (-1..+1 is road surface)
  final double speedKmh;
  final double maxSpeedKmh;
  final bool nitroActive;
  final double skyParallax;
  final double timeSeconds;
  final ThemeState themeState;
  final RacingThemePalette palette;
  final ui.Image? driverPhoto;
  final List<TrackObstacle> obstacles;
  final List<ImpactSpark> sparks;
  final Offset cameraShake;
  final double hitVignetteAlpha;

  RacingTrackPainter({
    required this.segments,
    required this.trafficCars,
    required this.orbs,
    required this.playerZ,
    required this.playerX,
    required this.speedKmh,
    required this.maxSpeedKmh,
    required this.nitroActive,
    required this.skyParallax,
    required this.timeSeconds,
    required this.themeState,
    required this.palette,
    this.driverPhoto,
    this.obstacles = const [],
    this.sparks = const [],
    this.cameraShake = Offset.zero,
    this.hitVignetteAlpha = 0.0,
  });

  static const int _drawDistance = 96;
  static const double _cameraHeight = 2400.0;
  static const double _cameraDepth = 0.10;
  static const double _curveWorldMultiplier = 13.5;
  static const double _hillWorldMultiplier = 3.8;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty || size.width <= 0 || size.height <= 0) return;

    final isDark = palette.isDark;
    final accent = palette.accent;
    final secondary = palette.secondary;
    final visualTheme = palette.visualTheme;

    final totalSegs = segments.length;
    final segLen = CircuitBuilder.segmentLength;
    final trackLen = CircuitBuilder.trackLength;
    final roadWidth = CircuitBuilder.roadWidth;

    final normalizedZ = ((playerZ % trackLen) + trackLen) % trackLen;
    final baseIndex = (normalizedZ ~/ segLen) % totalSegs;
    final basePercent = (normalizedZ % segLen) / segLen;

    final baseSeg = segments[baseIndex];
    final nextSeg = segments[(baseIndex + 1) % totalSegs];
    final playerElevation =
        (baseSeg.y + (nextSeg.y - baseSeg.y) * basePercent) *
            _hillWorldMultiplier;
    final slopeDelta = (nextSeg.y - baseSeg.y) * _hillWorldMultiplier;
    final horizonY =
        (size.height * 0.41) + (slopeDelta * 0.012).clamp(-26.0, 26.0);

    canvas.save();
    if (cameraShake != Offset.zero) {
      canvas.translate(cameraShake.dx, cameraShake.dy);
    }

    // 1. SKY, SUN/STADIUM & PARALLAX HORIZON
    _paintSkyAndHorizon(
      canvas,
      size,
      horizonY,
      accent,
      secondary,
      isDark,
      visualTheme,
    );

    // 2. BASE GROUND PLANE
    final groundTop = horizonY - 1;
    final groundRect = Rect.fromLTRB(0, groundTop, size.width, size.height);
    canvas.drawRect(
      groundRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.groundFar, palette.groundNear],
        ).createShader(groundRect),
    );

    // Perspective ground grid (prominent neon pink/cyan in Synthwave!)
    _paintGroundPerspectiveGrid(
      canvas,
      size,
      horizonY,
      visualTheme,
    );

    // 3. PROJECT 3D ROAD NODES FRONT-TO-BACK (WITH HILL CREST OCCLUSION)
    final slices = List<_ProjectedSlice>.generate(
      _drawDistance + 1,
      (_) => _ProjectedSlice(),
    );
    double worldCurveX = 0.0;
    double dx = -(baseSeg.curve * _curveWorldMultiplier * basePercent);
    final camWorldX = playerX * roadWidth;
    final halfW = size.width * 0.5;
    final halfH = size.height * 0.5;
    final baseOffsetZ = normalizedZ % segLen;

    for (int n = 0; n <= _drawDistance; n++) {
      final seg = segments[(baseIndex + n) % totalSegs];
      final relZ = math.max(95.0, (n * segLen) - baseOffsetZ + 200.0);
      final scale = _cameraDepth / relZ;
      final segWorldY = seg.y * _hillWorldMultiplier;
      final camY = _cameraHeight + playerElevation;

      final slice = slices[n];
      slice.scale = scale;
      slice.x = halfW + (scale * (worldCurveX - camWorldX) * halfW);
      slice.y = horizonY - (scale * (segWorldY - camY) * halfH);
      slice.w = scale * roadWidth * halfW;

      worldCurveX += dx;
      dx += seg.curve * _curveWorldMultiplier;
    }

    double maxY = size.height;
    for (int n = 0; n < _drawDistance; n++) {
      final near = slices[n];
      final far = slices[n + 1];
      near.clipY = maxY;
      if (far.y < maxY && near.y > far.y) {
        near.drawRoad = true;
        maxY = far.y;
      } else {
        near.drawRoad = false;
      }
    }

    final carsByOffset = <int, List<TrafficCar>>{};
    for (final car in trafficCars) {
      double dz = car.z - normalizedZ;
      if (dz < -segLen) dz += trackLen;
      if (dz >= 0 && dz < _drawDistance * segLen) {
        final offsetIdx = (dz ~/ segLen).clamp(0, _drawDistance - 1);
        (carsByOffset[offsetIdx] ??= []).add(car);
      }
    }

    final orbsByOffset = <int, List<DataCrystalOrb>>{};
    for (final orb in orbs) {
      if (orb.collected) continue;
      double dz = orb.z - normalizedZ;
      if (dz < -segLen) dz += trackLen;
      if (dz >= 0 && dz < _drawDistance * segLen) {
        final offsetIdx = (dz ~/ segLen).clamp(0, _drawDistance - 1);
        (orbsByOffset[offsetIdx] ??= []).add(orb);
      }
    }

    final obstaclesByOffset = <int, List<TrackObstacle>>{};
    for (final obs in obstacles) {
      double dz = obs.z - normalizedZ;
      if (dz < -segLen) dz += trackLen;
      if (dz >= 0 && dz < _drawDistance * segLen) {
        final offsetIdx = (dz ~/ segLen).clamp(0, _drawDistance - 1);
        (obstaclesByOffset[offsetIdx] ??= []).add(obs);
      }
    }

    // 4. PAINTER'S ALGORITHM: RENDER BACK-TO-FRONT (FAR -> NEAR)
    for (int n = _drawDistance - 1; n >= 0; n--) {
      final near = slices[n];
      final far = slices[n + 1];
      final segIndex = (baseIndex + n) % totalSegs;
      final seg = segments[segIndex];

      if (near.drawRoad) {
        final drawNearY = math.min(near.y, near.clipY);
        final drawFarY = far.y;
        if (drawNearY > drawFarY) {
          _paintRoadQuad(
            canvas: canvas,
            seg: seg,
            x1: near.x,
            y1: drawNearY,
            w1: near.w,
            x2: far.x,
            y2: drawFarY,
            w2: far.w,
            accent: accent,
            secondary: secondary,
            isDark: isDark,
          );
        }
      }

      if (far.y < near.clipY) {
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(0, 0, size.width, near.clipY));

        if (seg.isTunnelZone && seg.index % 4 == 0 && n < 70) {
          _paintNeonTunnelArch(
            canvas,
            far.x,
            far.y,
            far.w,
            accent,
            secondary,
            n,
          );
        } else if (seg.hasLightPylon && n < 72) {
          if (visualTheme == RacingVisualTheme.retroSynthwave) {
            _paintSynthwavePalms(
              canvas,
              far.x,
              far.y,
              far.w,
              accent,
              secondary,
            );
          } else {
            _paintRoadsideLightPylons(
              canvas,
              far.x,
              far.y,
              far.w,
              accent,
              secondary,
              seg.index.isEven,
            );
          }
        }

        if (seg.leftBillboard != null && n < 64 && n >= 1) {
          _paintBillboard3D(
            canvas: canvas,
            spec: seg.leftBillboard!,
            roadCenterX: far.x,
            groundY: far.y,
            roadHalfW: far.w,
            isLeft: true,
            distanceSteps: n,
            accent: accent,
            secondary: secondary,
            isDark: isDark,
          );
        }

        if (seg.rightBillboard != null && n < 64 && n >= 1) {
          _paintBillboard3D(
            canvas: canvas,
            spec: seg.rightBillboard!,
            roadCenterX: far.x,
            groundY: far.y,
            roadHalfW: far.w,
            isLeft: false,
            distanceSteps: n,
            accent: accent,
            secondary: secondary,
            isDark: isDark,
          );
        }

        if (seg.gantryTitle != null && n < 76 && n >= 1) {
          _paintCheckpointGantry(
            canvas: canvas,
            code: seg.gantryCode ?? 'CHECKPOINT',
            title: seg.gantryTitle!,
            subtitle: seg.gantrySubtitle ?? '',
            destinationLabel: seg.gantryDestinationLabel,
            roadCenterX: far.x,
            groundY: far.y,
            roadHalfW: far.w,
            distanceSteps: n,
            accent: accent,
            secondary: secondary,
            visualTheme: visualTheme,
          );
        }

        final sliceObstacles = obstaclesByOffset[n];
        if (sliceObstacles != null) {
          for (final obs in sliceObstacles) {
            double dz = obs.z - normalizedZ;
            if (dz < 0) dz += trackLen;
            final t = ((dz - n * segLen) / segLen).clamp(0.0, 1.0);
            final ox = near.x + (far.x - near.x) * t;
            final oy = near.y + (far.y - near.y) * t;
            final ow = near.w + (far.w - near.w) * t;
            _paintTrackObstacle3D(
              canvas: canvas,
              obstacle: obs,
              screenX: ox + obs.lane * ow,
              screenY: oy,
              roadHalfW: ow,
              distanceSteps: n,
            );
          }
        }

        final sliceOrbs = orbsByOffset[n];
        if (sliceOrbs != null) {
          for (final orb in sliceOrbs) {
            double dz = orb.z - normalizedZ;
            if (dz < 0) dz += trackLen;
            final t = ((dz - n * segLen) / segLen).clamp(0.0, 1.0);
            final ox = near.x + (far.x - near.x) * t;
            final oy = near.y + (far.y - near.y) * t;
            final ow = near.w + (far.w - near.w) * t;
            _paintDataOrb(
              canvas,
              ox + orb.lane * ow,
              oy,
              ow,
              orb.label,
              accent,
              secondary,
            );
          }
        }

        final sliceCars = carsByOffset[n];
        if (sliceCars != null) {
          for (final car in sliceCars) {
            double dz = car.z - normalizedZ;
            if (dz < 0) dz += trackLen;
            final t = ((dz - n * segLen) / segLen).clamp(0.0, 1.0);
            final cx = near.x + (far.x - near.x) * t;
            final cy = near.y + (far.y - near.y) * t;
            final cw = near.w + (far.w - near.w) * t;
            _paintRivalCar3D(
              canvas: canvas,
              car: car,
              screenX: cx + car.effectiveLane * cw,
              screenY: cy,
              roadHalfW: cw,
              distanceSteps: n,
            );
          }
        }

        canvas.restore();
      }
    }

    // 5. HIGH-SPEED WIND / NITRO WARP LINES
    if (speedKmh > 210 || nitroActive) {
      _paintSpeedWarpLines(canvas, size, horizonY, accent);
    }

    canvas.restore();

    // 6. COLLISION IMPACT SPARKS
    if (sparks.isNotEmpty) {
      final lanePx = (size.width * 0.18).clamp(80.0, 180.0);
      final originX = size.width * 0.5;
      final originY = size.height * 0.80;
      for (final sp in sparks) {
        final alpha = (sp.life / sp.maxLife).clamp(0.0, 1.0);
        final sx = originX + (sp.x - playerX) * lanePx;
        final sy = originY + sp.y;
        canvas.drawCircle(
          Offset(sx, sy),
          sp.size * (0.6 + 0.6 * alpha),
          Paint()..color = sp.color.withValues(alpha: alpha),
        );
      }
    }

    // 7. IMPACT EDGE VIGNETTE FLASH
    if (hitVignetteAlpha > 0.01) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            radius: 1.05,
            colors: [
              Colors.transparent,
              const Color(0xFFFF1E42)
                  .withValues(alpha: hitVignetteAlpha.clamp(0.0, 0.45)),
            ],
            stops: const [0.55, 1.0],
          ).createShader(Offset.zero & size),
      );
    }
  }

  void _paintSkyAndHorizon(
    Canvas canvas,
    Size size,
    double horizonY,
    Color accent,
    Color secondary,
    bool isDark,
    RacingVisualTheme visualTheme,
  ) {
    final skyRect = Rect.fromLTRB(0, 0, size.width, horizonY + 2);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.58, 1.0],
          colors: [palette.skyTop, palette.skyMid, palette.skyBottom],
        ).createShader(skyRect),
    );

    if (isDark) {
      final starPaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 42; i++) {
        final sx = ((i * 173.7 - skyParallax * 140) % size.width + size.width) %
            size.width;
        final sy = (i * 47.3) % (horizonY * 0.78);
        final pulse = 0.3 + 0.6 * (0.5 + 0.5 * math.sin(timeSeconds * 2.2 + i));
        starPaint.color = (i % 4 == 0 ? secondary : Colors.white)
            .withValues(alpha: pulse * 0.55);
        canvas.drawCircle(Offset(sx, sy), i % 5 == 0 ? 1.8 : 1.1, starPaint);
      }
    }

    final sunX = size.width * 0.5 - (skyParallax * 90).clamp(-180.0, 180.0);
    final sunY = horizonY -
        (visualTheme == RacingVisualTheme.retroSynthwave ? 8.0 : 18.0);
    final sunRadius = math.min(size.width, size.height) *
        (visualTheme == RacingVisualTheme.retroSynthwave ? 0.17 : 0.125);

    if (visualTheme != RacingVisualTheme.f1PitWall) {
      // Reactor / OutRun Sunset Sun
      final sunColors = visualTheme == RacingVisualTheme.retroSynthwave
          ? const [Color(0xFFFDE047), Color(0xFFFB7185), Color(0xFFEC4899)]
          : [
              accent.withValues(alpha: isDark ? 0.85 : 0.65),
              secondary.withValues(alpha: isDark ? 0.85 : 0.65),
            ];

      canvas.drawCircle(
        Offset(sunX, sunY),
        sunRadius * 1.9,
        Paint()
          ..shader = RadialGradient(
            colors: [
              sunColors.first.withValues(alpha: 0.32),
              accent.withValues(alpha: 0.14),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(sunX, sunY),
              radius: sunRadius * 1.9,
            ),
          ),
      );

      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, 0, size.width, horizonY));
      final sunRect =
          Rect.fromCircle(center: Offset(sunX, sunY), radius: sunRadius);
      canvas.drawCircle(
        Offset(sunX, sunY),
        sunRadius,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: sunColors,
          ).createShader(sunRect),
      );

      final cutColor = palette.skyMid;
      final stripes = visualTheme == RacingVisualTheme.retroSynthwave ? 7 : 5;
      for (int s = 0; s < stripes; s++) {
        final bandY = sunY + (s * sunRadius * 0.14);
        canvas.drawRect(
          Rect.fromLTWH(
            sunX - sunRadius - 2,
            bandY,
            sunRadius * 2 + 4,
            2.2 + s * 1.25,
          ),
          Paint()..color = cutColor.withValues(alpha: 0.88),
        );
      }
      canvas.restore();
    } else {
      // Formula 1 Stadium Floodlights & Grandstand Horizon
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, 0, size.width, horizonY));
      for (int f = 0; f < 6; f++) {
        final fx = (((f * (size.width / 5)) - skyParallax * 180) % size.width +
                size.width) %
            size.width;
        final towerTop = horizonY - 68;
        canvas.drawLine(
          Offset(fx, horizonY),
          Offset(fx, towerTop),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.25)
            ..strokeWidth = 2.5,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(fx, towerTop),
            width: 24,
            height: 8,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.90),
        );
        canvas.drawCircle(
          Offset(fx, towerTop),
          34,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.16)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
      }
      canvas.restore();
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, horizonY));
    _paintParallaxMountains(canvas, size, horizonY, accent, isDark);
    canvas.restore();

    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      Paint()
        ..color = (visualTheme == RacingVisualTheme.retroSynthwave
                ? secondary
                : accent)
            .withValues(alpha: 0.80)
        ..strokeWidth = 2.2,
    );
  }

  void _paintParallaxMountains(
    Canvas canvas,
    Size size,
    double horizonY,
    Color accent,
    bool isDark,
  ) {
    final mountainPath = Path()..moveTo(0, horizonY);
    const peaks = 18;
    final span = size.width / peaks;
    final shift = (skyParallax * 260) % size.width;

    for (int i = -2; i <= peaks + 2; i++) {
      final px = i * span - (shift % span);
      final seed = i + (shift ~/ span);
      final h1 = 22 + ((seed * 37).abs() % 46);
      mountainPath.lineTo(px, horizonY - h1);
      mountainPath.lineTo(px + span * 0.5, horizonY - (h1 * 0.45));
    }
    mountainPath
      ..lineTo(size.width, horizonY)
      ..close();

    canvas.drawPath(
      mountainPath,
      Paint()
        ..color = isDark
            ? const Color(0xFF070B19)
            : Color.lerp(const Color(0xFF94A3B8), accent, 0.2)!,
    );
    canvas.drawPath(
      mountainPath,
      Paint()
        ..color = accent.withValues(alpha: isDark ? 0.45 : 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
  }

  void _paintGroundPerspectiveGrid(
    Canvas canvas,
    Size size,
    double horizonY,
    RacingVisualTheme visualTheme,
  ) {
    final gridPaint = Paint()
      ..color = palette.gridLine
      ..strokeWidth =
          visualTheme == RacingVisualTheme.retroSynthwave ? 1.3 : 1.0;

    final vanishX = size.width * 0.5;
    for (int i = -10; i <= 10; i++) {
      if (i == 0) continue;
      canvas.drawLine(
        Offset(vanishX + i * 22.0, horizonY),
        Offset(vanishX + i * 230.0, size.height),
        gridPaint,
      );
    }

    if (visualTheme == RacingVisualTheme.retroSynthwave) {
      // Classic OutRun scrolling horizontal wireframe grid lines
      final scroll = (playerZ * 0.0025) % 1.0;
      for (int r = 1; r <= 8; r++) {
        final t = ((r + scroll) / 9.0).clamp(0.0, 1.0);
        final y = horizonY + math.pow(t, 2.2) * (size.height - horizonY);
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          gridPaint,
        );
      }
    }
  }

  void _paintRoadQuad({
    required Canvas canvas,
    required RoadSegment seg,
    required double x1,
    required double y1,
    required double w1,
    required double x2,
    required double y2,
    required double w2,
    required Color accent,
    required Color secondary,
    required bool isDark,
  }) {
    final altBand = (seg.index ~/ 3).isEven;
    final roadColor = altBand ? palette.asphaltA : palette.asphaltB;

    final roadPath = Path()
      ..moveTo(x1 - w1, y1)
      ..lineTo(x2 - w2, y2)
      ..lineTo(x2 + w2, y2)
      ..lineTo(x1 + w1, y1)
      ..close();
    canvas.drawPath(roadPath, Paint()..color = roadColor);

    // Motorsport Rumble Kerbs (FIA Red/White in F1, Pink/Cyan in Synthwave!)
    final kerbW1 = w1 * 0.115;
    final kerbW2 = w2 * 0.115;
    final kerbAlt = (seg.index ~/ 2).isEven;
    final kerbColor = kerbAlt ? palette.kerbA : palette.kerbB;

    final leftKerb = Path()
      ..moveTo(x1 - w1 - kerbW1, y1)
      ..lineTo(x2 - w2 - kerbW2, y2)
      ..lineTo(x2 - w2, y2)
      ..lineTo(x1 - w1, y1)
      ..close();
    final rightKerb = Path()
      ..moveTo(x1 + w1, y1)
      ..lineTo(x2 + w2, y2)
      ..lineTo(x2 + w2 + kerbW2, y2)
      ..lineTo(x1 + w1 + kerbW1, y1)
      ..close();

    final kerbPaint = Paint()..color = kerbColor.withValues(alpha: 0.94);
    canvas.drawPath(leftKerb, kerbPaint);
    canvas.drawPath(rightKerb, kerbPaint);

    if (seg.isCheckered) {
      const cols = 8;
      for (int c = 0; c < cols; c++) {
        final tA = -1.0 + (2.0 * c / cols);
        final tB = -1.0 + (2.0 * (c + 1) / cols);
        final isWhite = (c + seg.index).isEven;
        final tilePath = Path()
          ..moveTo(x1 + w1 * tA, y1)
          ..lineTo(x2 + w2 * tA, y2)
          ..lineTo(x2 + w2 * tB, y2)
          ..lineTo(x1 + w1 * tB, y1)
          ..close();
        canvas.drawPath(
          tilePath,
          Paint()
            ..color = isWhite
                ? Colors.white.withValues(alpha: 0.94)
                : const Color(0xFF090D16),
        );
      }
      return;
    }

    // 3-Lane Dashed Dividers
    if ((seg.index ~/ 2).isEven) {
      final divColor = palette.visualTheme == RacingVisualTheme.retroSynthwave
          ? secondary.withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: isDark ? 0.42 : 0.65);
      final lanePaint = Paint()..color = divColor;
      for (final lanePos in const [-0.33, 0.33]) {
        final lw1 = math.max(1.2, w1 * 0.018);
        final lw2 = math.max(0.6, w2 * 0.018);
        final lx1 = x1 + w1 * lanePos;
        final lx2 = x2 + w2 * lanePos;
        final dash = Path()
          ..moveTo(lx1 - lw1, y1)
          ..lineTo(lx2 - lw2, y2)
          ..lineTo(lx2 + lw2, y2)
          ..lineTo(lx1 + lw1, y1)
          ..close();
        canvas.drawPath(dash, lanePaint);
      }
    }

    if (seg.boostLane != null) {
      final bl = seg.boostLane!;
      final padHalf1 = w1 * 0.18;
      final padHalf2 = w2 * 0.18;
      final bx1 = x1 + w1 * bl;
      final bx2 = x2 + w2 * bl;
      final padPath = Path()
        ..moveTo(bx1 - padHalf1, y1)
        ..lineTo(bx2 - padHalf2, y2)
        ..lineTo(bx2 + padHalf2, y2)
        ..lineTo(bx1 + padHalf1, y1)
        ..close();
      canvas.drawPath(
        padPath,
        Paint()..color = const Color(0xFF00F0FF).withValues(alpha: 0.80),
      );
    }
  }

  void _paintNeonTunnelArch(
    Canvas canvas,
    double cx,
    double cy,
    double roadHalfW,
    Color accent,
    Color secondary,
    int n,
  ) {
    final w = roadHalfW * 1.18;
    final h = roadHalfW * 1.05;
    if (w < 6) return;
    final color = (n ~/ 4).isEven ? accent : secondary;
    final archPaint = Paint()
      ..color = color.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (roadHalfW * 0.025).clamp(1.0, 5.0);

    final path = Path()
      ..moveTo(cx - w, cy)
      ..lineTo(cx - w * 0.88, cy - h)
      ..lineTo(cx + w * 0.88, cy - h)
      ..lineTo(cx + w, cy);
    canvas.drawPath(path, archPaint);
  }

  void _paintSynthwavePalms(
    Canvas canvas,
    double cx,
    double cy,
    double roadHalfW,
    Color accent,
    Color secondary,
  ) {
    if (roadHalfW < 10) return;
    final h = roadHalfW * 0.88;
    final offset = roadHalfW * 1.28;
    final trunkPaint = Paint()
      ..color = const Color(0xFF1E0B36)
      ..strokeWidth = (roadHalfW * 0.032).clamp(1.5, 7.0)
      ..strokeCap = StrokeCap.round;
    final frondPaint = Paint()
      ..color = secondary.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (roadHalfW * 0.018).clamp(1.0, 3.5);

    for (final dir in const [-1.0, 1.0]) {
      final baseX = cx + dir * offset;
      final topX = baseX + dir * (roadHalfW * 0.10);
      final topY = cy - h;
      canvas.drawLine(Offset(baseX, cy), Offset(topX, topY), trunkPaint);
      for (final fAngle in const [-2.3, -1.7, -1.1, -0.5]) {
        final len = roadHalfW * 0.28;
        final endX = topX + math.cos(fAngle) * len * -dir;
        final endY = topY + math.sin(fAngle).abs() * len * 0.55;
        canvas.drawLine(Offset(topX, topY), Offset(endX, endY), frondPaint);
      }
    }
  }

  void _paintRoadsideLightPylons(
    Canvas canvas,
    double cx,
    double cy,
    double roadHalfW,
    Color accent,
    Color secondary,
    bool altColor,
  ) {
    if (roadHalfW < 8) return;
    final poleH = roadHalfW * 0.82;
    final offset = roadHalfW * 1.24;
    final strokeW = (roadHalfW * 0.018).clamp(1.0, 4.0);
    final lampColor = altColor ? accent : secondary;

    final postPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = strokeW;

    for (final dir in const [-1.0, 1.0]) {
      final baseX = cx + dir * offset;
      final topX = cx + dir * (offset * 0.88);
      final topY = cy - poleH;
      canvas.drawLine(Offset(baseX, cy), Offset(topX, topY), postPaint);
      canvas.drawCircle(
        Offset(topX, topY),
        (roadHalfW * 0.04).clamp(1.5, 8.0),
        Paint()..color = lampColor.withValues(alpha: 0.9),
      );
    }
  }

  void _paintBillboard3D({
    required Canvas canvas,
    required BillboardSpec spec,
    required double roadCenterX,
    required double groundY,
    required double roadHalfW,
    required bool isLeft,
    required int distanceSteps,
    required Color accent,
    required Color secondary,
    required bool isDark,
  }) {
    if (roadHalfW < 10) return;

    final boardColor = spec.useSecondaryAccent ? secondary : accent;
    final isPhotoBoard = spec.showDriverPhoto;
    final boardW =
        (roadHalfW * (isPhotoBoard ? 1.06 : 0.92)).clamp(16.0, 390.0);
    final boardH = boardW * (isPhotoBoard ? 0.54 : 0.48);
    final strutH = roadHalfW * 0.24;

    final anchorX = isLeft
        ? roadCenterX - roadHalfW * 1.22 - boardW
        : roadCenterX + roadHalfW * 1.22;
    final boardTop = groundY - strutH - boardH;
    final rect = Rect.fromLTWH(anchorX, boardTop, boardW, boardH);

    final strutPaint = Paint()
      ..color = boardColor.withValues(alpha: 0.65)
      ..strokeWidth = (boardW * 0.025).clamp(1.0, 4.5);
    canvas.drawLine(
      Offset(rect.left + boardW * 0.2, rect.bottom),
      Offset(rect.left + boardW * 0.2, groundY),
      strutPaint,
    );
    canvas.drawLine(
      Offset(rect.right - boardW * 0.2, rect.bottom),
      Offset(rect.right - boardW * 0.2, groundY),
      strutPaint,
    );

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular((boardW * 0.04).clamp(2.0, 10.0)),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = palette.hudSurface.withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = boardColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (boardW * 0.016).clamp(1.0, 3.0),
    );

    final headerH = boardH * 0.25;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(rect.left, rect.top, rect.width, headerH),
        topLeft: Radius.circular((boardW * 0.04).clamp(2.0, 10.0)),
        topRight: Radius.circular((boardW * 0.04).clamp(2.0, 10.0)),
      ),
      Paint()..color = boardColor.withValues(alpha: 0.26),
    );

    if (boardW >= 58 && distanceSteps < 46) {
      final pad = boardW * 0.05;
      double textLeft = rect.left + pad;
      double textMaxW = boardW - pad * 2;

      // Draw Sivaprasad NK's portrait inside Hero Jumbotron Billboards!
      if (isPhotoBoard && driverPhoto != null && boardH >= 34) {
        final avatarSize = (boardH * 0.60).clamp(18.0, 110.0);
        final avatarRect = Rect.fromLTWH(
          rect.left + pad,
          rect.top + headerH + (boardH - headerH - avatarSize) * 0.5,
          avatarSize,
          avatarSize,
        );
        canvas.drawCircle(
          avatarRect.center,
          avatarSize * 0.52,
          Paint()..color = boardColor.withValues(alpha: 0.25),
        );
        canvas.save();
        canvas.clipPath(Path()..addOval(avatarRect));
        canvas.drawImageRect(
          driverPhoto!,
          Rect.fromLTWH(
            0,
            0,
            driverPhoto!.width.toDouble(),
            driverPhoto!.height.toDouble(),
          ),
          avatarRect,
          Paint()..filterQuality = FilterQuality.medium,
        );
        canvas.restore();
        canvas.drawCircle(
          avatarRect.center,
          avatarSize * 0.5,
          Paint()
            ..color = boardColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = (boardW * 0.012).clamp(1.0, 2.5),
        );

        textLeft = avatarRect.right + pad * 0.85;
        textMaxW = rect.right - pad - textLeft;
      }

      _drawFittedText(
        canvas: canvas,
        text: spec.tag,
        offset: Offset(rect.left + pad, rect.top + headerH * 0.16),
        maxWidth: boardW - pad * 2,
        fontSize: (boardH * 0.145).clamp(7.0, 13.5),
        color: boardColor,
        weight: FontWeight.w700,
      );
      _drawFittedText(
        canvas: canvas,
        text: spec.title,
        offset: Offset(textLeft, rect.top + boardH * 0.36),
        maxWidth: textMaxW,
        fontSize: (boardH * 0.22).clamp(9.0, 23.0),
        color: Colors.white,
        weight: FontWeight.w800,
      );
      _drawFittedText(
        canvas: canvas,
        text: spec.subtitle,
        offset: Offset(textLeft, rect.top + boardH * 0.69),
        maxWidth: textMaxW,
        fontSize: (boardH * 0.14).clamp(7.0, 14.0),
        color: secondary.withValues(alpha: 0.92),
        weight: FontWeight.w700,
      );
    }
  }

  void _paintCheckpointGantry({
    required Canvas canvas,
    required String code,
    required String title,
    required String subtitle,
    String? destinationLabel,
    required double roadCenterX,
    required double groundY,
    required double roadHalfW,
    required int distanceSteps,
    required Color accent,
    required Color secondary,
    required RacingVisualTheme visualTheme,
  }) {
    if (roadHalfW < 12) return;

    final spanHalfW = roadHalfW * 1.16;
    final legH = roadHalfW * 0.96;
    final bannerH = (roadHalfW * 0.30).clamp(10.0, 96.0);
    final pillarW = (roadHalfW * 0.055).clamp(2.0, 18.0);
    const holoCyan = Color(0xFF00F0FF);

    // Holographic projection pad across road surface
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(roadCenterX, groundY),
        width: spanHalfW * 1.88,
        height: (roadHalfW * 0.22).clamp(4.0, 36.0),
      ),
      Paint()..color = holoCyan.withValues(alpha: 0.22),
    );

    // Volumetric light pillars rising skyward from gantry towers
    for (final px in [roadCenterX - spanHalfW, roadCenterX + spanHalfW]) {
      final beamRect = Rect.fromLTWH(
        px - pillarW * 0.7,
        groundY - legH * 1.85,
        pillarW * 1.4,
        legH * 1.85,
      );
      canvas.drawRect(
        beamRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              holoCyan.withValues(alpha: 0.26),
              Colors.transparent,
            ],
          ).createShader(beamRect),
      );
    }

    final pillarPaint = Paint()
      ..color = palette.hudSurface.withValues(alpha: 0.95);
    final pillarStroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = (roadHalfW * 0.012).clamp(1.0, 3.0);

    final leftTower = Rect.fromLTWH(
      roadCenterX - spanHalfW - pillarW,
      groundY - legH,
      pillarW,
      legH,
    );
    final rightTower = Rect.fromLTWH(
      roadCenterX + spanHalfW,
      groundY - legH,
      pillarW,
      legH,
    );
    canvas.drawRect(leftTower, pillarPaint);
    canvas.drawRect(leftTower, pillarStroke);
    canvas.drawRect(rightTower, pillarPaint);
    canvas.drawRect(rightTower, pillarStroke);

    final bannerRect = Rect.fromLTWH(
      roadCenterX - spanHalfW - pillarW,
      groundY - legH - bannerH * 0.2,
      (spanHalfW + pillarW) * 2,
      bannerH,
    );
    final bannerRRect =
        RRect.fromRectAndRadius(bannerRect, const Radius.circular(6));
    canvas.drawRRect(
      bannerRRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            palette.hudSurface.withValues(alpha: 0.96),
            Color.lerp(palette.hudSurface, accent, 0.25)!
                .withValues(alpha: 0.96),
            palette.hudSurface.withValues(alpha: 0.96),
          ],
        ).createShader(bannerRect),
    );
    canvas.drawRRect(
      bannerRRect,
      Paint()
        ..color = holoCyan.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (roadHalfW * 0.014).clamp(1.2, 3.2),
    );

    // Floating 3D wireframe hologram beacon hovering above gantry banner
    if (bannerH >= 16 && distanceSteps < 58) {
      final holoR = (bannerH * 0.38).clamp(6.0, 26.0);
      final holoCy =
          bannerRect.top - holoR * 1.45 + math.sin(timeSeconds * 4.0) * 3.5;
      final spinW = holoR * (0.45 + 0.55 * math.cos(timeSeconds * 2.6).abs());
      final diamond = Path()
        ..moveTo(roadCenterX, holoCy - holoR)
        ..lineTo(roadCenterX + spinW, holoCy)
        ..lineTo(roadCenterX, holoCy + holoR)
        ..lineTo(roadCenterX - spinW, holoCy)
        ..close();
      canvas.drawPath(
        diamond,
        Paint()..color = holoCyan.withValues(alpha: 0.24),
      );
      canvas.drawPath(
        diamond,
        Paint()
          ..color = holoCyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      if (destinationLabel != null && bannerRect.width >= 130) {
        _drawCenteredText(
          canvas: canvas,
          text: 'HOLO-GATE • $destinationLabel',
          center: Offset(roadCenterX, holoCy - holoR - 10),
          maxWidth: bannerRect.width * 0.85,
          fontSize: (bannerH * 0.20).clamp(7.5, 13.0),
          color: holoCyan,
          weight: FontWeight.w800,
        );
      }
    }

    if (bannerRect.width >= 95 && distanceSteps < 56) {
      final prefix =
          visualTheme == RacingVisualTheme.f1PitWall ? 'FIA $code' : code;
      _drawCenteredText(
        canvas: canvas,
        text: '$prefix  •  $title',
        center: Offset(
          bannerRect.center.dx,
          bannerRect.top + bannerH * 0.34,
        ),
        maxWidth: bannerRect.width * 0.92,
        fontSize: (bannerH * 0.36).clamp(8.5, 26.0),
        color: Colors.white,
        weight: FontWeight.w800,
      );
      if (bannerH >= 28) {
        _drawCenteredText(
          canvas: canvas,
          text: subtitle.toUpperCase(),
          center: Offset(
            bannerRect.center.dx,
            bannerRect.top + bannerH * 0.73,
          ),
          maxWidth: bannerRect.width * 0.90,
          fontSize: (bannerH * 0.21).clamp(7.5, 14.5),
          color: secondary,
          weight: FontWeight.w700,
        );
      }
    }
  }

  void _paintTrackObstacle3D({
    required Canvas canvas,
    required TrackObstacle obstacle,
    required double screenX,
    required double screenY,
    required double roadHalfW,
    required int distanceSteps,
  }) {
    final obsW = (roadHalfW * 0.32).clamp(6.0, 140.0);
    if (obsW < 7.0) return;
    final obsH = obsW * 0.48;
    final isFlashing = obstacle.hitFlashTimer > 0;
    final beaconColor = isFlashing
        ? Colors.white
        : ((timeSeconds * 8).floor().isEven
            ? const Color(0xFFFF3B5C)
            : const Color(0xFFF59E0B));

    final rect = Rect.fromLTWH(
      screenX - obsW * 0.5,
      screenY - obsH,
      obsW,
      obsH,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(screenX, screenY - obsH * 0.05),
        width: obsW * 1.15,
        height: obsH * 0.24,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isFlashing
            ? const Color(0xFFFF3B5C)
            : const Color(0xFF1F1224),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = beaconColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (obsW * 0.03).clamp(1.2, 3.0),
    );

    // Hazard diagonal stripes
    final stripePaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.85)
      ..strokeWidth = (obsW * 0.06).clamp(1.5, 5.5);
    for (int s = -1; s <= 1; s++) {
      final sx = screenX + s * obsW * 0.26;
      canvas.drawLine(
        Offset(sx - obsW * 0.08, rect.bottom - 2),
        Offset(sx + obsW * 0.08, rect.top + 2),
        stripePaint,
      );
    }

    // Twin top hazard beacons
    for (final side in const [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(screenX + side * obsW * 0.34, rect.top),
        (obsW * 0.07).clamp(1.5, 6.0),
        Paint()..color = beaconColor,
      );
    }

    if (obsW >= 54 && distanceSteps < 20) {
      _drawCenteredText(
        canvas: canvas,
        text: obstacle.label,
        center: Offset(screenX, rect.top - obsH * 0.28),
        maxWidth: obsW * 1.2,
        fontSize: (obsH * 0.24).clamp(7.5, 11.5),
        color: const Color(0xFFFBBF24),
        weight: FontWeight.w800,
      );
    }
  }

  void _paintDataOrb(
    Canvas canvas,
    double x,
    double groundY,
    double roadHalfW,
    String label,
    Color accent,
    Color secondary,
  ) {
    final r = (roadHalfW * 0.068).clamp(2.5, 24.0);
    if (r < 3.0) return;
    final bob = math.sin(timeSeconds * 5.0 + x * 0.02) * (r * 0.25);
    final cy = groundY - r * 1.4 + bob;
    final color = label.contains('NITRO') ? secondary : const Color(0xFFF59E0B);

    canvas.drawCircle(
      Offset(x, cy),
      r * 1.6,
      Paint()..color = color.withValues(alpha: 0.26),
    );

    final diamond = Path()
      ..moveTo(x, cy - r)
      ..lineTo(x + r * 0.82, cy)
      ..lineTo(x, cy + r)
      ..lineTo(x - r * 0.82, cy)
      ..close();
    canvas.drawPath(diamond, Paint()..color = color);
    canvas.drawPath(
      diamond,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.12).clamp(1.0, 2.2),
    );
  }

  void _paintRivalCar3D({
    required Canvas canvas,
    required TrafficCar car,
    required double screenX,
    required double screenY,
    required double roadHalfW,
    required int distanceSteps,
  }) {
    final carW = (roadHalfW * car.kind.visualWidthFactor).clamp(6.0, 175.0);
    if (carW < 7.0) return;
    final isTruck = car.kind == OpponentVehicleKind.truck;
    final carH = carW * (isTruck ? 0.74 : 0.56);
    final isHit = car.hitFlashTimer > 0;

    const rivalPalette = [
      Color(0xFF38BDF8),
      Color(0xFFF43F5E),
      Color(0xFFA855F7),
      Color(0xFF10B981),
    ];
    final trimColor = isHit
        ? const Color(0xFFFF3B5C)
        : rivalPalette[car.colorVariant % rivalPalette.length];

    final rect = Rect.fromLTWH(
      screenX - carW * 0.5,
      screenY - carH,
      carW,
      carH,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(screenX, screenY - carH * 0.06),
        width: carW * 1.12,
        height: carH * 0.26,
      ),
      Paint()..color = trimColor.withValues(alpha: isHit ? 0.52 : 0.28),
    );

    final wheelW = carW * 0.18;
    final wheelH = carH * 0.36;
    final tirePaint = Paint()..color = const Color(0xFF090D16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, screenY - wheelH, wheelW, wheelH),
        const Radius.circular(3),
      ),
      tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.right - wheelW, screenY - wheelH, wheelW, wheelH),
        const Radius.circular(3),
      ),
      tirePaint,
    );

    final bodyFill = isHit ? const Color(0xFF5A1625) : const Color(0xFF161F33);
    if (isTruck) {
      final cargoRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left + carW * 0.06,
          rect.top + carH * 0.10,
          carW * 0.88,
          carH * 0.72,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(cargoRect, Paint()..color = bodyFill);
      canvas.drawRRect(
        cargoRect,
        Paint()
          ..color = trimColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = (carW * 0.022).clamp(1.0, 2.8),
      );
      // Roof hazard clearance lights on armored trucks
      for (final side in const [-0.26, 0.0, 0.26]) {
        canvas.drawCircle(
          Offset(screenX + side * carW, rect.top + carH * 0.14),
          (carW * 0.032).clamp(1.2, 4.0),
          Paint()..color = const Color(0xFFF59E0B),
        );
      }
    } else {
      final bodyPath = Path()
        ..moveTo(rect.left + carW * 0.05, screenY - wheelH * 0.35)
        ..lineTo(rect.left + carW * 0.12, rect.top + carH * 0.36)
        ..lineTo(rect.right - carW * 0.12, rect.top + carH * 0.36)
        ..lineTo(rect.right - carW * 0.05, screenY - wheelH * 0.35)
        ..close();
      canvas.drawPath(bodyPath, Paint()..color = bodyFill);
      canvas.drawPath(
        bodyPath,
        Paint()
          ..color = trimColor.withValues(alpha: 0.88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (carW * 0.02).clamp(1.0, 2.5),
      );

      final cabinPath = Path()
        ..moveTo(rect.left + carW * 0.20, rect.top + carH * 0.38)
        ..lineTo(rect.left + carW * 0.28, rect.top + carH * 0.06)
        ..lineTo(rect.right - carW * 0.28, rect.top + carH * 0.06)
        ..lineTo(rect.right - carW * 0.20, rect.top + carH * 0.38)
        ..close();
      canvas.drawPath(cabinPath, Paint()..color = const Color(0xFF0B1120));

      if (car.kind == OpponentVehicleKind.interceptor) {
        canvas.drawLine(
          Offset(rect.left + carW * 0.12, rect.top + carH * 0.28),
          Offset(rect.right - carW * 0.12, rect.top + carH * 0.28),
          Paint()
            ..color = trimColor
            ..strokeWidth = (carH * 0.07).clamp(1.2, 3.6),
        );
      }
    }

    final tailY = rect.top + carH * (isTruck ? 0.62 : 0.50);
    canvas.drawLine(
      Offset(rect.left + carW * 0.14, tailY),
      Offset(rect.right - carW * 0.14, tailY),
      Paint()
        ..color = const Color(0xFFFF2A5F)
        ..strokeWidth = (carH * 0.10).clamp(1.5, 5.0),
    );

    if (isHit) {
      canvas.drawOval(
        rect.inflate(carW * 0.10),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    if (carW >= 54 && distanceSteps < 22) {
      _drawCenteredText(
        canvas: canvas,
        text: car.label,
        center: Offset(screenX, rect.top + carH * 0.74),
        maxWidth: carW * 0.72,
        fontSize: (carH * 0.18).clamp(7.0, 12.0),
        color: trimColor,
        weight: FontWeight.w800,
      );
    }
  }

  void _paintSpeedWarpLines(
    Canvas canvas,
    Size size,
    double horizonY,
    Color accent,
  ) {
    final ratio = ((speedKmh - 200) / (maxSpeedKmh - 200)).clamp(0.15, 1.0);
    final cx = size.width * 0.5;
    final cy = horizonY;
    final streakCount = nitroActive ? 22 : 12;

    for (int i = 0; i < streakCount; i++) {
      final angle = (i / streakCount) * math.pi * 2;
      if ((angle > 0.35 && angle < math.pi - 0.35) &&
          (math.sin(angle).abs() > 0.85)) {
        continue;
      }
      final phase =
          ((timeSeconds * (nitroActive ? 3.6 : 2.0)) + i * 0.27) % 1.0;
      final rStart = 140.0 + phase * (size.width * 0.42);
      final rEnd = rStart + (nitroActive ? 110.0 : 55.0) * ratio;

      final p1 = Offset(
        cx + math.cos(angle) * rStart,
        cy + math.sin(angle) * rStart * 0.65,
      );
      final p2 = Offset(
        cx + math.cos(angle) * rEnd,
        cy + math.sin(angle) * rEnd * 0.65,
      );

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = (nitroActive && i.isEven ? const Color(0xFF00F0FF) : accent)
              .withValues(alpha: (nitroActive ? 0.45 : 0.22) * ratio)
          ..strokeWidth = nitroActive ? 2.2 : 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawFittedText({
    required Canvas canvas,
    required String text,
    required Offset offset,
    required double maxWidth,
    required double fontSize,
    required Color color,
    required FontWeight weight,
  }) {
    if (text.isEmpty || maxWidth <= 8) return;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, offset);
  }

  void _drawCenteredText({
    required Canvas canvas,
    required String text,
    required Offset center,
    required double maxWidth,
    required double fontSize,
    required Color color,
    required FontWeight weight,
  }) {
    if (text.isEmpty || maxWidth <= 8) return;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: 1.1,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant RacingTrackPainter oldDelegate) => true;
}
