import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:spnk/views/screens/christmas/christmas_painters.dart';
import 'package:spnk/views/screens/christmas/christmas_theme_config.dart';

/// Navigation cloud item metadata.
class CloudNavItem {
  const CloudNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.driftPhase,
    required this.driftSpeed,
    required this.bobAmp,
  });

  final String id;
  final String label;
  final IconData icon;
  final double driftPhase;
  final double driftSpeed;
  final double bobAmp;
}

const List<CloudNavItem> kWinterCloudNavItems = [
  CloudNavItem(
    id: 'home',
    label: 'Home',
    icon: Icons.cottage_rounded,
    driftPhase: 0.2,
    driftSpeed: 0.72,
    bobAmp: 4.5,
  ),
  CloudNavItem(
    id: 'about',
    label: 'About',
    icon: Icons.person_pin_rounded,
    driftPhase: 1.4,
    driftSpeed: 0.58,
    bobAmp: 5.5,
  ),
  CloudNavItem(
    id: 'experience',
    label: 'Experience',
    icon: Icons.timeline_rounded,
    driftPhase: 2.6,
    driftSpeed: 0.84,
    bobAmp: 4.0,
  ),
  CloudNavItem(
    id: 'projects',
    label: 'Projects',
    icon: Icons.auto_awesome_mosaic_rounded,
    driftPhase: 3.7,
    driftSpeed: 0.65,
    bobAmp: 5.2,
  ),
  CloudNavItem(
    id: 'skills',
    label: 'Skills',
    icon: Icons.ac_unit_rounded,
    driftPhase: 4.9,
    driftSpeed: 0.78,
    bobAmp: 4.2,
  ),
  CloudNavItem(
    id: 'contact',
    label: 'Contact',
    icon: Icons.mail_outline_rounded,
    driftPhase: 5.8,
    driftSpeed: 0.62,
    bobAmp: 5.0,
  ),
];

/// Fixed top-left glass snow globe displaying "SP" initials, a miniature snowy
/// evergreen tree, animated swirling snow flakes, and hover glass reflection.
class SpGlassSnowGlobe extends StatefulWidget {
  const SpGlassSnowGlobe({
    super.key,
    required this.elapsed,
    required this.dayFactor,
    required this.reducedMotion,
    required this.onTap,
    this.size = 64,
  });

  final double elapsed;
  final double dayFactor;
  final bool reducedMotion;
  final VoidCallback onTap;
  final double size;

  @override
  State<SpGlassSnowGlobe> createState() => _SpGlassSnowGlobeState();
}

