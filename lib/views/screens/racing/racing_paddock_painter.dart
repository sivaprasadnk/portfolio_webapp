import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:spnk/views/screens/racing/racing_car_painter.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';

class PaddockRivalState {
  double angle;
  final double speedRad;
  final double radiusX;
  final double radiusY;
  final int colorVariant;
  final String label;
  final OpponentVehicleKind kind;
  double hitCooldown;
  double hitFlashTimer;
  Offset staggerOffset;

  PaddockRivalState({
    required this.angle,
    required this.speedRad,
    this.radiusX = 900.0,
    this.radiusY = 535.0,
    required this.colorVariant,
    required this.label,
    this.kind = OpponentVehicleKind.coupe,
    this.hitCooldown = 0.0,
    this.hitFlashTimer = 0.0,
    this.staggerOffset = Offset.zero,
  });

  Offset get position => Offset(
        math.cos(angle) * radiusX + staggerOffset.dx,
        math.sin(angle) * radiusY + staggerOffset.dy,
      );

  double get heading => math.atan2(-math.sin(angle) * radiusX, -math.cos(angle) * radiusY);
}

class RacingPaddockPainter extends CustomPainter {
  final Offset playerPos;
  final Offset cameraPos;
  final double playerHeading; // 0 = UP (-Y)
  final double steerVisual;
  final double speedKmh;
  final bool isAccelerating;
  final bool isBraking;
  final bool nitroActive;
  final double timeSeconds;
  final RacingThemePalette palette;
  final RaceSectorMeta activeSector;
  final RaceSectorMeta? hoveredZone;
  final DriverQuickLink? activePortalLink;
  final Offset? gpsTarget;
  final List<PaddockLinkPortal> linkPortals;
  final List<PaddockBoostStrip> boostStrips;
  final List<PaddockOrb> orbs;
  final List<PaddockSkidMark> skidMarks;
  final List<PaddockRivalState> rivals;
  final ui.Image? driverPhoto;
  final VehicleType vehicleType;
  final bool collisionFlash;
  final List<ImpactSpark> sparks;
  final Offset cameraShake;
  final double hitVignetteAlpha;

  RacingPaddockPainter({
    required this.playerPos,
    required this.cameraPos,
    required this.playerHeading,
    required this.steerVisual,
    required this.speedKmh,
    required this.isAccelerating,
    required this.isBraking,
    required this.nitroActive,
    required this.timeSeconds,
    required this.palette,
    required this.activeSector,
    required this.hoveredZone,
    required this.activePortalLink,
    required this.gpsTarget,
    required this.linkPortals,
    required this.boostStrips,
    required this.orbs,
    required this.skidMarks,
    required this.rivals,
    this.driverPhoto,
    this.vehicleType = VehicleType.apexGt,
    this.collisionFlash = false,
    this.sparks = const [],
    this.cameraShake = Offset.zero,
    this.hitVignetteAlpha = 0.0,
  });

  /// Converts a screen tap coordinate into a world-space coordinate.
  static Offset screenToWorld(Offset localPos, Size size, Offset cameraPos) {
    return Offset(
      cameraPos.dx + (localPos.dx - size.width * 0.5),
      cameraPos.dy + (localPos.dy - size.height * 0.54),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final accent = palette.accent;
    final secondary = palette.secondary;

    // 1. Paddock Ground Fill
    final bgRect = Offset.zero & size;
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.05,
          colors: [palette.groundFar, palette.groundNear],
        ).createShader(bgRect),
    );

    canvas.save();
    // Camera transform: place `cameraPos` slightly below screen center
    canvas.translate(
      size.width * 0.5 - cameraPos.dx + cameraShake.dx,
      size.height * 0.54 - cameraPos.dy + cameraShake.dy,
    );

    // 2. World Blueprint / Turf / Synthwave Grid & Boundary Fence
    _paintWorldGridAndBoundary(canvas, size, accent, secondary);

    // 3. Connected Grand Prix Paddock Asphalt Loop & Plaza Spokes
    _paintPaddockRoadNetwork(canvas, accent, secondary);

    // 4. Persistent Drift Tire Skid Marks
    for (final mark in skidMarks) {
      canvas.drawLine(
        mark.a,
        mark.b,
        Paint()
          ..color = (palette.visualTheme == RacingVisualTheme.retroSynthwave
                  ? accent
                  : Colors.black)
              .withValues(alpha: (0.42 * mark.life).clamp(0.0, 0.45))
          ..strokeWidth = 4.2
          ..strokeCap = StrokeCap.round,
      );
    }

