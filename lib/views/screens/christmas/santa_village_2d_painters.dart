import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:spnk/views/screens/christmas/christmas_painters.dart';
import 'package:spnk/views/screens/christmas/christmas_theme_config.dart';

/// Panoramic parallax 2D Christmas Winter Village background painter featuring
/// multi-layer mountains, pine forests, packed-snow igloos, cozy log cabins with
/// rising chimney smoke, grazing & stepping deer, golden lantern trail,
/// day/night aurora sky, and depth-layered snowfall.
class SantaVillage2dBackdropPainter extends CustomPainter {
  const SantaVillage2dBackdropPainter({
    required this.dayFactor,
    required this.elapsed,
    required this.scrollOffset,
    required this.worldWidth,
    required this.snowEnabled,
    required this.reducedMotion,
    required this.snowSim,
    required this.groundYFrac,
  });

  final double dayFactor;
  final double elapsed;
  final double scrollOffset;
  final double worldWidth;
  final bool snowEnabled;
  final bool reducedMotion;
  final SnowfallSimulation snowSim;
  final double groundYFrac;

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * groundYFrac;
    _paintSkyAndCelestials(canvas, size, groundY);
    _paintParallaxMountains(canvas, size, groundY);
    _paintMidgroundForestAndVillage(canvas, size, groundY);
    _paintForegroundSnowAndTrail(canvas, size, groundY);
    if (snowEnabled) {
      _paintSnowfall(canvas, size);
    }
  }

  void _paintSkyAndCelestials(Canvas canvas, Size size, double groundY) {
    final rect = Offset.zero & size;
    final skyShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        ChristmasThemeConfig.skyTop(dayFactor),
        ChristmasThemeConfig.skyMid(dayFactor),
        ChristmasThemeConfig.skyHorizon(dayFactor),
      ],
      stops: const [0.0, 0.56, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = skyShader);

    // Night Stars & Flowing Aurora Borealis
    if (dayFactor < 0.88) {
      final nightAlpha = (1.0 - dayFactor).clamp(0.0, 1.0);
      final starPaint = Paint();
      for (int i = 0; i < 82; i++) {
        final parallax = (scrollOffset * 0.03) % size.width;
        final sx = ((i * 197.3 - parallax) % size.width + size.width) %
            size.width;
        final sy = (i * 71.9) % (groundY * 0.65);
        final twinkle = reducedMotion
            ? 0.72
            : 0.42 + 0.58 * math.sin(elapsed * (1.1 + (i % 5) * 0.35) + i);
        starPaint.color =
            Colors.white.withValues(alpha: nightAlpha * twinkle * 0.88);
        canvas.drawCircle(Offset(sx, sy), i % 6 == 0 ? 1.8 : 1.05, starPaint);
      }

      // Multi-band Aurora Borealis
      final drift = scrollOffset * 0.04;
      for (int b = 0; b < 2; b++) {
        final wave =
            reducedMotion ? 0.0 : math.sin(elapsed * 0.35 + b * 1.6) * 20.0;
        final path = Path()
          ..moveTo(-40, groundY * (0.20 + b * 0.09) + wave)
          ..cubicTo(
            size.width * 0.25 - (drift % 120),
            groundY * (0.10 + b * 0.06) - wave,
            size.width * 0.65,
            groundY * (0.28 + b * 0.05) + wave,
            size.width + 40,
            groundY * (0.15 + b * 0.08),
          );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = b == 0 ? 38 : 26
            ..color = (b == 0
                    ? const Color(0xFF34D399)
                    : const Color(0xFF38BDF8))
                .withValues(alpha: (b == 0 ? 0.17 : 0.12) * nightAlpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
        );
      }
    }

    // Sun (Day) / Moon (Night)
    final sunShift = -(scrollOffset * 0.025);
    final orbPos = Offset(
      size.width * 0.78 + sunShift,
      groundY * ui.lerpDouble(0.22, 0.19, dayFactor)!,
    );
    final orbColor = Color.lerp(
      const Color(0xFFEDF5FF),
      const Color(0xFFFFF4C2),
      dayFactor,
    )!;
    canvas.drawCircle(
      orbPos,
      ui.lerpDouble(42, 62, dayFactor)!,
      Paint()
        ..color = orbColor.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawCircle(
      orbPos,
      ui.lerpDouble(19, 25, dayFactor)!,
      Paint()..color = orbColor,
    );

    // Distant Painterly Clouds
    final cloudBase = Color.lerp(
      const Color(0x6647668F),
      const Color(0xB8FFFFFF),
      dayFactor,
    )!;
    for (int c = 0; c < 6; c++) {
      final speed = 5.0 + (c % 3) * 3.0;
      final cx =
          ((c * 290.0 - scrollOffset * 0.08 + elapsed * speed) %
              (size.width + 260)) -
          130;
      final cy = groundY * (0.16 + (c % 3) * 0.11);
      final cw = 95.0 + (c % 3) * 26.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: cw, height: cw * 0.34),
        Paint()
          ..color = cloudBase
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - cw * 0.16, cy - 8),
          width: cw * 0.56,
          height: cw * 0.28,
        ),
        Paint()
          ..color = cloudBase
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  void _paintParallaxMountains(Canvas canvas, Size size, double groundY) {
    // Layer A: Far Alpine Range (0.15x scroll)
    _drawMountainBand(
      canvas: canvas,
      size: size,
      groundY: groundY,
      scrollFactor: 0.15,
      peakSpacing: 220,
      baseHeight: 165,
      amplitude: 88,
      rockColor: Color.lerp(
        const Color(0xFF152949),
        const Color(0xFF8BB7E0),
        dayFactor,
      )!,
      snowColor: Color.lerp(
        const Color(0xFF3E5F8A),
        const Color(0xFFE6F3FD),
        dayFactor,
      )!,
      seed: 1.0,
    );

    // Layer B: Closer Granitic Ridge (0.30x scroll)
    _drawMountainBand(
      canvas: canvas,
      size: size,
      groundY: groundY,
      scrollFactor: 0.30,
      peakSpacing: 260,
      baseHeight: 120,
      amplitude: 68,
      rockColor: Color.lerp(
        const Color(0xFF1E375D),
        const Color(0xFF6B99C7),
        dayFactor,
      )!,
      snowColor: Color.lerp(
        const Color(0xFF5D84B2),
        const Color(0xFFF5FAFF),
        dayFactor,
      )!,
      seed: 4.3,
    );
  }

  void _drawMountainBand({
    required Canvas canvas,
    required Size size,
    required double groundY,
    required double scrollFactor,
    required double peakSpacing,
    required double baseHeight,
    required double amplitude,
    required Color rockColor,
    required Color snowColor,
    required double seed,
  }) {
    final shift = scrollOffset * scrollFactor;
    final startIdx = (shift / peakSpacing).floor() - 1;
    final count = (size.width / peakSpacing).ceil() + 3;

    final ridgePath = Path()..moveTo(-peakSpacing, groundY + 12);
    for (int i = 0; i <= count; i++) {
      final idx = startIdx + i;
      final px = idx * peakSpacing - shift;
      final hMod =
          math.sin(idx * 1.43 + seed) * 0.55 +
          math.cos(idx * 2.31 - seed) * 0.45;
      final peakY = groundY - baseHeight - hMod * amplitude;
      final midX = px + peakSpacing * 0.48;
      final saddleY =
          groundY -
          baseHeight * 0.42 -
          math.sin(idx * 2.1 + seed) * (amplitude * 0.25);

      ridgePath.lineTo(px, peakY);
      ridgePath.lineTo(midX, saddleY);
    }
    ridgePath
      ..lineTo(size.width + peakSpacing, groundY + 12)
      ..close();

    canvas.drawPath(
      ridgePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [snowColor, rockColor],
          stops: const [0.18, 0.85],
        ).createShader(
          Rect.fromLTWH(0, groundY - baseHeight - amplitude, size.width, baseHeight + amplitude),
        ),
    );
  }

  void _paintMidgroundForestAndVillage(
    Canvas canvas,
    Size size,
    double groundY,
  ) {
    // 1. Midground Rolling Foothills + Evergreen Pines (0.55x parallax)
    final pineShift = scrollOffset * 0.55;
    final pineSpacing = 128.0;
    final firstPine = (pineShift / pineSpacing).floor() - 1;
    final pineCount = (size.width / pineSpacing).ceil() + 3;

    for (int i = 0; i < pineCount; i++) {
      final idx = firstPine + i;
      final px = idx * pineSpacing - pineShift + math.sin(idx * 2.7) * 18.0;
      final hillY = groundY - 14 + math.sin(idx * 0.9) * 10.0;
      final scale = 0.72 + ((idx.abs() % 4) * 0.14);
      final decorated = idx.abs() % 5 == 0;
      _paintRealistic2dPine(
        canvas: canvas,
        baseCenter: Offset(px, hillY),
        scale: scale,
        decorated: decorated,
        layerAlpha: 0.86,
      );
    }

    // 2. Village Architectural Layer (Igloos, Log Cabins, Wild Grazing Deer at 0.85x)
    final villageShift = scrollOffset * 0.85;
    final zoneSpan = 560.0;
    final firstZone = (villageShift / zoneSpan).floor() - 1;
    final zoneCount = (size.width / zoneSpan).ceil() + 3;

    for (int i = 0; i < zoneCount; i++) {
      final idx = firstZone + i;
      final originX = idx * zoneSpan - villageShift;

      if (idx.abs() % 2 == 0) {
        // Packed-snow Igloo
        _paintRealistic2dIgloo(
          canvas: canvas,
          centerBase: Offset(originX + 120, groundY - 2),
          scale: 1.0,
        );
      } else {
        // Cozy Log Cabin with chimney smoke
        _paintRealistic2dCabin(
          canvas: canvas,
          centerBase: Offset(originX + 140, groundY - 2),
          scale: 1.0,
        );
      }

      // Grazing / stepping 2D Deer in the snow meadow between buildings
      _paintRealistic2dDeer(
        canvas: canvas,
        groundPos: Offset(originX + 350, groundY - 3),
        seed: idx.toDouble(),
      );

      // Foreground flanking snow-laden pine beside path
      _paintRealistic2dPine(
        canvas: canvas,
        baseCenter: Offset(originX + 465, groundY - 1),
        scale: 1.08,
        decorated: idx.abs() % 3 == 1,
        layerAlpha: 1.0,
      );
    }
  }

  void _paintRealistic2dPine({
    required Canvas canvas,
    required Offset baseCenter,
    required double scale,
    required bool decorated,
    required double layerAlpha,
  }) {
    final trunkW = 10.0 * scale;
    final trunkH = 26.0 * scale;
    canvas.drawRect(
      Rect.fromLTWH(
        baseCenter.dx - trunkW / 2,
        baseCenter.dy - trunkH,
        trunkW,
        trunkH,
      ),
      Paint()
        ..color = Color.lerp(
          const Color(0xFF2C1B10),
          const Color(0xFF4D2E1B),
          dayFactor,
        )!.withValues(alpha: layerAlpha),
    );

    final tierColors = [
      const Color(0xFF103626),
      const Color(0xFF14422E),
      const Color(0xFF194E37),
      const Color(0xFF1E5B40),
    ];

    for (int t = 0; t < 4; t++) {
      final frac = t / 3.0;
      final w = ui.lerpDouble(86, 36, frac)! * scale;
      final h = ui.lerpDouble(42, 30, frac)! * scale;
      final bottomY = baseCenter.dy - (16 + t * 24) * scale;
      final topY = bottomY - h;

      // Irregular bough silhouette
      final p = Path()
        ..moveTo(baseCenter.dx, topY)
        ..lineTo(baseCenter.dx - w * 0.50, bottomY)
        ..quadraticBezierTo(
          baseCenter.dx - w * 0.25,
          bottomY - h * 0.14,
          baseCenter.dx,
          bottomY - h * 0.04,
        )
        ..quadraticBezierTo(
          baseCenter.dx + w * 0.25,
          bottomY - h * 0.14,
          baseCenter.dx + w * 0.50,
          bottomY,
        )
        ..close();

      canvas.drawPath(
        p,
        Paint()
          ..color = Color.lerp(
            tierColors[t],
            const Color(0xFF236647),
            dayFactor * 0.35,
          )!.withValues(alpha: layerAlpha),
      );

      // Natural snow cushion resting on top of the pine boughs
      final snowCap = Path()
        ..moveTo(baseCenter.dx, topY)
        ..lineTo(baseCenter.dx - w * 0.28, topY + h * 0.44)
        ..quadraticBezierTo(
          baseCenter.dx - w * 0.08,
          topY + h * 0.54,
          baseCenter.dx,
          topY + h * 0.40,
        )
        ..quadraticBezierTo(
          baseCenter.dx + w * 0.12,
          topY + h * 0.54,
          baseCenter.dx + w * 0.29,
          topY + h * 0.44,
        )
        ..close();

      canvas.drawPath(
        snowCap,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFCDE2F6),
            const Color(0xFFF6FAFF),
            dayFactor,
          )!.withValues(alpha: layerAlpha * 0.92),
      );
    }

    if (decorated) {
      final bulbColors = [
        ChristmasThemeConfig.champagneGold,
        const Color(0xFFE11D48),
        ChristmasThemeConfig.icyBlue,
        const Color(0xFF34D399),
      ];
      for (int b = 0; b < 8; b++) {
        final bx =
            baseCenter.dx + math.sin(b * 2.1) * (24.0 - b * 2.1) * scale;
        final by = baseCenter.dy - (28.0 + b * 10.5) * scale;
        final twinkle = reducedMotion
            ? 1.0
            : 0.62 + 0.38 * math.sin(elapsed * 3.2 + b);
        final col = bulbColors[b % bulbColors.length];
        canvas.drawCircle(
          Offset(bx, by),
          5.5 * scale,
          Paint()
            ..color = col.withValues(alpha: 0.36 * twinkle)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(bx, by),
          2.2 * scale,
          Paint()..color = col.withValues(alpha: twinkle),
        );
      }

      // Glowing star crown
      final starPos = Offset(baseCenter.dx, baseCenter.dy - 122 * scale);
      canvas.drawCircle(
        starPos,
        8 * scale,
        Paint()
          ..color = ChristmasThemeConfig.champagneGold.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        starPos,
        3.2 * scale,
        Paint()..color = ChristmasThemeConfig.champagneGold,
      );
    }
  }

  void _paintRealistic2dIgloo({
    required Canvas canvas,
    required Offset centerBase,
    required double scale,
  }) {
    final w = 112.0 * scale;
    final h = 68.0 * scale;
    final domeRect = Rect.fromCenter(
      center: Offset(centerBase.dx, centerBase.dy),
      width: w,
      height: h * 1.45,
    );

    // Subtle snow mound shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerBase.dx, centerBase.dy + 3),
        width: w * 1.12,
        height: 12,
      ),
      Paint()..color = const Color(0x331E3A5F),
    );

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        centerBase.dx - w,
        centerBase.dy - h * 1.1,
        w * 2,
        h * 1.1,
      ),
    );

    // Packed snow dome shaded gradient
    canvas.drawOval(
      domeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              const Color(0xFFDCEBFB),
              const Color(0xFFFFFFFF),
              dayFactor,
            )!,
            Color.lerp(
              const Color(0xFF7FA6CF),
              const Color(0xFFCCE1F4),
              dayFactor,
            )!,
          ],
        ).createShader(domeRect),
    );

    // Block seam lines
    final seamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF6B93BF).withValues(alpha: 0.42);
    for (int r = 1; r <= 3; r++) {
      final y = centerBase.dy - r * 14.0 * scale;
      canvas.drawLine(
        Offset(centerBase.dx - w * 0.45, y),
        Offset(centerBase.dx + w * 0.45, y),
        seamPaint,
      );
    }
    canvas.restore();

    // Arched entrance + warm glowing interior
    final tunnelRect = Rect.fromCenter(
      center: Offset(centerBase.dx + 10 * scale, centerBase.dy),
      width: 34 * scale,
      height: 40 * scale,
    );
    canvas.drawArc(
      tunnelRect,
      math.pi,
      math.pi,
      true,
      Paint()
        ..color = Color.lerp(
          const Color(0xFFFFB74D),
          const Color(0xFFD97706),
          dayFactor * 0.55,
        )!,
    );
    if (dayFactor < 0.75) {
      canvas.drawCircle(
        Offset(centerBase.dx + 10 * scale, centerBase.dy - 8 * scale),
        22 * scale,
        Paint()
          ..color = ChristmasThemeConfig.warmLanternAmber
              .withValues(alpha: (1 - dayFactor) * 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  void _paintRealistic2dCabin({
    required Canvas canvas,
    required Offset centerBase,
    required double scale,
  }) {
    final w = 122.0 * scale;
    final h = 62.0 * scale;
    final wallRect = Rect.fromLTWH(
      centerBase.dx - w / 2,
      centerBase.dy - h,
      w,
      h,
    );

    // Stone chimney + drifting smoke
    final chRect = Rect.fromLTWH(
      centerBase.dx + w * 0.20,
      centerBase.dy - h - 42 * scale,
      18 * scale,
      36 * scale,
    );
    canvas.drawRect(chRect, Paint()..color = const Color(0xFF475569));

    for (int s = 0; s < 4; s++) {
      final age =
          reducedMotion ? s * 0.22 : ((elapsed * 0.25 + s * 0.25) % 1.0);
      final sx = chRect.center.dx + math.sin(age * 4 + s) * 8.0 + age * 14.0;
      final sy = chRect.top - age * 46.0;
      canvas.drawCircle(
        Offset(sx, sy),
        (5.5 + age * 9.0) * scale,
        Paint()
          ..color = const Color(0xFFE2E8F0)
              .withValues(alpha: math.sin(age * math.pi) * 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Timber log walls
    canvas.drawRRect(
      RRect.fromRectAndRadius(wallRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF5C3824),
    );
    final logStroke = Paint()
      ..color = const Color(0xFF3A2215)
      ..strokeWidth = 1.4;
    for (double ly = wallRect.top + 8; ly < wallRect.bottom; ly += 9) {
      canvas.drawLine(
        Offset(wallRect.left, ly),
        Offset(wallRect.right, ly),
        logStroke,
      );
    }

    // Steep pitched roof + snow overhang
    final roof = Path()
      ..moveTo(centerBase.dx, centerBase.dy - h - 44 * scale)
      ..lineTo(centerBase.dx - w * 0.60, centerBase.dy - h + 4)
      ..lineTo(centerBase.dx + w * 0.60, centerBase.dy - h + 4)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF3E2618));

    final snowRoof = Path()
      ..moveTo(centerBase.dx, centerBase.dy - h - 46 * scale)
      ..lineTo(centerBase.dx - w * 0.62, centerBase.dy - h + 1)
      ..quadraticBezierTo(
        centerBase.dx,
        centerBase.dy - h - 6,
        centerBase.dx + w * 0.62,
        centerBase.dy - h + 1,
      )
      ..close();
    canvas.drawPath(
      snowRoof,
      Paint()
        ..color = Color.lerp(
          const Color(0xFFD5E8FA),
          Colors.white,
          dayFactor,
        )!,
    );

    // Door & glowing mullioned windows
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerBase.dx - 11 * scale,
          centerBase.dy - 36 * scale,
          22 * scale,
          36 * scale,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = ChristmasThemeConfig.burgundy,
    );

    final winGlow = Color.lerp(
      const Color(0xFFFFCA62),
      const Color(0xFFF59E0B),
      dayFactor * 0.4,
    )!;
    for (final dx in [-36.0, 36.0]) {
      final wRect = Rect.fromCenter(
        center: Offset(centerBase.dx + dx * scale, centerBase.dy - 28 * scale),
        width: 20 * scale,
        height: 20 * scale,
      );
      canvas.drawCircle(
        wRect.center,
        22 * scale,
        Paint()
          ..color = winGlow.withValues(alpha: (1 - dayFactor * 0.65) * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawRect(wRect, Paint()..color = winGlow);
      canvas.drawRect(
        wRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFF3A2215),
      );
      canvas.drawLine(
        Offset(wRect.left, wRect.center.dy),
        Offset(wRect.right, wRect.center.dy),
        Paint()
          ..strokeWidth = 1.3
          ..color = const Color(0xFF3A2215),
      );
      canvas.drawLine(
        Offset(wRect.center.dx, wRect.top),
        Offset(wRect.center.dx, wRect.bottom),
        Paint()
          ..strokeWidth = 1.3
          ..color = const Color(0xFF3A2215),
      );
    }
  }

  void _paintRealistic2dDeer({
    required Canvas canvas,
    required Offset groundPos,
    required double seed,
  }) {
    // Organic grazing/alert cycle
    final cycle = (elapsed * 0.45 + seed.abs() * 1.7) % 6.0;
    final walking = cycle < 3.6 && !reducedMotion;
    final walkShift = walking ? math.sin(cycle * 0.85) * 26.0 : math.sin(3.6 * 0.85) * 26.0;
    final facing = walking && math.cos(cycle * 0.85) < 0 ? -1.0 : 1.0;
    final stride = walking ? math.sin(elapsed * 5.2 + seed) * 0.34 : 0.0;
    final headNod = walking
        ? math.sin(elapsed * 5.2 + seed) * 0.05
        : 0.28 + math.sin(elapsed * 1.4 + seed) * 0.14;

    canvas.save();
    canvas.translate(groundPos.dx + walkShift, groundPos.dy);
    canvas.scale(facing * 0.88, 0.88);

    final furCoat = Color.lerp(
      const Color(0xFF7B4F33),
      const Color(0xFF936243),
      dayFactor,
    )!;
    final paleBelly = const Color(0xFFE5D7C6);
    final antlerColor = const Color(0xFFD6C7B2);
    final hoofColor = const Color(0xFF1F1916);

    // Shadow on snow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 1), width: 38, height: 7),
      Paint()..color = const Color(0x2E1E3A5F),
    );

    // 4 Articulated slim legs
    final legPaint = Paint()
      ..color = furCoat
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final legStarts = [
      Offset(-12, -18),
      Offset(-9, -18),
      Offset(11, -18),
      Offset(14, -18),
    ];
    for (int l = 0; l < 4; l++) {
      final a = (l.isEven ? stride : -stride);
      final hip = legStarts[l];
      final knee = Offset(hip.dx + math.sin(a) * 9, -9);
      final foot = Offset(knee.dx + math.sin(a * 0.6) * 7, 0);
      canvas.drawLine(hip, knee, legPaint);
      canvas.drawLine(knee, foot, legPaint);
      canvas.drawCircle(foot, 1.8, Paint()..color = hoofColor);
    }

    // Smooth curved deer torso
    final torso = Path()
      ..moveTo(-17, -23)
      ..quadraticBezierTo(-19, -31, -8, -30)
      ..quadraticBezierTo(4, -29, 15, -31)
      ..quadraticBezierTo(21, -28, 19, -20)
      ..quadraticBezierTo(10, -14, -14, -17)
      ..close();
    canvas.drawPath(torso, Paint()..color = furCoat);

    // Pale belly & white tail patch
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(2, -18), width: 20, height: 7),
      Paint()..color = paleBelly,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-18, -25), width: 5, height: 6),
      Paint()..color = Colors.white,
    );

    // Pivoted S-curved neck + sculpted muzzle + multi-tine antlers
    canvas.save();
    canvas.translate(15, -28);
    canvas.rotate(headNod);

    final neckHead = Path()
      ..moveTo(-4, 4)
      ..quadraticBezierTo(2, -7, 4, -18)
      ..lineTo(14, -15) // tapered snout
      ..quadraticBezierTo(15, -12, 11, -11)
      ..quadraticBezierTo(4, -6, 3, 5)
      ..close();
    canvas.drawPath(neckHead, Paint()..color = furCoat);

    // Nose + Ear
    canvas.drawCircle(const Offset(14.5, -14.5), 1.6, Paint()..color = hoofColor);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(2, -20), width: 4, height: 7),
      Paint()..color = furCoat,
    );

    // Sweeping curved antlers
    final antlerPaint = Paint()
      ..color = antlerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final beam = Path()
      ..moveTo(4, -19)
      ..quadraticBezierTo(0, -29, 8, -34);
    final tine = Path()
      ..moveTo(3, -26)
      ..lineTo(10, -27);
    canvas.drawPath(beam, antlerPaint);
    canvas.drawPath(tine, antlerPaint);

    canvas.restore();
    canvas.restore();
  }

  void _paintForegroundSnowAndTrail(
    Canvas canvas,
    Size size,
    double groundY,
  ) {
    final snowGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(const Color(0xFF7CA4CA), const Color(0xFFEAF4FD), dayFactor)!,
        Color.lerp(const Color(0xFFB5D2EC), const Color(0xFFFFFFFF), dayFactor)!,
      ],
    ).createShader(
      Rect.fromLTWH(0, groundY - 12, size.width, size.height - groundY + 14),
    );

    final hillPath = Path()..moveTo(0, groundY);
    final step = 40.0;
    for (double sx = 0; sx <= size.width + step; sx += step) {
      final worldX = sx + scrollOffset;
      final sy =
          groundY + math.sin(worldX * 0.0085) * 6.0 + math.cos(worldX * 0.021) * 2.5;
      hillPath.lineTo(sx, sy);
    }
    hillPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hillPath, Paint()..shader = snowGrad);

    // Trodden snowy trail band where Santa walks + subtle bootprints
    final pathBand = Rect.fromLTWH(0, groundY + 12, size.width, 30);
    canvas.drawRect(
      pathBand,
      Paint()
        ..color = Color.lerp(
          const Color(0x406086AE),
          const Color(0x55B8D4EB),
          dayFactor,
        )!,
    );

    final trackShift = scrollOffset % 34.0;
    final printPaint = Paint()
      ..color = Color.lerp(
        const Color(0x502B486B),
        const Color(0x5589AFCE),
        dayFactor,
      )!;
    for (double tx = -trackShift; tx < size.width + 20; tx += 34.0) {
      final isRight = ((tx + scrollOffset) / 34).floor().isEven;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tx, groundY + (isRight ? 23 : 29)),
          width: 9,
          height: 4,
        ),
        printPaint,
      );
    }
  }

  void _paintSnowfall(Canvas canvas, Size size) {
    final p = Paint();
    for (final f in snowSim.flakes) {
      final x = ((f.xFrac * size.width) - (scrollOffset * 0.22 % size.width) + size.width) %
              size.width +
          (reducedMotion
              ? 0.0
              : math.sin(elapsed * 0.95 + f.driftPhase) * f.driftAmp * size.width);
      final y = f.yFrac * size.height;
      p.color = Colors.white.withValues(
        alpha: f.alpha * ui.lerpDouble(0.86, 0.72, dayFactor)!,
      );
      canvas.drawCircle(Offset(x, y), f.radius, p);
    }
  }

  @override
  bool shouldRepaint(covariant SantaVillage2dBackdropPainter oldDelegate) =>
      true;
}