class _SpGlassSnowGlobeState extends State<SpGlassSnowGlobe> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final globeSize = widget.size;
    return Semantics(
      button: true,
      label: 'SP Snow Globe — Return to Home',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          key: const ValueKey('sp_snow_globe'),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hovered && !widget.reducedMotion ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: Tooltip(
              message: 'SP Winter Village — Back to Home',
              child: SizedBox(
                width: globeSize + 6,
                height: globeSize + 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: globeSize,
                      height: globeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.lerp(
                              const Color(0x667DD3FC),
                              const Color(0x551E40AF),
                              widget.dayFactor,
                            )!,
                            blurRadius: _hovered ? 22 : 12,
                            spreadRadius: _hovered ? 2 : 0,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _SpSnowGlobePainter(
                          elapsed: widget.reducedMotion ? 0.0 : widget.elapsed,
                          dayFactor: widget.dayFactor,
                          hovered: _hovered,
                        ),
                      ),
                    ),
                    // Brass & dark wood pedestal base
                    Transform.translate(
                      offset: const Offset(0, -4),
                      child: Container(
                        width: globeSize * 0.72,
                        height: 11,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              ChristmasThemeConfig.champagneGold,
                              ChristmasThemeConfig.cabinWoodDark,
                            ],
                          ),
                          border: Border.all(
                            color: ChristmasThemeConfig.warmGold
                                .withValues(alpha: 0.75),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpSnowGlobePainter extends CustomPainter {
  const _SpSnowGlobePainter({
    required this.elapsed,
    required this.dayFactor,
    required this.hovered,
  });

  final double elapsed;
  final double dayFactor;
  final bool hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    // Sky inside globe (interpolates day / night)
    final skyGradient = RadialGradient(
      center: const Alignment(-0.25, -0.35),
      radius: 1.1,
      colors: [
        Color.lerp(const Color(0xFF1E3A6D), const Color(0xFF8BD3FA), dayFactor)!,
        Color.lerp(const Color(0xFF071329), const Color(0xFF2B7AC4), dayFactor)!,
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = skyGradient.createShader(Offset.zero & size),
    );

    // Snow bank mound at bottom of globe
    final snowPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.62,
        size.width,
        size.height * 0.73,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      snowPath,
      Paint()
        ..color = Color.lerp(
          const Color(0xFFDCEEFB),
          const Color(0xFFFFFFFF),
          dayFactor,
        )!,
    );

    // Miniature snowy evergreen tree tucked beside SP
    final treePaint = Paint()..color = const Color(0xFF14533B);
    final tx = size.width * 0.73;
    final ty = size.height * 0.68;
    for (int i = 0; i < 3; i++) {
      final w = 11.0 - i * 2.5;
      final h = 9.0;
      final topY = ty - 16 + i * 5.0;
      final p = Path()
        ..moveTo(tx, topY - h * 0.5)
        ..lineTo(tx - w * 0.5, topY + h * 0.5)
        ..lineTo(tx + w * 0.5, topY + h * 0.5)
        ..close();
      canvas.drawPath(p, treePaint);
    }
    // Star on mini tree
    canvas.drawCircle(
      Offset(tx, ty - 22),
      2.1,
      Paint()..color = ChristmasThemeConfig.champagneGold,
    );

    // Swirling miniature snow inside the glass globe
    final flakePaint = Paint()..color = Colors.white.withValues(alpha: 0.88);
    for (int i = 0; i < 16; i++) {
      final px = ((i * 17.3 + math.sin(elapsed * 1.4 + i) * 7.0) %
          (size.width - 8)) +
          4;
      final py = ((i * 11.7 + elapsed * (11 + (i % 4) * 3)) %
          (size.height * 0.66)) +
          4;
      canvas.drawCircle(Offset(px, py), (i % 3 == 0) ? 1.5 : 0.95, flakePaint);
    }

    // Crisp SP monogram centered in the globe
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'SP',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.30,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: const [
            Shadow(color: Color(0xAA071329), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width * 0.42 - textPainter.width / 2,
        size.height * 0.44 - textPainter.height / 2,
      ),
    );

    // Specular glass highlight arc & dynamic hover sweep
    final sweepShift = hovered ? math.sin(elapsed * 3.5) * 6.0 : 0.0;
    final glassArc = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: hovered ? 0.58 : 0.42),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.32 + sweepShift, size.height * 0.25),
          radius: radius * 0.85,
        ),
      );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.14 + sweepShift * 0.4,
        size.height * 0.08,
        size.width * 0.54,
        size.height * 0.30,
      ),
      glassArc,
    );

    canvas.restore();

    // Outer glass rim
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hovered ? 2.0 : 1.4
        ..color = Color.lerp(
          const Color(0x99BAE6FD),
          const Color(0xCCFFFFFF),
          hovered ? 1.0 : dayFactor * 0.6,
        )!,
    );
  }

  @override
  bool shouldRepaint(covariant _SpSnowGlobePainter oldDelegate) {
    return oldDelegate.elapsed != elapsed ||
        oldDelegate.dayFactor != dayFactor ||
        oldDelegate.hovered != hovered;
  }
}

/// Floating cloud navigation bar with no rectangular chrome — each destination
/// lives inside its own fluffy cloud gently drifting across the sky.
class FloatingCloudNavigation extends StatelessWidget {
  const FloatingCloudNavigation({
    super.key,
    required this.items,
    required this.activeSectionId,
    required this.elapsed,
    required this.dayFactor,
    required this.reducedMotion,
    required this.onSelect,
  });

  final List<CloudNavItem> items;
  final String activeSectionId;
  final double elapsed;
  final double dayFactor;
  final bool reducedMotion;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: compact ? 6 : 12,
          runSpacing: compact ? 6 : 10,
          children: [
            for (final item in items)
              _FloatingCloudItem(
                item: item,
                isActive: activeSectionId == item.id,
                elapsed: elapsed,
                dayFactor: dayFactor,
                reducedMotion: reducedMotion,
                compact: compact,
                onTap: () => onSelect(item.id),
              ),
          ],
        );
      },
    );
  }
}