    // 5. ECU Skill Boost Strips
    for (final strip in boostStrips) {
      _paintBoostStrip(canvas, strip, secondary);
    }

    // 6. 6 Interactive Portfolio Sector Bays
    for (final sector in RaceSectorMeta.sectors) {
      _paintSectorBay(
        canvas,
        sector,
        isHovered: hoveredZone?.index == sector.index,
        isActive: activeSector.index == sector.index,
        accent: accent,
        secondary: secondary,
      );
    }

    // 7. Central Driver Monument Plaza (0, 0) + Sivaprasad NK Photo + 7 Link Portals
    _paintCenterDriverPlaza(canvas, accent, secondary);
    for (final portal in linkPortals) {
      _paintLinkPortal(
        canvas,
        portal,
        isSelected: activePortalLink?.id == portal.link.id,
      );
    }

    // 8. Collectible Data Crystals
    for (final orb in orbs) {
      if (orb.collected) continue;
      _paintOrb(canvas, orb, secondary);
    }

    // 9. GPS Auto-Drive Guidance Beam
    if (gpsTarget != null) {
      _paintGpsBeam(canvas, playerPos, gpsTarget!, secondary);
    }

    // 10. Roaming Rival Cars on the Paddock Loop
    const rivalTrim = [
      Color(0xFF38BDF8),
      Color(0xFFF43F5E),
      Color(0xFFA855F7),
      Color(0xFF10B981),
    ];
    for (final r in rivals) {
      TopDownRaceCarRenderer.paint(
        canvas: canvas,
        position: r.position,
        headingRadians: r.heading,
        width: r.kind.topDownWidth,
        length: r.kind.topDownLength,
        steer: -0.18,
        isAccelerating: true,
        isBraking: false,
        nitroActive: false,
        timeSeconds: timeSeconds,
        palette: palette,
        badge: '',
        overrideTrim: rivalTrim[r.colorVariant % rivalTrim.length],
        showHeadlights: false,
        opponentKind: r.kind,
        collisionFlash: r.hitFlashTimer > 0,
      );
    }

    // 11. Player Top-Down Vehicle (`SPNK-01`)
    TopDownRaceCarRenderer.paint(
      canvas: canvas,
      position: playerPos,
      headingRadians: playerHeading,
      width: vehicleType.topDownWidth,
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

    // World-space collision sparks
    for (final sp in sparks) {
      final alpha = (sp.life / sp.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(sp.x, sp.y),
        sp.size * (0.6 + 0.5 * alpha),
        Paint()..color = sp.color.withValues(alpha: alpha),
      );
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

    // 12. Screen-Space Corner Paddock Mini-Map Radar
    if (size.width >= 680 && size.height >= 500) {
      _paintMiniMapRadar(canvas, size, accent, secondary);
    }
  }

  void _paintWorldGridAndBoundary(
    Canvas canvas,
    Size size,
    Color accent,
    Color secondary,
  ) {
    const hw = PaddockWorldBuilder.halfWidth;
    const hh = PaddockWorldBuilder.halfHeight;
    const step = 110.0;

    final gridPaint = Paint()
      ..color = palette.gridLine
      ..strokeWidth =
          palette.visualTheme == RacingVisualTheme.retroSynthwave ? 1.3 : 1.0;

    final minX = (cameraPos.dx - size.width * 0.65).clamp(-hw, hw);
    final maxX = (cameraPos.dx + size.width * 0.65).clamp(-hw, hw);
    final minY = (cameraPos.dy - size.height * 0.65).clamp(-hh, hh);
    final maxY = (cameraPos.dy + size.height * 0.65).clamp(-hh, hh);

    final startX = (minX ~/ step) * step;
    for (double x = startX; x <= maxX; x += step) {
      canvas.drawLine(Offset(x, minY), Offset(x, maxY), gridPaint);
    }
    final startY = (minY ~/ step) * step;
    for (double y = startY; y <= maxY; y += step) {
      canvas.drawLine(Offset(minX, y), Offset(maxX, y), gridPaint);
    }

    // Glowing World Arena Barrier
    final arenaRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(-hw, -hh, hw, hh),
      const Radius.circular(64),
    );
    canvas.drawRRect(
      arenaRect,
      Paint()
        ..color = accent.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0,
    );
  }

