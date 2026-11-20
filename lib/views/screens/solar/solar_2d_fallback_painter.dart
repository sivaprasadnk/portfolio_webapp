import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spnk/views/screens/solar/solar_models.dart';

/// Result returned when tapping the 3D Solar System or 2D projected fallback.
class SolarHitResult {
  const SolarHitResult({
    required this.kind,
    this.planetId,
    this.moonId,
  });

  final SolarFocusKind kind;
  final String? planetId;
  final String? moonId;
}

class _ProjectedPoint {
  const _ProjectedPoint({
    required this.screen,
    required this.depth,
    required this.scale,
  });

  final Offset screen;
  final double depth;
  final double scale;
}

class _RenderBody {
  const _RenderBody({
    required this.depth,
    required this.draw,
  });

  final double depth;
  final VoidCallback draw;
}

/// 3D-projected vector solar system painter used when WebGL is unavailable
/// (including headless widget tests) and for matching pointer hit-testing.
class Solar2dFallbackPainter extends CustomPainter {
  Solar2dFallbackPainter({
    required this.planets,
    required this.physics,
    required this.yaw,
    required this.pitch,
    required this.zoomOffset,
    required this.elapsedSeconds,
    required this.isDark,
  });

  final List<SolarPlanetData> planets;
  final SolarOrbitPhysics physics;
  final double yaw;
  final double pitch;
  final double zoomOffset;
  final double elapsedSeconds;
  final bool isDark;

  static _ProjectedPoint? _project(
    Vec3 worldPos,
    Vec3 lookAt,
    double dist,
    double yaw,
    double pitch,
    Size size,
  ) {
    if (size.width <= 0 || size.height <= 0) return null;
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);
    final sinY = math.sin(yaw);
    final cosY = math.cos(yaw);

    final camX = lookAt.x + sinY * cosP * dist;
    final camY = lookAt.y + sinP * dist;
    final camZ = lookAt.z + cosY * cosP * dist;

    final fx = -sinY * cosP;
    final fy = -sinP;
    final fz = -cosY * cosP;

    final rx = cosY;
    const ry = 0.0;
    final rz = -sinY;

    final ux = -sinY * sinP;
    final uy = cosP;
    final uz = -cosY * sinP;

    final dx = worldPos.x - camX;
    final dy = worldPos.y - camY;
    final dz = worldPos.z - camZ;

    final zCam = dx * fx + dy * fy + dz * fz;
    if (zCam < 0.25) return null;

    final xCam = dx * rx + dy * ry + dz * rz;
    final yCam = dx * ux + dy * uy + dz * uz;

    // 48-degree vertical field of view
    final focal = (size.height * 0.5) / math.tan(24.0 * math.pi / 180.0);
    final sx = size.width * 0.5 + (xCam / zCam) * focal;
    final sy = size.height * 0.5 - (yCam / zCam) * focal;

