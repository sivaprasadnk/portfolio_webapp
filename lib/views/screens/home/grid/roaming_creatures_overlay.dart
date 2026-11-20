import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Continuously roaming animated species living across the home screen viewport.
enum RoamingCreatureType {
  bird(label: 'BIRD', color: Color(0xFF38BDF8), accent: Color(0xFFFBBF24)),
  cat(label: 'CAT', color: Color(0xFFF472B6), accent: Color(0xFFFCE7F3)),
  dog(label: 'DOG', color: Color(0xFFF59E0B), accent: Color(0xFFFEF3C7)),
  bot(label: 'BOT', color: Color(0xFF10B981), accent: Color(0xFF00F0FF));

  const RoamingCreatureType({
    required this.label,
    required this.color,
    required this.accent,
  });

  final String label;
  final Color color;
  final Color accent;
}

enum RoamingParticleKind { star, heart, spark, feather }

class RoamingParticle {
  RoamingParticle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.kind,
    required this.size,
  });

  Offset position;
  Offset velocity;
  double life;
  final double maxLife;
  final Color color;
  final RoamingParticleKind kind;
  final double size;
}

class RoamingCreature {
  RoamingCreature({
    required this.id,
    required this.type,
    required this.position,
    required this.velocity,
    required this.baseSpeed,
    required this.size,
    required this.phaseOffset,
    required this.colorVariant,
  });

  final int id;
  final RoamingCreatureType type;
  Offset position;
  Offset velocity;
  final double baseSpeed;
  final double size;
  final double phaseOffset;
  final int colorVariant;

  bool facingRight = true;
  double excitedTimer = 0.0;
  double wanderAngle = 0.0;
  double speechTimer = 0.0;
  String? speechText;
  bool isScanningPointer = false;
  Offset? fetchTarget;
  Offset? patrolTarget;
}

/// Real-time 2D physics & mouse-reactivity simulation for roaming birds, cats,
/// dogs, and hovering bots across the viewport.
class RoamingCreaturesSimulation {
  final math.Random _rng = math.Random(42);
  final List<RoamingCreature> creatures = [];
  final List<RoamingParticle> particles = [];
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Offset _pickPatrolTarget(
    Size viewport,
    RoamingCreatureType type, {
    Offset? awayFrom,
  }) {
    const edgePad = 56.0;
    const topSafe = 92.0;
    final minX = edgePad;
    final maxX = math.max(minX + 10.0, viewport.width - edgePad);
    final minY = topSafe;
    final maxY = type == RoamingCreatureType.bird
        ? math.max(minY + 10.0, viewport.height * 0.52)
        : math.max(minY + 10.0, viewport.height - edgePad);

    double tx;
    if (awayFrom != null) {
      final midX = viewport.width * 0.5;
      // Pick target in the opposite horizontal half so creatures cross the screen
      if (awayFrom.dx >= midX) {
        tx = minX + _rng.nextDouble() * (midX - minX);
      } else {
        tx = midX + _rng.nextDouble() * (maxX - midX);
      }
    } else {
      tx = minX + _rng.nextDouble() * (maxX - minX);
    }
    final ty = minY + _rng.nextDouble() * (maxY - minY);
    return Offset(tx, ty);
  }

