import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/home/widgets/logo_text.dart';
import 'package:spnk/views/screens/home/widgets/theme_icon.dart';
import 'package:spnk/views/screens/home/widgets/theme_switch.dart';
import 'package:spnk/views/screens/solar/solar_models.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';

/// Top glass navigation bar for the `/v3` 3D Solar System Portfolio.
class SolarTopNavBar extends StatelessWidget {
  const SolarTopNavBar({
    super.key,
    required this.planets,
    required this.focusKind,
    required this.focusedPlanetId,
    required this.isPaused,
    required this.themeState,
    required this.onGoHome,
    required this.onOpenV2,
    required this.onFocusOverview,
    required this.onFocusStar,
    required this.onFocusPlanet,
    required this.onTogglePause,
  });

  final List<SolarPlanetData> planets;
  final SolarFocusKind focusKind;
  final String? focusedPlanetId;
  final bool isPaused;
  final ThemeState themeState;
  final VoidCallback onGoHome;
  final VoidCallback onOpenV2;
  final VoidCallback onFocusOverview;
  final VoidCallback onFocusStar;
  final ValueChanged<String> onFocusPlanet;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context) {
    final accent = themeState.accentColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final isVeryCompact = maxW < 560;

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: themeState.themeData.scaffoldBackgroundColor.withValues(
                  alpha: themeState.isDark ? 0.80 : 0.90,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: themeState.cardBorderColor,
                    width: 1.1,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: maxW >= 1200 ? 28 : 10,
                vertical: 7,
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    LogoText(onTap: onFocusOverview),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Back to Interactive Grid Home (/)',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: onGoHome,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVeryCompact ? 7 : 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: themeState.cardSurfaceColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: themeState.cardBorderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.grid_view_rounded, size: 13, color: accent),
                                if (!isVeryCompact) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    'HOME',
                                    style: context.bodySmall.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Tooltip(
                      message: 'Open 3D Racer (/v2)',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: onOpenV2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.65),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.sports_motorsports_rounded,
                                  size: 13,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '/v2',
                                  style: context.bodySmall.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Cosmic section selector bar
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: themeState.cardSurfaceColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: themeState.cardBorderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PlanetNavChip(
                                label: 'STAR',
                                color: const Color(0xFFFBBF24),
                                selected: focusKind == SolarFocusKind.star,
                                onTap: onFocusStar,
                              ),
                              ...planets.map((p) {
                                final isSelected = focusedPlanetId == p.id &&
                                    (focusKind == SolarFocusKind.planet ||
                                        focusKind == SolarFocusKind.moon);
                                return _PlanetNavChip(
                                  label: p.shortLabel,
                                  color: p.color,
                                  selected: isSelected,
                                  onTap: () => onFocusPlanet(p.id),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    Tooltip(
                      message: isPaused ? 'Resume Orbits (Space)' : 'Pause Orbits (Space)',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          key: const ValueKey('solar_toggle_orbit'),
                          onTap: onTogglePause,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: themeState.cardSurfaceColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: themeState.cardBorderColor),
                            ),
                            child: Icon(
                              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 16,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Tooltip(
                      message: 'Full Solar System View (0 / Esc)',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          key: const ValueKey('solar_reset_overview'),
                          onTap: onFocusOverview,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVeryCompact ? 6 : 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: focusKind == SolarFocusKind.overview
                                  ? accent.withValues(alpha: 0.2)
                                  : themeState.cardSurfaceColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: focusKind == SolarFocusKind.overview
                                    ? accent
                                    : themeState.cardBorderColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.public_rounded, size: 14, color: accent),
                                if (!isVeryCompact) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    'SYSTEM',
                                    style: context.bodySmall.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeState.cardSurfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: themeState.cardBorderColor),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BrightnessSwitch(),
                          SizedBox(width: 6),
                          ThemeIcon(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlanetNavChip extends StatelessWidget {
  const _PlanetNavChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected ? color : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: context.bodySmall.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.9,
                  color: selected
                      ? Colors.white
                      : context.primaryColor.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating glass inspector docked at the bottom when viewing Overview,
/// Central Star, Planet (section), or Moon (sub-section).
class SolarFocusInspectorCard extends StatelessWidget {
  const SolarFocusInspectorCard({
    super.key,
    required this.planets,
    required this.focusKind,
    required this.focusedPlanet,
    required this.focusedMoon,
    required this.themeState,
    required this.copiedValue,
    required this.onFocusOverview,
    required this.onFocusStar,
    required this.onFocusPlanet,
    required this.onFocusMoon,
    required this.onStepPrev,
    required this.onStepNext,
    required this.onLaunchUrl,
    required this.onCopyText,
    required this.onBoostSkill,
  });

  final List<SolarPlanetData> planets;
  final SolarFocusKind focusKind;
  final SolarPlanetData? focusedPlanet;
  final SolarMoonData? focusedMoon;
  final ThemeState themeState;
  final String? copiedValue;
  final VoidCallback onFocusOverview;
  final VoidCallback onFocusStar;
  final ValueChanged<String> onFocusPlanet;
  final void Function(String planetId, String moonId) onFocusMoon;
  final VoidCallback onStepPrev;
  final VoidCallback onStepNext;
  final ValueChanged<String> onLaunchUrl;
  final ValueChanged<String> onCopyText;
  final ValueChanged<String> onBoostSkill;

  @override
  Widget build(BuildContext context) {
    final screenW = context.screenWidth;
    final screenH = context.screenHeight;
    final isCompact = screenW < 640;
    final accentColor = switch (focusKind) {
      SolarFocusKind.moon => focusedMoon?.color ?? themeState.accentColor,
      SolarFocusKind.planet => focusedPlanet?.color ?? themeState.accentColor,
      SolarFocusKind.star => const Color(0xFFFBBF24),
      SolarFocusKind.overview => themeState.accentColor,
    };

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 840,
        maxHeight: (screenH * (isCompact ? 0.42 : 0.36)).clamp(140.0, 330.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFF070B14).withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.60),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.16),
                  blurRadius: 24,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: switch (focusKind) {
                SolarFocusKind.overview => _buildOverviewContent(context, accentColor),
                SolarFocusKind.star => _buildStarContent(context, accentColor, isCompact),
                SolarFocusKind.planet => _buildPlanetContent(context, accentColor),
                SolarFocusKind.moon => _buildMoonContent(context, accentColor),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewContent(BuildContext context, Color accent) {
    final totalMoons = planets.fold<int>(0, (acc, p) => acc + p.moons.length);
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SPNK SOLAR SYSTEM // $totalMoons ORBITING MOONS',
              style: context.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: accent,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Click the Central Star, any Planet, or Orbit Chip above to center & explore • Drag to orbit • Scroll to zoom',
              style: context.bodySmall.copyWith(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
        _HudButton(
          label: 'FOCUS CENTRAL STAR',
          icon: Icons.wb_sunny_rounded,
          color: const Color(0xFFFBBF24),
          filled: true,
          onTap: onFocusStar,
        ),
      ],
    );
  }

  Widget _buildStarContent(
    BuildContext context,
    Color starColor,
    bool isCompact,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: starColor, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/propic3.png',
                  width: isCompact ? 42 : 52,
                  height: isCompact ? 42 : 52,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIVAPRASAD NK',
                    style: context.displaySmall.copyWith(
                      fontSize: isCompact ? 17 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'CENTRAL STAR • SENIOR FLUTTER ARCHITECT • KERALA, INDIA',
                    style: context.bodySmall.copyWith(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: starColor,
                    ),
                  ),
                ],
              ),
            ),
            _HudButton(
              label: 'FULL SYSTEM',
              icon: Icons.public_rounded,
              color: Colors.white70,
              onTap: onFocusOverview,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HudButton(
              label: 'GitHub',
              icon: FontAwesomeIcons.github,
              color: Colors.white,
              onTap: () => onLaunchUrl(githubLink),
            ),
            _HudButton(
              label: 'LinkedIn',
              icon: FontAwesomeIcons.linkedinIn,
              color: const Color(0xFF38BDF8),
              onTap: () => onLaunchUrl(linkedInLink),
            ),
            _HudButton(
              label: 'Pub.dev',
              icon: Icons.widgets_rounded,
              color: const Color(0xFF0EA5E9),
              onTap: () => onLaunchUrl(pubDevLink),
            ),
            _HudButton(
              label: 'VS Code',
              icon: Icons.palette_rounded,
              color: const Color(0xFFA855F7),
              onTap: () => onLaunchUrl(vsCodeThemesLink),
            ),
            _HudButton(
              label: 'Resume PDF',
              icon: Icons.description_rounded,
              color: const Color(0xFF10B981),
              filled: true,
              onTap: () => onLaunchUrl(resumeLink),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanetContent(BuildContext context, Color planetColor) {
    final p = focusedPlanet;
    if (p == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(p.icon, color: planetColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: context.displaySmall.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    p.tagline,
                    style: context.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: planetColor,
                    ),
                  ),
                ],
              ),
            ),
            _HudButton(
              label: '← PREV',
              icon: Icons.chevron_left_rounded,
              color: Colors.white70,
              onTap: onStepPrev,
            ),
            const SizedBox(width: 6),
            _HudButton(
              label: 'NEXT →',
              icon: Icons.chevron_right_rounded,
              color: Colors.white70,
              onTap: onStepNext,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          p.summary.replaceAll('\n', ' '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.bodySmall.copyWith(
            fontSize: 12.5,
            color: Colors.white.withValues(alpha: 0.82),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'ORBITING MOONS (CLICK TO CENTER):',
          style: context.bodySmall.copyWith(
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: p.moons.map((m) {
            return _HudButton(
              label: m.title,
              icon: Icons.brightness_2_rounded,
              color: m.color,
              onTap: () => onFocusMoon(p.id, m.id),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMoonContent(BuildContext context, Color moonColor) {
    final p = focusedPlanet;
    final m = focusedMoon;
    if (p == null || m == null) return const SizedBox.shrink();

    final skillBoost = m.skillTitle != null
        ? GamificationController.instance.getSkillBoost(m.skillTitle!)
        : 0;

    return ListenableBuilder(
      listenable: GamificationController.instance,
      builder: (context, _) {
        final currentBoost = m.skillTitle != null
            ? GamificationController.instance.getSkillBoost(m.skillTitle!)
            : skillBoost;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            m.title,
                            style: context.displaySmall.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: moonColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: moonColor.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              m.badge,
                              style: context.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: moonColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${p.shortLabel} MOON • ${m.subtitle}',
                        style: context.bodySmall.copyWith(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _HudButton(
                  label: 'BACK TO ${p.shortLabel}',
                  icon: Icons.arrow_upward_rounded,
                  color: p.color,
                  onTap: () => onFocusPlanet(p.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...m.descriptionLines.take(3).map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $line',
                      style: context.bodySmall.copyWith(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HudButton(
                  label: 'PREV MOON',
                  icon: Icons.chevron_left_rounded,
                  color: Colors.white70,
                  onTap: onStepPrev,
                ),
                _HudButton(
                  label: 'NEXT MOON',
                  icon: Icons.chevron_right_rounded,
                  color: Colors.white70,
                  onTap: onStepNext,
                ),
                if (m.skillTitle != null)
                  _HudButton(
                    label: currentBoost > 0
                        ? 'OVERCLOCK LVL $currentBoost/5'
                        : 'OVERCLOCK +15 XP',
                    icon: Icons.bolt_rounded,
                    color: moonColor,
                    filled: true,
                    onTap: () => onBoostSkill(m.skillTitle!),
                  ),
                if (m.webUrl != null)
                  _HudButton(
                    label: 'LAUNCH WEB',
                    icon: Icons.open_in_new_rounded,
                    color: moonColor,
                    filled: true,
                    onTap: () => onLaunchUrl(m.webUrl!),
                  ),
                if (m.playStoreUrl != null)
                  _HudButton(
                    label: 'PLAY STORE',
                    icon: Icons.shop_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => onLaunchUrl(m.playStoreUrl!),
                  ),
                if (m.copyValue != null)
                  _HudButton(
                    label: copiedValue == m.copyValue ? 'COPIED!' : 'COPY',
                    icon: copiedValue == m.copyValue
                        ? Icons.check_rounded
                        : Icons.copy_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => onCopyText(m.copyValue!),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: filled
                ? color.withValues(alpha: 0.24)
                : color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: filled ? 0.85 : 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13.5, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.7,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
