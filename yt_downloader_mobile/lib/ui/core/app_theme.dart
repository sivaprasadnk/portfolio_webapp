import 'dart:math' as math;
import 'package:flutter/material.dart';

enum AppVisualStyle {
  glass('Glass', Icons.auto_awesome_rounded),
  bento('Bento', Icons.grid_view_rounded),
  cyber('Cyber', Icons.terminal_rounded);

  const AppVisualStyle(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum DynamicBackgroundStyle {
  aurora('Aurora Orbs', Icons.blur_on_rounded),
  cyberGrid('Cyber Grid', Icons.grid_4x4_rounded),
  starfield('Cosmic Stars', Icons.auto_awesome_mosaic_rounded),
  minimal('Minimal Solid', Icons.check_box_outline_blank_rounded);

  const DynamicBackgroundStyle(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum BackgroundPalette {
  crimsonStudio(
    'Crimson Studio',
    Color(0xFF0B0F19),
    Color(0xFFF6F8FC),
    Color(0xFFEF4444),
    Color(0xFF38BDF8),
  ),
  midnightCyan(
    'Midnight Cyan',
    Color(0xFF050B16),
    Color(0xFFEFF6FF),
    Color(0xFF38BDF8),
    Color(0xFFA855F7),
  ),
  emeraldMatrix(
    'Emerald Matrix',
    Color(0xFF04120D),
    Color(0xFFECFDF5),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
  ),
  royalAmethyst(
    'Royal Amethyst',
    Color(0xFF11071F),
    Color(0xFFF5F3FF),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
  );

  const BackgroundPalette(
    this.label,
    this.darkBg,
    this.lightBg,
    this.primaryGlow,
    this.secondaryGlow,
  );

  final String label;
  final Color darkBg;
  final Color lightBg;
  final Color primaryGlow;
  final Color secondaryGlow;
}

class YtThemeConfig {
  const YtThemeConfig({
    this.isDark = true,
    this.visualStyle = AppVisualStyle.glass,
    this.bgStyle = DynamicBackgroundStyle.aurora,
    this.palette = BackgroundPalette.crimsonStudio,
  });

  final bool isDark;
  final AppVisualStyle visualStyle;
  final DynamicBackgroundStyle bgStyle;
  final BackgroundPalette palette;

  Color get scaffoldBg => isDark ? palette.darkBg : palette.lightBg;

  Color get primaryText {
    switch (visualStyle) {
      case AppVisualStyle.glass:
        return isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
      case AppVisualStyle.bento:
        return isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B);
      case AppVisualStyle.cyber:
        return isDark ? const Color(0xFFE2F1FF) : const Color(0xFF0B1324);
    }
  }

  Color get accent => palette.primaryGlow;
  Color get secondary => palette.secondaryGlow;

  Color get cardSurface {
    switch (visualStyle) {
      case AppVisualStyle.glass:
        return isDark
            ? const Color(0xFF131B2E).withValues(alpha: 0.80)
            : Colors.white.withValues(alpha: 0.88);
      case AppVisualStyle.bento:
        return isDark ? const Color(0xFF121318) : Colors.white;
      case AppVisualStyle.cyber:
        return isDark
            ? const Color(0xFF0B1222).withValues(alpha: 0.90)
            : Colors.white.withValues(alpha: 0.92);
    }
  }

  Color get cardBorder {
    switch (visualStyle) {
      case AppVisualStyle.glass:
        return isDark
            ? Colors.white.withValues(alpha: 0.11)
            : const Color(0xFF0F172A).withValues(alpha: 0.10);
      case AppVisualStyle.bento:
        return isDark
            ? Colors.white.withValues(alpha: 0.09)
            : const Color(0xFF18181B).withValues(alpha: 0.10);
      case AppVisualStyle.cyber:
        return accent.withValues(alpha: isDark ? 0.35 : 0.25);
    }
  }

  double get cardRadius {
    switch (visualStyle) {
      case AppVisualStyle.glass:
        return 18;
      case AppVisualStyle.bento:
        return 22;
      case AppVisualStyle.cyber:
        return 10;
    }
  }

  ThemeData toThemeData() {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: accent,
        secondary: secondary,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Rajdhani',
        bodyColor: primaryText,
        displayColor: primaryText,
      ),
    );
  }

  YtThemeConfig copyWith({
    bool? isDark,
    AppVisualStyle? visualStyle,
    DynamicBackgroundStyle? bgStyle,
    BackgroundPalette? palette,
  }) {
    return YtThemeConfig(
      isDark: isDark ?? this.isDark,
      visualStyle: visualStyle ?? this.visualStyle,
      bgStyle: bgStyle ?? this.bgStyle,
      palette: palette ?? this.palette,
    );
  }
}

class DynamicStudioBackground extends StatelessWidget {
  const DynamicStudioBackground({
    super.key,
    required this.config,
    required this.child,
  });

  final YtThemeConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: config.scaffoldBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (config.bgStyle != DynamicBackgroundStyle.minimal)
            IgnorePointer(
              child: CustomPaint(
                painter: _StudioBgPainter(config: config),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _StudioBgPainter extends CustomPainter {
  const _StudioBgPainter({required this.config});

  final YtThemeConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = config.isDark;
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          config.accent.withValues(alpha: isDark ? 0.18 : 0.11),
          config.accent.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.15, size.height * 0.12),
          radius: size.shortestSide * 0.72,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.12),
      size.shortestSide * 0.72,
      p1,
    );

    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          config.secondary.withValues(alpha: isDark ? 0.15 : 0.09),
          config.secondary.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.88, size.height * 0.78),
          radius: size.shortestSide * 0.78,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.78),
      size.shortestSide * 0.78,
      p2,
    );

    if (config.bgStyle == DynamicBackgroundStyle.cyberGrid) {
      final gridPaint = Paint()
        ..color = config.accent.withValues(alpha: isDark ? 0.07 : 0.05)
        ..strokeWidth = 1;
      const step = 44.0;
      for (double x = 0; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    } else if (config.bgStyle == DynamicBackgroundStyle.starfield) {
      final starPaint = Paint()
        ..color = config.primaryText.withValues(alpha: isDark ? 0.22 : 0.14);
      final rand = math.Random(42);
      for (int i = 0; i < 55; i++) {
        final dx = rand.nextDouble() * size.width;
        final dy = rand.nextDouble() * size.height;
        final r = 0.8 + rand.nextDouble() * 1.4;
        canvas.drawCircle(Offset(dx, dy), r, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StudioBgPainter oldDelegate) =>
      oldDelegate.config != config;
}

