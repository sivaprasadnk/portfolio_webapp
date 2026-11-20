import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';

/// Five custom-animated vector mascot characters living on the Home grid.
enum GridCharacterKind {
  spnkBot(
    code: 'BOT-01',
    label: 'SPNK-BOT',
    role: 'System Architect Bot',
    primaryColor: Color(0xFF38BDF8),
    secondaryColor: Color(0xFFA855F7),
    quotes: [
      'Compiling 60fps UI!',
      'Clean Arch initialized!',
      'Grid systems at 100%!',
    ],
  ),
  nekoCat(
    code: 'CAT-02',
    label: 'NEKO.DART',
    role: 'Felintrovert Pair Coder',
    primaryColor: Color(0xFFF472B6),
    secondaryColor: Color(0xFF38BDF8),
    quotes: [
      'Purr-fect null safety!',
      'Shipping Dart packages!',
      'Night coding mode: ON!',
    ],
  ),
  flutterDash(
    code: 'DSH-03',
    label: 'DASH',
    role: 'Flutter Sky Mascot',
    primaryColor: Color(0xFF0EA5E9),
    secondaryColor: Color(0xFFFBBF24),
    quotes: [
      'Hot reload complete!',
      'Everything is a Widget!',
      'Compiled to Wasm GC!',
    ],
  ),
  m3Racer(
    code: 'GTR-04',
    label: 'M3-DRIFT',
    role: 'Rockport Street Runner',
    primaryColor: Color(0xFFE2E8F0),
    secondaryColor: Color(0xFF2563EB),
    quotes: [
      'Full boost on /v2!',
      'Nitro tank pressurized!',
      'See you in Rockport!',
    ],
  ),
  commsDrone(
    code: 'COM-05',
    label: 'COMMS-BOT',
    role: 'Orbital Telemetry Relay',
    primaryColor: Color(0xFF10B981),
    secondaryColor: Color(0xFF38BDF8),
    quotes: [
      'Signal strength: 5/5!',
      'Hailing Sivaprasad NK...',
      'Uplink encrypted!',
    ],
  );

  const GridCharacterKind({
    required this.code,
    required this.label,
    required this.role,
    required this.primaryColor,
    required this.secondaryColor,
    required this.quotes,
  });

  final String code;
  final String label;
  final String role;
  final Color primaryColor;
  final Color secondaryColor;
  final List<String> quotes;
}

/// Renders one of 5 bespoke CustomPainter animated characters that tracks the
/// cursor with its eyes/antennas, bounces/waves smoothly, and reacts to taps.
class AnimatedPortfolioCharacter extends StatefulWidget {
  const AnimatedPortfolioCharacter({
    super.key,
    required this.kind,
    required this.elapsedSeconds,
    this.pointerNorm = Offset.zero,
    this.size = 96.0,
    this.isDancing = false,
    this.showSpeechOnTap = true,
    this.onTap,
  });

  final GridCharacterKind kind;
  final double elapsedSeconds;
  final Offset pointerNorm;
  final double size;
  final bool isDancing;
  final bool showSpeechOnTap;
  final VoidCallback? onTap;

  @override
  State<AnimatedPortfolioCharacter> createState() =>
      _AnimatedPortfolioCharacterState();
}