  void ensureInitialized(Size viewport, {bool compact = false}) {
    if (_initialized || viewport.width < 120 || viewport.height < 120) return;
    _initialized = true;
    creatures.clear();
    particles.clear();

    // 4 clean, uncluttered creatures: 1 bird, 1 cat, 1 dog, 1 bot
    final specs = compact
        ? const [
            (RoamingCreatureType.bird, 0.22, 0.20, 72.0, 26.0, 0),
            (RoamingCreatureType.cat, 0.78, 0.72, 48.0, 30.0, 0),
            (RoamingCreatureType.dog, 0.24, 0.82, 58.0, 32.0, 0),
            (RoamingCreatureType.bot, 0.74, 0.36, 52.0, 30.0, 0),
          ]
        : const [
            (RoamingCreatureType.bird, 0.20, 0.18, 82.0, 28.0, 0),
            (RoamingCreatureType.cat, 0.78, 0.72, 50.0, 32.0, 0),
            (RoamingCreatureType.dog, 0.28, 0.84, 62.0, 34.0, 0),
            (RoamingCreatureType.bot, 0.72, 0.34, 56.0, 32.0, 0),
          ];

    for (int i = 0; i < specs.length; i++) {
      final (type, nx, ny, speed, size, variant) = specs[i];
      final startPos = Offset(
        (viewport.width * nx).clamp(48.0, viewport.width - 48.0),
        (viewport.height * ny).clamp(90.0, viewport.height - 48.0),
      );
      final target = _pickPatrolTarget(viewport, type, awayFrom: startPos);
      final toTarget = target - startPos;
      final angle = math.atan2(toTarget.dy, toTarget.dx);
      final vx = math.cos(angle) * speed;
      final vy = math.sin(angle) * speed;
      final creature = RoamingCreature(
        id: i,
        type: type,
        position: startPos,
        velocity: Offset(vx, vy),
        baseSpeed: speed,
        size: size,
        phaseOffset: i * 1.35,
        colorVariant: variant,
      )
        ..facingRight = vx >= 0
        ..wanderAngle = angle
        ..patrolTarget = target;
      creatures.add(creature);
    }
  }

