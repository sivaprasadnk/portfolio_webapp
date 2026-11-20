import 'dart:math' as math;
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
import 'package:spnk/views/screens/arcade/arcade_screen.dart';
import 'package:spnk/views/screens/qrcode/qr_code_screen.dart';
import 'package:spnk/views/screens/racing/racing_models.dart';
import 'package:spnk/views/screens/yt_downloader/yt_downloader_screen.dart';
import 'package:spnk/views/widgets/gamification_engine.dart';
import 'package:url_launcher/url_launcher.dart';

/// Futuristic floating 3D Hologram projection popped when arriving at a
/// portfolio destination (Home, About Me, Skills, Experience, Projects, Contact Us).
class DestinationHologramOverlay extends StatefulWidget {
  const DestinationHologramOverlay({
    super.key,
    required this.sector,
    required this.palette,
    required this.timeSeconds,
    required this.isPinned,
    required this.autoHideRemainingRatio,
    required this.onPin,
    required this.onDismiss,
    required this.onOpenFullDossier,
    required this.onPrevSector,
    required this.onNextSector,
  });

  final RaceSectorMeta sector;
  final RacingThemePalette palette;
  final double timeSeconds;
  final bool isPinned;
  final double autoHideRemainingRatio;
  final VoidCallback onPin;
  final VoidCallback onDismiss;
  final VoidCallback onOpenFullDossier;
  final VoidCallback onPrevSector;
  final VoidCallback onNextSector;

  @override
  State<DestinationHologramOverlay> createState() =>
      _DestinationHologramOverlayState();
}