class _AnimatedPortfolioCharacterState
    extends State<AnimatedPortfolioCharacter> {
  bool _hovered = false;
  double _excitedUntil = -1.0;
  int _quoteIndex = 0;

  void _handleTap() {
    setState(() {
      _excitedUntil = widget.elapsedSeconds + 1.1;
      _quoteIndex = (_quoteIndex + 1) % widget.kind.quotes.length;
    });
    GamificationController.instance.addXp(
      5,
      reason: 'High-fived ${widget.kind.label}!',
      uniqueKey: 'char_${widget.kind.name}',
    );
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final excited =
        ((_excitedUntil - widget.elapsedSeconds) / 1.1).clamp(0.0, 1.0);
    final quote = widget.kind.quotes[_quoteIndex];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _switchPainter(excited),
              ),
              if (excited > 0.05 && widget.showSpeechOnTap)
                Positioned(
                  top: -26,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: math.min(1.0, excited * 1.4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: widget.kind.primaryColor,
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.kind.primaryColor
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          quote,
                          style: context.bodySmall.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  CustomPainter _switchPainter(double excited) {
    switch (widget.kind) {
      case GridCharacterKind.spnkBot:
        return _SpnkBotPainter(
          t: widget.elapsedSeconds,
          pointerNorm: widget.pointerNorm,
          hovered: _hovered,
          excited: excited,
          isDancing: widget.isDancing,
        );
      case GridCharacterKind.nekoCat:
        return _NekoCatPainter(
          t: widget.elapsedSeconds,
          pointerNorm: widget.pointerNorm,
          hovered: _hovered,
          excited: excited,
          isDancing: widget.isDancing,
        );
      case GridCharacterKind.flutterDash:
        return _FlutterDashPainter(
          t: widget.elapsedSeconds,
          pointerNorm: widget.pointerNorm,
          hovered: _hovered,
          excited: excited,
          isDancing: widget.isDancing,
        );
      case GridCharacterKind.m3Racer:
        return _M3RacerPainter(
          t: widget.elapsedSeconds,
          pointerNorm: widget.pointerNorm,
          hovered: _hovered,
          excited: excited,
          isDancing: widget.isDancing,
        );
      case GridCharacterKind.commsDrone:
        return _CommsDronePainter(
          t: widget.elapsedSeconds,
          pointerNorm: widget.pointerNorm,
          hovered: _hovered,
          excited: excited,
          isDancing: widget.isDancing,
        );
    }
  }
}

bool _isBlinkFrame(double t, double period) {
  final phase = t % period;
  return phase > period - 0.14;
}

void _drawExcitedBurst(Canvas canvas, Offset center, double r, double excited,
    Color c1, Color c2) {
  if (excited <= 0.02) return;
  final starPaint = Paint()..style = PaintingStyle.fill;
  for (int i = 0; i < 6; i++) {
    final ang = (i / 6.0) * math.pi * 2 + (1.0 - excited) * 2.2;
    final dist = r * (0.72 + (1.0 - excited) * 0.38);
    final pos = center + Offset(math.cos(ang) * dist, math.sin(ang) * dist);
    starPaint.color = (i.isEven ? c1 : c2).withValues(alpha: excited * 0.9);
    canvas.drawCircle(pos, r * 0.055 * (0.6 + excited * 0.6), starPaint);
  }
}

class _SpnkBotPainter extends CustomPainter {
  _SpnkBotPainter({
    required this.t,
    required this.pointerNorm,
    required this.hovered,
    required this.excited,
    required this.isDancing,
  });

  final double t;
  final Offset pointerNorm;
  final bool hovered;
  final double excited;
  final bool isDancing;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final hoverMult = hovered ? 1.5 : 1.0;
    final danceSway = isDancing ? math.sin(t * 7.2) * s * 0.06 : 0.0;
    final jump = math.sin(excited * math.pi) * s * 0.14;
    final bob = math.sin(t * 3.4 * hoverMult) * s * 0.04 - jump;

    canvas.save();
    canvas.translate(cx + danceSway, cy + bob);
    if (isDancing) {
      canvas.rotate(math.sin(t * 7.2) * 0.12);
    }

    // Shadow / plasma thruster flame beneath bot
    final flameLen = s * (0.14 + 0.05 * math.sin(t * 24.0) + excited * 0.08);
    final flamePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF38BDF8),
          const Color(0xFFA855F7).withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromLTWH(-s * 0.14, s * 0.24, s * 0.28, flameLen));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-s * 0.10, s * 0.28 + flameLen * 0.3),
        width: s * 0.09,
        height: flameLen,
      ),
      flamePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.10, s * 0.28 + flameLen * 0.3),
        width: s * 0.09,
        height: flameLen,
      ),
      flamePaint,
    );

    // Waving left & right arms
    final waveR =
        -0.55 + math.sin(t * 6.5 * hoverMult + excited * 5.0) * (hovered ? 0.55 : 0.32);
    final waveL = 0.35 + math.sin(t * 4.0) * 0.16;

    void drawArm(double sideX, double angle) {
      canvas.save();
      canvas.translate(sideX, s * 0.07);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, s * 0.10), width: s * 0.09, height: s * 0.22),
          Radius.circular(s * 0.045),
        ),
        Paint()..color = const Color(0xFF38BDF8),
      );
      canvas.drawCircle(
        Offset(0, s * 0.21),
        s * 0.045,
        Paint()..color = const Color(0xFFA855F7),
      );
      canvas.restore();
    }

    drawArm(-s * 0.27, waveL);
    drawArm(s * 0.27, waveR);

    // Rounded metallic chassis torso
    final bodyRect = Rect.fromCenter(
      center: Offset(0, s * 0.10),
      width: s * 0.42,
      height: s * 0.34,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(s * 0.10)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ).createShader(bodyRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(s * 0.10)),
      Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02,
    );

    // Pulsing chest reactor core
    final corePulse = 0.7 + 0.3 * math.sin(t * 5.0);
    canvas.drawCircle(
      Offset(0, s * 0.10),
      s * 0.08 * corePulse,
      Paint()..color = const Color(0xFFA855F7).withValues(alpha: 0.38),
    );
    canvas.drawCircle(
      Offset(0, s * 0.10),
      s * 0.045,
      Paint()..color = const Color(0xFF38BDF8),
    );

    // Head dome + antenna
    final antSwing = math.sin(t * 4.5) * s * 0.03;
    canvas.drawLine(
      Offset(0, -s * 0.28),
      Offset(antSwing, -s * 0.41),
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = s * 0.025
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(antSwing, -s * 0.42),
      s * (0.04 + 0.012 * math.sin(t * 8.0)),
      Paint()..color = excited > 0 ? const Color(0xFFFBBF24) : const Color(0xFFA855F7),
    );

    final headRect = Rect.fromCenter(
      center: Offset(0, -s * 0.16),
      width: s * 0.44,
      height: s * 0.28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(s * 0.10)),
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(s * 0.10)),
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02,
    );

    // Visor + cursor-tracking glowing LED eyes
    final visorRect = Rect.fromCenter(
      center: Offset(0, -s * 0.16),
      width: s * 0.34,
      height: s * 0.15,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(visorRect, Radius.circular(s * 0.06)),
      Paint()..color = const Color(0xFF020617),
    );

    final eyeShift = Offset(pointerNorm.dx * s * 0.045, pointerNorm.dy * s * 0.025);
    final blink = _isBlinkFrame(t, 3.6);
    final eyePaint = Paint()..color = const Color(0xFF00F0FF);
    for (final ex in [-s * 0.075, s * 0.075]) {
      final ec = Offset(ex, -s * 0.16) + eyeShift;
      if (blink) {
        canvas.drawLine(
          Offset(ec.dx - s * 0.032, ec.dy),
          Offset(ec.dx + s * 0.032, ec.dy),
          Paint()
            ..color = const Color(0xFF00F0FF)
            ..strokeWidth = s * 0.02,
        );
      } else {
        canvas.drawCircle(ec, s * 0.034, eyePaint);
        canvas.drawCircle(
          ec + Offset(-s * 0.01, -s * 0.01),
          s * 0.011,
          Paint()..color = Colors.white,
        );
      }
    }

    _drawExcitedBurst(
      canvas,
      Offset.zero,
      s * 0.56,
      excited,
      const Color(0xFF38BDF8),
      const Color(0xFFFBBF24),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpnkBotPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.pointerNorm != pointerNorm ||
      oldDelegate.hovered != hovered ||
      oldDelegate.excited != excited ||
      oldDelegate.isDancing != isDancing;
}

