import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';

class RacingCarPainter extends CustomPainter {
  final double steer; // -1.0 .. +1.0
  final double speedKmh;
  final bool isAccelerating;
  final bool isBraking;
  final bool nitroActive;
  final bool collisionFlash;
  final double timeSeconds;
  final ThemeState themeState;

  RacingCarPainter({
    required this.steer,
    required this.speedKmh,
    required this.isAccelerating,
    required this.isBraking,
    required this.nitroActive,
    required this.collisionFlash,
    required this.timeSeconds,
    required this.themeState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final accent = themeState.accentColor;
    final secondary = themeState.secondaryAccent;
    final style = themeState.portfolioStyle;

    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final baseY = h * 0.86;

    // Subtle road/engine vibration
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
      // Animated tire tread grooves
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
    Color bodyBase;
    switch (style) {
      case PortfolioStyle.glass:
        bodyBase = const Color(0xFF141E36);
        break;
      case PortfolioStyle.bento:
        bodyBase = const Color(0xFF16181D);
        break;
      case PortfolioStyle.cyber:
        bodyBase = const Color(0xFF0A1228);
        break;
    }
    if (collisionFlash) {
      bodyBase = Color.lerp(bodyBase, const Color(0xFFEF4444), 0.45)!;
    }

    // Main widebody rear fenders
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
            Color.lerp(bodyBase, accent, 0.25)!,
            bodyBase,
            const Color(0xFF070A12),
          ],
        ).createShader(Rect.fromLTWH(-w * 0.42, -h * 0.64, w * 0.84, h * 0.56)),
    );
    canvas.drawPath(
      chassisPath,
      Paint()
        ..color = accent.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

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
            Color.lerp(const Color(0xFF0C152B), secondary, 0.22)!,
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

    // Glowing engine louvers on rear glass
    final louverPaint = Paint()
      ..color = (nitroActive ? const Color(0xFF00F0FF) : accent)
          .withValues(alpha: 0.55)
      ..strokeWidth = 1.8;
    for (int l = 0; l < 3; l++) {
      final ly = -h * (0.78 - l * 0.05);
      final halfSpan = w * (0.11 + l * 0.025);
      canvas.drawLine(Offset(-halfSpan, ly), Offset(halfSpan, ly), louverPaint);
    }

    // 6. ACTIVE AERO REAR WING (DRS)
    final drsOpen = speedKmh > 220 || nitroActive;
    final wingY = drsOpen ? -h * 0.73 : -h * 0.69;
    // Wing struts
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
    canvas.drawRRect(
      wingRect,
      Paint()..color = const Color(0xFF0D1528),
    );
    canvas.drawRRect(
      wingRect,
      Paint()
        ..color = drsOpen ? const Color(0xFF00F0FF) : accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Wing endplates
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

    // 7. CYBER LED TAIL-LIGHT BLADE & BRAKE HALO
    final tailColor =
        isBraking ? const Color(0xFFFF1E42) : const Color(0xFFF43F5E);
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

    // 8. LICENSE PLATE `SPNK 01`
    final plateRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -h * 0.31),
        width: w * 0.28,
        height: h * 0.14,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      plateRect,
      Paint()..color = const Color(0xFF070B14),
    );
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
          color: drsOpen ? const Color(0xFF00F0FF) : accent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(-tp.width / 2, -h * 0.31 - tp.height / 2),
    );

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
    final side = steer > 0 ? -1.0 : 1.0; // Outer loaded tire sparks!
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
