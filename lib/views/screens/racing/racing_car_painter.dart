import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';

class RacingCarPainter extends CustomPainter {
  final double steer; // -1.0 .. +1.0
  final double speedKmh;
  final bool isAccelerating;
  final bool isBraking;
  final bool nitroActive;
  final bool collisionFlash;
  final double timeSeconds;
  final ThemeState themeState;
  final RacingThemePalette palette;

  RacingCarPainter({
    required this.steer,
    required this.speedKmh,
    required this.isAccelerating,
    required this.isBraking,
    required this.nitroActive,
    required this.collisionFlash,
    required this.timeSeconds,
    required this.themeState,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final accent = palette.accent;
    final secondary = palette.secondary;
    final visualTheme = palette.visualTheme;

    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final baseY = h * 0.86;

    final vib = speedKmh > 5
        ? math.sin(timeSeconds * (nitroActive ? 58 : 38)) *
            (nitroActive ? 1.8 : 0.9)
        : 0.0;

    canvas.save();
    canvas.translate(cx + steer * 14.0, baseY + vib);
    canvas.rotate(steer * 0.058);

    // 1. NEON UNDERGLOW & SHADOW
    final glowColor = collisionFlash
        ? const Color(0xFFEF4444)
        : (nitroActive ? const Color(0xFF00F0FF) : accent);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, -4),
        width: w * 0.86,
        height: h * 0.24,
      ),
      Paint()
        ..color = glowColor.withValues(alpha: nitroActive ? 0.45 : 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, -3),
        width: w * 0.76,
        height: h * 0.16,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );

    // 2. DRIFT SPARKS WHEN HARD CORNERING AT SPEED
    if (steer.abs() > 0.42 && speedKmh > 125) {
      _paintDriftSparks(canvas, w, h);
    }

    // 3. WIDE MOTORSPORT REAR TIRES
    final tireW = w * 0.17;
    final tireH = h * 0.34;
    final leftTireRect = Rect.fromLTWH(-w * 0.41, -tireH, tireW, tireH);
    final rightTireRect = Rect.fromLTWH(w * 0.41 - tireW, -tireH, tireW, tireH);

    for (final tRect in [leftTireRect, rightTireRect]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(tRect, const Radius.circular(6)),
        Paint()..color = const Color(0xFF0B0F17),
      );
      if (visualTheme == RacingVisualTheme.f1PitWall) {
        // Pirelli-style soft-compound sidewall stripe
        canvas.drawRRect(
          RRect.fromRectAndRadius(tRect.deflate(2.5), const Radius.circular(4)),
          Paint()
            ..color = accent.withValues(alpha: 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
      final groovePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 1.6;
      final phase = (timeSeconds * speedKmh * 0.14) % 10.0;
      for (double gy = tRect.top + 4 + (phase % 8);
          gy < tRect.bottom - 3;
          gy += 8) {
        canvas.drawLine(
          Offset(tRect.left + 3, gy),
          Offset(tRect.right - 3, gy),
          groovePaint,
        );
      }
    }

    // 4. LOWER CARBON DIFFUSER & BODY CHASSIS
    Color bodyBase = palette.carBody;
    if (collisionFlash) {
      bodyBase = Color.lerp(bodyBase, const Color(0xFFEF4444), 0.45)!;
    }

    final chassisPath = Path()
      ..moveTo(-w * 0.40, -tireH * 0.32)
      ..lineTo(-w * 0.42, -h * 0.44)
      ..lineTo(-w * 0.32, -h * 0.62)
      ..lineTo(w * 0.32, -h * 0.62)
      ..lineTo(w * 0.42, -h * 0.44)
      ..lineTo(w * 0.40, -tireH * 0.32)
      ..close();

    canvas.drawPath(
      chassisPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(bodyBase, accent, 0.28)!,
            bodyBase,
            const Color(0xFF070A12),
          ],
        ).createShader(Rect.fromLTWH(-w * 0.42, -h * 0.64, w * 0.84, h * 0.56)),
    );
    canvas.drawPath(
      chassisPath,
      Paint()
        ..color = accent.withValues(alpha: 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Theme-specific center livery racing stripes
    if (visualTheme == RacingVisualTheme.f1PitWall) {
      for (final sx in const [-5.0, 5.0]) {
        canvas.drawLine(
          Offset(sx, -h * 0.62),
          Offset(sx, -tireH * 0.34),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.75)
            ..strokeWidth = 2.6,
        );
      }
    } else if (visualTheme == RacingVisualTheme.retroSynthwave) {
      canvas.drawLine(
        Offset(0, -h * 0.62),
        Offset(0, -tireH * 0.34),
        Paint()
          ..color = palette.tertiary.withValues(alpha: 0.85)
          ..strokeWidth = 3.2,
      );
    }

    // 5. FASTBACK CABIN & LOUVERED REACTOR ENGINE DECK
    final cabinPath = Path()
      ..moveTo(-w * 0.29, -h * 0.61)
      ..lineTo(-w * 0.20, -h * 0.84)
      ..lineTo(w * 0.20, -h * 0.84)
      ..lineTo(w * 0.29, -h * 0.61)
      ..close();

    canvas.drawPath(
      cabinPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF060913),
            Color.lerp(const Color(0xFF0C152B), secondary, 0.24)!,
          ],
        ).createShader(Rect.fromLTWH(-w * 0.3, -h * 0.85, w * 0.6, h * 0.26)),
    );
    canvas.drawPath(
      cabinPath,
      Paint()
        ..color = secondary.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final louverPaint = Paint()
      ..color = (nitroActive ? const Color(0xFF00F0FF) : secondary)
          .withValues(alpha: 0.62)
      ..strokeWidth = 1.8;
    for (int l = 0; l < 3; l++) {
      final ly = -h * (0.78 - l * 0.05);
      final halfSpan = w * (0.11 + l * 0.025);
      canvas.drawLine(Offset(-halfSpan, ly), Offset(halfSpan, ly), louverPaint);
    }

    // 6. ACTIVE AERO REAR WING (DRS)
    final drsOpen = speedKmh > 220 || nitroActive;
    final wingY = drsOpen ? -h * 0.73 : -h * 0.69;
    final strutPaint = Paint()
      ..color = accent.withValues(alpha: 0.85)
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(-w * 0.22, -h * 0.58),
      Offset(-w * 0.22, wingY),
      strutPaint,
    );
    canvas.drawLine(
      Offset(w * 0.22, -h * 0.58),
      Offset(w * 0.22, wingY),
      strutPaint,
    );

    final wingRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, wingY),
        width: w * 0.78,
        height: drsOpen ? 6.5 : 9.0,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(wingRect, Paint()..color = const Color(0xFF0D1528));
    canvas.drawRRect(
      wingRect,
      Paint()
        ..color = drsOpen ? secondary : accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    for (final side in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(side * w * 0.39, wingY + 2),
            width: 5,
            height: 16,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = secondary,
      );
    }

    // 7. LED TAIL-LIGHT BLADE & FIA RAIN LIGHT
    final tailColor = isBraking
        ? const Color(0xFFFF1E42)
        : (visualTheme == RacingVisualTheme.retroSynthwave
            ? const Color(0xFFFF2A85)
            : const Color(0xFFF43F5E));
    final tailY = -h * 0.48;
    if (isBraking) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, tailY),
            width: w * 0.74,
            height: 16,
          ),
          const Radius.circular(8),
        ),
        Paint()
          ..color = const Color(0xFFFF1E42).withValues(alpha: 0.65)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, tailY),
          width: w * 0.70,
          height: isBraking ? 7.0 : 5.0,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = tailColor,
    );

    if (visualTheme == RacingVisualTheme.f1PitWall) {
      // Blinking FIA ERS harvesting rain light in center diffuser
      final blink = (timeSeconds * 7).floor().isEven;
      if (blink) {
        canvas.drawCircle(
          Offset(0, -h * 0.16),
          4.0,
          Paint()..color = const Color(0xFFFF1E42),
        );
      }
    }

    // 8. LICENSE PLATE `SPNK 01`
    final plateRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -h * 0.31),
        width: w * 0.28,
        height: h * 0.14,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(plateRect, Paint()..color = const Color(0xFF070B14));
    canvas.drawRRect(
      plateRect,
      Paint()
        ..color = accent.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: drsOpen ? 'DRS • SPNK' : 'SPNK • 01',
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: (h * 0.095).clamp(8.0, 12.0),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: drsOpen ? secondary : accent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -h * 0.31 - tp.height / 2));

    // 9. TWIN EXHAUST PIPES & PLASMA AFTERBURNER FLAMES
    for (final exDir in const [-1.0, 1.0]) {
      final exX = exDir * w * 0.21;
      final exY = -h * 0.19;
      canvas.drawCircle(
        Offset(exX, exY),
        5.5,
        Paint()..color = const Color(0xFF1E293B),
      );
      canvas.drawCircle(
        Offset(exX, exY),
        3.8,
        Paint()
          ..color = nitroActive
              ? const Color(0xFF00F0FF)
              : (isAccelerating
                  ? const Color(0xFFF97316)
                  : const Color(0xFF0F172A)),
      );

      if ((isAccelerating && speedKmh > 25) || nitroActive) {
        final flicker = 0.75 + 0.35 * math.sin(timeSeconds * 65 + exDir * 2);
        final flameLen = (nitroActive ? h * 0.36 : h * 0.16) * flicker;
        final flameW = nitroActive ? 11.0 : 6.5;

        final outerFlame = Path()
          ..moveTo(exX - flameW, exY + 2)
          ..lineTo(exX, exY + flameLen)
          ..lineTo(exX + flameW, exY + 2)
          ..close();

        canvas.drawPath(
          outerFlame,
          Paint()
            ..color = (nitroActive
                    ? const Color(0xFF00F0FF)
                    : const Color(0xFFF97316))
                .withValues(alpha: 0.85)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );

        final coreFlame = Path()
          ..moveTo(exX - flameW * 0.45, exY + 2)
          ..lineTo(exX, exY + flameLen * 0.65)
          ..lineTo(exX + flameW * 0.45, exY + 2)
          ..close();
        canvas.drawPath(
          coreFlame,
          Paint()..color = Colors.white.withValues(alpha: 0.92),
        );
      }
    }

    canvas.restore();
  }

  void _paintDriftSparks(Canvas canvas, double w, double h) {
    final side = steer > 0 ? -1.0 : 1.0;
    final baseTireX = side * w * 0.36;
    final sparkPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final p = ((timeSeconds * 18) + i * 0.19) % 1.0;
      final sx = baseTireX + side * (p * 26 + i * 3);
      final sy = -6.0 - p * 18.0 - (i % 3) * 4;
      canvas.drawLine(
        Offset(sx, sy),
        Offset(sx + side * 7, sy - 5),
        sparkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RacingCarPainter oldDelegate) => true;
}