class _NekoCatPainter extends CustomPainter {
  _NekoCatPainter({
    required this.t,
    required this.pointerNorm,
    required this.hovered,
    required this.excited,
    required this.isDancing,
  });

  final double t;
  final Offset pointerNorm;
  final bool hovered;
  final double excited;
  final bool isDancing;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final danceY = isDancing ? math.sin(t * 7.5).abs() * -s * 0.08 : 0.0;
    final hop = math.sin(excited * math.pi) * -s * 0.12;
    final breath = math.sin(t * 3.0) * s * 0.015;

    canvas.save();
    canvas.translate(cx, cy + danceY + hop + breath);

    // Swishing curved tail
    final tailSwing = math.sin(t * (hovered ? 7.0 : 3.8)) * s * 0.14;
    final tailPath = Path()
      ..moveTo(s * 0.16, s * 0.14)
      ..quadraticBezierTo(
        s * 0.36,
        s * 0.10 + tailSwing * 0.5,
        s * 0.34,
        -s * 0.08 + tailSwing,
      );
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = const Color(0xFFF472B6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.055
        ..strokeCap = StrokeCap.round,
    );

    // Cat torso
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, s * 0.12), width: s * 0.36, height: s * 0.32),
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, s * 0.15), width: s * 0.22, height: s * 0.20),
      Paint()..color = const Color(0xFFFCE7F3).withValues(alpha: 0.9),
    );

    // Cat ears (subtle twitch)
    final earTwitch = math.sin(t * 5.5) * 0.05;
    void drawEar(double sign) {
      final path = Path()
        ..moveTo(sign * s * 0.06, -s * 0.22)
        ..lineTo(sign * s * 0.21, -s * 0.38 + (sign > 0 ? earTwitch : 0) * s)
        ..lineTo(sign * s * 0.22, -s * 0.12)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFF1E293B));
      final inner = Path()
        ..moveTo(sign * s * 0.09, -s * 0.21)
        ..lineTo(sign * s * 0.18, -s * 0.32)
        ..lineTo(sign * s * 0.18, -s * 0.15)
        ..close();
      canvas.drawPath(inner, Paint()..color = const Color(0xFFF472B6));
    }

    drawEar(-1);
    drawEar(1);

    // Cat head
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -s * 0.10), width: s * 0.42, height: s * 0.33),
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -s * 0.10), width: s * 0.42, height: s * 0.33),
      Paint()
        ..color = const Color(0xFFF472B6).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018,
    );

    // Cursor-tracking bright emerald/cyan cat eyes + nose
    final eyeShift = Offset(pointerNorm.dx * s * 0.03, pointerNorm.dy * s * 0.02);
    final blink = _isBlinkFrame(t, 4.1);
    for (final ex in [-s * 0.085, s * 0.085]) {
      final ec = Offset(ex, -s * 0.12) + eyeShift;
      if (blink) {
        canvas.drawLine(
          Offset(ec.dx - s * 0.03, ec.dy),
          Offset(ec.dx + s * 0.03, ec.dy),
          Paint()
            ..color = const Color(0xFF38BDF8)
            ..strokeWidth = s * 0.02,
        );
      } else {
        canvas.drawCircle(ec, s * 0.042, Paint()..color = const Color(0xFF38BDF8));
        canvas.drawCircle(ec, s * 0.020, Paint()..color = const Color(0xFF0F172A));
        canvas.drawCircle(
          ec + Offset(-s * 0.012, -s * 0.012),
          s * 0.011,
          Paint()..color = Colors.white,
        );
      }
    }
    canvas.drawCircle(
      Offset(0, -s * 0.05),
      s * 0.022,
      Paint()..color = const Color(0xFFF472B6),
    );

    // Glowing mini coding laptop in front + typing paws
    final laptopRect = Rect.fromCenter(
      center: Offset(0, s * 0.26),
      width: s * 0.34,
      height: s * 0.15,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(laptopRect, Radius.circular(s * 0.03)),
      Paint()..color = const Color(0xFF0F172A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(laptopRect, Radius.circular(s * 0.03)),
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.015,
    );
    // Animated screen glow bars inside laptop
    final screenW = s * (0.12 + 0.08 * (0.5 + 0.5 * math.sin(t * 9.0)));
    canvas.drawLine(
      Offset(-s * 0.10, s * 0.25),
      Offset(-s * 0.10 + screenW, s * 0.25),
      Paint()
        ..color = const Color(0xFFF472B6)
        ..strokeWidth = s * 0.018,
    );

    final pawLeftY = s * (0.17 + 0.03 * math.sin(t * 14.0));
    final pawRightY = s * (0.17 + 0.03 * math.cos(t * 14.0));
    canvas.drawCircle(
      Offset(-s * 0.08, pawLeftY),
      s * 0.04,
      Paint()..color = const Color(0xFFFCE7F3),
    );
    canvas.drawCircle(
      Offset(s * 0.08, pawRightY),
      s * 0.04,
      Paint()..color = const Color(0xFFFCE7F3),
    );

    _drawExcitedBurst(
      canvas,
      Offset.zero,
      s * 0.52,
      excited,
      const Color(0xFFF472B6),
      const Color(0xFF38BDF8),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NekoCatPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.pointerNorm != pointerNorm ||
      oldDelegate.hovered != hovered ||
      oldDelegate.excited != excited ||
      oldDelegate.isDancing != isDancing;
}

class _FlutterDashPainter extends CustomPainter {
  _FlutterDashPainter({
    required this.t,
    required this.pointerNorm,
    required this.hovered,
    required this.excited,
    required this.isDancing,
  });

  final double t;
  final Offset pointerNorm;
  final bool hovered;
  final double excited;
  final bool isDancing;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final flapSpeed = hovered || excited > 0 || isDancing ? 16.0 : 7.5;
    final flap = math.sin(t * flapSpeed);
    final bob = math.sin(t * 3.8) * s * 0.04 - math.sin(excited * math.pi) * s * 0.13;

    canvas.save();
    canvas.translate(cx, cy + bob);
    if (isDancing) {
      canvas.rotate(math.sin(t * 6.5) * 0.14);
    }

    // Left & right flapping wings
    void drawWing(double sign) {
      canvas.save();
      canvas.translate(sign * s * 0.22, s * 0.02);
      canvas.rotate(sign * (-0.35 + flap * 0.42));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(sign * s * 0.09, 0), width: s * 0.20, height: s * 0.11),
        Paint()..color = const Color(0xFF0284C7),
      );
      canvas.restore();
    }

    drawWing(-1);
    drawWing(1);

    // Top feathered crest
    for (final dx in [-s * 0.04, 0.0, s * 0.04]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dx, -s * 0.30 + math.sin(t * 5.0 + dx) * s * 0.015),
          width: s * 0.07,
          height: s * 0.13,
        ),
        Paint()..color = const Color(0xFF38BDF8),
      );
    }

    // Plump Dash body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 0), width: s * 0.50, height: s * 0.48),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.25, -0.35),
          colors: [Color(0xFF7DD3FC), Color(0xFF0EA5E9), Color(0xFF0369A1)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: s * 0.28)),
    );

    // Cream belly patch
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, s * 0.11), width: s * 0.30, height: s * 0.22),
      Paint()..color = const Color(0xFFF0F9FF),
    );

    // Expressive eyes
    final eyeShift = Offset(pointerNorm.dx * s * 0.028, pointerNorm.dy * s * 0.022);
    final blink = _isBlinkFrame(t, 3.3);
    for (final ex in [-s * 0.095, s * 0.095]) {
      canvas.drawCircle(Offset(ex, -s * 0.08), s * 0.078, Paint()..color = Colors.white);
      if (blink) {
        canvas.drawLine(
          Offset(ex - s * 0.05, -s * 0.08),
          Offset(ex + s * 0.05, -s * 0.08),
          Paint()
            ..color = const Color(0xFF0F172A)
            ..strokeWidth = s * 0.02,
        );
      } else {
        final pupil = Offset(ex, -s * 0.08) + eyeShift;
        canvas.drawCircle(pupil, s * 0.042, Paint()..color = const Color(0xFF0F172A));
        canvas.drawCircle(
          pupil + Offset(-s * 0.014, -s * 0.014),
          s * 0.015,
          Paint()..color = Colors.white,
        );
      }
    }

    // Golden beak + orange feet
    final beak = Path()
      ..moveTo(-s * 0.06, -s * 0.02)
      ..lineTo(s * 0.06, -s * 0.02)
      ..lineTo(0, s * 0.07)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFBBF24));

    for (final fx in [-s * 0.09, s * 0.09]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(fx, s * 0.26 + math.sin(t * 7.5 + fx) * s * 0.015),
          width: s * 0.11,
          height: s * 0.06,
        ),
        Paint()..color = const Color(0xFFF59E0B),
      );
    }

    _drawExcitedBurst(
      canvas,
      Offset.zero,
      s * 0.54,
      excited,
      const Color(0xFF38BDF8),
      const Color(0xFFFBBF24),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlutterDashPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.pointerNorm != pointerNorm ||
      oldDelegate.hovered != hovered ||
      oldDelegate.excited != excited ||
      oldDelegate.isDancing != isDancing;
}

