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
      reason: 'Opened Guild Comms: ${contactDetails.title.trim()}!',
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

              return PortfolioStyledCard(
                width: double.infinity,
                cyberHeader:
                    '~/comms/transceiver_${activeChannel.type.toLowerCase()}.channel',
                padding: EdgeInsets.all(isDesktop ? 36 : 20),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildRadarVisualizer(
                              context,
                              channels,
                              activeIdx,
                              accent,
                              secondary,
                              themeState,
                            ),
                          ),
                          const SizedBox(width: 36),
                          Expanded(
                            flex: 7,
                            child: _buildTransceiverConsole(
                              context,
                              channels,
                              activeChannel,
                              activeIdx,
                              accent,
                              secondary,
                              themeState,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildRadarVisualizer(
                            context,
                            channels,
                            activeIdx,
                            accent,
                            secondary,
                            themeState,
                          ),
                          const SizedBox(height: 24),
                          _buildTransceiverConsole(
                            context,
                            channels,
                            activeChannel,
                            activeIdx,
                            accent,
                            secondary,
                            themeState,
                          ),
                        ],
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRadarVisualizer(
    BuildContext context,
    List<ContactDetails> channels,
    int activeIdx,
    Color accent,
    Color secondary,
    ThemeState themeState,
  ) {
    const radarSize = 250.0;
    const center = Offset(radarSize / 2, radarSize / 2);
    const orbitRadius = 86.0;

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
            // Center Transceiver Core
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.18),
                border: Border.all(
                  color: accent,
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                Icons.radar_rounded,
                color: accent,
                size: 30,
              ),
            ),

            // Orbiting Channel Beacons
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
                left: pos.dx - 24,
                top: pos.dy - 24,
                width: 48,
                height: 48,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedChannelIndex = index;
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? accent
                            : context.scaffoldColor.withValues(
                                alpha: themeState.isDark ? 0.90 : 0.95,
                              ),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : accent.withValues(alpha: 0.45),
                          width: isSelected ? 2.2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(
                              alpha: isSelected ? 0.45 : 0.12,
                            ),
                            blurRadius: isSelected ? 16 : 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        beaconIcon,
                        size: 20,
                        color: isSelected
                            ? (themeState.isDark
                                ? const Color(0xFF090D16)
                                : Colors.white)
                            : accent,
                      ),
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

  Widget _buildTransceiverConsole(
    BuildContext context,
    List<ContactDetails> channels,
    ContactDetails activeChannel,
    int activeIdx,
    Color accent,
    Color secondary,
    ThemeState themeState,
  ) {
    final radius =
        themeState.portfolioStyle == PortfolioStyle.cyber ? 8.0 : 999.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SUBSPACE TRANSCEIVER // SIGNAL LOCKED',
                  style: context.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+25 XP PER TRANSMISSION',
                style: context.bodySmall.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Interactive Frequency Channel Selector Orbs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(channels.length, (index) {
              final ch = channels[index];
              final isSelected = index == activeIdx;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedChannelIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 16 : 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent
                          : context.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? accent
                            : accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'CH 0${index + 1} • ${ch.title.trim()}',
                      style: context.bodySmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? (themeState.isDark
                                ? const Color(0xFF090D16)
                                : Colors.white)
                            : context.primaryColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),

        // Active Channel Hologram Readout
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(activeChannel.type),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: themeState.isDark ? 0.14 : 0.08),
                  secondary.withValues(alpha: themeState.isDark ? 0.08 : 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent.withValues(
                          alpha: themeState.isDark ? 0.18 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: AnimateIcon(
                        key: ValueKey(
                          '${activeChannel.iconName}_${accent.toARGB32()}',
                        ),
                        onTap: () => _transmitChannel(activeChannel),
                        iconType: context.isLargeDevice
                            ? IconType.animatedOnHover
                            : IconType.continueAnimation,
                        height: 30,
                        width: 30,
                        color: accent,
                        animateIcon: activeChannel.iconName.iconFromString,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeChannel.title.trim(),
                            style: context.displaySmall.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeChannel.details.trim(),
                            style: context.bodyMedium.copyWith(
                              fontSize: 17,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => _transmitChannel(activeChannel),
                  borderRadius: BorderRadius.circular(radius),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Transmit on ${activeChannel.title.trim()} Channel',
                          style: context.bodySmall.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: themeState.isDark
                                ? const Color(0xFF090D16)
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 17,
                          color: themeState.isDark
                              ? const Color(0xFF090D16)
                              : Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
      ..strokeWidth = 1.1;

    canvas.drawCircle(center, maxR * 0.92, ringPaint);
    canvas.drawCircle(center, maxR * 0.68, ringPaint);
    canvas.drawCircle(center, maxR * 0.38, ringPaint);

    // Crosshairs
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

    // Rotating radar sweep cone
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