class _FloatingCloudItem extends StatefulWidget {
  const _FloatingCloudItem({
    required this.item,
    required this.isActive,
    required this.elapsed,
    required this.dayFactor,
    required this.reducedMotion,
    required this.compact,
    required this.onTap,
  });

  final CloudNavItem item;
  final bool isActive;
  final double elapsed;
  final double dayFactor;
  final bool reducedMotion;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_FloatingCloudItem> createState() => _FloatingCloudItemState();
}

class _FloatingCloudItemState extends State<_FloatingCloudItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.reducedMotion ? 0.0 : widget.elapsed;
    final dx = widget.compact || widget.reducedMotion
        ? 0.0
        : math.sin(t * widget.item.driftSpeed + widget.item.driftPhase) * 6.0;
    final dy = widget.reducedMotion
        ? 0.0
        : math.cos(t * (widget.item.driftSpeed * 1.15) + widget.item.driftPhase) *
            (widget.compact ? 2.0 : widget.item.bobAmp);

    final textColor = Color.lerp(
      const Color(0xFF0E294B),
      const Color(0xFF0A213F),
      widget.dayFactor,
    )!;
    final accentColor = widget.isActive
        ? const Color(0xFFB45309)
        : Color.lerp(
            const Color(0xFF0369A1),
            const Color(0xFF0284C7),
            widget.dayFactor,
          )!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: ValueKey('cloud_nav_${widget.item.id}'),
        onTap: widget.onTap,
        child: Transform.translate(
          offset: Offset(dx, dy + (_hovered ? -3.0 : 0.0)),
          child: AnimatedScale(
            scale: _hovered && !widget.reducedMotion ? 1.09 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: CustomPaint(
              painter: _CloudShapePainter(
                dayFactor: widget.dayFactor,
                isActive: widget.isActive,
                hovered: _hovered,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 14 : 18,
                  vertical: widget.compact ? 9 : 11,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.item.icon,
                      size: widget.compact ? 14 : 15,
                      color: accentColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.item.label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: widget.compact ? 12 : 13,
                        fontWeight:
                            widget.isActive ? FontWeight.w800 : FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloudShapePainter extends CustomPainter {
  const _CloudShapePainter({
    required this.dayFactor,
    required this.isActive,
    required this.hovered,
  });

  final double dayFactor;
  final bool isActive;
  final bool hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.06, h * 0.24, w * 0.88, h * 0.72),
          Radius.circular(h * 0.36),
        ),
      )
      ..addOval(Rect.fromCircle(center: Offset(w * 0.28, h * 0.34), radius: h * 0.30))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.52, h * 0.25), radius: h * 0.36))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.74, h * 0.36), radius: h * 0.28));

    // Soft atmospheric shadow underneath cloud
    canvas.drawPath(
      path.shift(const Offset(0, 4)),
      Paint()
        ..color = Color.lerp(
          const Color(0x66020817),
          const Color(0x331E3A5F),
          dayFactor,
        )!
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    if (hovered || isActive) {
      canvas.drawPath(
        path,
        Paint()
          ..color = (isActive
                  ? ChristmasThemeConfig.champagneGold
                  : ChristmasThemeConfig.icyBlue)
              .withValues(alpha: hovered ? 0.55 : 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Fluffy cloud fill
    final fillShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(const Color(0xFFEDF6FF), Colors.white, dayFactor)!,
        Color.lerp(const Color(0xFFCAE1F7), const Color(0xFFF0F7FF), dayFactor)!,
      ],
    ).createShader(Offset.zero & size);
    canvas.drawPath(path, Paint()..shader = fillShader);

    // Delicate highlight rim
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 1.4 : 0.9
        ..color = isActive
            ? ChristmasThemeConfig.warmGold.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _CloudShapePainter oldDelegate) {
    return oldDelegate.dayFactor != dayFactor ||
        oldDelegate.isActive != isActive ||
        oldDelegate.hovered != hovered;
  }
}

/// Top-right floating sky controls: Sun/Moon Day/Night toggle, Let It Snow,
/// and quick portals (/v4 classic, /v2 racer, /v3 solar).
class WinterControlCluster extends StatelessWidget {
  const WinterControlCluster({
    super.key,
    required this.isDayMode,
    required this.dayFactor,
    required this.snowEnabled,
    required this.compact,
    required this.onToggleDayNight,
    required this.onToggleSnow,
    required this.onOpenClassicV4,
    required this.onOpenRacerV2,
    required this.onOpenSolarV3,
  });

