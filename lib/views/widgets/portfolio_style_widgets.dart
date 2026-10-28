import 'dart:ui';

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

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: state.cardSurfaceColor,
            borderRadius: BorderRadius.circular(
              activeStyle == PortfolioStyle.cyber ? 6 : 999,
            ),
            border: Border.all(
              color: state.cardBorderColor,
              width: 1.2,
            ),
          ),
          child: Row(
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 14,
                      vertical: compact ? 5 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withOpacity(state.isDark ? 0.22 : 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        activeStyle == PortfolioStyle.cyber ? 4 : 999,
                      ),
                      border: isSelected
                          ? Border.all(
                              color: accent.withOpacity(0.75),
                              width: 1,
                            )
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.icon,
                          size: compact ? 14 : 15,
                          color: isSelected
                              ? accent
                              : context.primaryColor.withOpacity(0.65),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          style.label,
                          style: context.bodySmall.copyWith(
                            fontSize: compact ? 13 : 14,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? (state.isDark ? Colors.white : accent)
                                : context.primaryColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class PortfolioStyleBackground extends StatelessWidget {
  const PortfolioStyleBackground({super.key, required this.child});

  final Widget child;

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
            if (style == PortfolioStyle.glass) ...[
              Positioned(
                top: -120,
                left: -100,
                child: _AmbientGlowOrb(
                  color: accent.withOpacity(state.isDark ? 0.22 : 0.14),
                  size: 460,
                ),
              ),
              Positioned(
                top: 280,
                right: -140,
                child: _AmbientGlowOrb(
                  color: secondary.withOpacity(state.isDark ? 0.18 : 0.12),
                  size: 520,
                ),
              ),
              Positioned(
                bottom: -150,
                left: MediaQuery.of(context).size.width * 0.25,
                child: _AmbientGlowOrb(
                  color: accent.withOpacity(state.isDark ? 0.15 : 0.10),
                  size: 480,
                ),
              ),
            ] else if (style == PortfolioStyle.cyber) ...[
              Positioned.fill(
                child: CustomPaint(
                  painter: _CyberGridPainter(
                    lineColor: accent.withOpacity(state.isDark ? 0.08 : 0.07),
                    accentColor:
                        secondary.withOpacity(state.isDark ? 0.12 : 0.08),
                  ),
                ),
              ),
            ] else if (style == PortfolioStyle.bento) ...[
              Positioned.fill(
                child: CustomPaint(
                  painter: _BentoDotPainter(
                    dotColor: context.primaryColor
                        .withOpacity(state.isDark ? 0.06 : 0.05),
                  ),
                ),
              ),
            ],
            child,
          ],
        );
      },
    );
  }
}

class _AmbientGlowOrb extends StatelessWidget {
  const _AmbientGlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _CyberGridPainter extends CustomPainter {
  _CyberGridPainter({required this.lineColor, required this.accentColor});

  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const double step = 48;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [accentColor, Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.2),
          radius: 360,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      360,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberGridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.accentColor != accentColor;
}

class _BentoDotPainter extends CustomPainter {
  _BentoDotPainter({required this.dotColor});

  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const double spacing = 32;
    for (double x = 16; x < size.width; x += spacing) {
      for (double y = 16; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BentoDotPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}

class PortfolioStyledCard extends StatefulWidget {
  const PortfolioStyledCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(24),
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
        final style = state.portfolioStyle;
        final accent = state.accentColor;
        final secondary = state.secondaryAccent;
        final radius = state.cardRadius;

        final borderColor = _hovered
            ? accent.withOpacity(0.85)
            : state.cardBorderColor;

        Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (style == PortfolioStyle.cyber &&
                widget.cyberHeader != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(state.isDark ? 0.12 : 0.08),
                  border: Border(
                    bottom: BorderSide(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _CyberDot(color: secondary),
                    const SizedBox(width: 6),
                    _CyberDot(color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    _CyberDot(color: accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.cyberHeader!,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodySmall.copyWith(
                          fontSize: 13,
                          letterSpacing: 1.1,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ],
        );

        Widget decorated = AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: state.cardSurfaceColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor,
              width: style == PortfolioStyle.bento
                  ? 1.5
                  : (_hovered ? 1.5 : 1.1),
            ),
            boxShadow: [
              if (style == PortfolioStyle.glass)
                BoxShadow(
                  color: _hovered
                      ? accent.withOpacity(state.isDark ? 0.22 : 0.15)
                      : Colors.black.withOpacity(state.isDark ? 0.28 : 0.06),
                  blurRadius: _hovered ? 28 : 18,
                  offset: const Offset(0, 10),
                )
              else if (style == PortfolioStyle.bento)
                BoxShadow(
                  color: Colors.black.withOpacity(state.isDark ? 0.35 : 0.05),
                  blurRadius: _hovered ? 20 : 10,
                  offset: const Offset(0, 6),
                )
              else if (style == PortfolioStyle.cyber && _hovered)
                BoxShadow(
                  color: accent.withOpacity(0.25),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: style == PortfolioStyle.glass
                ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: content,
                  )
                : content,
          ),
        );

        return MouseRegion(
          cursor: widget.onTap != null
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: decorated,
          ),
        );
      },
    );
  }
}

class _CyberDot extends StatelessWidget {
  const _CyberDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

