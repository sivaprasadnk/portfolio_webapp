import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spnk/domain/entity/contact_details.dart';
import 'package:spnk/domain/entity/project_details.dart';
import 'package:spnk/utils/extensions/context_extension.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:spnk/views/bloc/about_me/about_me_bloc.dart';
import 'package:spnk/views/bloc/about_me/about_me_state.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_bloc.dart';
import 'package:spnk/views/bloc/contact_details/contact_details_state.dart';
import 'package:spnk/views/bloc/experience/exp_details_bloc.dart';
import 'package:spnk/views/bloc/experience/exp_details_state.dart';
import 'package:spnk/views/bloc/project/project_bloc.dart';
import 'package:spnk/views/bloc/project/project_state.dart';
import 'package:spnk/views/bloc/skills/skills_bloc.dart';
import 'package:spnk/views/bloc/skills/skills_state.dart';
import 'package:spnk/views/bloc/theme_switch/theme_bloc.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';
import 'package:spnk/views/screens/arcade/arcade_screen.dart';
import 'package:spnk/views/screens/qrcode/qr_code_screen.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:spnk/views/widgets/portfolio_style_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Compact heads-up telemetry card projected on the upper-left windshield
/// while driving through each portfolio sector on the 3D circuit.
class SectorWindshieldHud extends StatelessWidget {
  const SectorWindshieldHud({
    super.key,
    required this.sector,
    required this.onOpenPitStop,
    required this.onWarpNextSector,
    required this.compact,
  });

  final RaceSectorMeta sector;
  final VoidCallback onOpenPitStop;
  final VoidCallback onWarpNextSector;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;
        final secondary = themeState.secondaryAccent;

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: Container(
                key: ValueKey(sector.code),
                constraints: BoxConstraints(
                  maxWidth: compact ? 290 : 380,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: compact ? 10 : 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF070C1A).withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.50),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(sector.icon, size: 15, color: accent),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '${sector.code} // ${sector.shortLabel} ZONE',
                            overflow: TextOverflow.ellipsis,
                            style: context.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: accent,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onWarpNextSector,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'NEXT',
                                  style: context.bodySmall.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: secondary,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 15,
                                  color: secondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      sector.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.displaySmall.copyWith(
                        fontSize: compact ? 15.5 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 3),
                      _buildLiveSectorLine(context, sector.screen),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MiniHudActionChip(
                          label: compact ? 'PIT-STOP' : 'ENTER PIT-STOP [E]',
                          icon: Icons.garage_rounded,
                          color: accent,
                          filled: true,
                          onTap: onOpenPitStop,
                        ),
                        if (sector.screen == Screen.home ||
                            sector.screen == Screen.contactMe)
                          _MiniHudActionChip(
                            label: 'CV PDF',
                            icon: Icons.emoji_events_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: () async {
                              GamificationController.instance
                                  .completeQuest('loot_collector');
                              await launchUrl(Uri.parse(resumeLink));
                            },
                          ),
                        if (sector.screen == Screen.projects)
                          _MiniHudActionChip(
                            label: 'ARCADE',
                            icon: Icons.sports_esports_rounded,
                            color: secondary,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                ArcadeScreen.routeName,
                              );
                            },
                          ),
                      ],
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

  Widget _buildLiveSectorLine(BuildContext context, Screen screen) {
    final textStyle = context.bodySmall.copyWith(
      fontSize: 12.5,
      color: Colors.white.withValues(alpha: 0.78),
    );

    switch (screen) {
      case Screen.home:
        return Text(
          'Flutter Architect (3.7+ Yrs) • Tripunithura, Kerala • 98% Dart',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        );
      case Screen.aboutMe:
        return Text(
          'Clean Arch & BLoC • Pub.dev Author • Fitness & Felintrovert',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        );
      case Screen.skills:
        return BlocBuilder<SkillDetailsBloc, SkillsState>(
          builder: (context, s) {
            final names = s.skillDetails
                .map((e) => e.title.trim())
                .where((e) => e.isNotEmpty)
                .join(' • ');
            return Text(
              names.isEmpty
                  ? 'Dart • Flutter • Firebase • HTML5 • CSS3'
                  : names,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            );
          },
        );
      case Screen.experience:
        return BlocBuilder<ExpDetailsBloc, ExpDetailsState>(
          builder: (context, s) {
            final orgs =
                s.expList.map((e) => e.orgName.split(' ').first).join(' → ');
            return Text(
              orgs.isEmpty
                  ? 'Bayasys → Indbytes → Invenics (2019–Present)'
                  : '$orgs • ${s.expList.length} Pro Seasons',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            );
          },
        );
      case Screen.projects:
        return BlocBuilder<ProjectBloc, ProjectState>(
          builder: (context, s) {
            return Text(
              s.projectList.isEmpty
                  ? 'Quiz • Quotes • Portfolio • QR Studio • Arcade'
                  : '${s.projectList.length} Deployed Apps — Inspect Showroom',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            );
          },
        );
      case Screen.contactMe:
        return Text(
          'sivaprasadnk.official@gmail.com • +91 8086028340',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        );
    }
  }
}

