import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:spnk/views/screens/racing/racing_car_painter.dart';
import 'package:spnk/views/screens/racing/racing_collision_engine.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';

/// Top-Down Vertical Highway Lane Racer painter (Mode 3).
/// Shares `playerZ`, `playerX`, `_segments`, `_trafficCars`, and `_orbs`
/// with the 3D Horizon Racer so switching modes preserves exact race progress!
class RacingHighwayPainter extends CustomPainter {
  final List<RoadSegment> segments;
  final List<TrafficCar> trafficCars;
  final List<DataCrystalOrb> orbs;
  final double playerZ;
  final double playerX; // -1.4 .. +1.4
  final double steerVisual;
  final double speedKmh;
  final bool isAccelerating;
  final bool isBraking;
  final bool nitroActive;
  final double timeSeconds;
  final RacingThemePalette palette;
  final ui.Image? driverPhoto;
  final VehicleType vehicleType;
  final List<TrackObstacle> obstacles;
  final List<ImpactSpark> sparks;
  final Offset cameraShake;
  final bool collisionFlash;
  final double hitVignetteAlpha;

  RacingHighwayPainter({
    required this.segments,
    required this.trafficCars,
    required this.orbs,
    required this.playerZ,
    required this.playerX,
    required this.steerVisual,
    required this.speedKmh,
    required this.isAccelerating,
    required this.isBraking,
    required this.nitroActive,
    required this.timeSeconds,
    required this.palette,
    this.driverPhoto,
    this.vehicleType = VehicleType.apexGt,
    this.obstacles = const [],
    this.sparks = const [],
    this.cameraShake = Offset.zero,
    this.collisionFlash = false,
    this.hitVignetteAlpha = 0.0,
  });

