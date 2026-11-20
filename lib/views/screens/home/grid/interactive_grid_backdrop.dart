import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';

/// Expanding circular ripple spawned at pointer down coordinates on the grid.
class GridRipple {
  const GridRipple({
    required this.origin,
    required this.birthTime,
    required this.color,
  });

  final Offset origin;
  final double birthTime;
  final Color color;
}

/// Recently hovered or tapped architectural grid cell with decay timestamp.
class GridTrailCell {
  const GridTrailCell({
    required this.col,
    required this.row,
    required this.lastTouchedTime,
  });

  final int col;
  final int row;
  final double lastTouchedTime;
}

/// Interactive background coordinate grid that subtly warps vertices toward the
/// cursor, lights up recently visited cells, and animates click ripples.
class InteractiveGridBackdrop extends StatelessWidget {
  const InteractiveGridBackdrop({
    super.key,
    required this.pointerLocal,
    required this.trailCells,
    required this.ripples,
    required this.elapsedSeconds,
    required this.themeState,
    this.cellSize = 44.0,
  });

  final Offset? pointerLocal;
  final List<GridTrailCell> trailCells;
  final List<GridRipple> ripples;
  final double elapsedSeconds;
  final ThemeState themeState;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        isComplex: true,
        painter: _InteractiveGridPainter(
          pointerLocal: pointerLocal,
          trailCells: List<GridTrailCell>.of(trailCells),
          ripples: List<GridRipple>.of(ripples),
          elapsedSeconds: elapsedSeconds,
          isDark: themeState.isDark,
          accent: themeState.accentColor,
          secondary: themeState.secondaryAccent,
          scaffoldColor: themeState.themeData.scaffoldBackgroundColor,
          style: themeState.portfolioStyle,
          cellSize: cellSize,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _InteractiveGridPainter extends CustomPainter {
  _InteractiveGridPainter({
    required this.pointerLocal,
    required this.trailCells,
    required this.ripples,
    required this.elapsedSeconds,
    required this.isDark,
    required this.accent,
    required this.secondary,
    required this.scaffoldColor,
    required this.style,
    required this.cellSize,
  });

  final Offset? pointerLocal;
  final List<GridTrailCell> trailCells;
  final List<GridRipple> ripples;
  final double elapsedSeconds;
  final bool isDark;
  final Color accent;
  final Color secondary;
  final Color scaffoldColor;
  final PortfolioStyle style;
  final double cellSize;

  static const double _warpRadius = 175.0;
  static const double _warpStrength = 10.5;
  static const double _trailLifetime = 2.2;
  static const double _rippleLifetime = 1.4;

  Offset _warpPoint(double gx, double gy) {
    final ptr = pointerLocal;
    if (ptr == null) return Offset(gx, gy);
    final dx = ptr.dx - gx;
    final dy = ptr.dy - gy;
    final distSq = dx * dx + dy * dy;
    if (distSq >= _warpRadius * _warpRadius || distSq < 0.001) {
      return Offset(gx, gy);
    }
    final dist = math.sqrt(distSq);
    final falloff = math.pow(1.0 - dist / _warpRadius, 2).toDouble();
    final pull = falloff * _warpStrength / dist;
    return Offset(gx + dx * pull, gy + dy * pull);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base scaffold wash + gentle radial atmospheric glow
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = scaffoldColor,
    );

    final glowCenter = pointerLocal ??
        Offset(
          size.width * (0.5 + 0.14 * math.sin(elapsedSeconds * 0.25)),
          size.height * (0.35 + 0.08 * math.cos(elapsedSeconds * 0.22)),
        );
    final ambientGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: isDark ? 0.14 : 0.08),
          secondary.withValues(alpha: isDark ? 0.06 : 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: 360));
    canvas.drawCircle(glowCenter, 360, ambientGlow);

    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;