  final bool isDayMode;
  final double dayFactor;
  final bool snowEnabled;
  final bool compact;
  final VoidCallback onToggleDayNight;
  final VoidCallback onToggleSnow;
  final VoidCallback onOpenClassicV4;
  final VoidCallback onOpenRacerV2;
  final VoidCallback onOpenSolarV3;

  @override
  Widget build(BuildContext context) {
    final pillBg = Color.lerp(
      const Color(0xC209172E),
      const Color(0xE0F5FAFF),
      dayFactor,
    )!;
    final pillBorder = ChristmasThemeConfig.cardBorder(dayFactor);
    final labelColor = ChristmasThemeConfig.primaryText(dayFactor);

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: compact ? 6 : 8,
      runSpacing: 6,
      children: [
        // Sun / Moon Day-Night Environment Toggle
        Tooltip(
          message: isDayMode
              ? 'Switch to Night Village (Stars & Aurora)'
              : 'Switch to Day Village (Sunlight & Clear Sky)',
          child: InkWell(
            key: const ValueKey('day_night_toggle'),
            onTap: onToggleDayNight,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: pillBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Icon(
                      isDayMode
                          ? Icons.wb_sunny_rounded
                          : Icons.nightlight_round,
                      key: ValueKey(isDayMode),
                      size: 16,
                      color: isDayMode
                          ? const Color(0xFFD97706)
                          : ChristmasThemeConfig.champagneGold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isDayMode ? 'Day' : 'Night',
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Let It Snow toggle
        InkWell(
          key: const ValueKey('let_it_snow_toggle'),
          onTap: onToggleSnow,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: snowEnabled
                    ? ChristmasThemeConfig.accentIce(dayFactor)
                        .withValues(alpha: 0.7)
                    : pillBorder,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x28000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.ac_unit_rounded,
                  size: 15,
                  color: snowEnabled
                      ? ChristmasThemeConfig.accentIce(dayFactor)
                      : labelColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 5),
                Text(
                  snowEnabled ? 'Let It Snow: ON' : 'Let It Snow: OFF',
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Classic /v4 + portals
        InkWell(
          onTap: onOpenClassicV4,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: pillBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 14,
                  color: ChristmasThemeConfig.accentGold(dayFactor),
                ),
                const SizedBox(width: 5),
                Text(
                  'CLASSIC /v4',
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (!compact) ...[
          _PortalMiniChip(
            label: '3D RACER /v2',
            dayFactor: dayFactor,
            onTap: onOpenRacerV2,
          ),
          _PortalMiniChip(
            label: '3D SOLAR /v3',
            dayFactor: dayFactor,
            onTap: onOpenSolarV3,
          ),
        ],
      ],
    );
  }
}

class _PortalMiniChip extends StatelessWidget {
  const _PortalMiniChip({
    required this.label,
    required this.dayFactor,
    required this.onTap,
  });

  final String label;
  final double dayFactor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: ChristmasThemeConfig.cardSurface(dayFactor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ChristmasThemeConfig.cardBorder(dayFactor)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ChristmasThemeConfig.secondaryText(dayFactor),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// Frosted snow-glass environmental container with delicate snow cap trim and
/// optional carved-wood header plaque styling.
class VillageFrostPanel extends StatelessWidget {
  const VillageFrostPanel({
    super.key,
    required this.dayFactor,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 24,
    this.woodenAccent = false,
  });

  final double dayFactor;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool woodenAccent;

  @override
  Widget build(BuildContext context) {
    final surface = ChristmasThemeConfig.cardSurface(dayFactor);
    final border = woodenAccent
        ? Color.lerp(
            const Color(0x88D4A039),
            const Color(0xAA8B5A2B),
            dayFactor,
          )!
        : ChristmasThemeConfig.cardBorder(dayFactor);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: surface,
            border: Border.all(color: border, width: woodenAccent ? 1.5 : 1.1),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  const Color(0x55020817),
                  const Color(0x281E3A5F),
                  dayFactor,
                )!,
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Multi-layer interactive 2D Winter Village canvas painter used as a graceful
/// non-WebGL / headless-test fallback when Three.js WebGL canvas isn't mounted,
/// plus optional crisp foreground snow cursor trail.
class WinterVillageFallbackPainter extends CustomPainter {
  const WinterVillageFallbackPainter({
    required this.dayFactor,
    required this.elapsed,
    required this.scrollOffset,
    required this.pointerNorm,
    required this.snowEnabled,
    required this.reducedMotion,
    required this.snowSim,
    required this.renderEnvironment,
  });

  final double dayFactor;
  final double elapsed;
  final double scrollOffset;
  final Offset pointerNorm;
  final bool snowEnabled;
  final bool reducedMotion;
  final SnowfallSimulation snowSim;

  /// When `false`, only snowfall + cursor snow sparkle is painted (used above the
  /// live Three.js 3D canvas).
  final bool renderEnvironment;

  @override
  void paint(Canvas canvas, Size size) {
    if (renderEnvironment) {
      _paintSkyAndCelestial(canvas, size);
      _paintMountainsAndTerrain(canvas, size);
      _paintVillageElements(canvas, size);
    }

    if (snowEnabled) {
      _paintSnowflakes(canvas, size);
    }
  }

  void _paintSkyAndCelestial(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final skyShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        ChristmasThemeConfig.skyTop(dayFactor),
        ChristmasThemeConfig.skyMid(dayFactor),
        ChristmasThemeConfig.skyHorizon(dayFactor),
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = skyShader);

    final parallaxX = pointerNorm.dx * -16.0;
    final parallaxY = pointerNorm.dy * -10.0;

    // Night Stars & Aurora Borealis
    if (dayFactor < 0.85) {
      final nightStrength = (1.0 - dayFactor).clamp(0.0, 1.0);
      final starPaint = Paint();
      for (int i = 0; i < 65; i++) {
        final sx = ((i * 193.7 + parallaxX * 0.4) % size.width);
        final sy = ((i * 89.3 + parallaxY * 0.4) % (size.height * 0.58));
        final twinkle = reducedMotion
            ? 0.7
            : 0.45 + 0.55 * math.sin(elapsed * (1.2 + (i % 5) * 0.35) + i);
        starPaint.color =
            Colors.white.withValues(alpha: nightStrength * twinkle * 0.85);
        canvas.drawCircle(Offset(sx, sy), i % 5 == 0 ? 1.8 : 1.1, starPaint);
      }

      // Soft Aurora ribbon
      final auroraWave = reducedMotion ? 0.0 : math.sin(elapsed * 0.4) * 18.0;
      final auroraPath = Path()
        ..moveTo(0, size.height * 0.22 + auroraWave)
        ..cubicTo(
          size.width * 0.28,
          size.height * 0.12 - auroraWave,
          size.width * 0.68,
          size.height * 0.28 + auroraWave,
          size.width,
          size.height * 0.16,
        );
      canvas.drawPath(
        auroraPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 34
          ..color = const Color(0xFF22D3A6)
              .withValues(alpha: 0.18 * nightStrength)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
      );
    }

    // Sun or Moon
    final orbPos = Offset(
      size.width * lerpDouble(0.80, 0.74, dayFactor)! + parallaxX * 0.6,
      size.height * lerpDouble(0.18, 0.16, dayFactor)! + parallaxY * 0.6,
    );
    final orbColor = Color.lerp(
      const Color(0xFFE6F1FF),
      const Color(0xFFFFF4C7),
      dayFactor,
    )!;
    canvas.drawCircle(
      orbPos,
      lerpDouble(44, 62, dayFactor)!,
      Paint()
        ..color = orbColor.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawCircle(
      orbPos,
      lerpDouble(20, 26, dayFactor)!,
      Paint()..color = orbColor,
    );
  }

  void _paintMountainsAndTerrain(Canvas canvas, Size size) {
    final shift = (scrollOffset * 0.06).clamp(0.0, 120.0);
    final farColor = Color.lerp(
      const Color(0xFF1A3358),
      const Color(0xFF9AC5EB),
      dayFactor,
    )!;
    final farPath = Path()..moveTo(0, size.height * 0.68);
    final peaks = [0.0, 0.16, 0.34, 0.52, 0.72, 0.88, 1.0];
    final heights = [0.64, 0.44, 0.58, 0.41, 0.56, 0.43, 0.62];
    for (int i = 0; i < peaks.length; i++) {
      farPath.lineTo(
        peaks[i] * size.width,
        size.height * heights[i] - shift * 0.2,
      );
    }
    farPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(farPath, Paint()..color = farColor);

    // Rolling snow terrain ground
    final groundGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(const Color(0xFF5F85B0), const Color(0xFFE8F4FD), dayFactor)!,
        Color.lerp(const Color(0xFF9CC0DF), const Color(0xFFF8FCFF), dayFactor)!,
      ],
    ).createShader(
      Rect.fromLTWH(0, size.height * 0.56, size.width, size.height * 0.44),
    );
    final groundPath = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.56,
        size.width * 0.55,
        size.height * 0.63,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.70,
        size.width,
        size.height * 0.60,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(groundPath, Paint()..shader = groundGrad);
  }

  void _paintVillageElements(Canvas canvas, Size size) {
    final baseY = size.height * 0.74;

    // Pine trees scattered across horizon
    final treePositions = [0.09, 0.21, 0.37, 0.66, 0.82, 0.92];
    for (int i = 0; i < treePositions.length; i++) {
      final tx = size.width * treePositions[i];
      final ty = baseY - (i.isEven ? 18.0 : 6.0);
      final h = 44.0 + (i % 3) * 14.0;
      final treeColor = Color.lerp(
        const Color(0xFF0E3A2A),
        const Color(0xFF1A5B40),
        dayFactor,
      )!;
      final p = Path()
        ..moveTo(tx, ty - h)
        ..lineTo(tx - h * 0.34, ty)
        ..lineTo(tx + h * 0.34, ty)
        ..close();
      canvas.drawPath(p, Paint()..color = treeColor);
    }

    // Glowing Igloo on left-midground
    final iglooCenter = Offset(size.width * 0.24, baseY + 12);
    canvas.drawArc(
      Rect.fromCenter(center: iglooCenter, width: 64, height: 48),
      math.pi,
      math.pi,
      true,
      Paint()
        ..color = Color.lerp(
          const Color(0xFFCCE4F7),
          const Color(0xFFF6FBFF),
          dayFactor,
        )!,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: iglooCenter.translate(0, 1),
        width: 22,
        height: 24,
      ),
      math.pi,
      math.pi,
      true,
      Paint()
        ..color = Color.lerp(
          const Color(0xFFFFB74D),
          const Color(0xFF4B5563),
          dayFactor * 0.75,
        )!,
    );

    // Santa sleigh periodically crossing sky (every 40s)
    if (!reducedMotion) {
      final cycle = elapsed % 40.0;
      if (cycle < 10.0) {
        final sx = lerpDouble(-80, size.width + 80, cycle / 10.0)!;
        final sy = size.height * 0.20 + math.sin(cycle * 1.4) * 8.0;
        canvas.drawCircle(
          Offset(sx - 18, sy),
          14,
          Paint()
            ..color = ChristmasThemeConfig.champagneGold.withValues(alpha: 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(sx, sy), width: 22, height: 9),
            const Radius.circular(4),
          ),
          Paint()..color = ChristmasThemeConfig.burgundy,
        );
      }
    }
  }

  void _paintSnowflakes(Canvas canvas, Size size) {
    final p = Paint();
    for (final f in snowSim.flakes) {
      final x = (f.xFrac * size.width) +
          (reducedMotion
              ? 0.0
              : math.sin(elapsed * 0.9 + f.driftPhase) * f.driftAmp * size.width);
      final y = f.yFrac * size.height;
      p.color = Colors.white.withValues(
        alpha: f.alpha * lerpDouble(0.85, 0.70, dayFactor)!,
      );
      canvas.drawCircle(Offset(x, y), f.radius, p);
    }

    for (final c in snowSim.cursorTrail) {
      final age = (elapsed - c.birthTime).clamp(0.0, 0.85);
      final progress = age / 0.85;
      final pos = c.position + c.velocity * age;
      p.color = ChristmasThemeConfig.champagneGold
          .withValues(alpha: (1.0 - progress) * 0.75);
      canvas.drawCircle(pos, c.size * (1.0 - progress * 0.4), p);
    }
  }

  @override
  bool shouldRepaint(covariant WinterVillageFallbackPainter oldDelegate) => true;
}