  // World Z units visible per vertical pixel on screen
  static const double _zPerPixel = CircuitCollisionDetector.highwayZPerPixel;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty || size.width <= 0 || size.height <= 0) return;

    final accent = palette.accent;
    final secondary = palette.secondary;
    final segLen = CircuitBuilder.segmentLength;
    final trackLen = CircuitBuilder.trackLength;
    final totalSegs = segments.length;

    final normZ = ((playerZ % trackLen) + trackLen) % trackLen;
    final playerScreenY = size.height * 0.72;

    // Responsive highway road width leaving room on left & right shoulders for Pit-Bays
    final roadHalfW = (size.width * 0.24).clamp(115.0, 260.0);
    final roadCenterX = size.width * 0.5;
    final roadLeft = roadCenterX - roadHalfW;
    final roadRight = roadCenterX + roadHalfW;

    canvas.save();
    if (cameraShake != Offset.zero) {
      canvas.translate(cameraShake.dx, cameraShake.dy);
    }

    // 1. Scrolling Terrain Shoulders
    final bgRect = Offset.zero & size;
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.groundFar, palette.groundNear],
        ).createShader(bgRect),
    );

    _paintScrollingShoulderGrid(
      canvas,
      size,
      roadLeft,
      roadRight,
      normZ,
    );

    // 2. Main 4-Lane Highway Surface & Rumble Kerbs
    canvas.drawRect(
      Rect.fromLTRB(roadLeft, 0, roadRight, size.height),
      Paint()..color = palette.asphaltA,
    );

    // Scrolling kerb blocks + lane dividers + segment billboards
    final minVisibleRelZ = -(size.height - playerScreenY) * _zPerPixel - segLen;
    final maxVisibleRelZ = playerScreenY * _zPerPixel + segLen * 2;

    final startStep = (minVisibleRelZ / segLen).floor();
    final endStep = (maxVisibleRelZ / segLen).ceil();
    final baseSegFloat = normZ / segLen;
    final baseSegInt = baseSegFloat.floor();
    final subOffsetZ = normZ - (baseSegInt * segLen);

    const kerbWidth = 14.0;

    // Pass 1: Road markings, kerbs, checkered line & boost strips
    for (int step = startStep; step <= endStep; step++) {
      final segIdx = ((baseSegInt + step) % totalSegs + totalSegs) % totalSegs;
      final seg = segments[segIdx];

      final relZNear = (step * segLen) - subOffsetZ;
      final relZFar = relZNear + segLen;
      final yBottom = playerScreenY - (relZNear / _zPerPixel);
      final yTop = playerScreenY - (relZFar / _zPerPixel);

      // Alternating asphalt band
      if ((segIdx ~/ 2).isEven) {
        canvas.drawRect(
          Rect.fromLTRB(roadLeft, yTop, roadRight, yBottom),
          Paint()..color = palette.asphaltB,
        );
      }

      // Left & Right Serrated Kerbs
      final kerbColor = (segIdx ~/ 2).isEven ? palette.kerbA : palette.kerbB;
      canvas.drawRect(
        Rect.fromLTRB(roadLeft - kerbWidth, yTop, roadLeft, yBottom),
        Paint()..color = kerbColor,
      );
      canvas.drawRect(
        Rect.fromLTRB(roadRight, yTop, roadRight + kerbWidth, yBottom),
        Paint()..color = kerbColor,
      );

      // Checkered Start / Finish Line
      if (seg.isCheckered) {
        const cols = 10;
        final colW = (roadHalfW * 2) / cols;
        for (int c = 0; c < cols; c++) {
          final isWhite = (c + segIdx).isEven;
          canvas.drawRect(
            Rect.fromLTRB(
              roadLeft + c * colW,
              yTop,
              roadLeft + (c + 1) * colW,
              yBottom,
            ),
            Paint()
              ..color = isWhite ? Colors.white : const Color(0xFF090D16),
          );
        }
      } else if (segIdx.isEven) {
        // 3 Lane Divider Dashes (forming 4 lanes / 3 main racing lines)
        final divColor = palette.visualTheme == RacingVisualTheme.retroSynthwave
            ? secondary.withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.42);
        for (final laneDiv in const [-0.34, 0.34]) {
          final lx = roadCenterX + laneDiv * roadHalfW;
          canvas.drawRect(
            Rect.fromLTRB(lx - 2, yTop + 4, lx + 2, yBottom - 4),
            Paint()..color = divColor,
          );
        }
      }

      // Surface Nitro / Skill Boost Strip
      if (seg.boostLane != null) {
        final bx = roadCenterX + seg.boostLane! * roadHalfW;
        final padRect = Rect.fromLTRB(
          bx - roadHalfW * 0.16,
          yTop - 6,
          bx + roadHalfW * 0.16,
          yBottom + 6,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(padRect, const Radius.circular(6)),
          Paint()..color = const Color(0xFF00F0FF).withValues(alpha: 0.78),
        );
      }
    }

    // Pass 2: Collectible Data Crystals
    for (final orb in orbs) {
      if (orb.collected) continue;
      final relZ = _signedTrackDelta(orb.z, normZ, trackLen);
      if (relZ < minVisibleRelZ || relZ > maxVisibleRelZ) continue;
      final oy = playerScreenY - (relZ / _zPerPixel);
      final ox = roadCenterX + orb.lane * roadHalfW;
      final c =
          orb.label.contains('NITRO') ? secondary : const Color(0xFFF59E0B);
      canvas.drawCircle(
        Offset(ox, oy),
        13,
        Paint()..color = c.withValues(alpha: 0.24),
      );
      final d = Path()
        ..moveTo(ox, oy - 9)
        ..lineTo(ox + 8, oy)
        ..lineTo(ox, oy + 9)
        ..lineTo(ox - 8, oy)
        ..close();
      canvas.drawPath(d, Paint()..color = c);
    }

    // Pass 2.5: Static Highway Roadblock Obstacles
    for (final obs in obstacles) {
      final relZ = _signedTrackDelta(obs.z, normZ, trackLen);
      if (relZ < minVisibleRelZ - 80 || relZ > maxVisibleRelZ + 80) continue;
      final oy = playerScreenY - (relZ / _zPerPixel);
      final ox = roadCenterX + obs.lane * roadHalfW;
      final ow = (roadHalfW * obs.roadHalfWidth * 1.9).clamp(28.0, 74.0);
      final isHit = obs.hitFlashTimer > 0;
      final blinkColor = isHit
          ? Colors.white
          : ((timeSeconds * 8).floor().isEven
              ? const Color(0xFFFF3B5C)
              : const Color(0xFFF59E0B));
      final rect = Rect.fromCenter(center: Offset(ox, oy), width: ow, height: 20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..color = isHit ? const Color(0xFFFF3B5C) : const Color(0xFF1F1224),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..color = blinkColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      for (final side in const [-0.36, 0.36]) {
        canvas.drawCircle(
          Offset(ox + side * ow, oy),
          3.2,
          Paint()..color = blinkColor,
        );
      }
    }

    // Pass 3: Rival Traffic Cars in Highway Lanes
    const rivalColors = [
      Color(0xFF38BDF8),
      Color(0xFFF43F5E),
      Color(0xFFA855F7),
      Color(0xFF10B981),
    ];
    for (final car in trafficCars) {
      final relZ = _signedTrackDelta(car.z, normZ, trackLen);
      if (relZ < minVisibleRelZ - 80 || relZ > maxVisibleRelZ + 80) continue;
      final cy = playerScreenY - (relZ / _zPerPixel);
      final cx = roadCenterX + car.effectiveLane * roadHalfW;
      final rivalW = (roadHalfW * car.kind.roadHalfWidth * 1.95).clamp(
        car.kind.topDownWidth * 0.78,
        car.kind.topDownWidth * 1.35,
      );
      TopDownRaceCarRenderer.paint(
        canvas: canvas,
        position: Offset(cx, cy),
        headingRadians: 0,
        width: rivalW,
        length: car.kind.topDownLength,
        steer: 0,
        isAccelerating: true,
        isBraking: false,
        nitroActive: false,
        timeSeconds: timeSeconds,
        palette: palette,
        badge: '',
        overrideTrim: rivalColors[car.colorVariant % rivalColors.length],
        showHeadlights: false,
        opponentKind: car.kind,
        collisionFlash: car.hitFlashTimer > 0,
      );
    }

    // Pass 4: Player Top-Down Vehicle (`SPNK-01`)
    final playerScreenX = roadCenterX + playerX * roadHalfW;
    final playerW = (roadHalfW * vehicleType.roadHalfWidth * 1.95).clamp(
      vehicleType.topDownWidth * 0.78,
      vehicleType.topDownWidth * 1.35,
    );
    TopDownRaceCarRenderer.paint(
      canvas: canvas,
      position: Offset(playerScreenX, playerScreenY),
      headingRadians: steerVisual * 0.20,
      width: playerW,
      length: vehicleType.topDownLength,
      steer: steerVisual,
      isAccelerating: isAccelerating,
      isBraking: isBraking,
      nitroActive: nitroActive,
      timeSeconds: timeSeconds,
      palette: palette,
      badge: '01',
      vehicleType: vehicleType,
      collisionFlash: collisionFlash,
    );

    // Collision Sparks on Highway
    for (final sp in sparks) {
      final alpha = (sp.life / sp.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(roadCenterX + sp.x * roadHalfW, playerScreenY + sp.y),
        sp.size * (0.6 + 0.5 * alpha),
        Paint()..color = sp.color.withValues(alpha: alpha),
      );
    }

    // Pass 5: Roadside Pit-Stop Bays, Driver Photo Jumbotrons & Overhead Gantries
    for (int step = startStep; step <= endStep; step++) {
      final segIdx = ((baseSegInt + step) % totalSegs + totalSegs) % totalSegs;
      final seg = segments[segIdx];
      final relZ = (step * segLen) - subOffsetZ;
      final y = playerScreenY - (relZ / _zPerPixel);

      if (seg.leftBillboard != null && size.width >= 620) {
        _paintShoulderBayCard(
          canvas: canvas,
          spec: seg.leftBillboard!,
          shoulderEdgeX: roadLeft - kerbWidth - 12,
          centerY: y,
          availableWidth: roadLeft - kerbWidth - 22,
          isLeft: true,
          accent: accent,
          secondary: secondary,
        );
      }
      if (seg.rightBillboard != null && size.width >= 620) {
        _paintShoulderBayCard(
          canvas: canvas,
          spec: seg.rightBillboard!,
          shoulderEdgeX: roadRight + kerbWidth + 12,
          centerY: y,
          availableWidth: size.width - (roadRight + kerbWidth + 22),
          isLeft: false,
          accent: accent,
          secondary: secondary,
        );
      }
      if (seg.gantryTitle != null) {
        _paintOverheadHighwayGantry(
          canvas: canvas,
          code: seg.gantryCode ?? 'SECTOR',
          title: seg.gantryTitle!,
          destinationLabel: seg.gantryDestinationLabel,
          roadLeft: roadLeft - kerbWidth - 8,
          roadRight: roadRight + kerbWidth + 8,
          y: y,
          accent: accent,
          secondary: secondary,
        );
      }
    }

    canvas.restore();

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

  void _paintScrollingShoulderGrid(
    Canvas canvas,
    Size size,
    double roadLeft,
    double roadRight,
    double normZ,
  ) {
    const stepPx = 68.0;
    final offsetPx = (normZ / _zPerPixel) % stepPx;
    final gridPaint = Paint()
      ..color = palette.gridLine
      ..strokeWidth = 1.1;

    for (double y = offsetPx; y < size.height; y += stepPx) {
      canvas.drawLine(Offset(0, y), Offset(roadLeft, y), gridPaint);
      canvas.drawLine(Offset(roadRight, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 40; x < roadLeft; x += stepPx) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double x = roadRight + 40; x < size.width; x += stepPx) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  void _paintShoulderBayCard({
    required Canvas canvas,
    required BillboardSpec spec,
    required double shoulderEdgeX,
    required double centerY,
    required double availableWidth,
    required bool isLeft,
    required Color accent,
    required Color secondary,
  }) {
    if (availableWidth < 110) return;
    final cardW = math.min(availableWidth, 236.0);
    final cardH = spec.showDriverPhoto ? 82.0 : 68.0;
    final left = isLeft ? shoulderEdgeX - cardW : shoulderEdgeX;
    final rect =
        Rect.fromLTWH(left, centerY - cardH * 0.5, cardW, cardH);
    final color = spec.useSecondaryAccent ? secondary : accent;

    // Connector arm to highway kerb
    canvas.drawLine(
      Offset(isLeft ? rect.right : rect.left, centerY),
      Offset(shoulderEdgeX + (isLeft ? 10 : -10), centerY),
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = 2.5,
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(
      rrect,
      Paint()..color = palette.hudSurface.withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    double textX = rect.left + 10;
    double textMaxW = rect.width - 20;

    if (spec.showDriverPhoto && driverPhoto != null) {
      final avatarRect = Rect.fromLTWH(rect.left + 10, rect.top + 13, 54, 54);
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
        27,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      textX = avatarRect.right + 10;
      textMaxW = rect.right - 10 - textX;
    }

    _drawFittedText(
      canvas: canvas,
      text: spec.tag,
      offset: Offset(textX, rect.top + 8),
      maxWidth: textMaxW,
      fontSize: 10,
      color: color,
      weight: FontWeight.w800,
    );
    _drawFittedText(
      canvas: canvas,
      text: spec.title,
      offset: Offset(textX, rect.top + 25),
      maxWidth: textMaxW,
      fontSize: 15,
      color: Colors.white,
      weight: FontWeight.w800,
    );
    _drawFittedText(
      canvas: canvas,
      text: spec.subtitle,
      offset: Offset(textX, rect.top + 47),
      maxWidth: textMaxW,
      fontSize: 10.5,
      color: secondary,
      weight: FontWeight.w700,
    );
  }

  void _paintOverheadHighwayGantry({
    required Canvas canvas,
    required String code,
    required String title,
    String? destinationLabel,
    required double roadLeft,
    required double roadRight,
    required double y,
    required Color accent,
    required Color secondary,
  }) {
    final rect = Rect.fromLTRB(roadLeft, y - 19, roadRight, y + 19);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    const holoCyan = Color(0xFF00F0FF);
    canvas.drawRRect(
      rrect,
      Paint()..color = palette.hudSurface.withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = holoCyan.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final labelPrefix = destinationLabel != null
        ? 'HOLO-GATE: $destinationLabel'
        : code;
    final tp = TextPainter(
      text: TextSpan(
        text: '$labelPrefix  •  $title',
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: Colors.white,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 24);
    tp.paint(
      canvas,
      Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
    );
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

  @override
  bool shouldRepaint(covariant RacingHighwayPainter oldDelegate) => true;
}