  void step(double dt, Size viewport, Offset? pointerPos) {
    if (!_initialized || viewport.width < 120 || viewport.height < 120) return;
    final clampedDt = dt.clamp(0.0, 0.05);
    const topSafe = 74.0;
    const edgePad = 28.0;

    for (final c in creatures) {
      if (c.excitedTimer > 0) {
        c.excitedTimer = math.max(0.0, c.excitedTimer - clampedDt);
      }
      if (c.speechTimer > 0) {
        c.speechTimer = math.max(0.0, c.speechTimer - clampedDt);
        if (c.speechTimer == 0) {
          c.speechText = null;
        }
      }
      c.isScanningPointer = false;

      // 1. Cross-viewport waypoint patrol steering + subtle organic sway
      c.patrolTarget ??=
          _pickPatrolTarget(viewport, c.type, awayFrom: c.position);
      final toPatrol = c.patrolTarget! - c.position;
      final patrolDist = toPatrol.distance;
      if (patrolDist < 58.0) {
        c.patrolTarget =
            _pickPatrolTarget(viewport, c.type, awayFrom: c.position);
      }
      final activePatrol = c.patrolTarget! - c.position;
      final activeDist = activePatrol.distance;
      final patrolDir = activeDist > 1.0
          ? activePatrol / activeDist
          : Offset(math.cos(c.wanderAngle), math.sin(c.wanderAngle));

      c.wanderAngle += (_rng.nextDouble() - 0.5) * 1.4 * clampedDt;
      var desiredAccel = patrolDir * 72.0 +
          Offset(
            math.cos(c.wanderAngle) * 14.0,
            math.sin(c.wanderAngle) *
                (c.type == RoamingCreatureType.bird ? 10.0 : 14.0),
          );

      // 2. Fetch target for excited dogs
      if (c.type == RoamingCreatureType.dog && c.fetchTarget != null) {
        final toFetch = c.fetchTarget! - c.position;
        final dist = toFetch.distance;
        if (dist < 24.0) {
          c.fetchTarget = null;
          c.excitedTimer = 0.9;
          _setSpeech(c, 'ARF! ★', 1.2);
          _spawnBurst(c.position, RoamingParticleKind.star, c.type.color, 5);
        } else {
          desiredAccel += (toFetch / dist) * 240.0;
        }
      }

      // 3. Species-specific mouse interaction
      if (pointerPos != null) {
        final toMouse = pointerPos - c.position;
        final dist = toMouse.distance;

        switch (c.type) {
          case RoamingCreatureType.bird:
            // Birds flutter & swoop away swiftly if the cursor gets close
            if (dist < 140.0 && dist > 1.0) {
              final away = -(toMouse / dist);
              final urgency = (1.0 - dist / 140.0).clamp(0.2, 1.0);
              desiredAccel += away * (310.0 * urgency);
              if (c.excitedTimer <= 0.05 && dist < 88.0) {
                c.excitedTimer = 0.75;
                _setSpeech(c, 'CHIRP!', 1.0);
                _spawnBurst(
                  c.position,
                  RoamingParticleKind.feather,
                  c.type.accent,
                  3,
                );
              }
            }
            break;

          case RoamingCreatureType.cat:
            // Cats playfully stalk/chase the cursor like a laser dot, pausing nearby
            if (dist < 195.0 && dist > 48.0) {
              desiredAccel += (toMouse / dist) * 145.0;
              if (c.speechTimer <= 0 && dist < 96.0) {
                _setSpeech(c, 'MEOW?', 1.1);
              }
            } else if (dist <= 48.0 && dist > 1.0) {
              // Orbit gently & paw at cursor
              final tangent = Offset(-toMouse.dy / dist, toMouse.dx / dist);
              desiredAccel += tangent * 120.0;
              if (c.excitedTimer <= 0.05) {
                c.excitedTimer = 0.65;
                _setSpeech(c, 'PURR ♥', 1.1);
                _spawnBurst(
                  c.position,
                  RoamingParticleKind.heart,
                  c.type.color,
                  2,
                );
              }
            }
            break;

          case RoamingCreatureType.dog:
            // Dogs enthusiastically trot toward the cursor and circle happily
            if (dist < 230.0 && dist > 52.0) {
              desiredAccel += (toMouse / dist) * 195.0;
              if (c.speechTimer <= 0 && dist < 120.0) {
                _setSpeech(c, 'WOOF!', 1.1);
              }
            } else if (dist <= 52.0 && dist > 1.0) {
              final tangent = Offset(toMouse.dy / dist, -toMouse.dx / dist);
              desiredAccel += tangent * 175.0;
            }
            break;

          case RoamingCreatureType.bot:
            // Bots orbit smoothly around the pointer and project a cyan scan beam
            if (dist < 190.0 && dist > 1.0) {
              c.isScanningPointer = true;
              final dir = toMouse / dist;
              final tangent = Offset(-dir.dy, dir.dx);
              final radialPull = dist > 95.0
                  ? dir * 130.0
                  : (dist < 65.0 ? -dir * 120.0 : Offset.zero);
              desiredAccel += radialPull + tangent * 135.0;
              if (c.speechTimer <= 0 && dist < 115.0) {
                _setSpeech(c, 'SCANNING...', 1.1);
              }
            }
            break;
        }
      }

      // 4. Integrate velocity and enforce smooth speed envelope
      c.velocity += desiredAccel * clampedDt;
      final speed = c.velocity.distance;
      final maxSpeed = c.baseSpeed * (c.excitedTimer > 0 ? 1.85 : 1.35);
      final minSpeed = c.baseSpeed * 0.45;
      if (speed > maxSpeed && speed > 0.001) {
        c.velocity = (c.velocity / speed) * maxSpeed;
      } else if (speed < minSpeed) {
        final fallbackDir = speed > 0.001
            ? c.velocity / speed
            : Offset(math.cos(c.wanderAngle), math.sin(c.wanderAngle));
        c.velocity = fallbackDir * minSpeed;
      }

      c.position += c.velocity * clampedDt;

      // 5. Crisp viewport boundaries with inward rebound & opposite-side patrol retarget
      var hitEdge = false;
      final minBounceSpeed = c.baseSpeed * 0.65;
      if (c.position.dx < edgePad) {
        c.position = Offset(edgePad, c.position.dy);
        c.velocity = Offset(
          math.max(c.velocity.dx.abs(), minBounceSpeed),
          c.velocity.dy,
        );
        hitEdge = true;
      } else if (c.position.dx > viewport.width - edgePad) {
        c.position = Offset(viewport.width - edgePad, c.position.dy);
        c.velocity = Offset(
          -math.max(c.velocity.dx.abs(), minBounceSpeed),
          c.velocity.dy,
        );
        hitEdge = true;
      }

      if (c.position.dy < topSafe) {
        c.position = Offset(c.position.dx, topSafe);
        c.velocity = Offset(
          c.velocity.dx,
          math.max(c.velocity.dy.abs(), minBounceSpeed * 0.5),
        );
        hitEdge = true;
      } else if (c.position.dy > viewport.height - edgePad) {
        c.position = Offset(c.position.dx, viewport.height - edgePad);
        c.velocity = Offset(
          c.velocity.dx,
          -math.max(c.velocity.dy.abs(), minBounceSpeed * 0.5),
        );
        hitEdge = true;
      }

      if (hitEdge) {
        c.wanderAngle = math.atan2(c.velocity.dy, c.velocity.dx);
        c.patrolTarget =
            _pickPatrolTarget(viewport, c.type, awayFrom: c.position);
      }

      if (c.velocity.dx.abs() > 4.0) {
        c.facingRight = c.velocity.dx >= 0;
      }
    }

    // 6. Update particles
    for (final p in particles) {
      p.life -= clampedDt;
      p.position += p.velocity * clampedDt;
      p.velocity = Offset(p.velocity.dx * 0.96, p.velocity.dy + 22.0 * clampedDt);
    }
    particles.removeWhere((p) => p.life <= 0);
  }

