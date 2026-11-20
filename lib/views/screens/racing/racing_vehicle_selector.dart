import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/racing/racing_car_painter.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';

/// Opens the interactive Holographic 3D Vehicle Garage allowing the player to
/// inspect and select among 5 distinct vehicle classes.
Future<void> showVehicleSelectorModal({
  required BuildContext context,
  required VehicleType currentVehicle,
  required RacingThemePalette palette,
  required ValueChanged<VehicleType> onSelectVehicle,
}) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (ctx) {
      return _VehicleGarageDialog(
        initialVehicle: currentVehicle,
        palette: palette,
        onDeployVehicle: (v) {
          Navigator.of(ctx).pop();
          onSelectVehicle(v);
        },
      );
    },
  );
}

class _VehicleGarageDialog extends StatefulWidget {
  const _VehicleGarageDialog({
    required this.initialVehicle,
    required this.palette,
    required this.onDeployVehicle,
  });

  final VehicleType initialVehicle;
  final RacingThemePalette palette;
  final ValueChanged<VehicleType> onDeployVehicle;

  @override
  State<_VehicleGarageDialog> createState() => _VehicleGarageDialogState();
}

class _VehicleGarageDialogState extends State<_VehicleGarageDialog>
    with SingleTickerProviderStateMixin {
  late VehicleType _selected;
  late final AnimationController _turntableCtrl;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialVehicle;
    _turntableCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _turntableCtrl.dispose();
    super.dispose();
  }

  String _hitboxTag(VehicleType v) {
    if (v.roadHalfWidth <= 0.12) return 'NARROW HITBOX';
    if (v.roadHalfWidth >= 0.21) return 'HEAVY ARMOR';
    return 'BALANCED HITBOX';
  }

  @override
  Widget build(BuildContext context) {
    final winSize = MediaQuery.sizeOf(context);
    final isCompact = winSize.width < 760;
    final accent = widget.palette.accent;
    final secondary = widget.palette.secondary;
    const holoCyan = Color(0xFF00F0FF);

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 28,
            vertical: isCompact ? 14 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 880,
              maxHeight: winSize.height * 0.88,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF070C1B).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: holoCyan.withValues(alpha: 0.65),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: holoCyan.withValues(alpha: 0.20),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // HEADER
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 14 : 22,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: holoCyan.withValues(alpha: 0.10),
                          border: Border(
                            bottom: BorderSide(
                              color: holoCyan.withValues(alpha: 0.28),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.garage_rounded,
                              color: holoCyan,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '3D VEHICLE GARAGE // SELECT CHASSIS',
                                    style: context.bodySmall.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.6,
                                      color: holoCyan,
                                    ),
                                  ),
                                  Text(
                                    'CUSTOMIZE SPEED, HANDLING & COLLISION HITBOX',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.displaySmall.copyWith(
                                      fontSize: isCompact ? 15 : 19,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close Garage',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // BODY
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isCompact ? 14 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 3D + Top-Down Turntable Preview + Stat Bars
                              _buildPreviewPanel(
                                context,
                                themeState: themeState,
                                holoCyan: holoCyan,
                                accent: accent,
                                secondary: secondary,
                                isCompact: isCompact,
                              ),
                              const SizedBox(height: 16),

                              // 5 Vehicle Selector Cards
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: VehicleType.values.map((v) {
                                  final selected = v == _selected;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selected = v),
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        width: isCompact ? 146 : 156,
                                        padding: const EdgeInsets.all(11),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? holoCyan.withValues(alpha: 0.20)
                                              : Colors.white
                                                  .withValues(alpha: 0.04),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: selected
                                                ? holoCyan
                                                : Colors.white
                                                    .withValues(alpha: 0.14),
                                            width: selected ? 1.6 : 1.0,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Icon(
                                                  v.icon,
                                                  size: 20,
                                                  color: selected
                                                      ? holoCyan
                                                      : secondary,
                                                ),
                                                Text(
                                                  '${v.nitroMaxSpeed.toInt()} KM/H',
                                                  style:
                                                      context.bodySmall.copyWith(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: selected
                                                        ? holoCyan
                                                        : Colors.white60,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              v.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  context.bodyMedium.copyWith(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              v.shortLabel,
                                              style: context.bodySmall.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                                color: accent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              // Deploy Button Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text(
                                      'CANCEL',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () => _deploy(_selected),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: holoCyan,
                                      foregroundColor: const Color(0xFF050E1E),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 11,
                                      ),
                                    ),
                                    icon: Icon(_selected.icon, size: 18),
                                    label: Text(
                                      'DEPLOY ${_selected.name}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
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
        );
      },
    );
  }

  void _deploy(VehicleType v) {
    GamificationController.instance.addXp(
      15,
      reason: 'Deployed Vehicle Chassis: ${v.name}',
      uniqueKey: 'vehicle_${v.name}',
    );
    widget.onDeployVehicle(v);
  }

  Widget _buildPreviewPanel(
    BuildContext context, {
    required ThemeState themeState,
    required Color holoCyan,
    required Color accent,
    required Color secondary,
    required bool isCompact,
  }) {
    final turntable = AnimatedBuilder(
      animation: _turntableCtrl,
      builder: (context, _) {
        final t = _turntableCtrl.value * 2 * math.pi;
        return Container(
          height: isCompact ? 150 : 176,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF040916),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: holoCyan.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              // 3D Rear Chase View Preview
              Expanded(
                flex: 3,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: RacingCarPainter(
                    steer: math.sin(t) * 0.42,
                    speedKmh: 260,
                    isAccelerating: true,
                    isBraking: false,
                    nitroActive: true,
                    collisionFlash: false,
                    timeSeconds: _turntableCtrl.value * 6.0,
                    themeState: themeState,
                    palette: widget.palette,
                    vehicleType: _selected,
                  ),
                ),
              ),
              // Rotating Top-Down Turntable View
              Expanded(
                flex: 2,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _TopDownTurntablePainter(
                    vehicleType: _selected,
                    palette: widget.palette,
                    angleRad: t * 0.45,
                    timeSeconds: _turntableCtrl.value * 6.0,
                    holoCyan: holoCyan,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    final stats = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _selected.name,
                  style: context.displaySmall.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: holoCyan.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: holoCyan.withValues(alpha: 0.65)),
                ),
                child: Text(
                  _hitboxTag(_selected),
                  style: context.bodySmall.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: holoCyan,
                  ),
                ),
              ),
            ],
          ),
          Text(
            _selected.tagline,
            style: context.bodySmall.copyWith(
              fontSize: 12,
              color: secondary,
            ),
          ),
          const SizedBox(height: 10),
          _statBar('TOP SPEED', _selected.speedRating, holoCyan),
          const SizedBox(height: 6),
          _statBar('HANDLING', _selected.handlingRating, const Color(0xFF10B981)),
          const SizedBox(height: 6),
          _statBar('ARMOR / RAM', _selected.armorRating, const Color(0xFFF59E0B)),
          const SizedBox(height: 6),
          _statBar('LANE AGILITY', _selected.agilityRating, accent),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        children: [
          turntable,
          const SizedBox(height: 12),
          stats,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 6, child: turntable),
        const SizedBox(width: 14),
        Expanded(flex: 5, child: stats),
      ],
    );
  }

  Widget _statBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopDownTurntablePainter extends CustomPainter {
  final VehicleType vehicleType;
  final RacingThemePalette palette;
  final double angleRad;
  final double timeSeconds;
  final Color holoCyan;

  _TopDownTurntablePainter({
    required this.vehicleType,
    required this.palette,
    required this.angleRad,
    required this.timeSeconds,
    required this.holoCyan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final ringR = math.min(size.width, size.height) * 0.40;

    canvas.drawCircle(
      center,
      ringR,
      Paint()
        ..color = holoCyan.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringR + 6),
      angleRad,
      math.pi * 0.7,
      false,
      Paint()
        ..color = holoCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    TopDownRaceCarRenderer.paint(
      canvas: canvas,
      position: center,
      headingRadians: angleRad,
      width: vehicleType.topDownWidth * 1.12,
      length: vehicleType.topDownLength * 1.12,
      steer: 0.15,
      isAccelerating: true,
      isBraking: false,
      nitroActive: true,
      timeSeconds: timeSeconds,
      palette: palette,
      badge: '01',
      vehicleType: vehicleType,
      showHeadlights: false,
    );
  }

  @override
  bool shouldRepaint(covariant _TopDownTurntablePainter oldDelegate) => true;
}
