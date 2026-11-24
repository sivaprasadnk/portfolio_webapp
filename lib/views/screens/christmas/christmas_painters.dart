import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spnk/views/screens/christmas/christmas_theme_config.dart';

class SnowflakeParticle {
  SnowflakeParticle({
    required this.xFrac,
    required this.yFrac,
    required this.radius,
    required this.speed,
    required this.driftPhase,
    required this.driftAmp,
    required this.alpha,
  });

  double xFrac;
  double yFrac;
  final double radius;
  final double speed;
  final double driftPhase;
  final double driftAmp;
  final double alpha;
}

class CursorSnowflake {
  CursorSnowflake({
    required this.position,
    required this.birthTime,
    required this.velocity,
    required this.size,
  });

  final Offset position;
  final double birthTime;
  final Offset velocity;
  final double size;
}

class SnowfallSimulation {
  final List<SnowflakeParticle> flakes = [];
  final List<CursorSnowflake> cursorTrail = [];
  bool _initialized = false;

  void ensureInitialized({int count = 68}) {
    if (_initialized) return;
    _initialized = true;
    final rng = math.Random(20261225);
    for (int i = 0; i < count; i++) {
      flakes.add(
        SnowflakeParticle(
          xFrac: rng.nextDouble(),
          yFrac: rng.nextDouble(),
          radius: 1.2 + rng.nextDouble() * 2.8,
          speed: 0.025 + rng.nextDouble() * 0.055,
          driftPhase: rng.nextDouble() * math.pi * 2,
          driftAmp: 0.008 + rng.nextDouble() * 0.018,
          alpha: 0.28 + rng.nextDouble() * 0.58,
        ),
      );
    }
  }

  void step(double dt, double elapsed) {
    ensureInitialized();
    for (final f in flakes) {
      f.yFrac += f.speed * dt;
      if (f.yFrac > 1.04) {
        f.yFrac = -0.04;
      }
    }
    cursorTrail.removeWhere((c) => elapsed - c.birthTime > 0.85);
  }

  void addCursorFlake(Offset pos, double elapsed) {
    if (cursorTrail.isNotEmpty) {
      final last = cursorTrail.last;
      if ((pos - last.position).distance < 18 && elapsed - last.birthTime < 0.06) {
        return;
      }
    }
    final rng = math.Random((elapsed * 1000).toInt());
    cursorTrail.add(
      CursorSnowflake(
        position: pos,
        birthTime: elapsed,
        velocity: Offset((rng.nextDouble() - 0.5) * 26, 22 + rng.nextDouble() * 24),
        size: 3.5 + rng.nextDouble() * 3.5,
      ),
    );
    if (cursorTrail.length > 26) {
      cursorTrail.removeAt(0);
    }
  }
}

/// Paints the deep midnight winter sky, twinkling stars, snow-covered mountains,
/// silhouette pines, snowfall, cursor snowflake trail, and occasional Santa sleigh.
class ChristmasSkyAndSnowPainter extends CustomPainter {
  ChristmasSkyAndSnowPainter({
    required this.simulation,
    required this.elapsedSeconds,
    required this.snowEnabled,
    required this.reducedMotion,
  });

