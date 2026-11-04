import 'dart:math' as math;

import 'package:animated_icon/animated_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spnk/domain/entity/contact_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/extensions/string_extensions.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_bloc.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_state.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/contact_me/loading_contact_container.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDetailsListView extends StatefulWidget {
  const ContactDetailsListView({super.key});

  @override
  State<ContactDetailsListView> createState() => _ContactDetailsListViewState();
}

class _ContactDetailsListViewState extends State<ContactDetailsListView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarController;
  int _selectedChannelIndex = 0;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _transmitChannel(ContactDetails contactDetails) async {
    GamificationController.instance.addXp(
      25,
      reason: 'Transmitted Signal on ${contactDetails.title.trim()}!',
      uniqueKey: 'contact_${contactDetails.type}',
    );
    var link = '';
    if (contactDetails.type == 'mobile') {
      final linkList = contactDetails.link.split(',');
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        link = linkList.last.trim();
      } else {
        link = linkList.first.trim();
      }
    } else {
      link = contactDetails.link;
    }
    await launchUrl(Uri.parse(link));
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPad =
        context.isMobileDevice ? 16.0 : context.screenWidth * 0.08;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final accent = themeState.accentColor;
          final secondary = themeState.secondaryAccent;

          return BlocBuilder<ContactDetailsBloc, ContactDetailsState>(
            builder: (context, state) {
              if (state.isLoading || state.contactDetailList.isEmpty) {
                return const Center(child: LoadingContactContainer());
              }

              final channels = state.contactDetailList;
              final activeIdx =
                  _selectedChannelIndex.clamp(0, channels.length - 1);
              final activeChannel = channels[activeIdx];
              final isDesktop = context.isLargeDevice;

              return isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildOpenAirRadarVisualizer(
                            context,
                            channels,
                            activeIdx,
                            accent,
                            secondary,
                            themeState,
                          ),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          flex: 7,
                          child: _buildOpenAirTransceiver(
                            context,
                            channels,
                            activeChannel,
                            activeIdx,
                            accent,
                            secondary,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildOpenAirRadarVisualizer(
                          context,
                          channels,
                          activeIdx,
                          accent,
                          secondary,
                          themeState,
                        ),
                        const SizedBox(height: 32),
                        _buildOpenAirTransceiver(
                          context,
                          channels,
                          activeChannel,
                          activeIdx,
                          accent,
                          secondary,
                        ),
                      ],
                    );
            },
          );
        },
      ),
    );
  }

  Widget _buildOpenAirRadarVisualizer(
    BuildContext context,
    List<ContactDetails> channels,
    int activeIdx,
    Color accent,
    Color secondary,
    ThemeState themeState,
  ) {
    const radarSize = 250.0;
    const center = Offset(radarSize / 2, radarSize / 2);
    const orbitRadius = 88.0;

    return Center(
      child: SizedBox(
        width: radarSize,
        height: radarSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _radarController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CommsRadarPainter(
                      sweepAngle: _radarController.value * 2 * math.pi,
                      accent: accent,
                      secondary: secondary,
                      isDark: themeState.isDark,
                    ),
                  );
                },
              ),
            ),
            Icon(
              Icons.radar_rounded,
              color: accent,
              size: 32,
            ),

            // Open-Air Orbiting Signal Stars (Zero Box Containers)
            ...List.generate(channels.length, (index) {
              final item = channels[index];
              final isSelected = index == activeIdx;
              final angle =
                  (-math.pi / 2) + (2 * math.pi * index / channels.length);
              final pos = Offset(
                center.dx + orbitRadius * math.cos(angle),
                center.dy + orbitRadius * math.sin(angle),
              );

              IconData beaconIcon = Icons.alternate_email_rounded;
              if (item.type == 'location') {
                beaconIcon = Icons.location_on_rounded;
              } else if (item.type == 'mobile') {
                beaconIcon = Icons.phone_android_rounded;
              } else {
                beaconIcon = Icons.mail_rounded;
              }

              return Positioned(
                left: pos.dx - 32,
                top: pos.dy - 26,
                width: 64,
                height: 52,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedChannelIndex = index;
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          beaconIcon,
                          size: isSelected ? 24 : 18,
                          color: isSelected
                              ? accent
                              : context.primaryColor.withValues(alpha: 0.55),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'CH 0${index + 1}',
                          style: context.bodySmall.copyWith(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? accent
                                : context.primaryColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenAirTransceiver(
    BuildContext context,
    List<ContactDetails> channels,
    ContactDetails activeChannel,
    int activeIdx,
    Color accent,
    Color secondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUBSPACE FREQUENCY ARRAY // +25 XP PER TRANSMISSION',
          style: context.bodySmall.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(height: 16),

        // Open-Air Frequency Beacons (Zero Box Containers)
        Wrap(
          spacing: 24,
          runSpacing: 10,
          children: List.generate(channels.length, (index) {
            final ch = channels[index];
            final isSelected = index == activeIdx;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _selectedChannelIndex = index;
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FREQ 0${index + 1} // ${ch.title.trim().toUpperCase()}',
                      style: context.bodySmall.copyWith(
                        fontSize: 13,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? accent
                            : context.primaryColor.withValues(alpha: 0.58),
                        shadows: isSelected
                            ? [
                                Shadow(
                                  color: accent.withValues(alpha: 0.8),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 2,
                      width: isSelected ? 48 : 0,
                      color: accent,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 28),

        // Open-Air Signal Readout (Zero Box Containers)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Column(
            key: ValueKey(activeChannel.type),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimateIcon(
                    key: ValueKey(
                      '${activeChannel.iconName}_${accent.toARGB32()}',
                    ),
                    onTap: () => _transmitChannel(activeChannel),
                    iconType: context.isLargeDevice
                        ? IconType.animatedOnHover
                        : IconType.continueAnimation,
                    height: 36,
                    width: 36,
                    color: accent,
                    animateIcon: activeChannel.iconName.iconFromString,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeChannel.title.trim().toUpperCase(),
                          style: context.bodySmall.copyWith(
                            fontSize: 12,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeChannel.details.trim(),
                          style: context.displaySmall.copyWith(
                            fontSize: context.isLargeDevice ? 26 : 20,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OpenAirActionTrigger(
                label: 'Transmit on ${activeChannel.title.trim()} (+25 XP)',
                icon: Icons.arrow_outward_rounded,
                color: accent,
                isPrimary: true,
                onTap: () => _transmitChannel(activeChannel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommsRadarPainter extends CustomPainter {
  final double sweepAngle;
  final Color accent;
  final Color secondary;
  final bool isDark;

  _CommsRadarPainter({
    required this.sweepAngle,
    required this.accent,
    required this.secondary,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    final ringPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.22 : 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, maxR * 0.92, ringPaint);
    canvas.drawCircle(center, maxR * 0.68, ringPaint);
    canvas.drawCircle(center, maxR * 0.36, ringPaint);

    final axisPaint = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(center.dx, 10),
      Offset(center.dx, size.height - 10),
      axisPaint,
    );
    canvas.drawLine(
      Offset(10, center.dy),
      Offset(size.width - 10, center.dy),
      axisPaint,
    );

    final sweepRect = Rect.fromCircle(center: center, radius: maxR * 0.92);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          accent.withValues(alpha: 0.0),
          accent.withValues(alpha: isDark ? 0.28 : 0.18),
        ],
        transform: GradientRotation(sweepAngle),
      ).createShader(sweepRect);

    canvas.drawArc(
      sweepRect,
      sweepAngle,
      math.pi / 2,
      true,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CommsRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle || oldDelegate.accent != accent;
  }
}