class _M3RacerPainter extends CustomPainter {
  _M3RacerPainter({
    required this.t,
    required this.pointerNorm,
    required this.hovered,
    required this.excited,
    required this.isDancing,
  });

  final double t;
  final Offset pointerNorm;
  final bool hovered;
  final double excited;
  final bool isDancing;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final engineVib = math.sin(t * 36.0) * s * 0.008;
    final jump = math.sin(excited * math.pi) * s * 0.09;
    final sway = isDancing ? math.sin(t * 7.5) * 0.09 : pointerNorm.dx * 0.08;

    canvas.save();
    canvas.translate(cx, cy - jump + engineVib);
    canvas.rotate(sway);

    // Underglow & track shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, s * 0.22), width: s * 0.78, height: s * 0.14),
      Paint()
        ..color = (hovered || excited > 0
                ? const Color(0xFF00F0FF)
                : const Color(0xFF2563EB))
            .withValues(alpha: 0.35),
    );

    // Exhaust N2O flame from left dual-tips
    final n2oLen = s * (0.14 + 0.08 * math.sin(t * 28.0) + (hovered ? 0.10 : 0.0) + excited * 0.14);
    final n2oRect = Rect.fromLTWH(-s * 0.36 - n2oLen, s * 0.04, n2oLen, s * 0.09);
    canvas.drawOval(
      n2oRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.transparent, Color(0xFF00F0FF), Color(0xFFF59E0B)],
        ).createShader(n2oRect),
    );

    // Silver M3 GTR coupe silhouette
    final carBody = Path()
      ..moveTo(-s * 0.38, s * 0.14)
      ..lineTo(-s * 0.37, -s * 0.04)
      ..lineTo(-s * 0.22, -s * 0.08)
      ..lineTo(-s * 0.08, -s * 0.22)
      ..lineTo(s * 0.14, -s * 0.22)
      ..lineTo(s * 0.28, -s * 0.06)
      ..lineTo(s * 0.40, s * 0.02)
      ..lineTo(s * 0.39, s * 0.14)
      ..close();
    canvas.drawPath(
      carBody,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1F5F9), Color(0xFF94A3B8)],
        ).createShader(Rect.fromCenter(center: Offset.zero, width: s * 0.8, height: s * 0.5)),
    );

    // Iconic Most Wanted royal blue racing vinyl stripe
    final vinyl = Path()
      ..moveTo(-s * 0.36, s * 0.10)
      ..lineTo(s * 0.10, -s * 0.04)
      ..lineTo(s * 0.38, s * 0.04)
      ..lineTo(s * 0.38, s * 0.12)
      ..close();
    canvas.drawPath(vinyl, Paint()..color = const Color(0xFF1D4ED8));

    // Rear GT wing
    canvas.drawLine(
      Offset(-s * 0.34, -s * 0.05),
      Offset(-s * 0.39, -s * 0.18),
      Paint()
        ..color = const Color(0xFF0F172A)
        ..strokeWidth = s * 0.03,
    );
    canvas.drawLine(
      Offset(-s * 0.43, -s * 0.18),
      Offset(-s * 0.30, -s * 0.18),
      Paint()
        ..color = const Color(0xFF0F172A)
        ..strokeWidth = s * 0.035
        ..strokeCap = StrokeCap.round,
    );

    // Tinted cabin glass + bobbing driver helmet
    final cabin = Path()
      ..moveTo(-s * 0.18, -s * 0.07)
      ..lineTo(-s * 0.07, -s * 0.19)
      ..lineTo(s * 0.12, -s * 0.19)
      ..lineTo(s * 0.22, -s * 0.07)
      ..close();
    canvas.drawPath(cabin, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(
      Offset(s * 0.02, -s * 0.11 + math.sin(t * 14.0) * s * 0.01),
      s * 0.045,
      Paint()..color = const Color(0xFFF59E0B),
    );

    // Headlight beam & brake tail light
    canvas.drawCircle(
      Offset(s * 0.37, s * 0.03),
      s * 0.035,
      Paint()..color = const Color(0xFFFEF08A),
    );
    canvas.drawCircle(
      Offset(-s * 0.36, s * 0.02),
      s * 0.026,
      Paint()..color = const Color(0xFFEF4444),
    );

    // Spinning alloy wheels
    for (final wx in [-s * 0.22, s * 0.21]) {
      canvas.drawCircle(Offset(wx, s * 0.15), s * 0.095, Paint()..color = const Color(0xFF0F172A));
      canvas.drawCircle(Offset(wx, s * 0.15), s * 0.055, Paint()..color = const Color(0xFFCBD5E1));
      final spinAngle = t * 18.0;
      canvas.drawLine(
        Offset(wx + math.cos(spinAngle) * s * 0.05, s * 0.15 + math.sin(spinAngle) * s * 0.05),
        Offset(wx - math.cos(spinAngle) * s * 0.05, s * 0.15 - math.sin(spinAngle) * s * 0.05),
        Paint()
          ..color = const Color(0xFF1D4ED8)
          ..strokeWidth = s * 0.018,
      );
    }

    _drawExcitedBurst(
      canvas,
      Offset.zero,
      s * 0.54,
      excited,
      const Color(0xFF00F0FF),
      const Color(0xFFF59E0B),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _M3RacerPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.pointerNorm != pointerNorm ||
      oldDelegate.hovered != hovered ||
      oldDelegate.excited != excited ||
      oldDelegate.isDancing != isDancing;
}

class _CommsDronePainter extends CustomPainter {
  _CommsDronePainter({
    required this.t,
    required this.pointerNorm,
    required this.hovered,
    required this.excited,
    required this.isDancing,
  });

  final double t;
  final Offset pointerNorm;
  final bool hovered;
  final double excited;
  final bool isDancing;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final floatY = math.sin(t * 2.9) * s * 0.05 - math.sin(excited * math.pi) * s * 0.12;
    final rot = isDancing ? math.sin(t * 6.5) * 0.14 : pointerNorm.dx * 0.07;

    canvas.save();
    canvas.translate(cx, cy + floatY);
    canvas.rotate(rot);

    // Expanding telemetry radio rings above dish
    for (int i = 0; i < 3; i++) {
      final p = ((t * 0.8 + i * 0.33) % 1.0);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(0, -s * 0.28), width: s * (0.20 + p * 0.40), height: s * (0.14 + p * 0.28)),
        -math.pi * 0.85,
        math.pi * 0.70,
        false,
        Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: (1.0 - p) * 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.018,
      );
    }

    // Rotating dish on mast
    final dishTilt = math.sin(t * 3.2) * 0.28;
    canvas.drawLine(
      Offset(0, -s * 0.20),
      Offset(dishTilt * s * 0.18, -s * 0.31),
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = s * 0.025,
    );
    canvas.drawCircle(
      Offset(dishTilt * s * 0.18, -s * 0.33),
      s * 0.042,
      Paint()..color = const Color(0xFF10B981),
    );

    // Side stabilizers
    for (final sx in [-s * 0.28, s * 0.28]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(sx, s * 0.02), width: s * 0.09, height: s * 0.22),
          Radius.circular(s * 0.045),
        ),
        Paint()..color = const Color(0xFF10B981),
      );
    }

    // Circular astronaut/comms helmet shell
    canvas.drawCircle(
      Offset(0, s * 0.02),
      s * 0.25,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFF8FAFC), Color(0xFFCBD5E1)],
        ).createShader(Rect.fromCircle(center: Offset(0, s * 0.02), radius: s * 0.25)),
    );

    // Reflective dark visor + cursor glint
    final visor = Rect.fromCenter(center: Offset(0, s * 0.02), width: s * 0.34, height: s * 0.24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(visor, Radius.circular(s * 0.11)),
      Paint()..color = const Color(0xFF064E3B),
    );

    final glint = Offset(pointerNorm.dx * s * 0.045, pointerNorm.dy * s * 0.03);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-s * 0.05, -s * 0.01) + glint, width: s * 0.10, height: s * 0.055),
      Paint()..color = const Color(0xFF34D399).withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(s * 0.06, s * 0.02) + glint,
      s * 0.024,
      Paint()..color = const Color(0xFF38BDF8),
    );

    _drawExcitedBurst(
      canvas,
      Offset.zero,
      s * 0.54,
      excited,
      const Color(0xFF10B981),
      const Color(0xFF38BDF8),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CommsDronePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.pointerNorm != pointerNorm ||
      oldDelegate.hovered != hovered ||
      oldDelegate.excited != excited ||
      oldDelegate.isDancing != isDancing;
}