    return _ProjectedPoint(
      screen: Offset(sx, sy),
      depth: zCam,
      scale: focal / zCam,
    );
  }

  /// Exposes projected screen coordinates cleanly for hit-testing & tests.
  static Offset? projectPoint({
    required Vec3 worldPos,
    required Vec3 lookAt,
    required double dist,
    required double yaw,
    required double pitch,
    required Size size,
  }) {
    return _project(worldPos, lookAt, dist, yaw, pitch, size)?.screen;
  }

  /// Performs depth-sorted hit-testing against Star, Planets, and Moons.
  static SolarHitResult? hitTestBodies({
    required Offset tapPos,
    required Size size,
    required List<SolarPlanetData> planets,
    required SolarOrbitPhysics physics,
    required double yaw,
    required double pitch,
    required double zoomOffset,
  }) {
    final effectiveDist = (physics.cameraDistance + zoomOffset).clamp(4.0, 120.0);
    final candidates = <({double depth, SolarHitResult result})>[];

    final starProj = _project(
      Vec3.zero,
      physics.cameraLookAt,
      effectiveDist,
      yaw,
      pitch,
      size,
    );
    if (starProj != null) {
      final hitR = math.max(26.0, 4.2 * starProj.scale * 1.25);
      if ((starProj.screen - tapPos).distance <= hitR) {
        candidates.add((
          depth: starProj.depth,
          result: const SolarHitResult(kind: SolarFocusKind.star),
        ));
      }
    }

    for (final p in planets) {
      final pPos = physics.planetPosition(p);
      final pProj = _project(
        pPos,
        physics.cameraLookAt,
        effectiveDist,
        yaw,
        pitch,
        size,
      );
      if (pProj != null) {
        final hitR = math.max(20.0, p.radius * pProj.scale * 1.45);
        if ((pProj.screen - tapPos).distance <= hitR) {
          candidates.add((
            depth: pProj.depth,
            result: SolarHitResult(kind: SolarFocusKind.planet, planetId: p.id),
          ));
        }
      }

      final parentFocused = physics.focusedPlanetId == p.id;
      for (final m in p.moons) {
        final mPos = physics.moonPosition(p, m, isParentFocused: parentFocused);
        final mProj = _project(
          mPos,
          physics.cameraLookAt,
          effectiveDist,
          yaw,
          pitch,
          size,
        );
        if (mProj != null) {
          final hitR = math.max(15.0, m.radius * mProj.scale * 1.9);
          if ((mProj.screen - tapPos).distance <= hitR) {
            candidates.add((
              depth: mProj.depth - 0.5, // slightly favor moons when overlapping
              result: SolarHitResult(
                kind: SolarFocusKind.moon,
                planetId: p.id,
                moonId: m.id,
              ),
            ));
          }
        }
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.depth.compareTo(b.depth));
    return candidates.first.result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveDist = (physics.cameraDistance + zoomOffset).clamp(4.0, 120.0);

    // 1. Deep space backdrop gradient
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, -0.1),
          radius: 1.15,
          colors: isDark
              ? const [Color(0xFF0E172A), Color(0xFF050812), Color(0xFF020409)]
              : const [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF070B16)],
        ).createShader(Offset.zero & size),
    );

    // 2. Twinkling deep-space stars
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 110; i++) {
      final sx = ((i * 197.3) % 1000) / 1000.0 * size.width;
      final sy = ((i * 313.7) % 1000) / 1000.0 * size.height;
      final twinkle = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(elapsedSeconds * 1.8 + i));
      starPaint.color = (i % 5 == 0
              ? const Color(0xFF7DD3FC)
              : (i % 7 == 0 ? const Color(0xFFFDE68A) : Colors.white))
          .withValues(alpha: twinkle * 0.7);
      canvas.drawCircle(Offset(sx, sy), (i % 4 == 0) ? 1.8 : 1.0, starPaint);
    }

    // 3. Projected planetary orbital ellipses
    for (final p in planets) {
      final isFocused = physics.focusedPlanetId == p.id;
      final path = Path();
      bool started = false;
      const steps = 72;
      for (int i = 0; i <= steps; i++) {
        final a = (i / steps) * math.pi * 2;
        final cx = math.cos(a) * p.orbitRadius;
        final cz = math.sin(a) * p.orbitRadius;
        final pt = _project(
          Vec3(cx, cz * math.sin(p.inclination), cz * math.cos(p.inclination)),
          physics.cameraLookAt,
          effectiveDist,
          yaw,
          pitch,
          size,
        );
        if (pt != null) {
          if (!started) {
            path.moveTo(pt.screen.dx, pt.screen.dy);
            started = true;
          } else {
            path.lineTo(pt.screen.dx, pt.screen.dy);
          }
        }
      }
      if (started) {
        canvas.drawPath(
          path,
          Paint()
            ..color = p.color.withValues(
              alpha: physics.focusedPlanetId == null
                  ? 0.34
                  : (isFocused ? 0.72 : 0.14),
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = isFocused ? 1.6 : 1.0,
        );
      }
    }

    // 4. Collect depth-sorted celestial bodies (Star, Planets, Moons)
    final bodies = <_RenderBody>[];

    // Central Star
    final starProj = _project(
      Vec3.zero,
      physics.cameraLookAt,
      effectiveDist,
      yaw,
      pitch,
      size,
    );
    if (starProj != null) {
      bodies.add(
        _RenderBody(
          depth: starProj.depth,
          draw: () => _drawStar(canvas, starProj),
        ),
      );
    }

    // Planets & Moons
    for (final p in planets) {
      final pPos = physics.planetPosition(p);
      final pProj = _project(
        pPos,
        physics.cameraLookAt,
        effectiveDist,
        yaw,
        pitch,
        size,
      );
      final isFocusedPlanet = physics.focusedPlanetId == p.id;

      // Local moon orbit rings when visible
      if (pProj != null && (isFocusedPlanet || physics.focusKind == SolarFocusKind.overview)) {
        final expand = isFocusedPlanet ? 1.45 : 1.0;
        for (final m in p.moons) {
          final mPath = Path();
          bool mStarted = false;
          for (int k = 0; k <= 36; k++) {
            final a = (k / 36) * math.pi * 2;
            final r = m.orbitRadius * expand;
            final lx = math.cos(a) * r;
            final lz = math.sin(a) * r;
            final mPt = _project(
              Vec3(
                pPos.x + lx,
                pPos.y + lz * math.sin(m.inclination),
                pPos.z + lz * math.cos(m.inclination),
              ),
              physics.cameraLookAt,
              effectiveDist,
              yaw,
              pitch,
              size,
            );
            if (mPt != null) {
              if (!mStarted) {
                mPath.moveTo(mPt.screen.dx, mPt.screen.dy);
                mStarted = true;
              } else {
                mPath.lineTo(mPt.screen.dx, mPt.screen.dy);
              }
            }
          }
          if (mStarted) {
            canvas.drawPath(
              mPath,
              Paint()
                ..color = m.color.withValues(alpha: isFocusedPlanet ? 0.45 : 0.14)
                ..style = PaintingStyle.stroke
                ..strokeWidth = isFocusedPlanet ? 1.0 : 0.7,
            );
          }
        }
      }

      if (pProj != null) {
        bodies.add(
          _RenderBody(
            depth: pProj.depth,
            draw: () => _drawPlanet(
              canvas,
              p,
              pProj,
              isFocusedPlanet && physics.focusKind == SolarFocusKind.planet,
            ),
          ),
        );
      }

      for (final m in p.moons) {
        final mPos = physics.moonPosition(p, m, isParentFocused: isFocusedPlanet);
        final mProj = _project(
          mPos,
          physics.cameraLookAt,
          effectiveDist,
          yaw,
          pitch,
          size,
        );
        if (mProj != null) {
          final isFocusedMoon =
              physics.focusKind == SolarFocusKind.moon &&
                  physics.focusedMoonId == m.id;
          bodies.add(
            _RenderBody(
              depth: mProj.depth,
              draw: () => _drawMoon(
                canvas,
                m,
                mProj,
                showLabel: isFocusedPlanet || isFocusedMoon,
                isFocused: isFocusedMoon,
              ),
            ),
          );
        }
      }
    }

    // Painter's algorithm: farthest first
    bodies.sort((a, b) => b.depth.compareTo(a.depth));
    for (final body in bodies) {
      body.draw();
    }
  }

  void _drawStar(Canvas canvas, _ProjectedPoint proj) {
    final r = (4.2 * proj.scale).clamp(14.0, 120.0);
    // Multi-layer corona glow
    canvas.drawCircle(
      proj.screen,
      r * 2.35,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFDE68A).withValues(alpha: 0.55),
            const Color(0xFFF97316).withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: proj.screen, radius: r * 2.35)),
    );

    canvas.drawCircle(
      proj.screen,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.28, -0.28),
          colors: [
            Color(0xFFFFFBEB),
            Color(0xFFFBBF24),
            Color(0xFFEA580C),
          ],
        ).createShader(Rect.fromCircle(center: proj.screen, radius: r)),
    );

    if (physics.focusKind == SolarFocusKind.star) {
      _drawFocusReticle(canvas, proj.screen, r * 1.35, const Color(0xFFFBBF24));
    }

    _drawBadgeLabel(
      canvas,
      proj.screen + Offset(0, r + 14),
      '★ SIVAPRASAD NK',
      const Color(0xFFFBBF24),
    );
  }

  void _drawPlanet(
    Canvas canvas,
    SolarPlanetData planet,
    _ProjectedPoint proj,
    bool isFocused,
  ) {
    final r = (planet.radius * proj.scale).clamp(8.0, 76.0);

    if (planet.hasRing) {
      canvas.save();
      canvas.translate(proj.screen.dx, proj.screen.dy);
      canvas.rotate(-0.22);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 3.1, height: r * 0.92),
        Paint()
          ..color = planet.secondaryColor.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2.0, r * 0.24),
      );
      canvas.restore();
    }

    // Atmosphere halo
    canvas.drawCircle(
      proj.screen,
      r * 1.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            planet.color.withValues(alpha: 0.34),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: proj.screen, radius: r * 1.4)),
    );

    // Lit planet sphere
    canvas.drawCircle(
      proj.screen,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [
            Color.lerp(planet.color, Colors.white, 0.35)!,
            planet.color,
            Color.lerp(planet.secondaryColor, Colors.black, 0.45)!,
          ],
        ).createShader(Rect.fromCircle(center: proj.screen, radius: r)),
    );

    if (isFocused) {
      _drawFocusReticle(canvas, proj.screen, r * 1.5, planet.color);
    }

    _drawBadgeLabel(
      canvas,
      proj.screen + Offset(0, r + 12),
      planet.shortLabel,
      planet.color,
    );
  }

  void _drawMoon(
    Canvas canvas,
    SolarMoonData moon,
    _ProjectedPoint proj, {
    required bool showLabel,
    required bool isFocused,
  }) {
    final r = (moon.radius * proj.scale).clamp(4.0, 42.0);
    canvas.drawCircle(
      proj.screen,
      r * 1.45,
      Paint()..color = moon.color.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      proj.screen,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            Color.lerp(moon.color, Colors.white, 0.45)!,
            moon.color,
            Color.lerp(moon.color, Colors.black, 0.45)!,
          ],
        ).createShader(Rect.fromCircle(center: proj.screen, radius: r)),
    );

    if (isFocused) {
      _drawFocusReticle(canvas, proj.screen, r * 1.65, moon.color);
    }
    if (showLabel) {
      _drawBadgeLabel(
        canvas,
        proj.screen + Offset(0, r + 11),
        moon.title,
        moon.color,
        fontSize: isFocused ? 10.5 : 9.2,
      );
    }
  }

  void _drawFocusReticle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final rot = elapsedSeconds * 1.4;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (int i = 0; i < 4; i++) {
      final start = rot + i * (math.pi / 2);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        0.55,
        false,
        paint,
      );
    }
  }

  void _drawBadgeLabel(
    Canvas canvas,
    Offset center,
    String text,
    Color accentColor, {
    double fontSize = 10.0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.9,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCenter(
      center: center,
      width: tp.width + 12,
      height: tp.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(999)),
      Paint()..color = const Color(0xFF070B14).withValues(alpha: 0.80),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(999)),
      Paint()
        ..color = accentColor.withValues(alpha: 0.68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    tp.paint(canvas, Offset(rect.left + 6, rect.top + 3));
  }

  @override
  bool shouldRepaint(covariant Solar2dFallbackPainter oldDelegate) => true;
}