    // 2. Trail cell illuminates (decay smoothly after pointer leaves)
    final cellFillPaint = Paint()..style = PaintingStyle.fill;
    final cellBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final cell in trailCells) {
      final age = elapsedSeconds - cell.lastTouchedTime;
      if (age < 0 || age > _trailLifetime) continue;
      if (cell.col < 0 || cell.row < 0 || cell.col > cols || cell.row > rows) {
        continue;
      }
      final t = 1.0 - (age / _trailLifetime);
      final smoothAlpha = t * t;
      final rect = Rect.fromLTWH(
        cell.col * cellSize + 2,
        cell.row * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      );
      final tint = ((cell.col + cell.row).isEven ? accent : secondary);
      cellFillPaint.color = tint.withValues(
        alpha: (isDark ? 0.16 : 0.10) * smoothAlpha,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        cellFillPaint,
      );

      cellBorderPaint.color = tint.withValues(
        alpha: (isDark ? 0.45 : 0.30) * smoothAlpha,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        cellBorderPaint,
      );
    }

    // 3. Pointer-warped lattice lines
    final baseLineAlpha = isDark
        ? (style == PortfolioStyle.cyber ? 0.10 : 0.075)
        : 0.08;
    final baseLinePaint = Paint()
      ..color = accent.withValues(alpha: baseLineAlpha)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.30 : 0.22)
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke;

    final ptr = pointerLocal;
    for (int c = 0; c <= cols; c++) {
      final gx = c * cellSize;
      final nearPtr = ptr != null && (gx - ptr.dx).abs() < _warpRadius;
      if (!nearPtr) {
        canvas.drawLine(Offset(gx, 0), Offset(gx, size.height), baseLinePaint);
      } else {
        for (int r = 0; r < rows; r++) {
          final p1 = _warpPoint(gx, r * cellSize);
          final p2 = _warpPoint(gx, (r + 1) * cellSize);
          final segDist = ((p1 + p2) * 0.5 - ptr).distance;
          canvas.drawLine(
            p1,
            p2,
            segDist < _warpRadius * 0.72 ? highlightPaint : baseLinePaint,
          );
        }
      }
    }

    for (int r = 0; r <= rows; r++) {
      final gy = r * cellSize;
      final nearPtr = ptr != null && (gy - ptr.dy).abs() < _warpRadius;
      if (!nearPtr) {
        canvas.drawLine(Offset(0, gy), Offset(size.width, gy), baseLinePaint);
      } else {
        for (int c = 0; c < cols; c++) {
          final p1 = _warpPoint(c * cellSize, gy);
          final p2 = _warpPoint((c + 1) * cellSize, gy);
          final segDist = ((p1 + p2) * 0.5 - ptr).distance;
          canvas.drawLine(
            p1,
            p2,
            segDist < _warpRadius * 0.72 ? highlightPaint : baseLinePaint,
          );
        }
      }
    }

    // 4. Crisp intersection reticle dots & ambient drifting energy nodes
    final crossPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.16 : 0.14)
      ..strokeWidth = 1.0;
    for (int c = 1; c < cols; c += 2) {
      for (int r = 1; r < rows; r += 2) {
        final wp = _warpPoint(c * cellSize, r * cellSize);
        canvas.drawLine(
          Offset(wp.dx - 2.5, wp.dy),
          Offset(wp.dx + 2.5, wp.dy),
          crossPaint,
        );
        canvas.drawLine(
          Offset(wp.dx, wp.dy - 2.5),
          Offset(wp.dx, wp.dy + 2.5),
          crossPaint,
        );
      }
    }

    final nodePaint = Paint()..style = PaintingStyle.fill;
    final maxColsSafe = math.max(2, cols);
    final maxRowsSafe = math.max(2, rows);
    for (int i = 0; i < 16; i++) {
      final col = (i * 5 + 2) % maxColsSafe;
      final row = (i * 3 + 1) % maxRowsSafe;
      final pulse = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(elapsedSeconds * 2.1 + i));
      final wp = _warpPoint(col * cellSize, row * cellSize);
      final nodeColor = i.isEven ? accent : secondary;
      nodePaint.color = nodeColor.withValues(
        alpha: (isDark ? 0.42 : 0.30) * pulse,
      );
      canvas.drawCircle(wp, 1.8 + pulse * 1.4, nodePaint);
    }

    // 5. Pointer highlight ring & expanding click ripples
    if (ptr != null) {
      canvas.drawCircle(
        ptr,
        14,
        Paint()
          ..color = accent.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    final ripplePaint = Paint()..style = PaintingStyle.stroke;
    for (final ripple in ripples) {
      final age = elapsedSeconds - ripple.birthTime;
      if (age < 0 || age > _rippleLifetime) continue;
      final progress = age / _rippleLifetime;
      final fade = (1.0 - progress) * (1.0 - progress);
      final r1 = 12.0 + progress * 155.0;
      ripplePaint
        ..color = ripple.color.withValues(alpha: 0.60 * fade)
        ..strokeWidth = 2.0 * (1.0 - progress * 0.5);
      canvas.drawCircle(ripple.origin, r1, ripplePaint);

      final r2 = math.max(0.0, r1 - 24.0);
      if (r2 > 4.0) {
        ripplePaint
          ..color = secondary.withValues(alpha: 0.35 * fade)
          ..strokeWidth = 1.1;
        canvas.drawCircle(ripple.origin, r2, ripplePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveGridPainter oldDelegate) {
    return oldDelegate.pointerLocal != pointerLocal ||
        oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.isDark != isDark ||
        oldDelegate.accent != accent ||
        oldDelegate.secondary != secondary ||
        oldDelegate.style != style ||
        oldDelegate.trailCells.length != trailCells.length ||
        oldDelegate.ripples.length != ripples.length;
  }
}

/// Interactive architectural bento grid tile with pointer-driven 3D tilt,
/// cursor spotlight, optional coordinate header, and category highlight/dimming.
class InteractiveGridTile extends StatefulWidget {
  const InteractiveGridTile({
    super.key,
    this.gridCode,
    this.badge,
    this.accentOverride,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.isHighlighted = false,
    this.isDimmed = false,
    required this.child,
  });

  final String? gridCode;
  final String? badge;
  final Color? accentOverride;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final bool isDimmed;
  final Widget child;

  @override
  State<InteractiveGridTile> createState() => _InteractiveGridTileState();
}

class _InteractiveGridTileState extends State<InteractiveGridTile> {
  bool _hovered = false;
  Offset _localNorm = Offset.zero; // -1..1 within tile bounds

  void _updateLocalNorm(Offset localPos, Size boxSize) {
    if (boxSize.width <= 0 || boxSize.height <= 0) return;
    final nx = ((localPos.dx / boxSize.width) * 2.0 - 1.0).clamp(-1.0, 1.0);
    final ny = ((localPos.dy / boxSize.height) * 2.0 - 1.0).clamp(-1.0, 1.0);
    setState(() {
      _localNorm = Offset(nx, ny);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = widget.accentOverride ?? themeState.accentColor;
        final isDark = themeState.isDark;
        final radius = themeState.cardRadius;

        final rotX = _hovered ? -_localNorm.dy * 0.032 : 0.0;
        final rotY = _hovered ? _localNorm.dx * 0.032 : 0.0;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(rotX)
          ..rotateY(rotY);

        final borderColor = _hovered || widget.isHighlighted
            ? accent.withValues(alpha: isDark ? 0.85 : 0.75)
            : themeState.cardBorderColor;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: widget.isDimmed ? 0.42 : 1.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return MouseRegion(
                cursor: widget.onTap != null
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() {
                  _hovered = false;
                  _localNorm = Offset.zero;
                }),
                onHover: (event) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null && renderBox.hasSize) {
                    _updateLocalNorm(event.localPosition, renderBox.size);
                  }
                },
                child: GestureDetector(
                  onTap: widget.onTap,
                  behavior: HitTestBehavior.translucent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    transform: transform,
                    transformAlignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: themeState.cardSurfaceColor,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: borderColor,
                        width: _hovered || widget.isHighlighted ? 1.5 : 1.1,
                      ),
                      gradient: _hovered
                          ? RadialGradient(
                              center: Alignment(_localNorm.dx, _localNorm.dy),
                              radius: 1.15,
                              colors: [
                                accent.withValues(alpha: isDark ? 0.14 : 0.09),
                                themeState.cardSurfaceColor,
                              ],
                            )
                          : null,
                      boxShadow: [
                        if (_hovered || widget.isHighlighted)
                          BoxShadow(
                            color: accent.withValues(
                              alpha: isDark ? 0.22 : 0.14,
                            ),
                            blurRadius: 24,
                            spreadRadius: 1,
                            offset: const Offset(0, 8),
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.24 : 0.06,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                      ],
                    ),
                    child: Padding(
                      padding: widget.padding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.gridCode != null || widget.badge != null) ...[
                            Row(
                              children: [
                                if (widget.gridCode != null)
                                  Flexible(
                                    child: Text(
                                      widget.gridCode!.toUpperCase(),
                                      overflow: TextOverflow.ellipsis,
                                      style: context.bodySmall.copyWith(
                                        fontSize: 10.5,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.bold,
                                        color: accent.withValues(
                                          alpha: _hovered ? 1.0 : 0.85,
                                        ),
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                if (widget.badge != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: accent.withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Text(
                                      widget.badge!.toUpperCase(),
                                      style: context.bodySmall.copyWith(
                                        fontSize: 9.5,
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.bold,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          widget.child,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
