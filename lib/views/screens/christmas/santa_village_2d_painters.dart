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

/// Articulated 2D Santa Claus character carrying a gift sack & glowing brass
/// lantern, walking forward or backward cleanly along the snowy trail.
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
    final footY = size.height - 8.0;

    final stride = isMoving ? math.sin(walkPhase) * 0.52 : 0.0;
    final bob = isMoving
        ? math.sin(walkPhase).abs() * -4.2
        : math.sin(elapsed * 2.2) * 1.1;

    // Warm lantern ground pool below Santa
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, footY + 2), width: 66, height: 14),
      Paint()
        ..color = Color.lerp(
          const Color(0x66061224),
          const Color(0x401E3A5F),
          dayFactor,
        )!,
    );
    if (dayFactor < 0.85) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + (facingRight ? 24 : -24), footY + 2),
          width: 78,
          height: 20,
        ),
        Paint()
          ..color = ChristmasThemeConfig.warmLanternAmber
              .withValues(alpha: (1.0 - dayFactor) * 0.34)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    canvas.save();
    canvas.translate(cx, footY + bob);
    canvas.scale(facingRight ? 1.0 : -1.0, 1.0);

    final coatRed = const Color(0xFFB91C2E);
    final coatShadow = const Color(0xFF7F1120);
    final furWhite = const Color(0xFFF8FAFC);
    final beltLeather = const Color(0xFF1F1612);
    final bootBlack = const Color(0xFF1A191B);
    final sackBrown = const Color(0xFF8C5B37);

    // 1. Weathered Gift Sack slung over back shoulder (-X)
    canvas.save();
    canvas.rotate(isMoving ? math.sin(walkPhase * 2) * 0.04 : 0.0);
    final sackPath = Path()
      ..moveTo(-6, -48)
      ..cubicTo(-28, -56, -34, -28, -24, -18)
      ..quadraticBezierTo(-10, -14, -4, -30)
      ..close();
    canvas.drawPath(sackPath, Paint()..color = sackBrown);
    canvas.drawPath(
      sackPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF5C3A21),
    );
    canvas.restore();

    // 2. Articulated Striding Boots
    _drawBoot(canvas, offset: Offset(-6, -24), angle: -stride, bootColor: bootBlack);
    _drawBoot(canvas, offset: Offset(6, -24), angle: stride, bootColor: bootBlack);

    // 3. Back Arm holding Sack Strap
    canvas.save();
    canvas.translate(-8, -50);
    canvas.rotate(-stride * 0.35 + 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 0, 10, 22), const Radius.circular(5)),
      Paint()..color = coatShadow,
    );
    canvas.drawCircle(const Offset(0, 23), 4.5, Paint()..color = beltLeather);
    canvas.restore();

    // 4. Crimson Greatcoat & Plush Fur Hem
    final coat = Path()
      ..moveTo(-14, -56)
      ..lineTo(14, -56)
      ..quadraticBezierTo(20, -34, 18, -18)
      ..lineTo(-18, -18)
      ..quadraticBezierTo(-19, -34, -14, -56)
      ..close();
    canvas.drawPath(
      coat,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [coatRed, coatShadow],
        ).createShader(const Rect.fromLTWH(-20, -56, 40, 40)),
    );

    // Coat Fur Trim Hem
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-19, -22, 38, 7), const Radius.circular(3.5)),
      Paint()..color = furWhite,
    );

    // Leather Belt + Brushed Gold Buckle
    canvas.drawRect(const Rect.fromLTWH(-17, -37, 34, 6), Paint()..color = beltLeather);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(2, -38.5, 9, 9), const Radius.circular(2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = ChristmasThemeConfig.champagneGold,
    );

    // 5. Shaded Winter Face, Flowing Mustache & Beard
    canvas.drawCircle(const Offset(2, -66), 11.5, Paint()..color = const Color(0xFFF6C7AA));

    // Rosy cheek + gentle eye
    canvas.drawCircle(
      const Offset(7, -64),
      3.0,
      Paint()..color = const Color(0x66E11D48),
    );
    canvas.drawCircle(const Offset(7.5, -67.5), 1.4, Paint()..color = const Color(0xFF1E293B));

    // Sculpted layered Beard
    final beard = Path()
      ..moveTo(-7, -63)
      ..quadraticBezierTo(-8, -46, 3, -44)
      ..quadraticBezierTo(15, -46, 13, -62)
      ..quadraticBezierTo(5, -59, -7, -63)
      ..close();
    canvas.drawPath(beard, Paint()..color = furWhite);

    // Mustache
    final mustache = Path()
      ..moveTo(4, -63)
      ..quadraticBezierTo(-3, -60, -2, -57)
      ..quadraticBezierTo(5, -58, 12, -58)
      ..quadraticBezierTo(13, -61, 7, -63)
      ..close();
    canvas.drawPath(mustache, Paint()..color = Colors.white);

    // Fur-trimmed Drooping Cap & Pom-Pom trailing with movement
    final pomLag = isMoving ? -stride * 5.0 - 4.0 : 0.0;
    final cap = Path()
      ..moveTo(-10, -73)
      ..quadraticBezierTo(-6, -90, 2, -88)
      ..quadraticBezierTo(12, -86, 12 + pomLag, -77)
      ..lineTo(12, -73)
      ..close();
    canvas.drawPath(cap, Paint()..color = coatRed);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -76, 25, 6), const Radius.circular(3)),
      Paint()..color = furWhite,
    );
    canvas.drawCircle(Offset(13 + pomLag, -76), 4.0, Paint()..color = Colors.white);

    // 6. Front Arm + Glowing Brass Lantern
    canvas.save();
    canvas.translate(8, -50);
    canvas.rotate(stride * 0.45 - 0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4.5, 0, 9.5, 22), const Radius.circular(4.5)),
      Paint()..color = coatRed,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 17, 10, 4.5), const Radius.circular(2)),
      Paint()..color = furWhite,
    );
    canvas.drawCircle(const Offset(0, 24), 4.2, Paint()..color = beltLeather);

    // Warm Hanging Brass Lantern
    final lx = 2.0;
    final ly = 26.0;
    canvas.drawLine(Offset(0, 24), Offset(lx, ly + 4), Paint()..strokeWidth = 1.5..color = const Color(0xFF94A3B8));
    canvas.drawCircle(
      Offset(lx, ly + 11),
      14,
      Paint()
        ..color = ChristmasThemeConfig.warmLanternAmber.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(lx, ly + 11), width: 10, height: 13), const Radius.circular(2)),
      Paint()..color = const Color(0xFFFFD56B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(lx, ly + 11), width: 10, height: 13), const Radius.circular(2)),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = const Color(0xFF334155),
    );
    canvas.restore();

    canvas.restore();
  }

  void _drawBoot(
    Canvas canvas, {
    required Offset offset,
    required double angle,
    required Color bootColor,
  }) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle);
    // Trouser leg + leather boot
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4.5, 0, 9, 14), const Radius.circular(3)),
      Paint()..color = const Color(0xFF7F1120),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4.5, 12, 12, 11), const Radius.circular(3.5)),
      Paint()..color = bootColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SantaCharacterPainter oldDelegate) => true;
}
