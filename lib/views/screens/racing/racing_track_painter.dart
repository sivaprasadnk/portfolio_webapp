import 'dart:math' as math;

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
  final Color scaffoldColor;
  final Color primaryColor;

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
    required this.scaffoldColor,
    required this.primaryColor,
  });

  static const int _drawDistance = 96;
  static const double _cameraHeight = 2400.0;
  static const double _cameraDepth = 0.10;
  static const double _curveWorldMultiplier = 13.5;
  static const double _hillWorldMultiplier = 3.8;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty || size.width <= 0 || size.height <= 0) return;

    final isDark = themeState.isDark;
    final accent = themeState.accentColor;
    final secondary = themeState.secondaryAccent;
    final style = themeState.portfolioStyle;

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

    // 1. SKY, SUN/REACTOR & PARALLAX CYBER SKYLINE
    _paintSkyAndHorizon(
      canvas,
      size,
      horizonY,
      accent,
      secondary,
      isDark,
      style,
    );

    // 2. BASE GROUND PLANE
    final groundTop = horizonY - 1;
    final groundRect = Rect.fromLTRB(0, groundTop, size.width, size.height);
    final groundColor1 = isDark
        ? Color.lerp(const Color(0xFF050814), accent, 0.05)!
        : Color.lerp(const Color(0xFFDCE4F0), accent, 0.06)!;
    final groundColor2 =
        isDark ? const Color(0xFF03050C) : const Color(0xFFCBD5E1);
    canvas.drawRect(
      groundRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [groundColor1, groundColor2],
        ).createShader(groundRect),
    );

    // Subtle perspective ground grid lines in Cyber / Glass styles
    _paintGroundPerspectiveGrid(
      canvas,
      size,
      horizonY,
      accent,
      isDark,
    );

    // 3. PROJECT 3D ROAD NODES FRONT-TO-BACK (WITH HILL CREST OCCLUSION)
    final slices = List<_ProjectedSlice>.generate(
        _drawDistance + 1, (_) => _ProjectedSlice());
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

    // Group dynamic traffic cars & orbs by segment offset `n` for proper Z-ordering
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

      // Roadside Objects, Tunnel Ribs, Billboards, Gantries, Orbs & Cars
      // Clipped against hill occlusion `near.clipY`
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
            roadCenterX: far.x,
            groundY: far.y,
            roadHalfW: far.w,
            distanceSteps: n,
            accent: accent,
            secondary: secondary,
            isDark: isDark,
          );
        }

        // Data Crystal Orbs in this slice
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

        // Rival / Traffic Cars in this slice
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
              screenX: cx + car.lane * cw,
              screenY: cy,
              roadHalfW: cw,
              distanceSteps: n,
              accent: accent,
              secondary: secondary,
            );
          }
        }

        canvas.restore();
      }
    }

    // 5. HIGH-SPEED WIND / NITRO WARP LINES
    if (speedKmh > 210 || nitroActive) {
      _paintSpeedWarpLines(
        canvas,
        size,
        horizonY,
        accent,
        secondary,
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
    PortfolioStyle style,
  ) {
    final skyRect = Rect.fromLTRB(0, 0, size.width, horizonY + 2);
    final topSky = isDark
        ? const Color(0xFF040611)
        : Color.lerp(const Color(0xFFE0EAFC), accent, 0.08)!;
    final midSky = isDark
        ? Color.lerp(const Color(0xFF0A1026), secondary, 0.16)!
        : Color.lerp(const Color(0xFFCFDEF3), secondary, 0.10)!;
    final lowSky = isDark
        ? Color.lerp(const Color(0xFF111936), accent, 0.28)!
        : Color.lerp(const Color(0xFFF8FAFC), accent, 0.18)!;

    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.62, 1.0],
          colors: [topSky, midSky, lowSky],
        ).createShader(skyRect),
    );

    // Twinkling stars in dark mode
    if (isDark) {
      final starPaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 42; i++) {
        final sx = ((i * 173.7 - skyParallax * 140) % size.width + size.width) %
            size.width;
        final sy = (i * 47.3) % (horizonY * 0.78);
        final pulse = 0.3 + 0.6 * (0.5 + 0.5 * math.sin(timeSeconds * 2.2 + i));
        starPaint.color = (i % 4 == 0 ? accent : Colors.white)
            .withValues(alpha: pulse * 0.55);
        canvas.drawCircle(Offset(sx, sy), i % 5 == 0 ? 1.8 : 1.1, starPaint);
      }
    }

    // Synthwave / Telemetry Horizon Reactor Sun
    final sunX = size.width * 0.5 - (skyParallax * 90).clamp(-180.0, 180.0);
    final sunY = horizonY - 18;
    final sunRadius = math.min(size.width, size.height) * 0.13;

    canvas.drawCircle(
      Offset(sunX, sunY),
      sunRadius * 1.9,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: isDark ? 0.30 : 0.20),
            secondary.withValues(alpha: isDark ? 0.12 : 0.06),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(sunX, sunY), radius: sunRadius * 1.9),
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
          colors: [
            accent.withValues(alpha: isDark ? 0.85 : 0.65),
            secondary.withValues(alpha: isDark ? 0.85 : 0.65),
          ],
        ).createShader(sunRect),
    );

    // Horizontal synth scan-stripes cut across lower half of horizon orb
    final cutColor = isDark ? const Color(0xFF0A1026) : lowSky;
    for (int s = 0; s < 5; s++) {
      final bandY = sunY + (s * sunRadius * 0.16);
      canvas.drawRect(
        Rect.fromLTWH(
          sunX - sunRadius - 2,
          bandY,
          sunRadius * 2 + 4,
          2.2 + s * 1.1,
        ),
        Paint()..color = cutColor.withValues(alpha: 0.85),
      );
    }

    // Parallax Mountain Range & Cyber City Silhouette
    _paintParallaxMountains(
      canvas,
      size,
      horizonY,
      accent,
      secondary,
      isDark,
    );
    canvas.restore();

    // Glowing Horizon Laser Line
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      Paint()
        ..color = accent.withValues(alpha: isDark ? 0.75 : 0.55)
        ..strokeWidth = 2.0,
    );
  }

  void _paintParallaxMountains(
    Canvas canvas,
    Size size,
    double horizonY,
    Color accent,
    Color secondary,
    bool isDark,
  ) {
    final mountainPath = Path()..moveTo(0, horizonY);
    const peaks = 18;
    final span = size.width / peaks;
    final shift = (skyParallax * 260) % (size.width);

    for (int i = -2; i <= peaks + 2; i++) {
      final px = i * span - (shift % span);
      final seed = (i + (shift ~/ span));
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
        ..color = accent.withValues(alpha: isDark ? 0.35 : 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _paintGroundPerspectiveGrid(
    Canvas canvas,
    Size size,
    double horizonY,
    Color accent,
    bool isDark,
  ) {
    final gridPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.09 : 0.08)
      ..strokeWidth = 1.0;

    final vanishX = size.width * 0.5;
    for (int i = -8; i <= 8; i++) {
      if (i == 0) continue;
      canvas.drawLine(
        Offset(vanishX + i * 24.0, horizonY),
        Offset(vanishX + i * 220.0, size.height),
        gridPaint,
      );
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

    // Outer grass/shoulder rumble glow
    if ((seg.index ~/ 3) % 2 == 0) {
      final shoulderPaint = Paint()
        ..color = accent.withValues(alpha: isDark ? 0.035 : 0.04);
      canvas.drawRect(
        Rect.fromLTRB(0, y2, x2 - w2, y1),
        shoulderPaint,
      );
    }

    // 1. Asphalt Road Surface
    final roadColor = isDark
        ? (altBand ? const Color(0xFF0F1629) : const Color(0xFF131C33))
        : (altBand ? const Color(0xFF334155) : const Color(0xFF3E4C63));

    final roadPath = Path()
      ..moveTo(x1 - w1, y1)
      ..lineTo(x2 - w2, y2)
      ..lineTo(x2 + w2, y2)
      ..lineTo(x1 + w1, y1)
      ..close();
    canvas.drawPath(roadPath, Paint()..color = roadColor);

    // 2. Motorsport Rumble Kerbs (Left & Right)
    final kerbW1 = w1 * 0.11;
    final kerbW2 = w2 * 0.11;
    final kerbAlt = (seg.index ~/ 2).isEven;
    final kerbColor =
        kerbAlt ? accent : (isDark ? const Color(0xFFF8FAFC) : Colors.white);

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

    final kerbPaint = Paint()..color = kerbColor.withValues(alpha: 0.9);
    canvas.drawPath(leftKerb, kerbPaint);
    canvas.drawPath(rightKerb, kerbPaint);

    // 3. Checkered Start / Finish Line Pattern
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
                ? Colors.white.withValues(alpha: 0.92)
                : const Color(0xFF090D16),
        );
      }
      return;
    }

    // 4. 3-Lane Dashed Neon Dividers
    if ((seg.index ~/ 2).isEven) {
      final lanePaint = Paint()
        ..color = Colors.white.withValues(alpha: isDark ? 0.42 : 0.65);
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

    // 5. Track Surface Nitro / Skill Boost Pad (`>>>`)
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
        Paint()..color = const Color(0xFF00F0FF).withValues(alpha: 0.78),
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
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (roadHalfW * 0.025).clamp(1.0, 5.0);

    final path = Path()
      ..moveTo(cx - w, cy)
      ..lineTo(cx - w * 0.88, cy - h)
      ..lineTo(cx + w * 0.88, cy - h)
      ..lineTo(cx + w, cy);
    canvas.drawPath(path, archPaint);
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

    // Left & Right Pylons
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
    final boardW = (roadHalfW * 0.92).clamp(16.0, 340.0);
    final boardH = boardW * 0.48;
    final strutH = roadHalfW * 0.24;

    final anchorX = isLeft
        ? roadCenterX - roadHalfW * 1.22 - boardW
        : roadCenterX + roadHalfW * 1.22;
    final boardTop = groundY - strutH - boardH;
    final rect = Rect.fromLTWH(anchorX, boardTop, boardW, boardH);

    // Support struts
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

    // Holographic Dark Glass Board Surface + Neon Frame
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular((boardW * 0.04).clamp(2.0, 10.0)),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isDark
            ? const Color(0xFF070C1A).withValues(alpha: 0.92)
            : const Color(0xFF0F172A).withValues(alpha: 0.90),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = boardColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (boardW * 0.016).clamp(1.0, 3.0),
    );

    // Top accent header bar
    final headerH = boardH * 0.26;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(rect.left, rect.top, rect.width, headerH),
        topLeft: Radius.circular((boardW * 0.04).clamp(2.0, 10.0)),
        topRight: Radius.circular((boardW * 0.04).clamp(2.0, 10.0)),
      ),
      Paint()..color = boardColor.withValues(alpha: 0.24),
    );

    // Render crisp text only when billboard is large enough to read
    if (boardW >= 58 && distanceSteps < 46) {
      final pad = boardW * 0.055;
      _drawFittedText(
        canvas: canvas,
        text: spec.tag,
        offset: Offset(rect.left + pad, rect.top + headerH * 0.16),
        maxWidth: boardW - pad * 2,
        fontSize: (boardH * 0.15).clamp(7.0, 14.0),
        color: boardColor,
        weight: FontWeight.w700,
      );
      _drawFittedText(
        canvas: canvas,
        text: spec.title,
        offset: Offset(rect.left + pad, rect.top + boardH * 0.34),
        maxWidth: boardW - pad * 2,
        fontSize: (boardH * 0.23).clamp(9.0, 24.0),
        color: Colors.white,
        weight: FontWeight.w800,
      );
      _drawFittedText(
        canvas: canvas,
        text: spec.subtitle,
        offset: Offset(rect.left + pad, rect.top + boardH * 0.68),
        maxWidth: boardW - pad * 2,
        fontSize: (boardH * 0.145).clamp(7.0, 14.5),
        color: Colors.white.withValues(alpha: 0.80),
        weight: FontWeight.w600,
      );
    }
  }

  void _paintCheckpointGantry({
    required Canvas canvas,
    required String code,
    required String title,
    required String subtitle,
    required double roadCenterX,
    required double groundY,
    required double roadHalfW,
    required int distanceSteps,
    required Color accent,
    required Color secondary,
    required bool isDark,
  }) {
    if (roadHalfW < 12) return;

    final spanHalfW = roadHalfW * 1.16;
    final legH = roadHalfW * 0.96;
    final bannerH = (roadHalfW * 0.30).clamp(10.0, 96.0);
    final pillarW = (roadHalfW * 0.055).clamp(2.0, 18.0);

    // Left & Right Gantry Towers
    final pillarPaint = Paint()
      ..color = const Color(0xFF0B1325).withValues(alpha: 0.94);
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

    // Overhead Span Banner
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
            const Color(0xFF070C1B).withValues(alpha: 0.95),
            Color.lerp(const Color(0xFF0A1229), accent, 0.22)!
                .withValues(alpha: 0.95),
            const Color(0xFF070C1B).withValues(alpha: 0.95),
          ],
        ).createShader(bannerRect),
    );
    canvas.drawRRect(
      bannerRRect,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = (roadHalfW * 0.014).clamp(1.2, 3.2),
    );

    if (bannerRect.width >= 95 && distanceSteps < 56) {
      _drawCenteredText(
        canvas: canvas,
        text: '$code  •  $title',
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
          color: accent,
          weight: FontWeight.w700,
        );
      }
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
    final color = label.contains('NITRO')
        ? const Color(0xFF00F0FF)
        : const Color(0xFFF59E0B);

    // Outer glow
    canvas.drawCircle(
      Offset(x, cy),
      r * 1.6,
      Paint()..color = color.withValues(alpha: 0.26),
    );

    // Diamond crystal shape
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
    required Color accent,
    required Color secondary,
  }) {
    final carW = (roadHalfW * 0.34).clamp(6.0, 145.0);
    if (carW < 7.0) return;
    final carH = carW * 0.56;

    const palette = [
      Color(0xFF38BDF8),
      Color(0xFFF43F5E),
      Color(0xFFA855F7),
      Color(0xFF10B981),
    ];
    final trimColor = palette[car.colorVariant % palette.length];

    final rect = Rect.fromLTWH(
      screenX - carW * 0.5,
      screenY - carH,
      carW,
      carH,
    );

    // Underglow shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(screenX, screenY - carH * 0.06),
        width: carW * 1.12,
        height: carH * 0.26,
      ),
      Paint()..color = trimColor.withValues(alpha: 0.28),
    );

    // Rear tires
    final wheelW = carW * 0.18;
    final wheelH = carH * 0.38;
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

    // Lower widebody
    final bodyPath = Path()
      ..moveTo(rect.left + carW * 0.05, screenY - wheelH * 0.35)
      ..lineTo(rect.left + carW * 0.12, rect.top + carH * 0.36)
      ..lineTo(rect.right - carW * 0.12, rect.top + carH * 0.36)
      ..lineTo(rect.right - carW * 0.05, screenY - wheelH * 0.35)
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()..color = const Color(0xFF161F33),
    );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = trimColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (carW * 0.02).clamp(1.0, 2.5),
    );

    // Cabin canopy
    final cabinPath = Path()
      ..moveTo(rect.left + carW * 0.20, rect.top + carH * 0.38)
      ..lineTo(rect.left + carW * 0.28, rect.top + carH * 0.06)
      ..lineTo(rect.right - carW * 0.28, rect.top + carH * 0.06)
      ..lineTo(rect.right - carW * 0.20, rect.top + carH * 0.38)
      ..close();
    canvas.drawPath(
      cabinPath,
      Paint()..color = const Color(0xFF0B1120),
    );

    // Glowing LED tail-light bar
    final tailY = rect.top + carH * 0.50;
    canvas.drawLine(
      Offset(rect.left + carW * 0.14, tailY),
      Offset(rect.right - carW * 0.14, tailY),
      Paint()
        ..color = const Color(0xFFFF2A5F)
        ..strokeWidth = (carH * 0.10).clamp(1.5, 5.0),
    );

    if (carW >= 54 && distanceSteps < 22) {
      _drawCenteredText(
        canvas: canvas,
        text: car.label,
        center: Offset(screenX, rect.top + carH * 0.74),
        maxWidth: carW * 0.72,
        fontSize: (carH * 0.19).clamp(7.0, 12.0),
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
    Color secondary,
  ) {
    final ratio = ((speedKmh - 200) / (maxSpeedKmh - 200)).clamp(0.15, 1.0);
    final cx = size.width * 0.5;
    final cy = horizonY;
    final streakCount = nitroActive ? 22 : 12;

    for (int i = 0; i < streakCount; i++) {
      final angle = (i / streakCount) * math.pi * 2;
      // Focus streaks along peripheral edges so center road stays crystal clear
      if ((angle > 0.35 && angle < math.pi - 0.35) &&
          (math.sin(angle).abs() > 0.85)) {
        continue;
      }
      final phase =
          ((timeSeconds * (nitroActive ? 3.6 : 2.0)) + i * 0.27) % 1.0;
      final rStart = 140.0 + phase * (size.width * 0.42);
      final rEnd = rStart + (nitroActive ? 110.0 : 55.0) * ratio;

      final p1 = Offset(
          cx + math.cos(angle) * rStart, cy + math.sin(angle) * rStart * 0.65);
      final p2 = Offset(
          cx + math.cos(angle) * rEnd, cy + math.sin(angle) * rEnd * 0.65);

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
        canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant RacingTrackPainter oldDelegate) => true;
}