class _MiniHudActionChip extends StatelessWidget {
  const _MiniHudActionChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: filled
                ? color.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: color.withValues(alpha: filled ? 0.85 : 0.45),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: context.bodySmall.copyWith(
                  fontSize: 11,
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

/// Full Pit-Wall Telemetry Dossier Dialog allowing instant inspection of all
/// 6 portfolio sectors, ECU skill tuning, project launches, and CV/contact links.
Future<void> showPitStopDossierModal({
  required BuildContext context,
  required Screen initialScreen,
  required ValueChanged<Screen> onWarpToSector,
}) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.80),
    builder: (ctx) {
      return _PitStopDossierDialog(
        initialScreen: initialScreen,
        onWarpToSector: (target) {
          Navigator.of(ctx).pop();
          onWarpToSector(target);
        },
      );
    },
  );
}

class _PitStopDossierDialog extends StatefulWidget {
  const _PitStopDossierDialog({
    required this.initialScreen,
    required this.onWarpToSector,
  });

  final Screen initialScreen;
  final ValueChanged<Screen> onWarpToSector;

  @override
  State<_PitStopDossierDialog> createState() => _PitStopDossierDialogState();
}

class _PitStopDossierDialogState extends State<_PitStopDossierDialog> {
  late Screen _activeTab;
  int _selectedPerkIdx = 0;

