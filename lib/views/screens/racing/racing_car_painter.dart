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
  final VehicleType vehicleType;

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
    this.vehicleType = VehicleType.apexGt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final accent = palette.accent;
    final secondary = palette.secondary;
    final visualTheme = palette.visualTheme;

    final w = size.width * vehicleType.chaseWidthScale;
    final h = size.height;
    final cx = size.width * 0.5;
    final baseY = h * 0.86;

    final vib = speedKmh > 5
        ? math.sin(timeSeconds * (nitroActive ? 58 : 38)) *
            (nitroActive ? 1.8 : 0.9)
        : 0.0;
    final hoverBob = vehicleType == VehicleType.aeroHover
        ? math.sin(timeSeconds * 6.0) * 4.5
        : 0.0;
    final leanAngle = vehicleType == VehicleType.cyberBike
        ? steer * 0.28
        : steer * (vehicleType == VehicleType.titanTruck ? 0.04 : 0.065);

    canvas.save();
    canvas.translate(cx + steer * 14.0, baseY + vib + hoverBob);
    canvas.rotate(leanAngle);

    // 1. NEON UNDERGLOW & SHADOW
    final glowColor = collisionFlash
        ? const Color(0xFFEF4444)
        : (nitroActive ? const Color(0xFF00F0FF) : accent);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, vehicleType == VehicleType.aeroHover ? 4 : -4),
        width: w * 0.88,
        height: h * 0.24,
      ),
      Paint()
        ..color = glowColor.withValues(alpha: nitroActive ? 0.48 : 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, vehicleType == VehicleType.aeroHover ? 5 : -3),
        width: w * 0.76,
        height: h * 0.16,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );

    // 2. DRIFT SPARKS WHEN HARD CORNERING AT SPEED
    if (steer.abs() > 0.42 &&
        speedKmh > 125 &&
        vehicleType != VehicleType.aeroHover) {
      _paintDriftSparks(canvas, w, h);
    }

    switch (vehicleType) {
      case VehicleType.apexGt:
        _paintApexGt(canvas, w, h, accent, secondary, visualTheme);
      case VehicleType.formulaX:
        _paintFormulaX(canvas, w, h, accent, secondary);
      case VehicleType.cyberBike:
        _paintCyberBike(canvas, w, h, accent, secondary);
      case VehicleType.titanTruck:
        _paintTitanTruck(canvas, w, h, accent, secondary);
      case VehicleType.aeroHover:
        _paintAeroHover(canvas, w, h, accent, secondary);
    }

    // Collision shield impact ripple
    if (collisionFlash) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -h * 0.42),
          width: w * 1.18,
          height: h * 0.92,
        ),
        Paint()
          ..color = const Color(0xFFFF3B5C).withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2,
      );
    }

    canvas.restore();
  }

  void _paintApexGt(
    Canvas canvas,
    double w,
    double h,
    Color accent,
    Color secondary,
    RacingVisualTheme visualTheme,
  ) {
    final tireW = w * 0.17;
    final tireH = h * 0.34;
    final leftTireRect = Rect.fromLTWH(-w * 0.41, -tireH, tireW, tireH);
    final rightTireRect = Rect.fromLTWH(w * 0.41 - tireW, -tireH, tireW, tireH);

    for (final tRect in [leftTireRect, rightTireRect]) {
      _paintTireRect(canvas, tRect, accent, visualTheme);
    }

    Color bodyBase = palette.carBody;
    if (collisionFlash) {
      bodyBase = Color.lerp(bodyBase, const Color(0xFFEF4444), 0.48)!;
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
        ..color = accent.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

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

    _paintPlate(canvas, w, h, drsOpen ? 'DRS • SPNK' : 'SPNK • 01',
        drsOpen ? secondary : accent);

    for (final exDir in const [-1.0, 1.0]) {
      _paintExhaustFlame(canvas, exDir * w * 0.21, -h * 0.19, h, exDir);
    }
  }

  void _paintFormulaX(
    Canvas canvas,
    double w,
    double h,
    Color accent,
    Color secondary,
  ) {
    // Wide exposed slick rear tires on carbon suspension wishbones
    final tireW = w * 0.20;
    final tireH = h * 0.38;
    final leftTire = Rect.fromLTWH(-w * 0.47, -tireH, tireW, tireH);
    final rightTire = Rect.fromLTWH(w * 0.47 - tireW, -tireH, tireW, tireH);

    // Suspension wishbones
    final wishbonePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2.6;
    for (final side in const [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(side * w * 0.14, -h * 0.34),
        Offset(side * w * 0.38, -h * 0.24),
        wishbonePaint,
      );
      canvas.drawLine(
        Offset(side * w * 0.16, -h * 0.16),
        Offset(side * w * 0.38, -h * 0.14),
        wishbonePaint,
      );
    }

    for (final tRect in [leftTire, rightTire]) {
      _paintTireRect(canvas, tRect, accent, RacingVisualTheme.f1PitWall);
    }

    // Tapered ground-effect sidepods & floor diffuser
    Color bodyBase = collisionFlash
        ? Color.lerp(palette.carBody, const Color(0xFFEF4444), 0.45)!
        : palette.carBody;

    final floorPath = Path()
      ..moveTo(-w * 0.32, -h * 0.12)
      ..lineTo(-w * 0.30, -h * 0.52)
      ..lineTo(-w * 0.16, -h * 0.66)
      ..lineTo(w * 0.16, -h * 0.66)
      ..lineTo(w * 0.30, -h * 0.52)
      ..lineTo(w * 0.32, -h * 0.12)
      ..close();
    canvas.drawPath(
      floorPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(bodyBase, accent, 0.32)!, const Color(0xFF060912)],
        ).createShader(Rect.fromLTWH(-w * 0.32, -h * 0.66, w * 0.64, h * 0.54)),
    );
    canvas.drawPath(
      floorPath,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Central airbox intake + driver helmet & halo silhouette
    final airbox = Path()
      ..moveTo(-w * 0.12, -h * 0.42)
      ..lineTo(-w * 0.08, -h * 0.82)
      ..lineTo(w * 0.08, -h * 0.82)
      ..lineTo(w * 0.12, -h * 0.42)
      ..close();
    canvas.drawPath(airbox, Paint()..color = const Color(0xFF0A1020));
    canvas.drawPath(
      airbox,
      Paint()
        ..color = secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    canvas.drawCircle(
      Offset(0, -h * 0.72),
      w * 0.075,
      Paint()..color = secondary,
    );

    // High dual-plane F1 rear wing
    final drsOpen = speedKmh > 225 || nitroActive;
    final wingY = -h * (drsOpen ? 0.78 : 0.72);
    for (final side in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(side * w * 0.34, wingY + 8),
            width: 5.5,
            height: h * 0.34,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = accent,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, wingY),
          width: w * 0.72,
          height: drsOpen ? 7.0 : 12.0,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF0B1222),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, wingY),
          width: w * 0.72,
          height: drsOpen ? 7.0 : 12.0,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..color = drsOpen ? const Color(0xFF00F0FF) : accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Blinking FIA rain light & rear diffuser exhaust
    final blink = isBraking || (timeSeconds * 7).floor().isEven;
    if (blink) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -h * 0.14),
            width: 11,
            height: 15,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFFF1E42),
      );
    }

    _paintExhaustFlame(canvas, 0, -h * 0.25, h, 0.0, scale: 1.25);
  }

  void _paintCyberBike(
    Canvas canvas,
    double w,
    double h,
    Color accent,
    Color secondary,
  ) {
    // Sleek glowing hubless rear tire
    final tireW = w * 0.28;
    final tireH = h * 0.42;
    final tireRect = Rect.fromCenter(
      center: Offset(0, -tireH * 0.45),
      width: tireW,
      height: tireH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tireRect, Radius.circular(tireW * 0.45)),
      Paint()..color = const Color(0xFF090D16),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tireRect.deflate(2), Radius.circular(tireW * 0.4)),
      Paint()
        ..color = secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // Bike tail cowl & fairing
    final fairing = Path()
      ..moveTo(-w * 0.22, -h * 0.34)
      ..lineTo(-w * 0.34, -h * 0.64)
      ..lineTo(0, -h * 0.78)
      ..lineTo(w * 0.34, -h * 0.64)
      ..lineTo(w * 0.22, -h * 0.34)
      ..close();
    canvas.drawPath(
      fairing,
      Paint()
        ..color = collisionFlash
            ? const Color(0xFFEF4444).withValues(alpha: 0.75)
            : palette.carBody,
    );
    canvas.drawPath(
      fairing,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Crouched cyber rider silhouette & visor glow
    final torso = Path()
      ..moveTo(-w * 0.26, -h * 0.56)
      ..lineTo(-w * 0.16, -h * 0.86)
      ..lineTo(w * 0.16, -h * 0.86)
      ..lineTo(w * 0.26, -h * 0.56)
      ..close();
    canvas.drawPath(torso, Paint()..color = const Color(0xFF141B2D));
    canvas.drawCircle(
      Offset(0, -h * 0.89),
      w * 0.14,
      Paint()..color = const Color(0xFF0D1426),
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, -h * 0.89), radius: w * 0.14),
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Dual plasma light-ribbon tail lights
    final tailColor =
        isBraking ? const Color(0xFFFF1E42) : accent;
    for (final side in const [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(side * w * 0.16, -h * 0.38),
        Offset(side * w * 0.30, -h * 0.62),
        Paint()
          ..color = tailColor
          ..strokeWidth = isBraking ? 4.5 : 3.0
          ..strokeCap = StrokeCap.round,
      );
    }

    _paintExhaustFlame(canvas, 0, -h * 0.26, h, 0.0, scale: 1.15);
  }

  void _paintTitanTruck(
    Canvas canvas,
    double w,
    double h,
    Color accent,
    Color secondary,
  ) {
    // Heavy treaded off-road tires + visible coil suspension
    final tireW = w * 0.20;
    final tireH = h * 0.36;
    for (final tRect in [
      Rect.fromLTWH(-w * 0.45, -tireH, tireW, tireH),
      Rect.fromLTWH(w * 0.45 - tireW, -tireH, tireW, tireH),
    ]) {
      _paintTireRect(canvas, tRect, accent, RacingVisualTheme.neonCyber);
    }

    // Raised armored truck tailgate & wide steel bumper
    final bodyBase = collisionFlash
        ? Color.lerp(palette.carBody, const Color(0xFFEF4444), 0.35)!
        : palette.carBody;
    final cargoRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w * 0.42, -h * 0.72, w * 0.84, h * 0.56),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      cargoRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(bodyBase, accent, 0.22)!, const Color(0xFF0A0F1D)],
        ).createShader(cargoRect.outerRect),
    );
    canvas.drawRRect(
      cargoRect,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Armored cab top + roof LED lightbar
    final cabRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w * 0.34, -h * 0.94, w * 0.68, h * 0.24),
      const Radius.circular(5),
    );
    canvas.drawRRect(cabRect, Paint()..color = const Color(0xFF0B1222));
    canvas.drawRRect(
      cabRect,
      Paint()
        ..color = secondary.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Roof lightbar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -h * 0.95),
          width: w * 0.48,
          height: 5.5,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = secondary,
    );

    // Vertical tail light bars & steel rear bumper
    final tailColor =
        isBraking ? const Color(0xFFFF1E42) : const Color(0xFFF43F5E);
    for (final side in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(side * w * 0.36, -h * 0.48),
            width: 7,
            height: h * 0.22,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = tailColor,
      );
    }

    _paintPlate(canvas, w, h, 'TITAN • 6X', accent);

    // Quad exhausts
    for (final exDir in const [-1.0, -0.7, 0.7, 1.0]) {
      _paintExhaustFlame(canvas, exDir * w * 0.24, -h * 0.14, h, exDir,
          scale: 0.80);
    }
  }

  void _paintAeroHover(
    Canvas canvas,
    double w,
    double h,
    Color accent,
    Color secondary,
  ) {
    // Repulsor anti-grav rings underneath
    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(side * w * 0.26, -h * 0.08),
          width: w * 0.28,
          height: 9,
        ),
        Paint()
          ..color = const Color(0xFF00F0FF).withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Swept delta-wing hull
    final wingPath = Path()
      ..moveTo(-w * 0.50, -h * 0.24)
      ..lineTo(-w * 0.38, -h * 0.52)
      ..lineTo(0, -h * 0.76)
      ..lineTo(w * 0.38, -h * 0.52)
      ..lineTo(w * 0.50, -h * 0.24)
      ..lineTo(w * 0.20, -h * 0.32)
      ..lineTo(-w * 0.20, -h * 0.32)
      ..close();

    canvas.drawPath(
      wingPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(palette.carBody, secondary, 0.30)!,
            const Color(0xFF080E1E),
          ],
        ).createShader(Rect.fromLTWH(-w * 0.5, -h * 0.76, w, h * 0.55)),
    );
    canvas.drawPath(
      wingPath,
      Paint()
        ..color = secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Bubble glass canopy
    final canopy = Path()
      ..moveTo(-w * 0.18, -h * 0.45)
      ..quadraticBezierTo(0, -h * 0.94, w * 0.18, -h * 0.45)
      ..close();
    canvas.drawPath(canopy, Paint()..color = const Color(0xFF050A16));
    canvas.drawPath(
      canopy,
      Paint()
        ..color = const Color(0xFF00F0FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Twin vertical stabilizer fins
    for (final side in const [-1.0, 1.0]) {
      final fin = Path()
        ..moveTo(side * w * 0.30, -h * 0.32)
        ..lineTo(side * w * 0.38, -h * 0.68)
        ..lineTo(side * w * 0.22, -h * 0.44)
        ..close();
      canvas.drawPath(fin, Paint()..color = accent);
    }

    // Twin vector jet thruster nozzles
    for (final side in const [-1.0, 1.0]) {
      final nx = side * w * 0.16;
      final ny = -h * 0.30;
      canvas.drawCircle(
        Offset(nx, ny),
        9.0,
        Paint()..color = const Color(0xFF0B1325),
      );
      canvas.drawCircle(
        Offset(nx, ny),
        7.5,
        Paint()
          ..color = const Color(0xFF00F0FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      _paintExhaustFlame(canvas, nx, ny + 4, h, side,
          forceCyan: true, scale: 1.25);
    }
  }

  void _paintTireRect(
    Canvas canvas,
    Rect tRect,
    Color accent,
    RacingVisualTheme visualTheme,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(tRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFF0B0F17),
    );
    if (visualTheme == RacingVisualTheme.f1PitWall) {
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

  void _paintPlate(
    Canvas canvas,
    double w,
    double h,
    String text,
    Color color,
  ) {
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
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: (h * 0.095).clamp(7.5, 11.5),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -h * 0.31 - tp.height / 2));
  }

  void _paintExhaustFlame(
    Canvas canvas,
    double exX,
    double exY,
    double h,
    double phaseOffset, {
    bool forceCyan = false,
    double scale = 1.0,
  }) {
    canvas.drawCircle(
      Offset(exX, exY),
      5.5 * scale,
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawCircle(
      Offset(exX, exY),
      3.8 * scale,
      Paint()
        ..color = (nitroActive || forceCyan)
            ? const Color(0xFF00F0FF)
            : (isAccelerating
                ? const Color(0xFFF97316)
                : const Color(0xFF0F172A)),
    );

    if ((isAccelerating && speedKmh > 25) || nitroActive || forceCyan) {
      final flicker = 0.75 + 0.35 * math.sin(timeSeconds * 65 + phaseOffset * 2);
      final flameLen = (nitroActive ? h * 0.36 : h * 0.16) * flicker * scale;
      final flameW = (nitroActive ? 11.0 : 6.5) * scale;

      final outerFlame = Path()
        ..moveTo(exX - flameW, exY + 2)
        ..lineTo(exX, exY + flameLen)
        ..lineTo(exX + flameW, exY + 2)
        ..close();

      canvas.drawPath(
        outerFlame,
        Paint()
          ..color = ((nitroActive || forceCyan)
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

/// Shared top-down vehicle renderer used in Open-World Paddock, Vertical Highway,
/// and the Vehicle Garage preview turntable.
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
    VehicleType vehicleType = VehicleType.apexGt,
    OpponentVehicleKind? opponentKind,
    bool collisionFlash = false,
  }) {
    final trim = collisionFlash
        ? const Color(0xFFFF3B5C)
        : (overrideTrim ?? palette.accent);
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
        final lx = side * hw * 0.54;
        final ly = -hl + 2;
        final cone = Path()
          ..moveTo(lx - 3, ly)
          ..lineTo(lx - width * 0.40, ly - coneLen)
          ..lineTo(lx + width * 0.40, ly - coneLen)
          ..lineTo(lx + 3, ly)
          ..close();
        canvas.drawPath(
          cone,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                secondary.withValues(alpha: 0.24),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromLTWH(-width, ly - coneLen, width * 2, coneLen),
            ),
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
        ..color = (collisionFlash
                ? const Color(0xFFFF3B5C)
                : (nitroActive ? const Color(0xFF00F0FF) : trim))
            .withValues(alpha: collisionFlash ? 0.55 : (nitroActive ? 0.36 : 0.22))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    if (opponentKind == OpponentVehicleKind.truck ||
        (opponentKind == null && vehicleType == VehicleType.titanTruck)) {
      _paintTopDownTruck(
        canvas: canvas,
        width: width,
        length: length,
        steer: steer,
        isBraking: isBraking,
        palette: palette,
        trim: trim,
        secondary: secondary,
      );
    } else if (opponentKind == null && vehicleType == VehicleType.cyberBike) {
      _paintTopDownBike(
        canvas: canvas,
        width: width,
        length: length,
        steer: steer,
        isBraking: isBraking,
        palette: palette,
        trim: trim,
        secondary: secondary,
      );
    } else if (opponentKind == null && vehicleType == VehicleType.formulaX) {
      _paintTopDownFormula(
        canvas: canvas,
        width: width,
        length: length,
        steer: steer,
        isBraking: isBraking,
        palette: palette,
        trim: trim,
        secondary: secondary,
      );
    } else if (opponentKind == null && vehicleType == VehicleType.aeroHover) {
      _paintTopDownHover(
        canvas: canvas,
        width: width,
        length: length,
        palette: palette,
        trim: trim,
        secondary: secondary,
      );
    } else {
      _paintTopDownCoupe(
        canvas: canvas,
        width: width,
        length: length,
        steer: steer,
        isBraking: isBraking,
        palette: palette,
        trim: trim,
        secondary: secondary,
        isInterceptor: opponentKind == OpponentVehicleKind.interceptor,
      );
    }

    if (badge.isNotEmpty && width >= 18) {
      final tp = TextPainter(
        text: TextSpan(
          text: badge,
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: (width * 0.28).clamp(7.5, 11.5),
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -hl * 0.08 - tp.height / 2));
    }

    if (isAccelerating || nitroActive) {
      final flicker = 0.72 + 0.35 * math.sin(timeSeconds * 60);
      final flameLen = (nitroActive ? length * 0.45 : length * 0.20) * flicker;
      final isSingleFlame =
          opponentKind == null && vehicleType == VehicleType.cyberBike;
      final offsets = isSingleFlame ? const [0.0] : const [-0.36, 0.36];
      for (final side in offsets) {
        final exX = side * hw;
        final exY = hl;
        final flame = Path()
          ..moveTo(exX - 3.2, exY)
          ..lineTo(exX, exY + flameLen)
          ..lineTo(exX + 3.2, exY)
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

  static void _paintTopDownWheels({
    required Canvas canvas,
    required double hw,
    required double hl,
    required double width,
    required double length,
    required double steer,
    double wheelScaleW = 0.19,
  }) {
    final wheelW = width * wheelScaleW;
    final wheelL = length * 0.22;
    final wheelPaint = Paint()..color = const Color(0xFF090D16);

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
  }

  static void _paintTopDownCoupe({
    required Canvas canvas,
    required double width,
    required double length,
    required double steer,
    required bool isBraking,
    required RacingThemePalette palette,
    required Color trim,
    required Color secondary,
    bool isInterceptor = false,
  }) {
    final hw = width * 0.5;
    final hl = length * 0.5;
    _paintTopDownWheels(
      canvas: canvas,
      hw: hw,
      hl: hl,
      width: width,
      length: length,
      steer: steer,
    );

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
        ).createShader(
          Rect.fromCenter(center: Offset.zero, width: width, height: length),
        ),
    );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    canvas.drawLine(
      Offset(0, -hl * 0.92),
      Offset(0, hl * 0.86),
      Paint()
        ..color = (isInterceptor ? trim : secondary).withValues(alpha: 0.75)
        ..strokeWidth = width * 0.10,
    );

    final canopyRect = Rect.fromCenter(
      center: Offset(0, -hl * 0.04),
      width: width * 0.58,
      height: length * 0.44,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(canopyRect, Radius.circular(width * 0.24)),
      Paint()..color = const Color(0xFF060A14),
    );

    final wingRect = Rect.fromCenter(
      center: Offset(0, hl * 0.84),
      width: width * (isInterceptor ? 1.04 : 0.96),
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
  }

  static void _paintTopDownFormula({
    required Canvas canvas,
    required double width,
    required double length,
    required double steer,
    required bool isBraking,
    required RacingThemePalette palette,
    required Color trim,
    required Color secondary,
  }) {
    final hw = width * 0.5;
    final hl = length * 0.5;
    _paintTopDownWheels(
      canvas: canvas,
      hw: hw,
      hl: hl,
      width: width,
      length: length,
      steer: steer,
      wheelScaleW: 0.23,
    );

    // Front wing
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -hl * 0.88),
          width: width * 0.98,
          height: length * 0.11,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = trim,
    );

    // Nose cone & sidepods
    final f1Body = Path()
      ..moveTo(0, -hl)
      ..lineTo(hw * 0.24, -hl * 0.35)
      ..lineTo(hw * 0.68, -hl * 0.15)
      ..lineTo(hw * 0.62, hl * 0.55)
      ..lineTo(hw * 0.24, hl * 0.85)
      ..lineTo(-hw * 0.24, hl * 0.85)
      ..lineTo(-hw * 0.62, hl * 0.55)
      ..lineTo(-hw * 0.68, -hl * 0.15)
      ..lineTo(-hw * 0.24, -hl * 0.35)
      ..close();
    canvas.drawPath(f1Body, Paint()..color = palette.carBody);
    canvas.drawPath(
      f1Body,
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Driver helmet halo
    canvas.drawCircle(
      Offset(0, -hl * 0.05),
      width * 0.14,
      Paint()..color = secondary,
    );

    // Rear wing
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, hl * 0.88),
          width: width * 0.92,
          height: length * 0.12,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = trim,
    );
    if (isBraking) {
      canvas.drawCircle(
        Offset(0, hl * 0.96),
        3.5,
        Paint()..color = const Color(0xFFFF1E42),
      );
    }
  }

  static void _paintTopDownBike({
    required Canvas canvas,
    required double width,
    required double length,
    required double steer,
    required bool isBraking,
    required RacingThemePalette palette,
    required Color trim,
    required Color secondary,
  }) {
    final hl = length * 0.5;
    // Front tire
    canvas.save();
    canvas.translate(0, -hl * 0.72);
    canvas.rotate(steer * 0.38);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: width * 0.38,
          height: length * 0.25,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF0A0E18),
    );
    canvas.restore();

    // Rear tire
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, hl * 0.72),
          width: width * 0.46,
          height: length * 0.26,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF0A0E18),
    );

    // Handlebars
    canvas.drawLine(
      Offset(-width * 0.56, -hl * 0.42),
      Offset(width * 0.56, -hl * 0.42),
      Paint()
        ..color = secondary
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    // Bike body + rider helmet
    final chassis = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: width * 0.72,
        height: length * 0.62,
      ),
      Radius.circular(width * 0.35),
    );
    canvas.drawRRect(chassis, Paint()..color = palette.carBody);
    canvas.drawRRect(
      chassis,
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(
      Offset(0, -hl * 0.12),
      width * 0.28,
      Paint()..color = secondary,
    );
    canvas.drawLine(
      Offset(-width * 0.2, hl * 0.88),
      Offset(width * 0.2, hl * 0.88),
      Paint()
        ..color = isBraking ? const Color(0xFFFF1E42) : trim
        ..strokeWidth = 3.0,
    );
  }

  static void _paintTopDownTruck({
    required Canvas canvas,
    required double width,
    required double length,
    required double steer,
    required bool isBraking,
    required RacingThemePalette palette,
    required Color trim,
    required Color secondary,
  }) {
    final hw = width * 0.5;
    final hl = length * 0.5;
    _paintTopDownWheels(
      canvas: canvas,
      hw: hw,
      hl: hl,
      width: width,
      length: length,
      steer: steer,
      wheelScaleW: 0.20,
    );

    final truckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: width * 0.90,
        height: length * 0.96,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(truckRect, Paint()..color = palette.carBody);
    canvas.drawRRect(
      truckRect,
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Armored cab + cargo bed split
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -hl * 0.22),
          width: width * 0.72,
          height: length * 0.36,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF0A1020),
    );
    // Roof lightbar
    canvas.drawLine(
      Offset(-hw * 0.62, -hl * 0.10),
      Offset(hw * 0.62, -hl * 0.10),
      Paint()
        ..color = secondary
        ..strokeWidth = 3.0,
    );
    // Tail lights
    canvas.drawLine(
      Offset(-hw * 0.76, hl * 0.93),
      Offset(hw * 0.76, hl * 0.93),
      Paint()
        ..color = isBraking ? const Color(0xFFFF1E42) : const Color(0xFFF43F5E)
        ..strokeWidth = 3.2,
    );
  }

  static void _paintTopDownHover({
    required Canvas canvas,
    required double width,
    required double length,
    required RacingThemePalette palette,
    required Color trim,
    required Color secondary,
  }) {
    final hw = width * 0.5;
    final hl = length * 0.5;

    final delta = Path()
      ..moveTo(0, -hl)
      ..lineTo(hw, hl * 0.55)
      ..lineTo(hw * 0.55, hl * 0.95)
      ..lineTo(0, hl * 0.65)
      ..lineTo(-hw * 0.55, hl * 0.95)
      ..lineTo(-hw, hl * 0.55)
      ..close();

    canvas.drawPath(delta, Paint()..color = palette.carBody);
    canvas.drawPath(
      delta,
      Paint()
        ..color = secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -hl * 0.15),
        width: width * 0.36,
        height: length * 0.44,
      ),
      Paint()
        ..color = const Color(0xFF00F0FF).withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
  }
}