  /// Reacts to pointer clicks/taps anywhere on the screen.
  /// Returns the tapped creature if the tap landed directly near one.
  RoamingCreature? handlePointerDown(
    Offset pos, {
    void Function(RoamingCreature creature)? onCreatureTapped,
  }) {
    if (!_initialized) return null;
    RoamingCreature? tapped;

    for (final c in creatures) {
      final dist = (c.position - pos).distance;
      if (dist <= c.size * 1.45) {
        tapped ??= c;
        c.excitedTimer = 1.2;
        switch (c.type) {
          case RoamingCreatureType.bird:
            _setSpeech(c, 'WHEEE! ✨', 1.4);
            c.velocity = Offset(c.velocity.dx * 1.4, -135.0);
            _spawnBurst(c.position, RoamingParticleKind.feather, c.type.accent, 6);
            break;
          case RoamingCreatureType.cat:
            _setSpeech(c, 'PURRRR ♥', 1.4);
            _spawnBurst(c.position, RoamingParticleKind.heart, c.type.color, 6);
            break;
          case RoamingCreatureType.dog:
            _setSpeech(c, 'GOOD BOY! ★', 1.4);
            _spawnBurst(c.position, RoamingParticleKind.star, c.type.color, 6);
            break;
          case RoamingCreatureType.bot:
            _setSpeech(c, 'OVERCLOCKED ⚡', 1.4);
            _spawnBurst(c.position, RoamingParticleKind.spark, c.type.accent, 7);
            break;
        }
        onCreatureTapped?.call(c);
      } else if (c.type == RoamingCreatureType.dog && dist < 320.0) {
        // Nearby dogs playfully fetch the click ripple!
        c.fetchTarget = pos;
        _setSpeech(c, 'FETCH!', 1.0);
      }
    }

    return tapped;
  }

  void _setSpeech(RoamingCreature c, String text, double duration) {
    c.speechText = text;
    c.speechTimer = duration;
  }

