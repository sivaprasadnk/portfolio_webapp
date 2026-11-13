import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/views/screens/home/widgets/logo_text.dart';
import 'package:spnk/views/screens/home/widgets/theme_icon.dart';
import 'package:spnk/views/screens/home/widgets/theme_switch.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';

class RacingTopTelemetryBar extends StatelessWidget {
  const RacingTopTelemetryBar({
    super.key,
    required this.activeSector,
    required this.gameMode,
    required this.visualTheme,
    required this.palette,
    required this.lapProgress,
    required this.isWarping,
    required this.onSelectSector,
    required this.onSelectGameMode,
    required this.onSelectVisualTheme,
    required this.onOpenPitWall,
    required this.onTriggerNitroQuest,
  });

  final RaceSectorMeta activeSector;
  final RacingGameMode gameMode;
  final RacingVisualTheme visualTheme;
  final RacingThemePalette palette;
  final double lapProgress; // 0.0 .. 1.0
  final bool isWarping;
  final ValueChanged<Screen> onSelectSector;
  final ValueChanged<RacingGameMode> onSelectGameMode;
  final ValueChanged<RacingVisualTheme> onSelectVisualTheme;
  final VoidCallback onOpenPitWall;
  final VoidCallback onTriggerNitroQuest;

  @override
  Widget build(BuildContext context) {
    final accent = palette.accent;
    final secondary = palette.secondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final isVeryCompact = maxW < 560;

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: palette.hudSurface.withValues(alpha: 0.82),
                border: Border(
                  bottom: BorderSide(
                    color: accent.withValues(alpha: 0.42),
                    width: 1.2,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: maxW > 1200 ? 22 : 12,
                vertical: 6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ROW 1: LOGO + 3 GAMEPLAY MODES + 3 VISUAL THEMES + QUESTS + PIT WALL
                  Row(
                    children: [
                      LogoText(
                        onTap: () => onSelectSector(Screen.home),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ModeSelectorGroup(
                                activeMode: gameMode,
                                accent: accent,
                                secondary: secondary,
                                onSelectMode: onSelectGameMode,
                              ),
                              Container(
                                height: 18,
                                width: 1,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                              _VisualThemeSelectorGroup(
                                activeTheme: visualTheme,
                                accent: accent,
                                secondary: secondary,
                                onSelectTheme: onSelectVisualTheme,
                              ),
                              if (!isVeryCompact) ...[
                                const SizedBox(width: 10),
                                GamificationHudPill(
                                  compact: true,
                                  onOpenQuests: () => showQuestLogModal(
                                    context,
                                    onJumpToArcade: onTriggerNitroQuest,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: onOpenPitWall,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVeryCompact ? 9 : 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.80),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.dashboard_customize_rounded,
                                  size: 14,
                                  color: accent,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isVeryCompact ? 'DOSSIER' : 'PIT WALL',
                                  style: context.bodySmall.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const BrightnessSwitch(),
                      const SizedBox(width: 8),
                      const ThemeIcon(),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // ROW 2: 6 PORTFOLIO SECTOR QUICK-WARP STRIP
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _CircuitSectorStrip(
                      activeSector: activeSector,
                      accent: accent,
                      secondary: secondary,
                      compact: true,
                      onSelectSector: onSelectSector,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // ROW 3: LIVE LAP PROGRESS FILAMENT
                  SizedBox(
                    height: 4,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _LapProgressLinePainter(
                        progress: lapProgress,
                        accent: accent,
                        secondary: secondary,
                        isWarping: isWarping,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModeSelectorGroup extends StatelessWidget {
  const _ModeSelectorGroup({
    required this.activeMode,
    required this.accent,
    required this.secondary,
    required this.onSelectMode,
  });

  final RacingGameMode activeMode;
  final Color accent;
  final Color secondary;
  final ValueChanged<RacingGameMode> onSelectMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: RacingGameMode.values.map((mode) {
          final selected = mode == activeMode;
          return Tooltip(
            message: '${mode.title} — ${mode.subtitle}',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onSelectMode(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.26)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: selected
                        ? Border.all(color: accent, width: 1.1)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mode.icon,
                        size: 12.5,
                        color: selected
                            ? secondary
                            : Colors.white.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mode.shortLabel,
                        style: context.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.9,
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VisualThemeSelectorGroup extends StatelessWidget {
  const _VisualThemeSelectorGroup({
    required this.activeTheme,
    required this.accent,
    required this.secondary,
    required this.onSelectTheme,
  });

  final RacingVisualTheme activeTheme;
  final Color accent;
  final Color secondary;
  final ValueChanged<RacingVisualTheme> onSelectTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: RacingVisualTheme.values.map((theme) {
          final selected = theme == activeTheme;
          return Tooltip(
            message: theme.title,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onSelectTheme(theme),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? secondary.withValues(alpha: 0.24)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: selected
                        ? Border.all(color: secondary, width: 1.1)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        theme.icon,
                        size: 12,
                        color: selected
                            ? secondary
                            : Colors.white.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        theme.shortLabel,
                        style: context.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.9,
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CircuitSectorStrip extends StatelessWidget {
  const _CircuitSectorStrip({
    required this.activeSector,
    required this.accent,
    required this.secondary,
    required this.compact,
    required this.onSelectSector,
  });

  final RaceSectorMeta activeSector;
  final Color accent;
  final Color secondary;
  final bool compact;
  final ValueChanged<Screen> onSelectSector;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: RaceSectorMeta.sectors.map((s) {
        final selected = s.index == activeSector.index;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onSelectSector(s.screen),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 9 : 11,
                  vertical: compact ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: selected
                        ? accent
                        : Colors.white.withValues(alpha: 0.12),
                    width: selected ? 1.3 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      s.icon,
                      size: compact ? 12 : 14,
                      color: selected
                          ? accent
                          : Colors.white.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      s.shortLabel,
                      style: context.bodySmall.copyWith(
                        fontSize: compact ? 10.5 : 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LapProgressLinePainter extends CustomPainter {
  final double progress;
  final Color accent;
  final Color secondary;
  final bool isWarping;

  _LapProgressLinePainter({
    required this.progress,
    required this.accent,
    required this.secondary,
    required this.isWarping,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    canvas.drawLine(
      Offset(0, cy),
      Offset(size.width, cy),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 2.0,
    );

    final activeX = (progress.clamp(0.0, 1.0)) * size.width;
    canvas.drawLine(
      Offset(0, cy),
      Offset(activeX, cy),
      Paint()
        ..shader = LinearGradient(
          colors: [accent, secondary],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..strokeWidth = 2.4,
    );

    for (int i = 0; i < 6; i++) {
      final sx = (i / 6.0) * size.width;
      canvas.drawCircle(
        Offset(sx, cy),
        2.2,
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );
    }

    canvas.drawCircle(
      Offset(activeX, cy),
      isWarping ? 5.0 : 3.8,
      Paint()..color = isWarping ? const Color(0xFF00F0FF) : accent,
    );
  }

  @override
  bool shouldRepaint(covariant _LapProgressLinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isWarping != isWarping ||
      oldDelegate.accent != accent;
}

class RacingBottomCockpitHud extends StatelessWidget {
  const RacingBottomCockpitHud({
    super.key,
    required this.gameMode,
    required this.palette,
    required this.speedKmh,
    required this.maxSpeedKmh,
    required this.nitroCharge,
    required this.nitroActive,
    required this.autoPilot,
    required this.lapCount,
    required this.lapTimeSeconds,
    required this.bestLapSeconds,
    required this.overtakes,
    required this.showTouchPedals,
    required this.onToggleAutoPilot,
    required this.onToggleTouchPedals,
    required this.onSteerLeftChanged,
    required this.onSteerRightChanged,
    required this.onGasChanged,
    required this.onBrakeChanged,
    required this.onNitroChanged,
  });

  final RacingGameMode gameMode;
  final RacingThemePalette palette;
  final double speedKmh;
  final double maxSpeedKmh;
  final double nitroCharge; // 0.0 .. 1.0
  final bool nitroActive;
  final bool autoPilot;
  final int lapCount;
  final double lapTimeSeconds;
  final double? bestLapSeconds;
  final int overtakes;
  final bool showTouchPedals;
  final VoidCallback onToggleAutoPilot;
  final VoidCallback onToggleTouchPedals;
  final ValueChanged<bool> onSteerLeftChanged;
  final ValueChanged<bool> onSteerRightChanged;
  final ValueChanged<bool> onGasChanged;
  final ValueChanged<bool> onBrakeChanged;
  final ValueChanged<bool> onNitroChanged;

  String _formatLapTime(double sec) {
    final mins = sec ~/ 60;
    final rem = sec % 60;
    final minsStr = mins.toString().padLeft(2, '0');
    final secsStr = rem.toStringAsFixed(1).padLeft(4, '0');
    return '$minsStr:$secsStr';
  }

  String _computeGear() {
    if (speedKmh < 3) return 'N';
    if (speedKmh < 55) return '1';
    if (speedKmh < 105) return '2';
    if (speedKmh < 160) return '3';
    if (speedKmh < 215) return '4';
    if (speedKmh < 270) return '5';
    if (speedKmh < 335) return '6';
    return '7';
  }

  @override
  Widget build(BuildContext context) {
    final accent = palette.accent;
    final secondary = palette.secondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final isCompact = maxW < 860;
        final effectiveShowPedals = isCompact || showTouchPedals;

        final hintText = switch (gameMode) {
          RacingGameMode.openPaddock =>
            'WASD / ARROWS: FREE-ROAM & DRIFT   •   CLICK ANY ZONE OR LINK PAD   •   SPACE: NITRO   •   E: PIT-STOP   •   1/2/3: GAME MODE   •   T: THEME',
          RacingGameMode.verticalHighway =>
            'WASD / ARROWS: LANE WEAVE & THROTTLE   •   SPACE: NITRO   •   SCROLL: THROTTLE   •   E: PIT-STOP   •   1/2/3: GAME MODE   •   T: THEME',
          RacingGameMode.horizon3d =>
            'WASD / ARROWS: DRIVE & STEER   •   SPACE / SHIFT: NITRO   •   SCROLL: THROTTLE   •   E: PIT-STOP   •   1/2/3: GAME MODE   •   T: THEME',
        };

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 22,
            vertical: isCompact ? 8 : 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (effectiveShowPedals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HoldPedalButton(
                            icon: Icons.keyboard_arrow_left_rounded,
                            label: 'LEFT',
                            color: accent,
                            width: isCompact ? 62 : 70,
                            height: isCompact ? 54 : 60,
                            onHoldChanged: onSteerLeftChanged,
                          ),
                          const SizedBox(width: 8),
                          _HoldPedalButton(
                            icon: Icons.keyboard_arrow_right_rounded,
                            label: 'RIGHT',
                            color: accent,
                            width: isCompact ? 62 : 70,
                            height: isCompact ? 54 : 60,
                            onHoldChanged: onSteerRightChanged,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HoldPedalButton(
                            icon: Icons.south_rounded,
                            label: 'BRAKE',
                            color: const Color(0xFFF43F5E),
                            width: isCompact ? 56 : 66,
                            height: isCompact ? 54 : 60,
                            onHoldChanged: onBrakeChanged,
                          ),
                          const SizedBox(width: 8),
                          _HoldPedalButton(
                            icon: Icons.local_fire_department_rounded,
                            label: 'NITRO',
                            color: const Color(0xFF00F0FF),
                            width: isCompact ? 58 : 68,
                            height: isCompact ? 54 : 60,
                            activeGlow: nitroActive,
                            onHoldChanged: onNitroChanged,
                          ),
                          const SizedBox(width: 8),
                          _HoldPedalButton(
                            icon: Icons.north_rounded,
                            label: 'GAS',
                            color: const Color(0xFF10B981),
                            width: isCompact ? 68 : 78,
                            height: isCompact ? 62 : 68,
                            filled: true,
                            onHoldChanged: onGasChanged,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 18,
                      vertical: isCompact ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: palette.hudSurface.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (nitroActive ? const Color(0xFF00F0FF) : accent)
                            .withValues(alpha: 0.52),
                        width: 1.2,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: isCompact ? 52 : 64,
                                height: isCompact ? 52 : 64,
                                child: CustomPaint(
                                  painter: _TachometerArcPainter(
                                    ratio:
                                        (speedKmh / maxSpeedKmh).clamp(0, 1),
                                    accent: nitroActive
                                        ? const Color(0xFF00F0FF)
                                        : accent,
                                    secondary: secondary,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'G${_computeGear()}',
                                      style: context.bodySmall.copyWith(
                                        fontSize: isCompact ? 12 : 14,
                                        fontWeight: FontWeight.bold,
                                        color: nitroActive
                                            ? const Color(0xFF00F0FF)
                                            : accent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        speedKmh
                                            .round()
                                            .toString()
                                            .padLeft(3, '0'),
                                        style: context.displaySmall.copyWith(
                                          fontSize: isCompact ? 26 : 34,
                                          fontWeight: FontWeight.bold,
                                          height: 1.0,
                                          color: nitroActive
                                              ? const Color(0xFF00F0FF)
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'KM/H',
                                        style: context.bodySmall.copyWith(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                          color: accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department_rounded,
                                        size: 12,
                                        color: Color(0xFF00F0FF),
                                      ),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: isCompact ? 62 : 84,
                                        height: 5,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value:
                                                nitroCharge.clamp(0.0, 1.0),
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.14),
                                            valueColor:
                                                const AlwaysStoppedAnimation(
                                              Color(0xFF00F0FF),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(width: isCompact ? 8 : 22),
                          if (!isCompact || maxW > 430)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CockpitMetric(
                                  label: 'LAP $lapCount',
                                  value: _formatLapTime(lapTimeSeconds),
                                  color: Colors.white,
                                ),
                                if (!isCompact) ...[
                                  const SizedBox(width: 16),
                                  _CockpitMetric(
                                    label: 'BEST LAP',
                                    value: bestLapSeconds != null
                                        ? _formatLapTime(bestLapSeconds!)
                                        : '--:--.-',
                                    color: const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 16),
                                  _CockpitMetric(
                                    label: 'OVERTAKES',
                                    value: '$overtakes',
                                    color: secondary,
                                  ),
                                ],
                              ],
                            ),
                          if (!isCompact) const SizedBox(width: 22),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: onToggleAutoPilot,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 9 : 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: autoPilot
                                          ? const Color(0xFF10B981)
                                              .withValues(alpha: 0.22)
                                          : Colors.white
                                              .withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: autoPilot
                                            ? const Color(0xFF10B981)
                                            : Colors.white
                                                .withValues(alpha: 0.20),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          autoPilot
                                              ? Icons.motion_photos_auto_rounded
                                              : Icons.sports_score_rounded,
                                          size: 14,
                                          color: autoPilot
                                              ? const Color(0xFF10B981)
                                              : Colors.white70,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          autoPilot
                                              ? 'CRUISE: ON'
                                              : 'CRUISE: OFF',
                                          style: context.bodySmall.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                            color: autoPilot
                                                ? const Color(0xFF10B981)
                                                : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (!isCompact) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Toggle On-Screen Pedals',
                                  onPressed: onToggleTouchPedals,
                                  icon: Icon(
                                    Icons.gamepad_rounded,
                                    size: 18,
                                    color: showTouchPedals
                                        ? accent
                                        : Colors.white54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 5),
                Text(
                  hintText,
                  textAlign: TextAlign.center,
                  style: context.bodySmall.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CockpitMetric extends StatelessWidget {
  const _CockpitMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.bodySmall.copyWith(
            fontSize: 10,
            letterSpacing: 1.3,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        Text(
          value,
          style: context.bodyMedium.copyWith(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _HoldPedalButton extends StatefulWidget {
  const _HoldPedalButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.width,
    required this.height,
    required this.onHoldChanged,
    this.filled = false,
    this.activeGlow = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double width;
  final double height;
  final ValueChanged<bool> onHoldChanged;
  final bool filled;
  final bool activeGlow;

  @override
  State<_HoldPedalButton> createState() => _HoldPedalButtonState();
}

class _HoldPedalButtonState extends State<_HoldPedalButton> {
  bool _pressed = false;

  void _setPressed(bool val) {
    if (_pressed == val) return;
    setState(() => _pressed = val);
    widget.onHoldChanged(val);
  }

  @override
  Widget build(BuildContext context) {
    final active = _pressed || widget.activeGlow;
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: active
                ? widget.color.withValues(alpha: 0.36)
                : (widget.filled
                    ? widget.color.withValues(alpha: 0.18)
                    : const Color(0xFF070C1B).withValues(alpha: 0.78)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color.withValues(alpha: active ? 0.95 : 0.50),
              width: active ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 22),
              Text(
                widget.label,
                style: context.bodySmall.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
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

class _TachometerArcPainter extends CustomPainter {
  final double ratio;
  final Color accent;
  final Color secondary;

  _TachometerArcPainter({
    required this.ratio,
    required this.accent,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const startAngle = math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      startAngle,
      sweepTotal,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.5,
    );

    final activeColor = ratio > 0.85 ? const Color(0xFFEF4444) : accent;
    canvas.drawArc(
      rect,
      startAngle,
      sweepTotal * ratio.clamp(0.03, 1.0),
      false,
      Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.8,
    );
  }

  @override
  bool shouldRepaint(covariant _TachometerArcPainter oldDelegate) =>
      oldDelegate.ratio != ratio || oldDelegate.accent != accent;
}