/// Paints a weathered rustic wooden trail board with broken/chipped plank edges,
/// horizontal split seams, wood knots, forged nails, organic melted snow crest,
/// tiny corner icicles, and crooked timber posts anchored into a snow mound.
class RusticBrokenWoodBoardPainter extends CustomPainter {
  const RusticBrokenWoodBoardPainter({
    required this.seed,
    required this.dayFactor,
    required this.isMainBoard,
    required this.legHeight,
    required this.elapsed,
  });

  final int seed;
  final double dayFactor;
  final bool isMainBoard;
  final double legHeight;
  final double elapsed;

  double _hash(int n) {
    final x = math.sin(seed * 73.1 + n * 19.7) * 43758.5453;
    return x - x.floor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final boardH = (size.height - legHeight).clamp(60.0, size.height);
    final w = size.width;

    // 1. Paint supporting crooked timber post(s) behind the board first
    final postWood = Color.lerp(
      const Color(0xFF3A2112),
      const Color(0xFF56321D),
      dayFactor,
    )!;
    final postShadow = const Color(0xFF221209);
    if (isMainBoard) {
      _paintCrookedPost(
        canvas,
        topCenter: Offset(w * 0.25, boardH - 10),
        bottomY: size.height,
        topWidth: 14,
        bottomWidth: 17,
        tilt: (_hash(1) - 0.5) * 5.0,
        woodColor: postWood,
        shadowColor: postShadow,
      );
      _paintCrookedPost(
        canvas,
        topCenter: Offset(w * 0.75, boardH - 10),
        bottomY: size.height,
        topWidth: 14,
        bottomWidth: 17,
        tilt: (_hash(2) - 0.5) * 5.0,
        woodColor: postWood,
        shadowColor: postShadow,
      );
    } else {
      _paintCrookedPost(
        canvas,
        topCenter: Offset(w * 0.5, boardH - 8),
        bottomY: size.height,
        topWidth: 13,
        bottomWidth: 16,
        tilt: (_hash(3) - 0.5) * 4.5,
        woodColor: postWood,
        shadowColor: postShadow,
      );
    }

    // 2. Build irregular broken/chipped outer timber silhouette (NON-rectangular!)
    final brokenRightTop = _hash(4) > 0.45;
    final chipX = 11.0 + _hash(5) * 7.0;
    final chipY = 10.0 + _hash(6) * 7.0;
    final plank1Out = 3.0 + _hash(7) * 5.0;
    final plank2In = 3.5 + _hash(8) * 5.5;
    final leftNotchY = boardH * (0.34 + _hash(9) * 0.22);
    final rightNotchY = boardH * (0.52 + _hash(10) * 0.20);
    final bottomSplitX = w * (0.38 + _hash(11) * 0.28);
    final isPointedSign = !isMainBoard && (_hash(16) > 0.45);
    final arrowTipOut = isPointedSign ? 16.0 : 0.0;

    final boardPath = Path();
    // Start top-left (torn corner / rustic bevel)
    boardPath.moveTo(brokenRightTop ? 4.0 : chipX, brokenRightTop ? 3.0 : 1.0);
    boardPath.lineTo(w * 0.27, 0.5 + (_hash(12) - 0.5) * 4.0);
    boardPath.lineTo(w * 0.33, 5.5);
    boardPath.lineTo(w * 0.37, 1.0);
    boardPath.lineTo(w * 0.72, 2.0 + (_hash(13) - 0.5) * 3.5);
    if (brokenRightTop) {
      boardPath.lineTo(w - chipX, 1.0);
      boardPath.lineTo(w - 2.0, chipY);
    } else {
      boardPath.lineTo(w - 2.0, 3.0);
    }

    // Right edge — uneven split plank ends / rustic pointed trail tip + broken notch
    if (isPointedSign) {
      boardPath.lineTo(w + arrowTipOut * 0.6, boardH * 0.34);
      boardPath.lineTo(w + arrowTipOut, boardH * 0.50);
      boardPath.lineTo(w + arrowTipOut * 0.4, boardH * 0.68);
      boardPath.lineTo(w - 4.0, boardH - 6.0);
    } else {
      boardPath.lineTo(w + plank1Out * 0.6, boardH * 0.26);
      boardPath.lineTo(w - plank2In * 1.15, boardH * 0.33);
      boardPath.lineTo(w + plank1Out * 0.7, boardH * 0.43);
      boardPath.lineTo(w - 2.0, rightNotchY - 7);
      boardPath.lineTo(w - 11.0 - _hash(14) * 5.0, rightNotchY);
      boardPath.lineTo(w - 1.5, rightNotchY + 8);
      boardPath.lineTo(w - 3.5, boardH - 7.0);
    }

    // Bottom edge — deep weathered V-split crack
    boardPath.lineTo(w - 11.0, boardH - 1.5);
    boardPath.lineTo(bottomSplitX + 7, boardH - 2.5);
    boardPath.lineTo(bottomSplitX, boardH - 11.0);
    boardPath.lineTo(bottomSplitX - 6, boardH - 1.5);
    boardPath.lineTo(10.0, boardH - 2.0);
    boardPath.lineTo(2.0, boardH - 8.5);

    // Left edge — torn plank steps + V-crack notch
    boardPath.lineTo(0.5, leftNotchY + 9);
    boardPath.lineTo(10.0 + _hash(15) * 5.0, leftNotchY + 1);
    boardPath.lineTo(0.0, leftNotchY - 7);
    boardPath.lineTo(5.0, boardH * 0.25);
    if (!brokenRightTop) {
      boardPath.lineTo(1.5, chipY);
    }
    boardPath.close();

    // Soft ambient shadow cast by broken wood board
    canvas.drawPath(
      boardPath.shift(const Offset(4, 8)),
      Paint()
        ..color = const Color(0x5A020817)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // Rich dark aged oak / pine planks fill directly behind lettering (NO gray rectangle box!)
    final boardRect = Rect.fromLTWH(0, 0, w + arrowTipOut, boardH);
    canvas.drawPath(
      boardPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFF472A18), const Color(0xFF663E24), dayFactor)!,
            Color.lerp(const Color(0xFF341E11), const Color(0xFF4E2E1A), dayFactor)!,
            Color.lerp(const Color(0xFF24130A), const Color(0xFF392011), dayFactor)!,
          ],
        ).createShader(boardRect),
    );

    // Clip inner wood grain, deep horizontal plank splits, knots & forged nails
    canvas.save();
    canvas.clipPath(boardPath);

    // Alternating subtle plank shade bands so horizontal planks read distinctly
    for (int p = 0; p < 3; p++) {
      final py = boardH * (p / 3.0);
      final ph = boardH / 3.0;
      canvas.drawRect(
        Rect.fromLTWH(0, py, w + arrowTipOut, ph),
        Paint()
          ..color = p.isEven
              ? const Color(0x16FFFFFF)
              : const Color(0x1C000000),
      );
    }

    // Horizontal split plank seams + bevel highlights
    final splitPaint = Paint()
      ..color = const Color(0xCC120803)
      ..strokeWidth = 2.6;
    final splitHighlight = Paint()
      ..color = const Color(0x3DB98B63)
      ..strokeWidth = 1.2;
    for (final frac in [0.33, 0.67]) {
      final sy = boardH * frac + (_hash((frac * 10).round()) - 0.5) * 4.5;
      final seam = Path()
        ..moveTo(0, sy)
        ..quadraticBezierTo(w * 0.35, sy + 2.8, w * 0.72, sy - 1.8)
        ..lineTo(w + arrowTipOut + 6, sy + 1.2);
      canvas.drawPath(seam, splitPaint);
      canvas.drawPath(seam.shift(const Offset(0, 1.8)), splitHighlight);
    }

    // Fine wavy wood grain striations
    final grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = const Color(0x36140803);
    for (int g = 0; g < 9; g++) {
      final gy = 8.0 + (g / 9.0) * (boardH - 14.0);
      final wave = (_hash(20 + g) - 0.5) * 6.5;
      canvas.drawPath(
        Path()
          ..moveTo(0, gy)
          ..cubicTo(w * 0.3, gy + wave, w * 0.65, gy - wave, w + arrowTipOut + 6, gy),
        grainPaint,
      );
    }

    // Deep charred wood knot + crack radiate
    final knotPos = Offset(w * (0.18 + _hash(30) * 0.62), boardH * (0.20 + _hash(31) * 0.58));
    canvas.drawOval(
      Rect.fromCenter(center: knotPos, width: 16, height: 9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0x55120803),
    );
    canvas.drawOval(
      Rect.fromCenter(center: knotPos, width: 7, height: 4),
      Paint()..color = const Color(0x45120803),
    );

    // Subtle dark burnt edge vignette inside timber perimeter (keeps ivory typography ultra-crisp)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w + arrowTipOut, boardH),
      Paint()..color = const Color(0x280E0703),
    );

    canvas.restore();

    // Rugged outer edge bevel
    canvas.drawPath(
      boardPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xAA1A0D06),
    );

    // Forged dark-iron nail heads at corners
    final nailPaint = Paint()..color = const Color(0xFF1E2229);
    final nailHighlight = Paint()..color = const Color(0x6694A3B8);
    for (final np in [
      Offset(12, 14),
      Offset(w - 16, 15),
      Offset(12, boardH - 13),
      Offset(w - 13, boardH - 14),
    ]) {
      canvas.drawCircle(np, 2.7, nailPaint);
      canvas.drawCircle(np.translate(-0.7, -0.7), 0.9, nailHighlight);
    }

    // 3. Organic fluffy snow blanket piled unevenly along broken top rim
    final snowMain = Color.lerp(const Color(0xFFD6E9FA), Colors.white, dayFactor)!;
    final snowShade = Color.lerp(const Color(0xFF8BB2D8), const Color(0xFFCDE2F6), dayFactor)!;
    final snowPath = Path()
      ..moveTo(4, 3)
      ..quadraticBezierTo(w * 0.14, -6, w * 0.28, -1)
      ..quadraticBezierTo(w * 0.45, -7, w * 0.62, -2)
      ..quadraticBezierTo(w * 0.80, -6, w - (brokenRightTop ? chipX : 4), 2)
      ..quadraticBezierTo(w - 8, 9, w - 16, 5)
      ..quadraticBezierTo(w * 0.68, 9, w * 0.50, 5)
      ..quadraticBezierTo(w * 0.28, 10, 10, 6)
      ..close();
    canvas.drawPath(snowPath.shift(const Offset(0, 1.5)), Paint()..color = snowShade);
    canvas.drawPath(snowPath, Paint()..color = snowMain);

    // Small translucent icicles hanging beneath lower edges
    final iciclePaint = Paint()
      ..color = Color.lerp(
        const Color(0x99BAE6FD),
        const Color(0xBBFFFFFF),
        dayFactor,
      )!;
    for (int i = 0; i < 3; i++) {
      final ix = w * (0.18 + i * 0.31);
      final ilen = 7.0 + _hash(40 + i) * 7.0;
      final ip = Path()
        ..moveTo(ix - 2.2, boardH - 2)
        ..lineTo(ix + 2.2, boardH - 2)
        ..lineTo(ix, boardH - 2 + ilen)
        ..close();
      canvas.drawPath(ip, iciclePaint);
    }

    // Warm miniature hanging lantern on main section boards
    if (isMainBoard) {
      final twinkle = 0.78 + 0.22 * math.sin(elapsed * 3.0 + seed);
      final lanternPos = Offset(w - 6.0, 22.0);
      canvas.drawCircle(
        lanternPos,
        15,
        Paint()
          ..color = ChristmasThemeConfig.warmLanternAmber
              .withValues(alpha: (1 - dayFactor * 0.55) * 0.38 * twinkle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawPath(
        Path()
          ..moveTo(w - 10, 8)
          ..quadraticBezierTo(w - 4, 8, w - 6, 16),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFF1E293B),
      );
      canvas.drawOval(
        Rect.fromCenter(center: lanternPos, width: 9, height: 12),
        Paint()..color = Color(0xFFFFD56B).withValues(alpha: twinkle),
      );
    }
  }

  void _paintCrookedPost(
    Canvas canvas, {
    required Offset topCenter,
    required double bottomY,
    required double topWidth,
    required double bottomWidth,
    required double tilt,
    required Color woodColor,
    required Color shadowColor,
  }) {
    final bx = topCenter.dx + tilt;
    final postPath = Path()
      ..moveTo(topCenter.dx - topWidth * 0.5, topCenter.dy)
      ..lineTo(topCenter.dx + topWidth * 0.5, topCenter.dy)
      ..lineTo(bx + bottomWidth * 0.5, bottomY - 2)
      ..lineTo(bx - bottomWidth * 0.5, bottomY - 2)
      ..close();

    canvas.drawPath(postPath, Paint()..color = woodColor);
    canvas.drawLine(
      Offset(topCenter.dx + topWidth * 0.18, topCenter.dy),
      Offset(bx + bottomWidth * 0.18, bottomY - 2),
      Paint()
        ..color = shadowColor.withValues(alpha: 0.65)
        ..strokeWidth = 2.0,
    );

    // Snow collar heaped where the timber enters the ground
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bx, bottomY - 2),
        width: bottomWidth * 2.1,
        height: 11,
      ),
      Paint()
        ..color = Color.lerp(
          const Color(0xFFCDE2F6),
          const Color(0xFFFFFFFF),
          dayFactor,
        )!,
    );
  }

  @override
  bool shouldRepaint(covariant RusticBrokenWoodBoardPainter oldDelegate) =>
      oldDelegate.dayFactor != dayFactor ||
      oldDelegate.seed != seed ||
      oldDelegate.elapsed != elapsed;
}