  void _spawnBurst(
    Offset origin,
    RoamingParticleKind kind,
    Color color,
    int count,
  ) {
    for (int i = 0; i < count; i++) {
      final ang = (i / count) * math.pi * 2 + _rng.nextDouble() * 0.6;
      final spd = 28.0 + _rng.nextDouble() * 52.0;
      particles.add(
        RoamingParticle(
          position: origin,
          velocity: Offset(math.cos(ang) * spd, math.sin(ang) * spd - 24.0),
          life: 0.75 + _rng.nextDouble() * 0.35,
          maxLife: 1.1,
          color: color,
          kind: kind,
          size: 3.5 + _rng.nextDouble() * 2.5,
        ),
      );
    }
    if (particles.length > 60) {
      particles.removeRange(0, particles.length - 60);
    }
  }
}

/// Non-blocking visual layer that paints all continuously roaming birds, cats,
/// dogs, and bots along with scanner beams, particles, and speech bubbles.
class RoamingCreaturesOverlay extends StatelessWidget {
  const RoamingCreaturesOverlay({
    super.key,
    required this.simulation,
    required this.elapsedSeconds,
    required this.pointerPos,
    required this.isDark,
    required this.accent,
    required this.secondary,
  });

  final RoamingCreaturesSimulation simulation;
  final double elapsedSeconds;
  final Offset? pointerPos;
  final bool isDark;
  final Color accent;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        isComplex: true,
        painter: _RoamingCreaturesPainter(
          creatures: simulation.creatures,
          particles: simulation.particles,
          t: elapsedSeconds,
          pointerPos: pointerPos,
          isDark: isDark,
          accent: accent,
          secondary: secondary,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RoamingCreaturesPainter extends CustomPainter {
  _RoamingCreaturesPainter({
    required this.creatures,
    required this.particles,
    required this.t,
    required this.pointerPos,
    required this.isDark,
    required this.accent,
    required this.secondary,
  });

  final List<RoamingCreature> creatures;
  final List<RoamingParticle> particles;
  final double t;
  final Offset? pointerPos;
  final bool isDark;
  final Color accent;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw particles behind creatures
    for (final p in particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: alpha * 0.9);
      switch (p.kind) {
        case RoamingParticleKind.heart:
          _drawHeart(canvas, p.position, p.size, paint);
          break;
        case RoamingParticleKind.feather:
          canvas.save();
          canvas.translate(p.position.dx, p.position.dy);
          canvas.rotate(t * 4.0 + p.size);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 2.0,
              height: p.size * 0.85,
            ),
            paint,
          );
          canvas.restore();
          break;
        case RoamingParticleKind.star:
        case RoamingParticleKind.spark:
          canvas.drawCircle(p.position, p.size * 0.65, paint);
          break;
      }
    }

    // 2. Draw each roaming creature + optional bot scanner beam + speech pill
    for (final c in creatures) {
      if (c.isScanningPointer && pointerPos != null) {
        _drawBotScanBeam(canvas, c.position, pointerPos!);
      }

      canvas.save();
      canvas.translate(c.position.dx, c.position.dy);

      // Soft ambient ground/air shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, c.size * 0.48),
          width: c.size * 0.9,
          height: c.size * 0.24,
        ),
        Paint()
          ..color = (isDark ? Colors.black : const Color(0xFF0F172A))
              .withValues(alpha: isDark ? 0.32 : 0.14),
      );

      // Excited hop bounce
      final hopY = c.excitedTimer > 0
          ? -math.sin(c.excitedTimer * math.pi * 3.0).abs() * c.size * 0.28
          : 0.0;
      canvas.translate(0, hopY);

      if (!c.facingRight) {
        canvas.scale(-1, 1);
      }

      switch (c.type) {
        case RoamingCreatureType.bird:
          _drawBird(canvas, c);
          break;
        case RoamingCreatureType.cat:
          _drawCat(canvas, c);
          break;
        case RoamingCreatureType.dog:
          _drawDog(canvas, c);
          break;
        case RoamingCreatureType.bot:
          _drawBot(canvas, c);
          break;
      }
      canvas.restore();

      if (c.speechText != null && c.speechTimer > 0) {
        _drawSpeechTag(
          canvas,
          c.position + Offset(0, -c.size * 0.88),
          c.speechText!,
          c.type.color,
          math.min(1.0, c.speechTimer * 2.0),
        );
      }
    }
  }

  void _drawBird(Canvas canvas, RoamingCreature c) {
    final s = c.size;
    final flapSpeed = c.excitedTimer > 0 ? 22.0 : 12.0;
    final flap = math.sin(t * flapSpeed + c.phaseOffset);
    final bodyColor = c.colorVariant == 0
        ? const Color(0xFF38BDF8)
        : (c.colorVariant == 1
            ? const Color(0xFFA855F7)
            : const Color(0xFF2DD4BF));

    // Tail feathers
    final tail = Path()
      ..moveTo(-s * 0.34, 0)
      ..lineTo(-s * 0.56, -s * 0.14)
      ..lineTo(-s * 0.52, s * 0.08)
      ..close();
    canvas.drawPath(tail, Paint()..color = bodyColor.withValues(alpha: 0.85));

    // Streamlined body
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.72, height: s * 0.44),
      Paint()..color = bodyColor,
    );
    // Belly highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.02, s * 0.08),
        width: s * 0.42,
        height: s * 0.20,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );

    // Flapping wing
    final wingPath = Path()
      ..moveTo(-s * 0.10, -s * 0.02)
      ..quadraticBezierTo(
        -s * 0.02,
        -s * (0.20 + flap * 0.36),
        s * 0.14,
        -s * (0.04 + flap * 0.24),
      )
      ..close();
    canvas.drawPath(
      wingPath,
      Paint()..color = Color.lerp(bodyColor, Colors.white, 0.25)!,
    );

    // Head eye + golden beak
    canvas.drawCircle(
      Offset(s * 0.22, -s * 0.06),
      s * 0.075,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(s * 0.24, -s * 0.06),
      s * 0.04,
      Paint()..color = const Color(0xFF0F172A),
    );
    final beak = Path()
      ..moveTo(s * 0.34, -s * 0.04)
      ..lineTo(s * 0.50, s * 0.01)
      ..lineTo(s * 0.34, s * 0.07)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFBBF24));
  }

  void _drawCat(Canvas canvas, RoamingCreature c) {
    final s = c.size;
    final stride = math.sin(t * 10.5 + c.phaseOffset);
    final furColor = c.colorVariant == 0
        ? const Color(0xFF334155)
        : const Color(0xFFF472B6);
    final trimColor = c.colorVariant == 0
        ? const Color(0xFFF472B6)
        : const Color(0xFF0F172A);

    // Swishing curved tail
    final tailSwing = math.sin(t * 6.5 + c.phaseOffset) * s * 0.16;
    final tail = Path()
      ..moveTo(-s * 0.32, s * 0.02)
      ..quadraticBezierTo(
        -s * 0.56,
        -s * 0.12 + tailSwing,
        -s * 0.44,
        -s * 0.36 + tailSwing,
      );
    canvas.drawPath(
      tail,
      Paint()
        ..color = furColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.10
        ..strokeCap = StrokeCap.round,
    );

    // Walking legs
    final legPaint = Paint()
      ..color = furColor
      ..strokeWidth = s * 0.095
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-s * 0.18, s * 0.16),
      Offset(-s * 0.18 + stride * s * 0.10, s * 0.38),
      legPaint,
    );
    canvas.drawLine(
      Offset(s * 0.16, s * 0.16),
      Offset(s * 0.16 - stride * s * 0.10, s * 0.38),
      legPaint,
    );

    // Torso
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.02, s * 0.06),
          width: s * 0.64,
          height: s * 0.34,
        ),
        Radius.circular(s * 0.16),
      ),
      Paint()..color = furColor,
    );

    // Head + pointy ears
    final headCenter = Offset(s * 0.28, -s * 0.10);
    for (final ex in [-s * 0.09, s * 0.08]) {
      final ear = Path()
        ..moveTo(headCenter.dx + ex - s * 0.06, headCenter.dy - s * 0.08)
        ..lineTo(headCenter.dx + ex, headCenter.dy - s * 0.24)
        ..lineTo(headCenter.dx + ex + s * 0.06, headCenter.dy - s * 0.08)
        ..close();
      canvas.drawPath(ear, Paint()..color = furColor);
    }
    canvas.drawCircle(headCenter, s * 0.19, Paint()..color = furColor);
    canvas.drawCircle(
      headCenter + Offset(s * 0.06, -s * 0.03),
      s * 0.045,
      Paint()..color = const Color(0xFF38BDF8),
    );
    canvas.drawCircle(
      headCenter + Offset(s * 0.14, s * 0.03),
      s * 0.03,
      Paint()..color = trimColor,
    );
  }

  void _drawDog(Canvas canvas, RoamingCreature c) {
    final s = c.size;
    final trot = math.sin(t * 13.5 + c.phaseOffset);
    final coatColor = c.colorVariant == 0
        ? const Color(0xFFF59E0B)
        : const Color(0xFFD97706);
    final earColor = const Color(0xFF78350F);

    // Rapidly wagging tail
    final wag = math.sin(t * (c.excitedTimer > 0 ? 28.0 : 16.0) + c.phaseOffset) *
        s *
        0.18;
    canvas.drawLine(
      Offset(-s * 0.34, -s * 0.02),
      Offset(-s * 0.54, -s * 0.22 + wag),
      Paint()
        ..color = coatColor
        ..strokeWidth = s * 0.10
        ..strokeCap = StrokeCap.round,
    );

    // Trotting legs
    final legPaint = Paint()
      ..color = coatColor
      ..strokeWidth = s * 0.10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-s * 0.20, s * 0.16),
      Offset(-s * 0.20 + trot * s * 0.12, s * 0.39),
      legPaint,
    );
    canvas.drawLine(
      Offset(s * 0.18, s * 0.16),
      Offset(s * 0.18 - trot * s * 0.12, s * 0.39),
      legPaint,
    );

    // Sturdy pup body + red collar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.02, s * 0.05),
          width: s * 0.68,
          height: s * 0.36,
        ),
        Radius.circular(s * 0.16),
      ),
      Paint()..color = coatColor,
    );
    canvas.drawLine(
      Offset(s * 0.16, -s * 0.08),
      Offset(s * 0.24, s * 0.10),
      Paint()
        ..color = const Color(0xFFEF4444)
        ..strokeWidth = s * 0.065
        ..strokeCap = StrokeCap.round,
    );

    // Head, snout, floppy ear, and happy tongue
    final headCenter = Offset(s * 0.30, -s * 0.12);
    canvas.drawCircle(headCenter, s * 0.19, Paint()..color = coatColor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: headCenter + Offset(s * 0.16, s * 0.03),
          width: s * 0.20,
          height: s * 0.13,
        ),
        Radius.circular(s * 0.06),
      ),
      Paint()..color = const Color(0xFFFEF3C7),
    );
    // Floppy bouncing ear
    canvas.drawOval(
      Rect.fromCenter(
        center: headCenter + Offset(-s * 0.07, s * 0.04 + trot * s * 0.04),
        width: s * 0.13,
        height: s * 0.22,
      ),
      Paint()..color = earColor,
    );
    // Eye & nose
    canvas.drawCircle(
      headCenter + Offset(s * 0.06, -s * 0.04),
      s * 0.04,
      Paint()..color = const Color(0xFF0F172A),
    );
    canvas.drawCircle(
      headCenter + Offset(s * 0.24, 0),
      s * 0.04,
      Paint()..color = const Color(0xFF0F172A),
    );
    // Pink tongue
    canvas.drawOval(
      Rect.fromCenter(
        center: headCenter + Offset(s * 0.16, s * 0.11),
        width: s * 0.07,
        height: s * 0.09,
      ),
      Paint()..color = const Color(0xFFF43F5E),
    );
  }

  void _drawBot(Canvas canvas, RoamingCreature c) {
    final s = c.size;
    final hover = math.sin(t * 5.2 + c.phaseOffset) * s * 0.08;
    canvas.translate(0, hover);

    // Thruster flame
    final flameH = s * (0.18 + 0.07 * math.sin(t * 26.0 + c.phaseOffset));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.30 + flameH * 0.25),
        width: s * 0.22,
        height: flameH,
      ),
      Paint()..color = const Color(0xFF00F0FF).withValues(alpha: 0.78),
    );

    // Antenna
    canvas.drawLine(
      Offset(0, -s * 0.26),
      Offset(0, -s * 0.42),
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = s * 0.05,
    );
    canvas.drawCircle(
      Offset(0, -s * 0.44),
      s * 0.07,
      Paint()
        ..color = c.isScanningPointer
            ? const Color(0xFF00F0FF)
            : const Color(0xFF10B981),
    );

    // Hover bot shell
    final shell = Rect.fromCenter(
      center: Offset.zero,
      width: s * 0.66,
      height: s * 0.54,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shell, Radius.circular(s * 0.16)),
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shell, Radius.circular(s * 0.16)),
      Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.045,
    );

    // Dark LED visor + glowing eyes
    final visor = Rect.fromCenter(
      center: Offset(s * 0.04, -s * 0.02),
      width: s * 0.44,
      height: s * 0.24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(visor, Radius.circular(s * 0.08)),
      Paint()..color = const Color(0xFF020617),
    );
    final eyeColor = c.isScanningPointer
        ? const Color(0xFF00F0FF)
        : const Color(0xFF34D399);
    canvas.drawCircle(
      Offset(-s * 0.05, -s * 0.02),
      s * 0.055,
      Paint()..color = eyeColor,
    );
    canvas.drawCircle(
      Offset(s * 0.13, -s * 0.02),
      s * 0.055,
      Paint()..color = eyeColor,
    );
  }

  void _drawBotScanBeam(Canvas canvas, Offset origin, Offset target) {
    final dir = target - origin;
    final len = dir.distance;
    if (len < 6.0) return;
    final perp = Offset(-dir.dy / len, dir.dx / len) * 18.0;
    final beam = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(target.dx + perp.dx, target.dy + perp.dy)
      ..lineTo(target.dx - perp.dx, target.dy - perp.dy)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00F0FF).withValues(alpha: 0.24),
            const Color(0xFF00F0FF).withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromPoints(origin, target)),
    );
  }

  void _drawHeart(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy + r * 0.7)
      ..cubicTo(c.dx - r * 1.1, c.dy, c.dx - r * 0.8, c.dy - r * 0.9, c.dx, c.dy - r * 0.25)
      ..cubicTo(c.dx + r * 0.8, c.dy - r * 0.9, c.dx + r * 1.1, c.dy, c.dx, c.dy + r * 0.7);
    canvas.drawPath(path, paint);
  }

  void _drawSpeechTag(
    Canvas canvas,
    Offset center,
    String text,
    Color borderColor,
    double alpha,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.7,
          color: Colors.white.withValues(alpha: alpha),
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
      Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.86 * alpha),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(999)),
      Paint()
        ..color = borderColor.withValues(alpha: 0.85 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    tp.paint(canvas, Offset(rect.left + 6, rect.top + 3));
  }

  @override
  bool shouldRepaint(covariant _RoamingCreaturesPainter oldDelegate) => true;
}