class _DestinationHologramOverlayState extends State<DestinationHologramOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  int _selectedTraitIdx = 0;

  static const _traits = [
    (
      '3.7+ Yrs Flutter',
      'LVL 37',
      'Architected cross-platform Android, iOS & Web apps at 60fps with custom Canvas engines & BLoC.',
    ),
    (
      'Clean Arch & BLoC',
      'S-TIER',
      'Modular domain-driven layering with GetIt DI, immutable states, and thorough automated tests.',
    ),
    (
      'Open Source',
      'GUILD',
      'Published reusable Flutter packages on pub.dev and VS Code themes used by developers worldwide.',
    ),
    (
      'Fitness & Cats',
      '99 STA',
      'Strength training discipline paired with quiet creative deep-work alongside feline companions.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant DestinationHologramOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sector.index != widget.sector.index) {
      _entryCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.palette.accent;
    final secondary = widget.palette.secondary;
    const holoCyan = Color(0xFF00F0FF);
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 760;

    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_entryCtrl.value);
        final glitchDx = t < 0.72
            ? math.sin(t * 48.0) * (1.0 - t) * 7.0
            : 0.0;
        final floatDy = math.sin(widget.timeSeconds * 2.4) * 3.5;
        final rotX = -0.035 + math.sin(widget.timeSeconds * 1.4) * 0.012;
        final rotY = math.cos(widget.timeSeconds * 1.1) * 0.018;

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(rotX)
          ..rotateY(rotY);

        return Listener(
          onPointerDown: (_) => widget.onPin(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isCompact ? size.width - 20 : 620,
                maxHeight: isCompact
                    ? (size.height - 290).clamp(240.0, 440.0)
                    : (size.height - 270).clamp(290.0, 470.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Transform.translate(
                      offset: Offset(glitchDx, floatDy),
                      child: Transform(
                        alignment: Alignment.bottomCenter,
                        transform: transform,
                        child: Transform.scale(
                          scaleY: (0.12 + 0.88 * t).clamp(0.12, 1.0),
                          scaleX: (0.86 + 0.14 * t).clamp(0.86, 1.0),
                          alignment: Alignment.bottomCenter,
                          child: Opacity(
                            opacity: t.clamp(0.0, 1.0),
                            child: _buildHologramFrame(
                              context,
                              holoCyan: holoCyan,
                              accent: accent,
                              secondary: secondary,
                              isCompact: isCompact,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: isCompact ? 34 : 46,
                    width: isCompact ? 260 : 380,
                    child: CustomPaint(
                      painter: _HologramBeamPainter(
                        timeSeconds: widget.timeSeconds,
                        holoColor: holoCyan,
                        accent: accent,
                        entryProgress: t,
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

  Widget _buildHologramFrame(
    BuildContext context, {
    required Color holoCyan,
    required Color accent,
    required Color secondary,
    required bool isCompact,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF041428).withValues(alpha: 0.78),
                const Color(0xFF061E38).withValues(alpha: 0.68),
                Color.lerp(const Color(0xFF041428), accent, 0.16)!
                    .withValues(alpha: 0.76),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: holoCyan.withValues(alpha: 0.72),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: holoCyan.withValues(alpha: 0.24),
                blurRadius: 24,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: accent.withValues(alpha: 0.16),
                blurRadius: 32,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _HoloScanlinePainter(
                      timeSeconds: widget.timeSeconds,
                      holoColor: holoCyan,
                      accent: accent,
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, holoCyan, accent, secondary, isCompact),
                  if (!widget.isPinned)
                    LinearProgressIndicator(
                      value: widget.autoHideRemainingRatio.clamp(0.0, 1.0),
                      minHeight: 2.5,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(holoCyan),
                    )
                  else
                    Container(
                      height: 1.5,
                      color: holoCyan.withValues(alpha: 0.35),
                    ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isCompact ? 12 : 16),
                      child: _buildDestinationContent(
                        context,
                        holoCyan,
                        accent,
                        secondary,
                        isCompact,
                      ),
                    ),
                  ),
                  _buildFooter(context, holoCyan, accent, secondary, isCompact),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color holoCyan,
    Color accent,
    Color secondary,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: 9,
      ),
      color: holoCyan.withValues(alpha: 0.10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: holoCyan.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: holoCyan.withValues(alpha: 0.6)),
            ),
            child: Icon(widget.sector.icon, size: 16, color: holoCyan),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HOLOGRAM PROJECTION // ${widget.sector.destinationLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodySmall.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: holoCyan,
                  ),
                ),
                Text(
                  widget.sector.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.displaySmall.copyWith(
                    fontSize: isCompact ? 14.5 : 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Previous Destination',
            visualDensity: VisualDensity.compact,
            onPressed: widget.onPrevSector,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
          IconButton(
            tooltip: 'Next Destination',
            visualDensity: VisualDensity.compact,
            onPressed: widget.onNextSector,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
          IconButton(
            tooltip: 'Dismiss Hologram (Esc)',
            visualDensity: VisualDensity.compact,
            onPressed: widget.onDismiss,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    Color holoCyan,
    Color accent,
    Color secondary,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        border: Border(
          top: BorderSide(color: holoCyan.withValues(alpha: 0.25)),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            widget.isPinned
                ? 'PINNED HOLOGRAM • TAP TO INTERACT'
                : 'LIVE ARRIVAL HOLOGRAM • TAP TO PIN',
            style: context.bodySmall.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: holoCyan.withValues(alpha: 0.85),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onOpenFullDossier,
                style: OutlinedButton.styleFrom(
                  foregroundColor: holoCyan,
                  side: BorderSide(color: holoCyan.withValues(alpha: 0.7)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.open_in_full_rounded, size: 14),
                label: const Text(
                  'FULL DOSSIER',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: widget.onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: holoCyan,
                  foregroundColor: const Color(0xFF04101E),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 15),
                label: const Text(
                  'RESUME DRIVE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationContent(
    BuildContext context,
    Color holoCyan,
    Color accent,
    Color secondary,
    bool isCompact,
  ) {
    switch (widget.sector.screen) {
      case Screen.home:
        return _buildHomeHolo(context, holoCyan, accent, secondary);
      case Screen.aboutMe:
        return _buildAboutMeHolo(context, holoCyan, accent, secondary);
      case Screen.skills:
        return _buildSkillsHolo(context, holoCyan, accent);
      case Screen.experience:
        return _buildExperienceHolo(context, holoCyan, accent, secondary);
      case Screen.projects:
        return _buildProjectsHolo(context, holoCyan, accent, secondary);
      case Screen.contactMe:
        return _buildContactHolo(context, holoCyan, accent, secondary);
    }
  }

  Widget _buildHomeHolo(
    BuildContext context,
    Color holoCyan,
    Color accent,
    Color secondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: holoCyan, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: holoCyan.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/propic3.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sivaprasad NK',
                    style: context.displaySmall.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Senior Flutter Architect • Tripunithura, Kerala',
                    style: context.bodySmall.copyWith(
                      fontSize: 12.5,
                      color: holoCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '3.7+ yrs crafting high-FPS Flutter apps, Clean Architecture, BLoC & 2D/3D web canvases.',
                    style: context.bodySmall.copyWith(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _holoActionChip(
              label: 'CLAIM CV PDF (+75 XP)',
              icon: Icons.description_rounded,
              color: const Color(0xFFF59E0B),
              onTap: () {
                widget.onPin();
                GamificationController.instance.completeQuest('loot_collector');
                launchUrl(Uri.parse(resumeLink));
              },
            ),
            ...DriverQuickLink.all.take(4).map(
                  (link) => _holoActionChip(
                    label: link.label,
                    icon: link.icon,
                    color: holoCyan,
                    onTap: () {
                      widget.onPin();
                      launchUrl(Uri.parse(link.url));
                    },
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutMeHolo(
    BuildContext context,
    Color holoCyan,
    Color accent,
    Color secondary,
  ) {
    return BlocBuilder<AboutMeBloc, AboutMeState>(
      builder: (context, state) {
        final bio = state.content.trim().isEmpty
            ? 'Passionate Flutter developer with 3.7+ years of experience crafting seamless cross-platform applications.'
            : state.content.trim();
        final trait = _traits[_selectedTraitIdx];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bio,
              style: context.bodySmall.copyWith(
                fontSize: 13,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_traits.length, (i) {
                final item = _traits[i];
                final selected = i == _selectedTraitIdx;
                return GestureDetector(
                  onTap: () {
                    widget.onPin();
                    setState(() => _selectedTraitIdx = i);
                    GamificationController.instance.completeQuest('lore_reader');
                    GamificationController.instance.addXp(
                      15,
                      reason: 'Inspected Holo Trait: ${item.$1}',
                      uniqueKey: 'holo_trait_${item.$1}',
                    );
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? holoCyan.withValues(alpha: 0.24)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? holoCyan
                              : holoCyan.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        '${item.$1} • ${item.$2}',
                        style: context.bodySmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: holoCyan.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: holoCyan.withValues(alpha: 0.40)),
              ),
              child: Text(
                '${trait.$1.toUpperCase()} (${trait.$2}): ${trait.$3}',
                style: context.bodySmall.copyWith(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkillsHolo(
    BuildContext context,
    Color holoCyan,
    Color accent,
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
              children: skills.map((skill) {
                final name = skill.title.trim();
                final boost =
                    GamificationController.instance.getSkillBoost(name);
                final isMax = boost >= 5;
                final ratio = (0.75 + boost * 0.05).clamp(0.0, 1.0);
                final barColor = isMax ? const Color(0xFFF59E0B) : holoCyan;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: barColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: SvgPicture.asset(
                          'assets/svg/${skill.iconName}.svg',
                          colorFilter: ColorFilter.mode(
                            barColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  name.toUpperCase(),
                                  style: context.bodySmall.copyWith(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  isMax
                                      ? 'STAGE 5 MAX'
                                      : 'STAGE ${boost + 1} (${(ratio * 100).toInt()}%)',
                                  style: context.bodySmall.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: barColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.12),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(barColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          widget.onPin();
                          GamificationController.instance.boostSkill(name);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: barColor,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          isMax ? 'MAX' : 'TUNE +15XP',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildExperienceHolo(
    BuildContext context,
    Color holoCyan,
    Color accent,
    Color secondary,
  ) {
    return BlocBuilder<ExpDetailsBloc, ExpDetailsState>(
      builder: (context, state) {
        final stages = state.expList;
        if (stages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: stages.map((exp) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: holoCyan.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exp.orgName,
                          style: context.bodyMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${exp.startDate} - ${exp.endDate}',
                        style: context.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: holoCyan,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    exp.title,
                    style: context.bodySmall.copyWith(
                      fontSize: 12.5,
                      color: secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: exp.detailsList
                        .map(
                          (d) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: holoCyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              d,
                              style: context.bodySmall.copyWith(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildProjectsHolo(
    BuildContext context,
    Color holoCyan,
    Color accent,
    Color secondary,
  ) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        final projects = state.projectList;
        if (projects.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: projects.map((proj) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: holoCyan.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          proj.projName,
                          style: context.bodyMedium.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ...proj.techStackList.take(3).map(
                            (tech) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: holoCyan.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tech,
                                  style: context.bodySmall.copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: holoCyan,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                  if (proj.descList.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      proj.descList.first,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall.copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.80),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (proj.webUrl.isNotEmpty)
                        _holoActionChip(
                          label: 'LAUNCH WEB',
                          icon: Icons.rocket_launch_rounded,
                          color: holoCyan,
                          onTap: () => _launchProject(context, proj, proj.webUrl),
                        ),
                      if (proj.playStoreUrl.isNotEmpty)
                        _holoActionChip(
                          label: 'PLAY STORE',
                          icon: Icons.android_rounded,
                          color: const Color(0xFF10B981),
                          onTap: () => _launchProject(
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
          }).toList(),
        );
      },
    );
  }

  Widget _buildContactHolo(
    BuildContext context,
    Color holoCyan,
    Color accent,
    Color secondary,
  ) {
    return BlocBuilder<ContactDetailsBloc, ContactDetailsState>(
      builder: (context, state) {
        final channels = state.contactDetailList;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...channels.map((ch) {
              IconData icon = Icons.mail_rounded;
              if (ch.type == 'location') icon = Icons.location_on_rounded;
              if (ch.type == 'mobile') icon = Icons.phone_android_rounded;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: holoCyan.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: holoCyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ch.title.trim().toUpperCase(),
                            style: context.bodySmall.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: holoCyan,
                            ),
                          ),
                          Text(
                            ch.details.trim(),
                            style: context.bodySmall.copyWith(
                              fontSize: 12.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _holoActionChip(
                      label: 'TRANSMIT',
                      icon: Icons.send_rounded,
                      color: holoCyan,
                      onTap: () => _openContact(ch),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _holoActionChip(
                  label: 'GitHub',
                  icon: FontAwesomeIcons.github,
                  color: const Color(0xFF38BDF8),
                  onTap: () {
                    widget.onPin();
                    launchUrl(Uri.parse(githubLink));
                  },
                ),
                _holoActionChip(
                  label: 'LinkedIn',
                  icon: FontAwesomeIcons.linkedin,
                  color: const Color(0xFF0A66C2),
                  onTap: () {
                    widget.onPin();
                    launchUrl(Uri.parse(linkedInLink));
                  },
                ),
                _holoActionChip(
                  label: 'WhatsApp',
                  icon: FontAwesomeIcons.whatsapp,
                  color: const Color(0xFF22C55E),
                  onTap: () {
                    widget.onPin();
                    launchUrl(Uri.parse(whatsappWebLink));
                  },
                ),
                _holoActionChip(
                  label: 'Resume PDF',
                  icon: Icons.description_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    widget.onPin();
                    launchUrl(Uri.parse(resumeLink));
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _holoActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color.withValues(alpha: 0.72)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12.5, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchProject(
    BuildContext context,
    ProjectDetails project,
    String url,
  ) async {
    if (url.isEmpty) return;
    widget.onPin();
    GamificationController.instance.completeQuest('boss_raider');
    GamificationController.instance.addXp(
      20,
      reason: 'Launched Hologram Project: ${project.projName}',
      uniqueKey: 'proj_${project.projName}',
    );
    if (url.endsWith('/qrcode')) {
      Navigator.pushNamed(context, QrCodeScreen.routeName);
      return;
    }
    if (url.endsWith('/arcade')) {
      Navigator.pushNamed(context, ArcadeScreen.routeName);
      return;
    }
    if (url.endsWith('/yt-downloader') || url.endsWith('/youtube-downloader')) {
      Navigator.pushNamed(context, YtDownloaderScreen.routeName);
      return;
    }
    await launchUrl(Uri.parse(url));
  }

  Future<void> _openContact(ContactDetails ch) async {
    widget.onPin();
    GamificationController.instance.completeQuest('loot_collector');
    GamificationController.instance.addXp(
      25,
      reason: 'Transmitted Contact Hologram: ${ch.title.trim()}',
      uniqueKey: 'contact_${ch.type}',
    );
    var link = ch.link;
    if (ch.type == 'mobile') {
      final parts = ch.link.split(',');
      link = (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)
          ? parts.last.trim()
          : parts.first.trim();
    }
    await launchUrl(Uri.parse(link));
  }
}

class _HologramBeamPainter extends CustomPainter {
  final double timeSeconds;
  final Color holoColor;
  final Color accent;
  final double entryProgress;

  _HologramBeamPainter({
    required this.timeSeconds,
    required this.holoColor,
    required this.accent,
    required this.entryProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final emitterY = size.height - 6;

    // Projection trapezoidal beam cone from emitter ring up into floating panel
    final beamPath = Path()
      ..moveTo(cx - 26, emitterY)
      ..lineTo(size.width * 0.06, 0)
      ..lineTo(size.width * 0.94, 0)
      ..lineTo(cx + 26, emitterY)
      ..close();

    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            holoColor.withValues(alpha: 0.42 * entryProgress),
            holoColor.withValues(alpha: 0.08 * entryProgress),
          ],
        ).createShader(Offset.zero & size),
    );

    // Laser emitter rays
    final rayPaint = Paint()
      ..color = holoColor.withValues(alpha: 0.45 * entryProgress)
      ..strokeWidth = 1.2;
    for (final frac in const [0.16, 0.35, 0.5, 0.65, 0.84]) {
      canvas.drawLine(
        Offset(cx + (frac - 0.5) * 32, emitterY),
        Offset(size.width * frac, 0),
        rayPaint,
      );
    }

    // Emitter floor ring
    final pulse = 1.0 + 0.15 * math.sin(timeSeconds * 5.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, emitterY),
        width: 72 * pulse,
        height: 11,
      ),
      Paint()
        ..color = holoColor.withValues(alpha: 0.85 * entryProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, emitterY),
        width: 42,
        height: 6,
      ),
      Paint()..color = accent.withValues(alpha: 0.65 * entryProgress),
    );
  }

  @override
  bool shouldRepaint(covariant _HologramBeamPainter oldDelegate) => true;
}

class _HoloScanlinePainter extends CustomPainter {
  final double timeSeconds;
  final Color holoColor;
  final Color accent;

  _HoloScanlinePainter({
    required this.timeSeconds,
    required this.holoColor,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scanPaint = Paint()
      ..color = holoColor.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    final offset = (timeSeconds * 18.0) % 6.0;
    for (double y = offset; y < size.height; y += 6.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
    }

    // Glowing moving scan bar
    final barY = ((timeSeconds * 55.0) % (size.height + 40)) - 20;
    canvas.drawRect(
      Rect.fromLTWH(0, barY, size.width, 14),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            holoColor.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, barY, size.width, 14)),
    );

    // Corner HUD targeting brackets
    const len = 14.0;
    final bracketPaint = Paint()
      ..color = holoColor.withValues(alpha: 0.90)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(4, len + 4)
        ..lineTo(4, 4)
        ..lineTo(len + 4, 4),
      bracketPaint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len - 4, 4)
        ..lineTo(size.width - 4, 4)
        ..lineTo(size.width - 4, len + 4),
      bracketPaint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(4, size.height - len - 4)
        ..lineTo(4, size.height - 4)
        ..lineTo(len + 4, size.height - 4),
      bracketPaint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len - 4, size.height - 4)
        ..lineTo(size.width - 4, size.height - 4)
        ..lineTo(size.width - 4, size.height - len - 4),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HoloScanlinePainter oldDelegate) => true;
}