  final SnowfallSimulation simulation;
  final double elapsedSeconds;
  final bool snowEnabled;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Deep midnight-blue to forest-green night sky
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ChristmasThemeConfig.midnightBlue,
          ChristmasThemeConfig.deepNavy,
          Color(0xFF082019),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    // Subtle northern-lights radial glow
    final auroraGold = Paint()
      ..shader = RadialGradient(
        colors: [
          ChristmasThemeConfig.warmGold.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.78, size.height * 0.16),
          radius: size.width * 0.42,
        ),
      );
    canvas.drawRect(Offset.zero & size, auroraGold);

    final auroraEmerald = Paint()
      ..shader = RadialGradient(
        colors: [
          ChristmasThemeConfig.pineEmerald.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.20, size.height * 0.30),
          radius: size.width * 0.45,
        ),
      );
    canvas.drawRect(Offset.zero & size, auroraEmerald);

    // 2. Twinkling night stars
    final starRng = math.Random(42);
    final starPaint = Paint();
    for (int i = 0; i < 48; i++) {
      final sx = starRng.nextDouble() * size.width;
      final sy = starRng.nextDouble() * (size.height * 0.58);
      final baseR = 0.8 + starRng.nextDouble() * 1.4;
      final phase = starRng.nextDouble() * math.pi * 2;
      final twinkle = reducedMotion
          ? 0.65
          : (0.35 + 0.65 * (0.5 + 0.5 * math.sin(elapsedSeconds * 2.1 + phase)));
      starPaint.color = (i % 5 == 0
              ? ChristmasThemeConfig.champagneGold
              : ChristmasThemeConfig.snowWhite)
          .withValues(alpha: twinkle * 0.7);
      canvas.drawCircle(Offset(sx, sy), baseR, starPaint);
    }

    // 3. Distant snow-covered mountain ridge near bottom of viewport
    final mountainBaseY = size.height * 0.90;
    final mountainPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, mountainBaseY)
      ..lineTo(size.width * 0.14, mountainBaseY - 64)
      ..lineTo(size.width * 0.28, mountainBaseY - 12)
      ..lineTo(size.width * 0.46, mountainBaseY - 88)
      ..lineTo(size.width * 0.64, mountainBaseY - 22)
      ..lineTo(size.width * 0.82, mountainBaseY - 76)
      ..lineTo(size.width, mountainBaseY - 26)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      mountainPath,
      Paint()..color = const Color(0xFF0A1D2B).withValues(alpha: 0.72),
    );

    // Snow caps along mountain peaks
    final capPaint = Paint()
      ..color = ChristmasThemeConfig.icyBlue.withValues(alpha: 0.14);
    for (final peak in [
      Offset(size.width * 0.14, mountainBaseY - 64),
      Offset(size.width * 0.46, mountainBaseY - 88),
      Offset(size.width * 0.82, mountainBaseY - 76),
    ]) {
      final cap = Path()
        ..moveTo(peak.dx, peak.dy)
        ..lineTo(peak.dx - 38, peak.dy + 28)
        ..lineTo(peak.dx + 42, peak.dy + 28)
        ..close();
      canvas.drawPath(cap, capPaint);
    }

    // 4. Occasional animated Santa sleigh passing across the top sky (every 26s)
    if (!reducedMotion) {
      final cycle = elapsedSeconds % 26.0;
      if (cycle < 9.5) {
        final t = cycle / 9.5;
        final sleighX = -160.0 + (size.width + 320.0) * t;
        final sleighY = 72.0 + math.sin(t * math.pi * 2) * 14.0;
        _drawSantaSleigh(canvas, Offset(sleighX, sleighY));
      }
    }

    // 5. Continuous lightweight snowfall
    if (snowEnabled && !reducedMotion) {
      final snowPaint = Paint();
      for (final f in simulation.flakes) {
        final driftX = math.sin(elapsedSeconds * 1.1 + f.driftPhase) * f.driftAmp;
        final px = ((f.xFrac + driftX) % 1.0) * size.width;
        final py = f.yFrac * size.height;
        snowPaint.color = ChristmasThemeConfig.snowWhite.withValues(alpha: f.alpha);
        canvas.drawCircle(Offset(px, py), f.radius, snowPaint);
      }

      // 6. Festive snowflake cursor trail
      for (final c in simulation.cursorTrail) {
        final age = (elapsedSeconds - c.birthTime).clamp(0.0, 0.85);
        final progress = age / 0.85;
        final alpha = (1.0 - progress) * 0.75;
        final pos = c.position + c.velocity * age;
        _drawMiniSnowflake(
          canvas,
          pos,
          c.size * (1.0 - progress * 0.35),
          ChristmasThemeConfig.icyBlue.withValues(alpha: alpha),
        );
      }
    }
  }

  void _drawMiniSnowflake(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final angle = i * math.pi / 3;
      final dx = math.cos(angle) * r;
      final dy = math.sin(angle) * r;
      canvas.drawLine(
        Offset(center.dx - dx, center.dy - dy),
        Offset(center.dx + dx, center.dy + dy),
        paint,
      );
    }
  }

  void _drawSantaSleigh(Canvas canvas, Offset origin) {
    final silhouette = Paint()
      ..color = ChristmasThemeConfig.champagneGold.withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = ChristmasThemeConfig.champagneGold.withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Sleigh runner & body
    final sleigh = Path()
      ..moveTo(origin.dx, origin.dy + 12)
      ..quadraticBezierTo(origin.dx + 16, origin.dy + 20, origin.dx + 34, origin.dy + 12)
      ..lineTo(origin.dx + 30, origin.dy)
      ..lineTo(origin.dx + 4, origin.dy + 3)
      ..close();
    canvas.drawPath(sleigh, silhouette);

    // Santa silhouette in sleigh
    canvas.drawCircle(Offset(origin.dx + 15, origin.dy - 3), 4.2, silhouette);

    // Reins + two stylized reindeer silhouettes ahead
    canvas.drawLine(
      Offset(origin.dx + 32, origin.dy + 4),
      Offset(origin.dx + 86, origin.dy + 2),
      stroke,
    );
    for (final rx in [origin.dx + 56, origin.dx + 82]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(rx, origin.dy + 4), width: 12, height: 6), silhouette);
      canvas.drawCircle(Offset(rx + 6, origin.dy - 1), 2.8, silhouette);
    }

    // Magic sparkle wake
    final sparkle = Paint()
      ..color = ChristmasThemeConfig.champagneGold.withValues(alpha: 0.30);
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(
        Offset(origin.dx - i * 11.0, origin.dy + 8 + (i % 2) * 3.0),
        (3.0 - i * 0.45).clamp(0.8, 3.0),
        sparkle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ChristmasSkyAndSnowPainter oldDelegate) =>
      oldDelegate.elapsedSeconds != elapsedSeconds ||
      oldDelegate.snowEnabled != snowEnabled ||
      oldDelegate.reducedMotion != reducedMotion;
}

