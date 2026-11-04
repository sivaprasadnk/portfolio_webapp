import 'package:animate_do/animate_do.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';

class WindowsLargeSectionTitle extends StatelessWidget {
  const WindowsLargeSectionTitle({
    super.key,
    required this.title,
    this.sectionIndex,
  });

  final String title;
  final String? sectionIndex;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final accent = state.accentColor;
        final secondary = state.secondaryAccent;

        return FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: Padding(
            padding: const EdgeInsets.only(top: 44, bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flare_rounded,
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ASTRAL SECTOR // ${title.toUpperCase()}',
                      style: context.bodySmall.copyWith(
                        fontSize: 12,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.bold,
                        color: accent,
                        shadows: [
                          Shadow(
                            color: accent.withValues(alpha: 0.55),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: AutoSizeText(
                        title,
                        maxLines: 1,
                        style: context.displayMedium.copyWith(
                          fontSize: context.isLargeDevice ? 42 : 32,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: context.isMobileDevice ? 60 : 140,
                      height: 12,
                      child: CustomPaint(
                        painter: _SectorHeaderBeamPainter(
                          accent: accent,
                          secondary: secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectorHeaderBeamPainter extends CustomPainter {
  final Color accent;
  final Color secondary;

  _SectorHeaderBeamPainter({
    required this.accent,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final diamondPath = Path()
      ..moveTo(0, cy)
      ..lineTo(5, cy - 5)
      ..lineTo(10, cy)
      ..lineTo(5, cy + 5)
      ..close();

    canvas.drawPath(diamondPath, Paint()..color = accent);

    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accent,
          secondary.withValues(alpha: 0.6),
          secondary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(12, 0, size.width - 12, size.height))
      ..strokeWidth = 1.6;

    canvas.drawLine(Offset(14, cy), Offset(size.width, cy), linePaint);
  }

  @override
  bool shouldRepaint(covariant _SectorHeaderBeamPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.secondary != secondary;
}