  static const _perks = [
    (
      Icons.bolt_rounded,
      '3.7+ Years',
      'Cross-Platform Flutter',
      'LVL 37',
      'Engineered production-grade Android, iOS, and Web applications with 60fps custom canvas rendering and adaptive spatial layouts.',
    ),
    (
      Icons.layers_rounded,
      'Architecture',
      'Clean Architecture & BLoC',
      'S-TIER',
      'Modular domain-driven codebases using BLoC, GetIt dependency injection, reactive streams, and testable state machines.',
    ),
    (
      Icons.public_rounded,
      'Open Source',
      'Pub.dev & VS Code Themes',
      'GUILD',
      'Published reusable Flutter packages on pub.dev and crafted developer tooling and themes for the global community.',
    ),
    (
      Icons.fitness_center_rounded,
      'Lifestyle',
      'Fitness & Felintrovert',
      '99 STA',
      'Fueled by discipline, strength training, and creative problem-solving alongside feline companions.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialScreen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _unlockSectorQuest(_activeTab);
      }
    });
  }

  void _unlockSectorQuest(Screen screen) {
    final sector = RaceSectorMeta.forScreen(screen);
    GamificationController.instance.completeQuest(sector.questId);
  }

  @override
  Widget build(BuildContext context) {
    final winSize = MediaQuery.sizeOf(context);
    final isCompact = winSize.width < 760;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final accent = themeState.accentColor;
        final secondary = themeState.secondaryAccent;
        final sectorMeta = RaceSectorMeta.forScreen(_activeTab);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 28,
            vertical: isCompact ? 14 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 980,
              maxHeight: winSize.height * 0.88,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B18).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.55),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. PIT-WALL TELEMETRY HEADER
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 16 : 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          border: Border(
                            bottom: BorderSide(
                              color: accent.withValues(alpha: 0.28),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sports_motorsports_rounded,
                              color: accent,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PIT-WALL TELEMETRY // ${sectorMeta.code}',
                                    style: context.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.8,
                                      color: accent,
                                    ),
                                  ),
                                  Text(
                                    sectorMeta.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.displaySmall.copyWith(
                                      fontSize: isCompact ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  widget.onWarpToSector(_activeTab),
                              style: TextButton.styleFrom(
                                foregroundColor: secondary,
                              ),
                              icon: const Icon(Icons.bolt_rounded, size: 18),
                              label: Text(
                                isCompact ? 'DRIVE' : 'DRIVE THIS SECTOR',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Return to Track (Esc)',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. 6-SECTOR PIT-STOP NAVIGATION TABS
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 22,
                          vertical: 10,
                        ),
                        child: Row(
                          children: RaceSectorMeta.sectors.map((s) {
                            final selected = s.screen == _activeTab;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _activeTab = s.screen);
                                  _unlockSectorQuest(s.screen);
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? accent.withValues(alpha: 0.22)
                                          : Colors.white
                                              .withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selected
                                            ? accent
                                            : Colors.white
                                                .withValues(alpha: 0.14),
                                        width: selected ? 1.4 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          s.icon,
                                          size: 16,
                                          color: selected
                                              ? accent
                                              : Colors.white
                                                  .withValues(alpha: 0.7),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          '0${s.index + 1} • ${s.shortLabel}',
                                          style: context.bodySmall.copyWith(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                            color: selected
                                                ? Colors.white
                                                : Colors.white
                                                    .withValues(alpha: 0.72),
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
                      ),

                      const Divider(height: 1, color: Color(0x24FFFFFF)),

                      // 3. ACTIVE SECTOR TELEMETRY CONTENT
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isCompact ? 16 : 24),
                          child: _buildActiveSectorBody(
                            context,
                            accent,
                            secondary,
                            isCompact,
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

  Widget _buildActiveSectorBody(
    BuildContext context,
    Color accent,
    Color secondary,
    bool isCompact,
  ) {
    switch (_activeTab) {
      case Screen.home:
        return _buildPolePositionTab(context, accent, secondary, isCompact);
      case Screen.aboutMe:
        return _buildOriginBioTab(context, accent, secondary, isCompact);
      case Screen.skills:
        return _buildSkillsDynoTab(context, accent, secondary, isCompact);
      case Screen.experience:
        return _buildCareerSeasonsTab(context, accent, secondary, isCompact);
      case Screen.projects:
        return _buildProjectShowroomTab(context, accent, secondary, isCompact);
      case Screen.contactMe:
        return _buildPaddockCommsTab(context, accent, secondary, isCompact);
    }
  }

  // ===========================================================================
  // TAB 01: POLE POSITION (DRIVER PROFILE, STATS, CV & SOCIAL PADDOCK)
  // ===========================================================================
  Widget _buildPolePositionTab(
    BuildContext context,
    Color accent,
    Color secondary,
    bool isCompact,
  ) {
    final profileCard = Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: isCompact ? 140 : 176,
              height: isCompact ? 140 : 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/picWithBlob.png',
                fit: BoxFit.cover,
              ),
            ),
            GestureDetector(
              onTap: () {
                GamificationController.instance.addXp(
                  20,
                  reason: 'Fist-bumped Co-Pilot Dash in Pit Lane! 🐦',
                  uniqueKey: 'dash_mascot_pet',
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: 'Tap Co-Pilot Dash (+20 XP)',
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1528),
                      shape: BoxShape.circle,
                      border: Border.all(color: secondary, width: 1.5),
                    ),
                    child: Image.asset(
                      'assets/images/dash/dash1.png',
                      height: 36,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'CAR #01 // SPNK-GT',
          style: context.bodySmall.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.6,
            color: secondary,
          ),
        ),
      ],
    );

    final driverInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DRIVER #01 // SENIOR FLUTTER ARCHITECT',
          style: context.bodySmall.copyWith(
            fontSize: 12,
            letterSpacing: 1.8,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sivaprasad NK',
          style: context.displayMedium.copyWith(
            fontSize: isCompact ? 34 : 46,
            color: Colors.white,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Cross-Platform Flutter Developer & Fitness Enthusiast based in Tripunithura, Kerala, India. Crafting high-framerate mobile & web experiences with Clean Architecture, BLoC, and custom 2D/3D canvas engines.',
          style: context.bodyMedium.copyWith(
            fontSize: 16.5,
            height: 1.5,
            color: Colors.white.withValues(alpha: 0.84),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _TelemetrySpecTile(
              label: 'FLUTTER & DART',
              value: '98%',
              sub: 'TWIN-TURBO ENGINE',
              color: accent,
            ),
            _TelemetrySpecTile(
              label: 'CLEAN ARCH & BLOC',
              value: '95%',
              sub: 'CHASSIS RIGIDITY',
              color: secondary,
            ),
            const _TelemetrySpecTile(
              label: 'FITNESS STAMINA',
              value: '99%',
              sub: 'ENDURANCE RATING',
              color: Color(0xFF10B981),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            OpenAirActionTrigger(
              label: 'Claim CV Trophy (+75 XP)',
              icon: Icons.emoji_events_rounded,
              color: accent,
              isPrimary: true,
              onTap: () async {
                GamificationController.instance.completeQuest('loot_collector');
                await launchUrl(Uri.parse(resumeLink));
              },
            ),
            OpenAirActionTrigger(
              label: 'QR Code Studio',
              icon: Icons.qr_code_2_rounded,
              color: secondary,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, QrCodeScreen.routeName);
              },
            ),
            OpenAirActionTrigger(
              label: 'Arcade Mini-Games',
              icon: Icons.sports_esports_rounded,
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, ArcadeScreen.routeName);
              },
            ),
          ],
        ),
        const SizedBox(height: 22),
        _SocialPaddockBar(accent: accent),
      ],
    );

    if (isCompact) {
      return Column(
        children: [
          profileCard,
          const SizedBox(height: 20),
          driverInfo,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        profileCard,
        const SizedBox(width: 32),
        Expanded(child: driverInfo),
      ],
    );
  }

  // ===========================================================================
  // TAB 02: ORIGIN BIO & CHASSIS PERKS
  // ===========================================================================
  Widget _buildOriginBioTab(
    BuildContext context,
    Color accent,
    Color secondary,
    bool isCompact,
  ) {
    return BlocBuilder<AboutMeBloc, AboutMeState>(
      builder: (context, state) {
        final bio = state.content.trim().isEmpty
            ? 'Passionate Flutter developer with 3.7+ years of experience crafting seamless, cross-platform applications that delight users and solve real-world problems.'
            : state.content.trim();
        final activePerk = _perks[_selectedPerkIdx];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DRIVER DOSSIER // ORIGIN: TRIPUNITHURA, KERALA, INDIA',
                    style: context.bodySmall.copyWith(
                      fontSize: 11.5,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bio,
                    style: context.bodyMedium.copyWith(
                      fontSize: 16.5,
                      height: 1.65,
                      color: Colors.white.withValues(alpha: 0.90),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'CHASSIS TUNING PERKS // TAP TO INSPECT (+15 XP)',
              style: context.bodySmall.copyWith(
                fontSize: 12,
                letterSpacing: 1.6,
                fontWeight: FontWeight.bold,
                color: secondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_perks.length, (i) {
                final p = _perks[i];
                final isSelected = i == _selectedPerkIdx;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPerkIdx = i);
                    GamificationController.instance
                        .completeQuest('lore_reader');
                    GamificationController.instance.addXp(
                      15,
                      reason: 'Inspected Driver Perk: ${p.$2} (${p.$4})',
                      uniqueKey: 'attr_${p.$2}',
                    );
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: isCompact ? double.infinity : 210,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : Colors.white.withValues(alpha: 0.14),
                          width: isSelected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(p.$1, color: accent, size: 20),
                              Text(
                                p.$4,
                                style: context.bodySmall.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.$2,
                            style: context.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            p.$3,
                            style: context.bodySmall.copyWith(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: secondary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: secondary.withValues(alpha: 0.35)),
              ),
              child: Text(
                '${activePerk.$2.toUpperCase()} (${activePerk.$4}): ${activePerk.$5}',
                style: context.bodyMedium.copyWith(
                  fontSize: 15.5,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // TAB 03: SKILLS ECU DYNO BAY
  // ===========================================================================
  Widget _buildSkillsDynoTab(
    BuildContext context,
    Color accent,
    Color secondary,
    bool isCompact,
  ) {
    return BlocBuilder<SkillDetailsBloc, SkillsState>(
      builder: (context, state) {
        final skills = state.skillDetails;
        if (skills.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListenableBuilder(
          listenable: GamificationController.instance,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ECU DYNO BENCH // CLICK TUNE TO OVERCLOCK HORSEPOWER (+15 XP)',
                  style: context.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.6,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 16),
                ...skills.map((skill) {
                  final name = skill.title.trim();
                  final boost =
                      GamificationController.instance.getSkillBoost(name);
                  final isMax = boost >= 5;
                  final ratio = (0.75 + boost * 0.05).clamp(0.0, 1.0);
                  final barColor = isMax ? const Color(0xFFF59E0B) : accent;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: barColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: SvgPicture.asset(
                            'assets/svg/${skill.iconName}.svg',
                            colorFilter: ColorFilter.mode(
                              barColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      name.toUpperCase(),
                                      overflow: TextOverflow.ellipsis,
                                      style: context.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      isMax
                                          ? 'STAGE 5 MAX • 100%'
                                          : 'STAGE ${boost + 1} • ${(ratio * 100).toInt()}%',
                                      overflow: TextOverflow.ellipsis,
                                      style: context.bodySmall.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: barColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 8,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.10),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(barColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton.icon(
                          onPressed: () =>
                              GamificationController.instance.boostSkill(name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                barColor.withValues(alpha: isMax ? 0.25 : 0.9),
                            foregroundColor:
                                isMax ? barColor : const Color(0xFF070B18),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          icon: Icon(
                            isMax ? Icons.verified_rounded : Icons.bolt_rounded,
                            size: 16,
                          ),
                          label: Text(
                            isMax ? 'MAXED' : 'TUNE ECU',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // TAB 04: CAREER SEASONS (EXPERIENCE TIMELINE)
  // ===========================================================================
  Widget _buildCareerSeasonsTab(
    BuildContext context,
    Color accent,
    Color secondary,
    bool isCompact,
  ) {
    return BlocBuilder<ExpDetailsBloc, ExpDetailsState>(
      builder: (context, state) {
        final stages = state.expList;
        if (stages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONSTRUCTOR CHAMPIONSHIP HISTORY // TAP ANY SEASON FOR +15 XP',
              style: context.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.6,
                color: accent,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(stages.length, (i) {
              final exp = stages[i];
              final seasonNum = exp.order + 1;
              return GestureDetector(
                onTap: () {
                  GamificationController.instance
                      .completeQuest('career_chronicler');
                  GamificationController.instance.addXp(
                    15,
                    reason:
                        'Logged Telemetry for Season 0$seasonNum: ${exp.orgName}',
                    uniqueKey: 'exp_stage_$seasonNum',
                  );
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (i.isEven ? accent : secondary)
                            .withValues(alpha: 0.42),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SEASON 0$seasonNum',
                                style: context.bodySmall.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.4,
                                  color: accent,
                                ),
                              ),
                            ),
                            Text(
                              '${exp.startDate} — ${exp.endDate}',
                              style: context.bodySmall.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          exp.title,
                          style: context.displaySmall.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CONSTRUCTOR TEAM: ${exp.orgName.toUpperCase()}',
                          style: context.bodySmall.copyWith(
                            fontSize: 13,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.76),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: exp.detailsList.map((d) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Text(
                                d,
                                style: context.bodySmall.copyWith(
                                  fontSize: 12.5,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // TAB 05: PROJECT SHOWROOM
  // ===========================================================================
  Widget _buildProjectShowroomTab(
    BuildContext context,
    Color accent,
    Color secondary,
    bool isCompact,
  ) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        final projects = state.projectList;
        if (projects.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHAMPIONSHIP GARAGE // LAUNCH DEPLOYED BUILDS (+20 XP)',
              style: context.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.6,
                color: accent,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(projects.length, (i) {
              final proj = projects[i];
              final hasWeb = proj.webUrl.isNotEmpty;
              final hasPlay = proj.playStoreUrl.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        (i.isEven ? accent : secondary).withValues(alpha: 0.38),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'BAY 0${i + 1}',
                          style: context.bodySmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        ...proj.techStackList.map(
                          (tech) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '#${tech.toUpperCase()}',
                              style: context.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      proj.projName,
                      style: context.displaySmall.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...proj.descList.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Icon(
                                Icons.double_arrow_rounded,
                                size: 14,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d,
                                style: context.bodySmall.copyWith(
                                  fontSize: 14.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        if (hasWeb)
                          OpenAirActionTrigger(
                            label: 'Launch Web App',
                            icon: Icons.rocket_launch_rounded,
                            color: accent,
                            isPrimary: true,
                            onTap: () => _launchProjectUrl(
                              context,
                              proj,
                              proj.webUrl,
                            ),
                          ),
                        if (hasPlay)
                          OpenAirActionTrigger(
                            label: 'Google Play Store',
                            icon: Icons.android_rounded,
                            color: secondary,
                            isPrimary: !hasWeb,
                            onTap: () => _launchProjectUrl(
                              context,
                              proj,
                              proj.playStoreUrl,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _launchProjectUrl(
    BuildContext context,
    ProjectDetails project,
    String url,
  ) async {
    if (url.isEmpty) return;
    GamificationController.instance.completeQuest('boss_raider');
    GamificationController.instance.addXp(
      20,
      reason: 'Test-drove Project: ${project.projName}!',
      uniqueKey: 'proj_${project.projName}',
    );
    if (url.endsWith('/qrcode')) {
      Navigator.of(context).pop();
      Navigator.pushNamed(context, QrCodeScreen.routeName);
      return;
    }
    if (url.endsWith('/arcade')) {
      Navigator.of(context).pop();
      Navigator.pushNamed(context, ArcadeScreen.routeName);
      return;
    }
    await launchUrl(Uri.parse(url));
  }

  // ===========================================================================
  // TAB 06: VICTORY PADDOCK & PIT-WALL RADIO COMMS
  // ===========================================================================
  Widget _buildPaddockCommsTab(
    BuildContext context,
    Color accent,
    Color secondary,
    bool isCompact,
  ) {
    return BlocBuilder<ContactDetailsBloc, ContactDetailsState>(
      builder: (context, state) {
        final channels = state.contactDetailList;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PIT-WALL RADIO ARRAY // DIRECT TRANSMISSION (+25 XP)',
              style: context.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.6,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 16),
            ...channels.map((ch) {
              IconData icon = Icons.mail_rounded;
              if (ch.type == 'location') icon = Icons.location_on_rounded;
              if (ch.type == 'mobile') icon = Icons.phone_android_rounded;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: accent, size: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ch.title.trim().toUpperCase(),
                            style: context.bodySmall.copyWith(
                              fontSize: 11.5,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ch.details.trim(),
                            style: context.bodyMedium.copyWith(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    OpenAirActionTrigger(
                      label: 'Transmit',
                      icon: Icons.arrow_outward_rounded,
                      color: accent,
                      isPrimary: true,
                      onTap: () => _openContactChannel(ch),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            _SocialPaddockBar(accent: accent),
          ],
        );
      },
    );
  }

  Future<void> _openContactChannel(ContactDetails ch) async {
    GamificationController.instance.addXp(
      25,
      reason: 'Radio Transmission sent on ${ch.title.trim()}!',
      uniqueKey: 'contact_${ch.type}',
    );
    var link = ch.link;
    if (ch.type == 'mobile') {
      final parts = ch.link.split(',');
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        link = parts.last.trim();
      } else {
        link = parts.first.trim();
      }
    }
    await launchUrl(Uri.parse(link));
  }
}

class _TelemetrySpecTile extends StatelessWidget {
  const _TelemetrySpecTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.bodySmall.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.3,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          Text(
            value,
            style: context.displaySmall.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            sub,
            style: context.bodySmall.copyWith(
              fontSize: 10,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialPaddockBar extends StatelessWidget {
  const _SocialPaddockBar({required this.accent});

  final Color accent;

  static final List<(String, IconData, String)> _links = [
    ('GitHub', FontAwesomeIcons.github, githubLink),
    ('LinkedIn', FontAwesomeIcons.linkedin, linkedInLink),
    ('Pub.dev', FontAwesomeIcons.dartLang, pubDevLink),
    ('VS Code', FontAwesomeIcons.store, vsCodeThemesLink),
    ('WhatsApp', FontAwesomeIcons.whatsapp, whatsappWebLink),
    ('Instagram', FontAwesomeIcons.instagram, instaLink),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOCIAL PADDOCK // GLOBAL LINKS',
          style: context.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.6,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _links.map((item) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () async {
                  GamificationController.instance
                      .completeQuest('loot_collector');
                  await launchUrl(Uri.parse(item.$3));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$2, size: 15, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        item.$1,
                        style: context.bodySmall.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