/// 3D-shaded layered Christmas tree with glowing golden star topper, snow-dusted
/// branches, garland, glossy 3D ornaments, twinkling lights, and wrapped gifts.
class Christmas3DTreePainter extends CustomPainter {
  Christmas3DTreePainter({
    required this.elapsedSeconds,
    required this.reducedMotion,
    this.pointerOffset = Offset.zero,
  });

  final double elapsedSeconds;
  final bool reducedMotion;
  final Offset pointerOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2 + pointerOffset.dx * 6;
    final topY = size.height * 0.11;
    final treeHeight = size.height * 0.72;
    final baseY = topY + treeHeight;

    // Ground snow mound shadow
    final groundShadow = Paint()
      ..shader = RadialGradient(
        colors: [
          ChristmasThemeConfig.champagneGold.withValues(alpha: 0.22),
          ChristmasThemeConfig.icyBlue.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCenter(
          center: Offset(cx, baseY + 24),
          width: size.width * 0.85,
          height: 52,
        ),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY + 24),
        width: size.width * 0.82,
        height: 46,
      ),
      groundShadow,
    );

    // 3D wooden trunk
    final trunkRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, baseY + 10),
        width: size.width * 0.11,
        height: size.height * 0.09,
      ),
      const Radius.circular(6),
    );
    final trunkPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4A2511), Color(0xFF7C3F1D), Color(0xFF34180B)],
      ).createShader(trunkRect.outerRect);
    canvas.drawRRect(trunkRect, trunkPaint);

    // 4 overlapping 3D pine foliage tiers (bottom to top)
    final tiers = [
      (yTop: topY + treeHeight * 0.50, yBot: baseY, halfW: size.width * 0.40),
      (yTop: topY + treeHeight * 0.34, yBot: topY + treeHeight * 0.72, halfW: size.width * 0.33),
      (yTop: topY + treeHeight * 0.18, yBot: topY + treeHeight * 0.50, halfW: size.width * 0.26),
      (yTop: topY, yBot: topY + treeHeight * 0.30, halfW: size.width * 0.18),
    ];

    for (final tier in tiers) {
      // Drop shadow under each bough layer for 3D depth
      final shadowPath = Path()
        ..moveTo(cx, tier.yTop + 8)
        ..quadraticBezierTo(cx + tier.halfW * 0.55, tier.yBot + 2, cx + tier.halfW, tier.yBot + 8)
        ..quadraticBezierTo(cx, tier.yBot + 18, cx - tier.halfW, tier.yBot + 8)
        ..quadraticBezierTo(cx - tier.halfW * 0.55, tier.yBot + 2, cx, tier.yTop + 8)
        ..close();
      canvas.drawPath(
        shadowPath,
        Paint()..color = Colors.black.withValues(alpha: 0.35),
      );

      final tierPath = Path()
        ..moveTo(cx, tier.yTop)
        ..quadraticBezierTo(cx + tier.halfW * 0.52, tier.yBot - 6, cx + tier.halfW, tier.yBot)
        ..quadraticBezierTo(cx, tier.yBot + 14, cx - tier.halfW, tier.yBot)
        ..quadraticBezierTo(cx - tier.halfW * 0.52, tier.yBot - 6, cx, tier.yTop)
        ..close();

      final tierPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFF1F7A54),
            ChristmasThemeConfig.pineEmerald,
            ChristmasThemeConfig.darkForestGreen,
          ],
        ).createShader(Rect.fromLTRB(cx - tier.halfW, tier.yTop, cx + tier.halfW, tier.yBot));
      canvas.drawPath(tierPath, tierPaint);

      // Subtle snow frost highlights on branch edges
      final frostEdge = Paint()
        ..color = ChristmasThemeConfig.snowWhite.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final frostPath = Path()
        ..moveTo(cx - tier.halfW * 0.92, tier.yBot - 2)
        ..quadraticBezierTo(cx, tier.yBot + 11, cx + tier.halfW * 0.92, tier.yBot - 2);
      canvas.drawPath(frostPath, frostEdge);
    }

    // Golden tinsel garlands
    final garlandPaint = Paint()
      ..color = ChristmasThemeConfig.champagneGold.withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (final frac in [0.28, 0.50, 0.72]) {
      final gy = topY + treeHeight * frac;
      final span = size.width * (0.13 + frac * 0.27);
      final garland = Path()
        ..moveTo(cx - span, gy - 6)
        ..quadraticBezierTo(cx, gy + 16, cx + span, gy - 2);
      canvas.drawPath(garland, garlandPaint);
    }

    // Glossy 3D ornaments + twinkling bulbs
    final ornamentData = [
      (dx: -0.09, dy: 0.24, c: ChristmasThemeConfig.crimsonGlow, r: 7.5),
      (dx: 0.08, dy: 0.30, c: ChristmasThemeConfig.champagneGold, r: 7.0),
      (dx: -0.17, dy: 0.45, c: ChristmasThemeConfig.icyBlue, r: 8.5),
      (dx: 0.02, dy: 0.48, c: ChristmasThemeConfig.crimsonGlow, r: 8.0),
      (dx: 0.16, dy: 0.52, c: ChristmasThemeConfig.champagneGold, r: 8.0),
      (dx: -0.22, dy: 0.69, c: ChristmasThemeConfig.champagneGold, r: 9.0),
      (dx: -0.05, dy: 0.73, c: ChristmasThemeConfig.icyBlue, r: 8.5),
      (dx: 0.13, dy: 0.71, c: ChristmasThemeConfig.crimsonGlow, r: 9.0),
      (dx: 0.26, dy: 0.80, c: ChristmasThemeConfig.champagneGold, r: 8.0),
      (dx: -0.27, dy: 0.86, c: ChristmasThemeConfig.crimsonGlow, r: 8.5),
      (dx: 0.05, dy: 0.88, c: ChristmasThemeConfig.champagneGold, r: 9.0),
    ];

    for (int i = 0; i < ornamentData.length; i++) {
      final o = ornamentData[i];
      final pos = Offset(cx + size.width * o.dx, topY + treeHeight * o.dy);
      final pulse = reducedMotion
          ? 0.85
          : 0.55 + 0.45 * math.sin(elapsedSeconds * 3.0 + i * 0.9);

      // Ambient halo
      canvas.drawCircle(
        pos,
        o.r * 1.9,
        Paint()..color = o.c.withValues(alpha: 0.24 * pulse),
      );
      // 3D sphere shading
      canvas.drawCircle(
        pos,
        o.r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.35),
            colors: [
              Colors.white.withValues(alpha: 0.95),
              o.c,
              Color.lerp(o.c, Colors.black, 0.45)!,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromCircle(center: pos, radius: o.r)),
      );
    }

    // Glowing Bethlehem star on top
    _drawGlowingStar(canvas, Offset(cx, topY - 4), 20.0);

    // Gift boxes under the tree
    _drawGiftBox(
      canvas,
      Rect.fromLTWH(cx - size.width * 0.28, baseY + 4, 34, 26),
      ChristmasThemeConfig.burgundy,
      ChristmasThemeConfig.champagneGold,
    );
    _drawGiftBox(
      canvas,
      Rect.fromLTWH(cx + size.width * 0.12, baseY + 6, 30, 24),
      ChristmasThemeConfig.pineEmerald,
      ChristmasThemeConfig.crimsonGlow,
    );
  }

  void _drawGlowingStar(Canvas canvas, Offset center, double outerR) {
    final pulse = reducedMotion ? 1.0 : 0.82 + 0.18 * math.sin(elapsedSeconds * 2.5);
    canvas.drawCircle(
      center,
      outerR * 2.1 * pulse,
      Paint()
        ..shader = RadialGradient(
          colors: [
            ChristmasThemeConfig.champagneGold.withValues(alpha: 0.55),
            ChristmasThemeConfig.warmGold.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: outerR * 2.1)),
    );

    final star = Path();
    final innerR = outerR * 0.44;
    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? outerR : innerR;
      final p = Offset(center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r);
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            ChristmasThemeConfig.champagneGold,
            ChristmasThemeConfig.warmGold,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: outerR)),
    );
  }

  void _drawGiftBox(Canvas canvas, Rect rect, Color boxColor, Color ribbonColor) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(rrect, Paint()..color = boxColor);
    canvas.drawRect(
      Rect.fromCenter(center: rect.center, width: 5, height: rect.height),
      Paint()..color = ribbonColor,
    );
    canvas.drawRect(
      Rect.fromCenter(center: rect.center, width: rect.width, height: 5),
      Paint()..color = ribbonColor,
    );
  }

  @override
  bool shouldRepaint(covariant Christmas3DTreePainter oldDelegate) =>
      oldDelegate.elapsedSeconds != elapsedSeconds ||
      oldDelegate.reducedMotion != reducedMotion ||
      oldDelegate.pointerOffset != pointerOffset;
}