  void _paintPaddockRoadNetwork(
    Canvas canvas,
    Color accent,
    Color secondary,
  ) {
    final ovalRect = Rect.fromCenter(
      center: Offset.zero,
      width: 1800,
      height: 1070,
    );

    // Outer kerb border
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = palette.kerbA.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 148,
    );

    // Main oval asphalt circuit
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = palette.asphaltA
        ..style = PaintingStyle.stroke
        ..strokeWidth = 132,
    );

    // Radial asphalt avenues connecting each Sector Zone to Center Driver Plaza
    final spokePaint = Paint()
      ..color = palette.asphaltB
      ..strokeWidth = 84
      ..strokeCap = StrokeCap.round;
    for (final s in RaceSectorMeta.sectors) {
      canvas.drawLine(Offset.zero, s.paddockCenter, spokePaint);
    }

    // Center Roundabout Plaza Asphalt Pad
    canvas.drawCircle(
      Offset.zero,
      365,
      Paint()..color = palette.asphaltA,
    );
    canvas.drawCircle(
      Offset.zero,
      365,
      Paint()
        ..color = accent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Dashed circuit racing line
    const dashes = 64;
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2.4;
    for (int i = 0; i < dashes; i += 2) {
      final a1 = (i / dashes) * 2 * math.pi;
      final a2 = ((i + 0.8) / dashes) * 2 * math.pi;
      canvas.drawLine(
        Offset(math.cos(a1) * 900, math.sin(a1) * 535),
        Offset(math.cos(a2) * 900, math.sin(a2) * 535),
        dashPaint,
      );
    }
  }

  void _paintCenterDriverPlaza(
    Canvas canvas,
    Color accent,
    Color secondary,
  ) {
    // Rotating telemetry halo around central Driver Shrine
    final sweep = (timeSeconds * 0.9) % (2 * math.pi);
    canvas.drawCircle(
      Offset.zero,
      168,
      Paint()..color = palette.hudSurface.withValues(alpha: 0.92),
    );
    canvas.drawCircle(
      Offset.zero,
      168,
      Paint()
        ..color = accent.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: 178),
      sweep,
      math.pi * 0.65,
      false,
      Paint()
        ..color = secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Sivaprasad NK Portrait Emblem at (0, -24)
    const photoCenter = Offset(0, -28);
    const photoRadius = 74.0;
    final photoRect =
        Rect.fromCircle(center: photoCenter, radius: photoRadius);

    canvas.drawCircle(
      photoCenter,
      photoRadius + 5,
      Paint()
        ..shader = LinearGradient(
          colors: [accent, secondary],
        ).createShader(photoRect),
    );
    canvas.drawCircle(
      photoCenter,
      photoRadius,
      Paint()..color = const Color(0xFF0E172A),
    );

    if (driverPhoto != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(photoRect));
      canvas.drawImageRect(
        driverPhoto!,
        Rect.fromLTWH(
          0,
          0,
          driverPhoto!.width.toDouble(),
          driverPhoto!.height.toDouble(),
        ),
        photoRect,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    } else {
      _drawCenteredText(
        canvas: canvas,
        text: 'SPNK',
        center: photoCenter,
        maxWidth: 120,
        fontSize: 28,
        color: accent,
        weight: FontWeight.w800,
      );
    }

    _drawCenteredText(
      canvas: canvas,
      text: 'SIVAPRASAD NK',
      center: const Offset(0, 68),
      maxWidth: 280,
      fontSize: 21,
      color: Colors.white,
      weight: FontWeight.w800,
    );
    _drawCenteredText(
      canvas: canvas,
      text: 'SENIOR FLUTTER ARCHITECT',
      center: const Offset(0, 92),
      maxWidth: 280,
      fontSize: 12.5,
      color: secondary,
      weight: FontWeight.w700,
    );
    _drawCenteredText(
      canvas: canvas,
      text: 'CLICK OR DRIVE TO LINK PADS',
      center: const Offset(0, 116),
      maxWidth: 260,
      fontSize: 11,
      color: Colors.white.withValues(alpha: 0.72),
      weight: FontWeight.w700,
    );
  }

  void _paintLinkPortal(
    Canvas canvas,
    PaddockLinkPortal portal, {
    required bool isSelected,
  }) {
    final link = portal.link;
    final r = isSelected ? portal.radius + 6 : portal.radius;
    final pulse = 0.5 + 0.5 * math.sin(timeSeconds * 4.5 + portal.center.dx);

    // Connector filament from Center Monument to Portal Pad
    canvas.drawLine(
      Offset(
        portal.center.dx * 0.58,
        portal.center.dy * 0.58,
      ),
      Offset(
        portal.center.dx * 0.82,
        portal.center.dy * 0.82,
      ),
      Paint()
        ..color = link.color.withValues(alpha: 0.40)
        ..strokeWidth = 2.0,
    );

    if (isSelected) {
      canvas.drawCircle(
        portal.center,
        r + 10,
        Paint()
          ..color = link.color.withValues(alpha: 0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    canvas.drawCircle(
      portal.center,
      r,
      Paint()..color = palette.hudSurface.withValues(alpha: 0.94),
    );
    canvas.drawCircle(
      portal.center,
      r,
      Paint()
        ..color = link.color.withValues(alpha: isSelected ? 1.0 : 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.2 : 2.0,
    );
    canvas.drawCircle(
      portal.center,
      r * (0.72 + 0.08 * pulse),
      Paint()
        ..color = link.color.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );

    _drawCenteredText(
      canvas: canvas,
      text: link.shortCode,
      center: Offset(portal.center.dx, portal.center.dy - 9),
      maxWidth: r * 1.6,
      fontSize: 17,
      color: link.color,
      weight: FontWeight.w800,
    );
    _drawCenteredText(
      canvas: canvas,
      text: link.label.toUpperCase(),
      center: Offset(portal.center.dx, portal.center.dy + 13),
      maxWidth: r * 1.75,
      fontSize: 10.5,
      color: Colors.white,
      weight: FontWeight.w700,
    );
  }

  void _paintSectorBay(
    Canvas canvas,
    RaceSectorMeta sector, {
    required bool isHovered,
    required bool isActive,
    required Color accent,
    required Color secondary,
  }) {
    final rect = Rect.fromCenter(
      center: sector.paddockCenter,
      width: PaddockWorldBuilder.zoneWidth,
      height: PaddockWorldBuilder.zoneHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    final borderColor =
        isHovered ? const Color(0xFF10B981) : (isActive ? accent : secondary);

    if (isHovered || isActive) {
      canvas.drawRRect(
        rrect.inflate(6),
        Paint()
          ..color = borderColor.withValues(alpha: isHovered ? 0.30 : 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    canvas.drawRRect(
      rrect,
      Paint()..color = palette.hudSurface.withValues(alpha: 0.90),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor.withValues(alpha: isHovered ? 1.0 : 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 3.2 : 2.0,
    );

    // Top telemetry strip
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(rect.left, rect.top, rect.width, 40),
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
      ),
      Paint()..color = borderColor.withValues(alpha: 0.22),
    );

    _drawCenteredText(
      canvas: canvas,
      text: '${sector.code}  •  ${sector.shortLabel} PADDOCK BAY',
      center: Offset(rect.center.dx, rect.top + 20),
      maxWidth: rect.width - 28,
      fontSize: 13,
      color: borderColor,
      weight: FontWeight.w800,
    );
    _drawCenteredText(
      canvas: canvas,
      text: sector.title,
      center: Offset(rect.center.dx, rect.top + 88),
      maxWidth: rect.width - 32,
      fontSize: 19,
      color: Colors.white,
      weight: FontWeight.w800,
    );
    _drawCenteredText(
      canvas: canvas,
      text: sector.subtitle,
      center: Offset(rect.center.dx, rect.top + 124),
      maxWidth: rect.width - 36,
      fontSize: 12.5,
      color: Colors.white.withValues(alpha: 0.78),
      weight: FontWeight.w600,
    );
    // Holographic projection emitter halo on sector bay
    final pulse = 0.5 + 0.5 * math.sin(timeSeconds * 3.5 + sector.index);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.bottom - 52),
        width: 110 + 18 * pulse,
        height: 22 + 5 * pulse,
      ),
      Paint()
        ..color = const Color(0xFF00F0FF)
            .withValues(alpha: isHovered ? 0.28 : 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    _drawCenteredText(
      canvas: canvas,
      text: isHovered
          ? '⚡ PARKED IN ${sector.destinationLabel} — HOLOGRAM READY'
          : 'HOLOGRAM ZONE • DRIVE INTO BAY TO PROJECT',
      center: Offset(rect.center.dx, rect.bottom - 30),
      maxWidth: rect.width - 28,
      fontSize: 11.5,
      color: isHovered ? const Color(0xFF00F0FF) : secondary,
      weight: FontWeight.w800,
    );
  }

  void _paintBoostStrip(
    Canvas canvas,
    PaddockBoostStrip strip,
    Color secondary,
  ) {
    canvas.save();
    canvas.translate(strip.center.dx, strip.center.dy);
    canvas.rotate(strip.angle);

    final rect = Rect.fromCenter(center: Offset.zero, width: 110, height: 48);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF00F0FF).withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF00F0FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    _drawCenteredText(
      canvas: canvas,
      text: '>>> ${strip.label} >>>',
      center: Offset.zero,
      maxWidth: 102,
      fontSize: 10.5,
      color: Colors.white,
      weight: FontWeight.w800,
    );
    canvas.restore();
  }

  void _paintOrb(Canvas canvas, PaddockOrb orb, Color secondary) {
    final pulse = 1.0 + 0.16 * math.sin(timeSeconds * 5.0 + orb.pos.dx);
    final r = 11.0 * pulse;
    final c =
        orb.label.contains('NITRO') ? secondary : const Color(0xFFF59E0B);
    canvas.drawCircle(
      orb.pos,
      r * 1.6,
      Paint()..color = c.withValues(alpha: 0.22),
    );
    final path = Path()
      ..moveTo(orb.pos.dx, orb.pos.dy - r)
      ..lineTo(orb.pos.dx + r * 0.85, orb.pos.dy)
      ..lineTo(orb.pos.dx, orb.pos.dy + r)
      ..lineTo(orb.pos.dx - r * 0.85, orb.pos.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = c);
  }

  void _paintGpsBeam(
    Canvas canvas,
    Offset from,
    Offset to,
    Color secondary,
  ) {
    final dist = (to - from).distance;
    if (dist < 20) return;
    final dir = (to - from) / dist;
    final phase = (timeSeconds * 90) % 28;
    final paint = Paint()
      ..color = secondary.withValues(alpha: 0.85)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    for (double d = phase; d < dist - 14; d += 28) {
      canvas.drawLine(
        from + dir * d,
        from + dir * math.min(d + 14, dist),
        paint,
      );
    }
  }

  void _paintMiniMapRadar(
    Canvas canvas,
    Size size,
    Color accent,
    Color secondary,
  ) {
    const mapW = 166.0;
    const mapH = 116.0;
    final mapRect = Rect.fromLTWH(
      size.width - mapW - 20,
      92,
      mapW,
      mapH,
    );
    final rrect = RRect.fromRectAndRadius(mapRect, const Radius.circular(12));

    canvas.drawRRect(
      rrect,
      Paint()..color = palette.hudSurface.withValues(alpha: 0.86),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    Offset toRadar(Offset world) {
      final nx = (world.dx / PaddockWorldBuilder.halfWidth).clamp(-1.0, 1.0);
      final ny = (world.dy / PaddockWorldBuilder.halfHeight).clamp(-1.0, 1.0);
      return Offset(
        mapRect.center.dx + nx * (mapW * 0.42),
        mapRect.center.dy + ny * (mapH * 0.40),
      );
    }

    // Oval track outline on radar
    canvas.drawOval(
      Rect.fromCenter(
        center: mapRect.center,
        width: mapW * 0.56,
        height: mapH * 0.46,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Center plaza dot
    canvas.drawCircle(
      mapRect.center,
      3.5,
      Paint()..color = secondary,
    );

    // 6 Sector blips
    for (final s in RaceSectorMeta.sectors) {
      final p = toRadar(s.paddockCenter);
      canvas.drawCircle(
        p,
        s.index == activeSector.index ? 4.2 : 2.8,
        Paint()
          ..color = s.index == activeSector.index
              ? accent
              : Colors.white.withValues(alpha: 0.65),
      );
    }

    // Live player car blip
    final carBlip = toRadar(playerPos);
    canvas.drawCircle(
      carBlip,
      5.0,
      Paint()..color = const Color(0xFF10B981),
    );
    canvas.drawCircle(
      carBlip,
      7.5,
      Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
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
  bool shouldRepaint(covariant RacingPaddockPainter oldDelegate) => true;
}