/// Painterly articulated 2D Santa Claus with wool greatcoat, curly shearling
/// fleece trim, belted waist, articulated bent-knee boots, draped fur cap,
/// flowing beard, cinched gift pack, and glowing brass carriage lantern.
class SantaCharacterPainter extends CustomPainter {
  const SantaCharacterPainter({
    required this.walkPhase,
    required this.isMoving,
    required this.facingRight,
    required this.dayFactor,
    required this.elapsed,
  });

  final double walkPhase;
  final bool isMoving;
  final bool facingRight;
  final double dayFactor;
  final double elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final footY = size.height - 9.0;

    final stride = isMoving ? math.sin(walkPhase) * 0.46 : 0.0;
    final bob = isMoving
        ? math.sin(walkPhase).abs() * -4.8
        : math.sin(elapsed * 2.1) * 1.2;

    // Ground cast shadow & warm lantern reflection pool on snow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, footY + 3), width: 72, height: 15),
      Paint()
        ..color = Color.lerp(
          const Color(0x6B051123),
          const Color(0x421D3557),
          dayFactor,
        )!,
    );
    if (dayFactor < 0.88) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + (facingRight ? 28 : -28), footY + 3),
          width: 90,
          height: 24,
        ),
        Paint()
          ..color = ChristmasThemeConfig.warmLanternAmber
              .withValues(alpha: (1.0 - dayFactor) * 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    canvas.save();
    canvas.translate(cx, footY + bob);
    canvas.scale(facingRight ? 1.0 : -1.0, 1.0);

    const coatRed = Color(0xFFB51B2C);
    const coatDeep = Color(0xFF750E1C);
    const coatHighlight = Color(0xFFD62B3D);
    const furMain = Color(0xFFF6F8FC);
    const furShadow = Color(0xFFC9D8EA);
    const leatherDark = Color(0xFF1F1612);
    const burlapMain = Color(0xFF8C5B36);
    const burlapShade = Color(0xFF5D3A20);

    // 1. Cinched Burlap Toy Sack slung over rear shoulder (-X)
    canvas.save();
    canvas.rotate(isMoving ? math.sin(walkPhase * 2) * 0.05 : 0.0);
    final sack = Path()
      ..moveTo(-7, -58)
      ..cubicTo(-30, -68, -42, -38, -28, -20)
      ..quadraticBezierTo(-13, -15, -6, -34)
      ..close();
    canvas.drawPath(
      sack,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [burlapMain, burlapShade],
        ).createShader(const Rect.fromLTWH(-42, -68, 38, 52)),
    );
    // Wrapped crimson gift corner peeking from sack opening
    canvas.drawPath(
      Path()
        ..moveTo(-18, -62)
        ..lineTo(-27, -71)
        ..lineTo(-14, -75)
        ..lineTo(-9, -63)
        ..close(),
      Paint()..color = const Color(0xFF0E7490),
    );
    // Hemp rope tie around sack neck
    canvas.drawLine(
      const Offset(-14, -60),
      const Offset(-8, -56),
      Paint()
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFD4A373),
    );
    canvas.restore();

    // 2. Articulated Striding Legs & Sculpted Leather Winter Boots
    _drawArticulatedLegAndBoot(
      canvas,
      hip: const Offset(-7, -27),
      swingAngle: -stride,
      isFront: false,
      furMain: furMain,
      furShadow: furShadow,
      bootColor: leatherDark,
    );
    _drawArticulatedLegAndBoot(
      canvas,
      hip: const Offset(7, -27),
      swingAngle: stride,
      isFront: true,
      furMain: furMain,
      furShadow: furShadow,
      bootColor: leatherDark,
    );

    // 3. Rear Sleeve & Mitten gripping sack strap
    canvas.save();
    canvas.translate(-10, -58);
    canvas.rotate(-stride * 0.32 + 0.24);
    final backSleeve = Path()
      ..moveTo(-5, 0)
      ..quadraticBezierTo(-7, 13, -4, 24)
      ..lineTo(5, 24)
      ..quadraticBezierTo(6, 12, 4, 0)
      ..close();
    canvas.drawPath(backSleeve, Paint()..color = coatDeep);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 27), width: 10, height: 11),
      Paint()..color = leatherDark,
    );
    canvas.restore();

    // 4. Tailored Flared Winter Greatcoat with Fabric Creases
    final flareLag = isMoving ? -stride * 4.5 : 0.0;
    final greatcoat = Path()
      ..moveTo(-15, -66)
      ..quadraticBezierTo(0, -69, 15, -66)
      ..cubicTo(19, -50, 22, -32, 21 + flareLag * 0.4, -19)
      ..quadraticBezierTo(0, -15, -22 + flareLag, -20)
      ..cubicTo(-22, -35, -18, -51, -15, -66)
      ..close();
    canvas.drawPath(
      greatcoat,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [coatHighlight, coatRed, coatDeep],
        ).createShader(const Rect.fromLTWH(-24, -68, 48, 52)),
    );

    // Curly overlapping shearling fur hem along coat bottom (no flat rectangle!)
    _drawWoolTufts(
      canvas,
      points: [
        Offset(-19 + flareLag, -19),
        Offset(-11 + flareLag * 0.8, -18),
        Offset(-3 + flareLag * 0.5, -17.5),
        Offset(5 + flareLag * 0.3, -17.5),
        Offset(13 + flareLag * 0.2, -18),
        Offset(19 + flareLag * 0.2, -19.5),
      ],
      radius: 5.2,
      furMain: furMain,
      furShadow: furShadow,
    );

    // Sculpted wide curved leather belt & brass buckle
    final belt = Path()
      ..moveTo(-18, -42)
      ..quadraticBezierTo(0, -39, 19, -42)
      ..lineTo(19, -35)
      ..quadraticBezierTo(0, -32, -19, -35)
      ..close();
    canvas.drawPath(belt, Paint()..color = leatherDark);
    canvas.drawPath(
      Path()
        ..moveTo(2, -43)
        ..lineTo(12, -43)
        ..lineTo(12, -34)
        ..lineTo(2, -34)
        ..close(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..color = ChristmasThemeConfig.champagneGold,
    );

    // Fur shawl cape collar around shoulders
    _drawWoolTufts(
      canvas,
      points: const [
        Offset(-14, -64),
        Offset(-7, -62),
        Offset(0, -61),
        Offset(8, -62),
        Offset(14, -64),
      ],
      radius: 5.0,
      furMain: furMain,
      furShadow: furShadow,
    );

    // 5. Detailed Head, Winter Complexion, Flowing Wavy Beard & Drooping Hat
    // Face oval with subtle shading
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(2, -77), width: 22, height: 24),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.3, -0.2),
          colors: [Color(0xFFFAD2B8), Color(0xFFE7A98B)],
        ).createShader(const Rect.fromLTWH(-10, -90, 24, 26)),
    );
    // Cheek flush, nose bridge & expressive eye
    canvas.drawCircle(const Offset(8, -74), 3.4, Paint()..color = const Color(0x55E11D48));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(12.5, -77.5), width: 5.5, height: 4.5),
      Paint()..color = const Color(0xFFF09986),
    );
    canvas.drawCircle(const Offset(8.5, -80.5), 1.5, Paint()..color = const Color(0xFF1E293B));
    // Silver eyebrow
    canvas.drawLine(
      const Offset(5.5, -83.5),
      const Offset(11.5, -83),
      Paint()
        ..color = furMain
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Sculpted curly overlapping beard locks flowing over chest
    final beardSway = isMoving ? -stride * 2.5 : 0.0;
    final beardPath = Path()
      ..moveTo(-9, -76)
      ..quadraticBezierTo(-11, -60, -5 + beardSway, -51)
      ..quadraticBezierTo(-1, -46, 3 + beardSway, -49)
      ..quadraticBezierTo(8 + beardSway, -46, 13, -53)
      ..quadraticBezierTo(16, -64, 13, -75)
      ..quadraticBezierTo(5, -71, -9, -76)
      ..close();
    canvas.drawPath(beardPath.shift(const Offset(0, 1.5)), Paint()..color = furShadow);
    canvas.drawPath(beardPath, Paint()..color = furMain);

    // Flowing handlebar mustache
    final mustache = Path()
      ..moveTo(6, -75)
      ..cubicTo(0, -76, -3, -70, 2, -68)
      ..quadraticBezierTo(7, -70, 12, -71)
      ..quadraticBezierTo(16, -72, 13, -75)
      ..close();
    canvas.drawPath(mustache, Paint()..color = Colors.white);

    // Velvet Stocking Hat curving back organically with S-drape & pom-pom
    final hatTipLag = isMoving ? -stride * 6.5 - 5.0 : 0.0;
    final cap = Path()
      ..moveTo(-11, -85)
      ..cubicTo(-8, -104, 4, -107, 13, -97)
      ..cubicTo(18 + hatTipLag * 0.5, -91, 18 + hatTipLag, -84, 15 + hatTipLag, -80)
      ..quadraticBezierTo(11, -82, 12, -85)
      ..close();
    canvas.drawPath(
      cap,
      Paint()
        ..shader = const LinearGradient(
          colors: [coatHighlight, coatDeep],
        ).createShader(const Rect.fromLTWH(-12, -108, 32, 30)),
    );
    // Fluffy scalloped hat brim
    _drawWoolTufts(
      canvas,
      points: const [
        Offset(-11, -85),
        Offset(-4, -86),
        Offset(3, -86),
        Offset(10, -85),
      ],
      radius: 4.4,
      furMain: furMain,
      furShadow: furShadow,
    );
    // Pom-pom
    canvas.drawCircle(Offset(15 + hatTipLag, -79), 4.6, Paint()..color = furShadow);
    canvas.drawCircle(Offset(14.5 + hatTipLag, -80), 4.2, Paint()..color = Colors.white);

    // 6. Lead Arm holding Ornate Hexagonal Glass Carriage Lantern
    canvas.save();
    canvas.translate(9, -60);
    canvas.rotate(stride * 0.35 - 0.42);
    final frontSleeve = Path()
      ..moveTo(-5, 0)
      ..quadraticBezierTo(8, 10, 6, 22)
      ..lineTo(-3, 23)
      ..quadraticBezierTo(-5, 11, -5, 0)
      ..close();
    canvas.drawPath(frontSleeve, Paint()..color = coatRed);
    _drawWoolTufts(
      canvas,
      points: const [Offset(-2, 22), Offset(2, 22), Offset(6, 21)],
      radius: 3.4,
      furMain: furMain,
      furShadow: furShadow,
    );
    // Padded leather mitten
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(2, 27), width: 9, height: 9),
      Paint()..color = leatherDark,
    );

    // Ornate Brass & Forged Iron Carriage Lantern
    final swing = isMoving ? stride * 0.25 : math.sin(elapsed * 2.0) * 0.05;
    canvas.save();
    canvas.translate(2, 30);
    canvas.rotate(swing);
    canvas.drawLine(
      Offset.zero,
      const Offset(0, 6),
      Paint()
        ..strokeWidth = 1.6
        ..color = const Color(0xFF475569),
    );
    canvas.drawCircle(
      const Offset(0, 14),
      16,
      Paint()
        ..color = ChristmasThemeConfig.warmLanternAmber.withValues(alpha: 0.46)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Tapered glass lantern housing
    final glassBody = Path()
      ..moveTo(-5.5, 8)
      ..lineTo(5.5, 8)
      ..lineTo(4.2, 21)
      ..lineTo(-4.2, 21)
      ..close();
    canvas.drawPath(glassBody, Paint()..color = const Color(0xFFFFD873));
    canvas.drawPath(
      glassBody,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF1E293B),
    );
    // Peaked iron hood cap & base
    canvas.drawPath(
      Path()
        ..moveTo(-7, 8)
        ..lineTo(0, 3)
        ..lineTo(7, 8)
        ..close(),
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawLine(
      const Offset(-5, 21),
      const Offset(5, 21),
      Paint()
        ..strokeWidth = 2.2
        ..color = const Color(0xFF1E293B),
    );
    canvas.restore();

    canvas.restore();
    canvas.restore();
  }

  void _drawWoolTufts(
    Canvas canvas, {
    required List<Offset> points,
    required double radius,
    required Color furMain,
    required Color furShadow,
  }) {
    final shadePaint = Paint()..color = furShadow;
    final mainPaint = Paint()..color = furMain;
    for (final p in points) {
      canvas.drawCircle(p.translate(0, 1.2), radius, shadePaint);
    }
    for (final p in points) {
      canvas.drawCircle(p, radius * 0.94, mainPaint);
    }
  }

  void _drawArticulatedLegAndBoot(
    Canvas canvas, {
    required Offset hip,
    required double swingAngle,
    required bool isFront,
    required Color furMain,
    required Color furShadow,
    required Color bootColor,
  }) {
    canvas.save();
    canvas.translate(hip.dx, hip.dy);
    canvas.rotate(swingAngle);

    // Tapered woolen trouser thigh -> bent knee
    final kneeBend = isFront ? math.max(0.0, -swingAngle) * 0.6 : math.max(0.0, swingAngle) * 0.5;
    final trouser = Path()
      ..moveTo(-5.5, 0)
      ..lineTo(5.5, 0)
      ..lineTo(4.2, 13)
      ..lineTo(-4.5, 13)
      ..close();
    canvas.drawPath(
      trouser,
      Paint()..color = isFront ? const Color(0xFF9A1624) : const Color(0xFF6B0C18),
    );

    canvas.translate(0, 12);
    canvas.rotate(kneeBend);

    // Sculpted knee-high winter leather boot with heel & curved toe vamp
    final boot = Path()
      ..moveTo(-4.6, 0)
      ..lineTo(4.6, 0)
      ..lineTo(4.8, 10)
      ..quadraticBezierTo(10.5, 11.5, 11.0, 15.0)
      ..lineTo(4.5, 15.5)
      ..lineTo(1.5, 15.0)
      ..lineTo(-4.8, 15.5)
      ..lineTo(-5.2, 11.0)
      ..close();
    canvas.drawPath(boot, Paint()..color = bootColor);

    // Boot cuff fur trim
    canvas.drawCircle(const Offset(-2, 0.5), 3.0, Paint()..color = furShadow);
    canvas.drawCircle(const Offset(2.5, 0.5), 3.0, Paint()..color = furMain);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SantaCharacterPainter oldDelegate) => true;
}