/// Festive string of twinkling Christmas lights along the Hero / sections.
class TwinklingLightsGarlandPainter extends CustomPainter {
  TwinklingLightsGarlandPainter({
    required this.elapsedSeconds,
    required this.reducedMotion,
    this.bulbCount = 16,
  });

  final double elapsedSeconds;
  final bool reducedMotion;
  final int bulbCount;

  @override
  void paint(Canvas canvas, Size size) {
    final wirePaint = Paint()
      ..color = ChristmasThemeConfig.pineEmerald.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final wire = Path()..moveTo(0, 6);
    final step = size.width / (bulbCount + 1);
    for (int i = 1; i <= bulbCount + 1; i++) {
      final prevX = (i - 1) * step;
      final nextX = i * step;
      final midX = (prevX + nextX) / 2;
      wire.quadraticBezierTo(midX, 16, nextX, 6);
    }
    canvas.drawPath(wire, wirePaint);

    const bulbPalette = [
      ChristmasThemeConfig.champagneGold,
      ChristmasThemeConfig.crimsonGlow,
      ChristmasThemeConfig.icyBlue,
      Color(0xFF34D399),
    ];

    for (int i = 1; i <= bulbCount; i++) {
      final bx = i * step;
      final by = 11.0;
      final color = bulbPalette[i % bulbPalette.length];
      final twinkle = reducedMotion
          ? 0.85
          : 0.45 + 0.55 * (0.5 + 0.5 * math.sin(elapsedSeconds * 3.4 + i * 1.15));

      canvas.drawCircle(
        Offset(bx, by + 4),
        10,
        Paint()..color = color.withValues(alpha: 0.25 * twinkle),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(bx, by + 4), width: 6.5, height: 9.0),
        Paint()..color = color.withValues(alpha: 0.95 * twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TwinklingLightsGarlandPainter oldDelegate) =>
      oldDelegate.elapsedSeconds != elapsedSeconds ||
      oldDelegate.reducedMotion != reducedMotion;
}

/// Decorative glowing Christmas wreath for the Contact section.
class ChristmasWreathPainter extends CustomPainter {
  ChristmasWreathPainter({
    required this.elapsedSeconds,
    required this.reducedMotion,
  });

  final double elapsedSeconds;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringR = math.min(size.width, size.height) * 0.34;

    // Soft golden aura
    canvas.drawCircle(
      center,
      ringR * 1.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            ChristmasThemeConfig.champagneGold.withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: ringR * 1.4)),
    );