/// Interactive 6x3 coordinate tile stage where users switch between all 5
/// animated characters, tap tiles to hop characters across cells, or toggle Party Mode.
class InteractiveCharacterGridStage extends StatefulWidget {
  const InteractiveCharacterGridStage({
    super.key,
    required this.elapsedSeconds,
    required this.pointerNorm,
    required this.accent,
    required this.secondary,
    required this.isDark,
  });

  final double elapsedSeconds;
  final Offset pointerNorm;
  final Color accent;
  final Color secondary;
  final bool isDark;

  @override
  State<InteractiveCharacterGridStage> createState() =>
      _InteractiveCharacterGridStageState();
}

class _InteractiveCharacterGridStageState
    extends State<InteractiveCharacterGridStage> {
  static const int _cols = 6;
  static const int _rows = 3;

  GridCharacterKind _activeCharacter = GridCharacterKind.spnkBot;
  int _targetCol = 2;
  int _targetRow = 1;
  bool _partyMode = false;
  int _movesCount = 0;
  final List<(int, int)> _stepTrail = [];

  static const List<(int, int)> _partyCoords = [
    (0, 0),
    (2, 1),
    (5, 0),
    (1, 2),
    (4, 2),
  ];

  void _moveToCell(int col, int row) {
    setState(() {
      if (_targetCol != col || _targetRow != row) {
        _stepTrail.add((_targetCol, _targetRow));
        if (_stepTrail.length > 6) {
          _stepTrail.removeAt(0);
        }
      }
      _targetCol = col;
      _targetRow = row;
      _movesCount++;
    });
    if (_movesCount == 3) {
      GamificationController.instance.addXp(
        15,
        reason: 'Explored Interactive Character Grid!',
        uniqueKey: 'grid_stage_explore',
      );
    }
  }

  void _togglePartyMode() {
    setState(() {
      _partyMode = !_partyMode;
    });
    if (_partyMode) {
      GamificationController.instance.addXp(
        25,
        reason: 'Activated Grid Character Party Mode!',
        uniqueKey: 'grid_party_mode',
      );
    }
  }

  Alignment _alignFor(int col, int row) {
    final ax = -1.0 + (col + 0.5) * (2.0 / _cols);
    final ay = -1.0 + (row + 0.5) * (2.0 / _rows);
    return Alignment(ax, ay);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.screenWidth < 600;
    final stageHeight = isMobile ? 196.0 : 228.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stage telemetry bar
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    'POS [${_targetCol + 1}, ${_targetRow + 1}]',
                    style: context.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: widget.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MOVES: $_movesCount',
                  style: context.bodySmall.copyWith(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    color: context.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _togglePartyMode,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: _partyMode
                        ? widget.secondary.withValues(alpha: 0.24)
                        : widget.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _partyMode
                          ? widget.secondary
                          : widget.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.celebration_rounded,
                        size: 14,
                        color: _partyMode ? widget.secondary : widget.accent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'PARTY MODE',
                        style: context.bodySmall.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: _partyMode
                              ? widget.secondary
                              : context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Character selector chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: GridCharacterKind.values.map((charKind) {
            final selected = charKind == _activeCharacter && !_partyMode;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() {
                  _activeCharacter = charKind;
                  _partyMode = false;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? charKind.primaryColor.withValues(alpha: 0.22)
                        : context.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? charKind.primaryColor
                          : context.primaryColor.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    charKind.label,
                    style: context.bodySmall.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: selected
                          ? charKind.primaryColor
                          : context.primaryColor.withValues(alpha: 0.78),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Playable 6x3 coordinate tile stage
        Container(
          height: stageHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isDark
                ? const Color(0xFF070B14).withValues(alpha: 0.78)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (_partyMode ? widget.secondary : widget.accent)
                  .withValues(alpha: 0.35),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                children: List.generate(_rows, (row) {
                  return Expanded(
                    child: Row(
                      children: List.generate(_cols, (col) {
                        final isActive = !_partyMode &&
                            col == _targetCol &&
                            row == _targetRow;
                        final inTrail = _stepTrail.any(
                          (pair) => pair.$1 == col && pair.$2 == row,
                        );
                        final partyPulse = _partyMode
                            ? 0.08 +
                                0.12 *
                                    (0.5 +
                                        0.5 *
                                            math.sin(widget.elapsedSeconds * 5.0 +
                                                col +
                                                row))
                            : 0.0;
                        return Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              key: ValueKey('grid_cell_${col}_$row'),
                              onTap: () => _moveToCell(col, row),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: _partyMode
                                      ? ((col + row).isEven
                                              ? widget.accent
                                              : widget.secondary)
                                          .withValues(alpha: partyPulse)
                                      : isActive
                                          ? widget.accent
                                              .withValues(alpha: 0.18)
                                          : inTrail
                                              ? widget.secondary
                                                  .withValues(alpha: 0.08)
                                              : Colors.transparent,
                                  border: Border.all(
                                    color: isActive
                                        ? widget.accent.withValues(alpha: 0.85)
                                        : widget.accent.withValues(
                                            alpha: widget.isDark ? 0.14 : 0.16,
                                          ),
                                    width: isActive ? 1.5 : 0.6,
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      '${col + 1},${row + 1}',
                                      style: context.bodySmall.copyWith(
                                        fontSize: 8.5,
                                        color: context.primaryColor.withValues(
                                          alpha: isActive ? 0.75 : 0.25,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
              if (_partyMode)
                ...List.generate(GridCharacterKind.values.length, (idx) {
                  final kind = GridCharacterKind.values[idx];
                  final (pCol, pRow) = _partyCoords[idx % _partyCoords.length];
                  return IgnorePointer(
                    ignoring: false,
                    child: Align(
                      alignment: _alignFor(pCol, pRow),
                      child: AnimatedPortfolioCharacter(
                        kind: kind,
                        elapsedSeconds: widget.elapsedSeconds,
                        pointerNorm: widget.pointerNorm,
                        size: isMobile ? 54 : 66,
                        isDancing: true,
                      ),
                    ),
                  );
                })
              else
                AnimatedAlign(
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeOutBack,
                  alignment: _alignFor(_targetCol, _targetRow),
                  child: AnimatedPortfolioCharacter(
                    kind: _activeCharacter,
                    elapsedSeconds: widget.elapsedSeconds,
                    pointerNorm: widget.pointerNorm,
                    size: isMobile ? 62 : 74,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _partyMode
              ? 'All 5 characters synced on stage! Tap any tile or toggle Party Mode anytime.'
              : 'Tap any tile on the 6x3 coordinate stage to move ${_activeCharacter.label}, or tap characters directly for dialogue!',
          style: context.bodySmall.copyWith(
            fontSize: 11.5,
            color: context.primaryColor.withValues(alpha: 0.68),
          ),
        ),
      ],
    );
  }
}
