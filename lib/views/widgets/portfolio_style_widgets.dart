import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_event.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';

class StyleSwitcherBar extends StatelessWidget {
  const StyleSwitcherBar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final activeStyle = state.portfolioStyle;
        final accent = state.accentColor;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: PortfolioStyle.values.map((style) {
            final isSelected = style == activeStyle;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  context
                      .read<ThemeBloc>()
                      .add(ChangePortfolioStyle(style: style));
                  GamificationController.instance
                      .completeQuest('style_shifter');
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 12,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            style.icon,
                            size: compact ? 14 : 15,
                            color: isSelected
                                ? accent
                                : context.primaryColor.withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            style.label.toUpperCase(),
                            style: context.bodySmall.copyWith(
                              fontSize: compact ? 11.5 : 12.5,
                              letterSpacing: 1.2,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? accent
                                  : context.primaryColor
                                      .withValues(alpha: 0.6),
                              shadows: isSelected
                                  ? [
                                      Shadow(
                                        color: accent.withValues(alpha: 0.6),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 2,
                        width: isSelected ? 22 : 0,
                        decoration: BoxDecoration(
                          color: accent,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class PortfolioStyleBackground extends StatefulWidget {
  const PortfolioStyleBackground({super.key, required this.child});

  final Widget child;

  @override
  State<PortfolioStyleBackground> createState() =>
      _PortfolioStyleBackgroundState();
}

class _PortfolioStyleBackgroundState extends State<PortfolioStyleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cosmosController;

  @override
  void initState() {
    super.initState();
    _cosmosController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _cosmosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final style = state.portfolioStyle;
        final accent = state.accentColor;
        final secondary = state.secondaryAccent;

        return Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: context.scaffoldColor),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _cosmosController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _LivingCosmosPainter(
                        phase: _cosmosController.value,
                        accent: accent,
                        secondary: secondary,
                        primary: context.primaryColor,
                        style: style,
                        isDark: state.isDark,
                      ),
                    );
                  },
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _LivingCosmosPainter extends CustomPainter {
  final double phase;
  final Color accent;
  final Color secondary;
  final Color primary;
  final PortfolioStyle style;
  final bool isDark;

  _LivingCosmosPainter({
    required this.phase,
    required this.accent,
    required this.secondary,
    required this.primary,
    required this.style,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft atmospheric energy nebulae
    final orb1Center = Offset(
      size.width * (0.2 + 0.05 * math.sin(phase * 2 * math.pi)),
      size.height * (0.22 + 0.04 * math.cos(phase * 2 * math.pi)),
    );
    final orb2Center = Offset(
      size.width * (0.82 - 0.05 * math.cos(phase * 2 * math.pi)),
      size.height * (0.68 + 0.05 * math.sin(phase * 2 * math.pi)),
    );

    final nebula1 = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: isDark ? 0.14 : 0.08),
          accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: orb1Center, radius: 420));
    canvas.drawCircle(orb1Center, 420, nebula1);

    final nebula2 = Paint()
      ..shader = RadialGradient(
        colors: [
          secondary.withValues(alpha: isDark ? 0.12 : 0.07),
          secondary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: orb2Center, radius: 460));
    canvas.drawCircle(orb2Center, 460, nebula2);

    // 2. Style-specific open-air astral geometry
    if (style == PortfolioStyle.cyber) {
      // Subtle horizon perspective rays
      final linePaint = Paint()
        ..color = accent.withValues(alpha: isDark ? 0.06 : 0.05)
        ..strokeWidth = 1.0;
      const double step = 64;
      for (double x = 0; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      }
    } else if (style == PortfolioStyle.bento) {
      // Concentric spatial sonar rings
      final ringPaint = Paint()
        ..color = accent.withValues(alpha: isDark ? 0.06 : 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final center = Offset(size.width * 0.5, size.height * 0.45);
      for (int i = 1; i <= 4; i++) {
        canvas.drawCircle(center, i * 190.0, ringPaint);
      }
    }

    // 3. Drifting starlight particles across open space
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 36; i++) {
      final seed = i * 137.5;
      final baseX = (seed * 31) % size.width;
      final baseY = (seed * 73) % size.height;
      final dy = (baseY - phase * 120 * ((i % 3) + 1)) % size.height;
      final y = dy < 0 ? dy + size.height : dy;
      final twinkle =
          0.25 + 0.55 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi * 2 + i));
      starPaint.color = (i % 3 == 0 ? accent : primary)
          .withValues(alpha: isDark ? twinkle * 0.35 : twinkle * 0.2);
      final radius = (i % 4 == 0) ? 2.0 : 1.2;
      canvas.drawCircle(Offset(baseX, y), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LivingCosmosPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.accent != accent ||
        oldDelegate.style != style ||
        oldDelegate.isDark != isDark;
  }
}

/// Containerless Open-Air HUD Zone — renders content directly in open space
/// with delicate custom-painted corner reticle ticks and zero box/card borders.
class PortfolioStyledCard extends StatefulWidget {
  const PortfolioStyledCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.margin,
    this.onTap,
    this.cyberHeader,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final String? cyberHeader;

  @override
  State<PortfolioStyledCard> createState() => _PortfolioStyledCardState();
}

class _PortfolioStyledCardState extends State<PortfolioStyledCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final accent = state.accentColor;
        final secondary = state.secondaryAccent;

        return MouseRegion(
          cursor: widget.onTap != null
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: CustomPaint(
                painter: _OpenAirReticlePainter(
                  accent: accent,
                  secondary: secondary,
                  hovered: _hovered,
                ),
                child: Padding(
                  padding: widget.padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.cyberHeader != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '◈ ${widget.cyberHeader!.toUpperCase()}',
                              style: context.bodySmall.copyWith(
                                fontSize: 11,
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.bold,
                                color: accent.withValues(
                                  alpha: _hovered ? 0.95 : 0.65,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 1,
                                child: CustomPaint(
                                  painter: _LaserLinePainter(
                                    color: accent.withValues(alpha: 0.25),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      Flexible(child: widget.child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OpenAirReticlePainter extends CustomPainter {
  final Color accent;
  final Color secondary;
  final bool hovered;

  _OpenAirReticlePainter({
    required this.accent,
    required this.secondary,
    required this.hovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: hovered ? 0.75 : 0.32)
      ..strokeWidth = hovered ? 1.8 : 1.2
      ..style = PaintingStyle.stroke;

    const double len = 14.0;
    // Top-left reticle tick
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), paint);

    // Top-right reticle tick
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - len, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, len),
      paint,
    );

    // Bottom-left reticle tick
    canvas.drawLine(
      Offset(0, size.height),
      Offset(len, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - len),
      paint,
    );

    // Bottom-right reticle tick
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - len, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _OpenAirReticlePainter oldDelegate) =>
      oldDelegate.hovered != hovered || oldDelegate.accent != accent;
}

class _LaserLinePainter extends CustomPainter {
  final Color color;
  _LaserLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LaserLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Containerless Open-Air Sci-Fi Bracket Action Trigger (`< LABEL >`)
/// Uses custom-painted angled vector brackets & laser underline instead of a box container.
class OpenAirActionTrigger extends StatefulWidget {
  const OpenAirActionTrigger({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  State<OpenAirActionTrigger> createState() => _OpenAirActionTriggerState();
}

class _OpenAirActionTriggerState extends State<OpenAirActionTrigger> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          painter: _AngledBracketPainter(
            color: widget.color,
            hovered: _hovered,
            isPrimary: widget.isPrimary,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.color,
                ),
                const SizedBox(width: 9),
                Text(
                  widget.label.toUpperCase(),
                  style: context.bodySmall.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                    color: _hovered || widget.isPrimary
                        ? widget.color
                        : context.primaryColor.withValues(alpha: 0.9),
                    shadows: (_hovered || widget.isPrimary)
                        ? [
                            Shadow(
                              color: widget.color.withValues(alpha: 0.65),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AngledBracketPainter extends CustomPainter {
  final Color color;
  final bool hovered;
  final bool isPrimary;

  _AngledBracketPainter({
    required this.color,
    required this.hovered,
    required this.isPrimary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color.withValues(alpha: hovered ? 1.0 : (isPrimary ? 0.85 : 0.5))
      ..strokeWidth = hovered || isPrimary ? 1.8 : 1.3
      ..style = PaintingStyle.stroke;

    const double cut = 8.0;
    const double wing = 14.0;

    // Left angled bracket `[`
    final leftPath = Path()
      ..moveTo(wing, 0)
      ..lineTo(cut, 0)
      ..lineTo(0, cut)
      ..lineTo(0, size.height - cut)
      ..lineTo(cut, size.height)
      ..lineTo(wing, size.height);
    canvas.drawPath(leftPath, strokePaint);

    // Right angled bracket `]`
    final rightPath = Path()
      ..moveTo(size.width - wing, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, cut)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(size.width - wing, size.height);
    canvas.drawPath(rightPath, strokePaint);

    // Glowing bottom laser filament
    if (hovered || isPrimary) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: hovered ? 0.8 : 0.45)
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawLine(
        Offset(wing + 4, size.height),
        Offset(size.width - wing - 4, size.height),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AngledBracketPainter oldDelegate) =>
      oldDelegate.hovered != hovered ||
      oldDelegate.color != color ||
      oldDelegate.isPrimary != isPrimary;
}