    // Layered pine leaves around circle
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * math.pi * 2;
      final p = Offset(
        center.dx + math.cos(angle) * ringR,
        center.dy + math.sin(angle) * ringR,
      );
      canvas.drawCircle(
        p,
        10.5,
        Paint()
          ..color = i.isEven
              ? ChristmasThemeConfig.pineEmerald
              : ChristmasThemeConfig.darkForestGreen,
      );
    }

    // Golden berries / lights
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2 + 0.2;
      final p = Offset(
        center.dx + math.cos(angle) * ringR,
        center.dy + math.sin(angle) * ringR,
      );
      final pulse = reducedMotion
          ? 0.9
          : 0.6 + 0.4 * math.sin(elapsedSeconds * 3.0 + i);
      final color = i.isEven
          ? ChristmasThemeConfig.champagneGold
          : ChristmasThemeConfig.crimsonGlow;
      canvas.drawCircle(p, 4.2, Paint()..color = color.withValues(alpha: pulse));
    }

    // Burgundy ribbon bow at bottom of wreath
    final bowY = center.dy + ringR;
    final bowPaint = Paint()..color = ChristmasThemeConfig.crimsonGlow;
    final leftWing = Path()
      ..moveTo(center.dx, bowY)
      ..lineTo(center.dx - 16, bowY - 8)
      ..lineTo(center.dx - 14, bowY + 8)
      ..close();
    final rightWing = Path()
      ..moveTo(center.dx, bowY)
      ..lineTo(center.dx + 16, bowY - 8)
      ..lineTo(center.dx + 14, bowY + 8)
      ..close();
    canvas.drawPath(leftWing, bowPaint);
    canvas.drawPath(rightWing, bowPaint);
    canvas.drawCircle(Offset(center.dx, bowY), 4.5, Paint()..color = ChristmasThemeConfig.champagneGold);
  }

  @override
  bool shouldRepaint(covariant ChristmasWreathPainter oldDelegate) =>
      oldDelegate.elapsedSeconds != elapsedSeconds ||
      oldDelegate.reducedMotion != reducedMotion;
}

/// Subtle miniature snowfall inside selected project cards.
class CardSnowfallPainter extends CustomPainter {
  CardSnowfallPainter({
    required this.elapsedSeconds,
    required this.seed,
    required this.reducedMotion,
  });

  final double elapsedSeconds;
  final int seed;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    if (reducedMotion) return;
    final rng = math.Random(seed);
    final paint = Paint();
    for (int i = 0; i < 16; i++) {
      final x0 = rng.nextDouble();
      final y0 = rng.nextDouble();
      final spd = 0.09 + rng.nextDouble() * 0.14;
      final r = 1.0 + rng.nextDouble() * 1.6;
      final x = ((x0 + math.sin(elapsedSeconds * 1.2 + i) * 0.03) % 1.0) * size.width;
      final y = ((y0 + elapsedSeconds * spd) % 1.0) * size.height;
      paint.color = ChristmasThemeConfig.snowWhite.withValues(alpha: 0.25);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CardSnowfallPainter oldDelegate) =>
      oldDelegate.elapsedSeconds != elapsedSeconds ||
      oldDelegate.reducedMotion != reducedMotion;
}