/// Shared top-down supercar renderer used in both Open-World Paddock
/// and Vertical Highway Lane Racer modes.
/// Local coordinates assume the car nose points UP (`0, -halfLen`).
class TopDownRaceCarRenderer {
  static void paint({
    required Canvas canvas,
    required Offset position,
    required double headingRadians, // 0 = pointing UP (-Y)
    required double width,
    required double length,
    required double steer, // -1 .. +1
    required bool isAccelerating,
    required bool isBraking,
    required bool nitroActive,
    required double timeSeconds,
    required RacingThemePalette palette,
    String badge = '01',
    Color? overrideTrim,
    bool showHeadlights = true,
  }) {
    final trim = overrideTrim ?? palette.accent;
    final secondary = palette.secondary;
    final hw = width * 0.5;
    final hl = length * 0.5;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(headingRadians);

    // 1. Volumetric Headlight Cones
    if (showHeadlights) {
      final coneLen = length * (nitroActive ? 2.2 : 1.65);
      for (final side in const [-1.0, 1.0]) {
        final lx = side * hw * 0.58;
        final ly = -hl + 2;
        final cone = Path()
          ..moveTo(lx - 3, ly)
          ..lineTo(lx - width * 0.42, ly - coneLen)
          ..lineTo(lx + width * 0.42, ly - coneLen)
          ..lineTo(lx + 3, ly)
          ..close();
        canvas.drawPath(
          cone,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                secondary.withValues(alpha: 0.26),
                Colors.transparent,
              ],
            ).createShader(Rect.fromLTWH(-width, ly - coneLen, width * 2, coneLen)),
        );
      }
    }

    // 2. Underglow Halo
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: width * 1.18,
          height: length * 1.06,
        ),
        Radius.circular(width * 0.35),
      ),
      Paint()
        ..color = (nitroActive ? const Color(0xFF00F0FF) : trim)
            .withValues(alpha: nitroActive ? 0.36 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 3. Four Wheels (Front wheels pivot with `steer`)
    final wheelW = width * 0.19;
    final wheelL = length * 0.22;
    final wheelPaint = Paint()..color = const Color(0xFF090D16);

    // Front wheels
    for (final side in const [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * (hw - wheelW * 0.2), -hl * 0.56);
      canvas.rotate(steer * 0.36);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: wheelW, height: wheelL),
          const Radius.circular(3),
        ),
        wheelPaint,
      );
      canvas.restore();
    }
    // Rear wheels
    for (final side in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(side * (hw - wheelW * 0.15), hl * 0.56),
            width: wheelW * 1.08,
            height: wheelL * 1.05,
          ),
          const Radius.circular(3),
        ),
        wheelPaint,
      );
    }

    // 4. Aerodynamic GT / Formula Sculpted Body
    final bodyPath = Path()
      ..moveTo(0, -hl)
      ..quadraticBezierTo(hw * 0.88, -hl * 0.92, hw * 0.92, -hl * 0.38)
      ..lineTo(hw, hl * 0.72)
      ..quadraticBezierTo(hw * 0.85, hl, 0, hl)
      ..quadraticBezierTo(-hw * 0.85, hl, -hw, hl * 0.72)
      ..lineTo(-hw * 0.92, -hl * 0.38)
      ..quadraticBezierTo(-hw * 0.88, -hl * 0.92, 0, -hl)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(palette.carBody, trim, 0.35)!,
            palette.carBody,
            const Color(0xFF080C16),
          ],
        ).createShader(Rect.fromCenter(
          center: Offset.zero,
          width: width,
          height: length,
        )),
    );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Center livery racing stripe
    canvas.drawLine(
      Offset(0, -hl * 0.92),
      Offset(0, hl * 0.86),
      Paint()
        ..color = secondary.withValues(alpha: 0.75)
        ..strokeWidth = width * 0.10,
    );

    // 5. Teardrop Cockpit Canopy
    final canopyRect = Rect.fromCenter(
      center: Offset(0, -hl * 0.04),
      width: width * 0.58,
      height: length * 0.44,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(canopyRect, Radius.circular(width * 0.24)),
      Paint()..color = const Color(0xFF060A14),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(canopyRect, Radius.circular(width * 0.24)),
      Paint()
        ..color = secondary.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // 6. Rear Aero Wing & Tail-Light Bar
    final wingRect = Rect.fromCenter(
      center: Offset(0, hl * 0.84),
      width: width * 0.96,
      height: length * 0.10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(wingRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF0B1120),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(wingRect, const Radius.circular(2)),
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawLine(
      Offset(-hw * 0.76, hl * 0.95),
      Offset(hw * 0.76, hl * 0.95),
      Paint()
        ..color = isBraking ? const Color(0xFFFF1E42) : const Color(0xFFF43F5E)
        ..strokeWidth = isBraking ? 3.4 : 2.2,
    );

    // Car Number Badge on Hood/Roof
    if (badge.isNotEmpty && width >= 22) {
      final tp = TextPainter(
        text: TextSpan(
          text: badge,
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: (width * 0.30).clamp(8.0, 12.0),
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -hl * 0.08 - tp.height / 2));
    }

    // 7. Twin Exhaust Plasma Flames
    if (isAccelerating || nitroActive) {
      final flicker = 0.72 + 0.35 * math.sin(timeSeconds * 60);
      final flameLen = (nitroActive ? length * 0.48 : length * 0.20) * flicker;
      for (final side in const [-1.0, 1.0]) {
        final exX = side * hw * 0.38;
        final exY = hl;
        final flame = Path()
          ..moveTo(exX - 3.5, exY)
          ..lineTo(exX, exY + flameLen)
          ..lineTo(exX + 3.5, exY)
          ..close();
        canvas.drawPath(
          flame,
          Paint()
            ..color = (nitroActive
                    ? const Color(0xFF00F0FF)
                    : const Color(0xFFF97316))
                .withValues(alpha: 0.88),
        );
      }
    }

    canvas.restore();
  }
}
