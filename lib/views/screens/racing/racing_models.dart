import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spnk/domain/entity/contact_details.dart';
import 'package:spnk/domain/entity/experience_details.dart';
import 'package:spnk/domain/entity/project_details.dart';
import 'package:spnk/domain/entity/skill_details.dart';
import 'package:spnk/utils/screen_type.dart';
import 'package:spnk/utils/string_constants.dart';
import 'package:spnk/views/bloc/theme_switch/theme_state.dart';

/// The 3 switchable racing camera & gameplay modes.
enum RacingGameMode {
  horizon3d(
    shortLabel: '3D HORIZON',
    title: 'Pseudo-3D Horizon Racer',
    subtitle: 'OutRun Chase-Cam Highway',
    icon: Icons.landscape_rounded,
  ),
  openPaddock(
    shortLabel: 'OPEN WORLD',
    title: 'Open-World Top-Down Paddock',
    subtitle: 'Free-Roam & Drift Zones',
    icon: Icons.explore_rounded,
  ),
  verticalHighway(
    shortLabel: 'HIGHWAY',
    title: 'Vertical Highway Lane Racer',
    subtitle: 'Top-Down Traffic & Pit-Bays',
    icon: Icons.add_road_rounded,
  );

  const RacingGameMode({
    required this.shortLabel,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String shortLabel;
  final String title;
  final String subtitle;
  final IconData icon;
}

/// The 3 switchable racing visual themes.
enum RacingVisualTheme {
  neonCyber(
    shortLabel: 'NEON CYBER',
    title: 'Neon Cyber Telemetry',
    icon: Icons.bolt_rounded,
  ),
  f1PitWall(
    shortLabel: 'F1 PIT-WALL',
    title: 'Formula 1 Pro Pit-Wall',
    icon: Icons.sports_score_rounded,
  ),
  retroSynthwave(
    shortLabel: 'SYNTHWAVE',
    title: 'Retro Synthwave Arcade',
    icon: Icons.wb_twilight_rounded,
  );

  const RacingVisualTheme({
    required this.shortLabel,
    required this.title,
    required this.icon,
  });

  final String shortLabel;
  final String title;
  final IconData icon;
}

/// Unified color & surface palette resolved from [ThemeState] + [RacingVisualTheme].
class RacingThemePalette {
  final RacingVisualTheme visualTheme;
  final bool isDark;
  final Color accent;
  final Color secondary;
  final Color tertiary;
  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;
  final Color groundNear;
  final Color groundFar;
  final Color gridLine;
  final Color asphaltA;
  final Color asphaltB;
  final Color kerbA;
  final Color kerbB;
  final Color carBody;
  final Color carStripe;
  final Color hudSurface;

  const RacingThemePalette({
    required this.visualTheme,
    required this.isDark,
    required this.accent,
    required this.secondary,
    required this.tertiary,
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.groundNear,
    required this.groundFar,
    required this.gridLine,
    required this.asphaltA,
    required this.asphaltB,
    required this.kerbA,
    required this.kerbB,
    required this.carBody,
    required this.carStripe,
    required this.hudSurface,
  });

  factory RacingThemePalette.resolve(
    ThemeState themeState,
    RacingVisualTheme visualTheme,
  ) {
    final isDark = themeState.isDark;

    switch (visualTheme) {
      case RacingVisualTheme.neonCyber:
        final accent = themeState.accentColor;
        final secondary = themeState.secondaryAccent;
        return RacingThemePalette(
          visualTheme: visualTheme,
          isDark: isDark,
          accent: accent,
          secondary: secondary,
          tertiary: const Color(0xFF00F0FF),
          skyTop: isDark
              ? const Color(0xFF040611)
              : Color.lerp(const Color(0xFFE0EAFC), accent, 0.08)!,
          skyMid: isDark
              ? Color.lerp(const Color(0xFF0A1026), secondary, 0.16)!
              : Color.lerp(const Color(0xFFCFDEF3), secondary, 0.10)!,
          skyBottom: isDark
              ? Color.lerp(const Color(0xFF111936), accent, 0.28)!
              : Color.lerp(const Color(0xFFF8FAFC), accent, 0.18)!,
          groundFar: isDark
              ? Color.lerp(const Color(0xFF050814), accent, 0.05)!
              : Color.lerp(const Color(0xFFDCE4F0), accent, 0.06)!,
          groundNear:
              isDark ? const Color(0xFF03050C) : const Color(0xFFCBD5E1),
          gridLine: accent.withValues(alpha: isDark ? 0.12 : 0.10),
          asphaltA: isDark ? const Color(0xFF0F1629) : const Color(0xFF334155),
          asphaltB: isDark ? const Color(0xFF131C33) : const Color(0xFF3E4C63),
          kerbA: accent,
          kerbB: isDark ? const Color(0xFFF8FAFC) : Colors.white,
          carBody: switch (themeState.portfolioStyle) {
            PortfolioStyle.glass => const Color(0xFF141E36),
            PortfolioStyle.bento => const Color(0xFF16181D),
            PortfolioStyle.cyber => const Color(0xFF0A1228),
          },
          carStripe: accent,
          hudSurface: const Color(0xFF060A18),
        );

      case RacingVisualTheme.f1PitWall:
        // Authentic Formula 1 Pit-Wall & FIA Circuit Livery
        const fiaRed = Color(0xFFE10600);
        const drsTeal = Color(0xFF00D2BE);
        const sectorPurple = Color(0xFFA855F7);
        return RacingThemePalette(
          visualTheme: visualTheme,
          isDark: isDark,
          accent: fiaRed,
          secondary: drsTeal,
          tertiary: sectorPurple,
          skyTop: isDark ? const Color(0xFF090D16) : const Color(0xFFBAE6FD),
          skyMid: isDark ? const Color(0xFF141C2B) : const Color(0xFFE0F2FE),
          skyBottom: isDark ? const Color(0xFF243044) : const Color(0xFFF8FAFC),
          groundFar: isDark ? const Color(0xFF0D2118) : const Color(0xFF15803D),
          groundNear:
              isDark ? const Color(0xFF091711) : const Color(0xFF166534),
          gridLine: Colors.white.withValues(alpha: isDark ? 0.06 : 0.10),
          asphaltA: isDark ? const Color(0xFF181C24) : const Color(0xFF272C36),
          asphaltB: isDark ? const Color(0xFF1E232D) : const Color(0xFF303744),
          kerbA: fiaRed,
          kerbB: const Color(0xFFF8FAFC),
          carBody: const Color(0xFF161920),
          carStripe: fiaRed,
          hudSurface: const Color(0xFF0B0E14),
        );

      case RacingVisualTheme.retroSynthwave:
        // Classic 1980s OutRun / Synthwave Sunset Arcade
        const neonPink = Color(0xFFFF2A85);
        const synthCyan = Color(0xFF00F5D4);
        const sunsetGold = Color(0xFFFDE047);
        return RacingThemePalette(
          visualTheme: visualTheme,
          isDark: isDark,
          accent: neonPink,
          secondary: synthCyan,
          tertiary: sunsetGold,
          skyTop: isDark ? const Color(0xFF0D0221) : const Color(0xFF2E1065),
          skyMid: isDark ? const Color(0xFF3B0764) : const Color(0xFF701A75),
          skyBottom: isDark ? const Color(0xFFBE185D) : const Color(0xFFF43F5E),
          groundFar: isDark ? const Color(0xFF17052E) : const Color(0xFF2A0A4A),
          groundNear:
              isDark ? const Color(0xFF090117) : const Color(0xFF18042E),
          gridLine: neonPink.withValues(alpha: 0.34),
          asphaltA: const Color(0xFF160B2E),
          asphaltB: const Color(0xFF1F103D),
          kerbA: neonPink,
          kerbB: synthCyan,
          carBody: const Color(0xFF1D1138),
          carStripe: synthCyan,
          hudSurface: const Color(0xFF120524),
        );
    }
  }
}

/// Canonical quick-links for Sivaprasad NK displayed on the HUD & in-world pads.
class DriverQuickLink {
  final String id;
  final String label;
  final String shortCode;
  final IconData icon;
  final Color color;
  final String Function() urlBuilder;
  final bool isResume;

  const DriverQuickLink({
    required this.id,
    required this.label,
    required this.shortCode,
    required this.icon,
    required this.color,
    required this.urlBuilder,
    this.isResume = false,
  });

  String get url => urlBuilder();

  static final List<DriverQuickLink> all = [
    DriverQuickLink(
      id: 'github',
      label: 'GitHub',
      shortCode: 'GH',
      icon: FontAwesomeIcons.github,
      color: const Color(0xFF38BDF8),
      urlBuilder: () => githubLink,
    ),
    DriverQuickLink(
      id: 'linkedin',
      label: 'LinkedIn',
      shortCode: 'IN',
      icon: FontAwesomeIcons.linkedinIn,
      color: const Color(0xFF0A66C2),
      urlBuilder: () => linkedInLink,
    ),
    DriverQuickLink(
      id: 'pubdev',
      label: 'pub.dev',
      shortCode: 'PUB',
      icon: FontAwesomeIcons.dartLang,
      color: const Color(0xFF00B4AB),
      urlBuilder: () => pubDevLink,
    ),
    DriverQuickLink(
      id: 'vscode',
      label: 'VS Code',
      shortCode: 'VSC',
      icon: FontAwesomeIcons.store,
      color: const Color(0xFFA855F7),
      urlBuilder: () => vsCodeThemesLink,
    ),
    DriverQuickLink(
      id: 'whatsapp',
      label: 'WhatsApp',
      shortCode: 'WA',
      icon: FontAwesomeIcons.whatsapp,
      color: const Color(0xFF22C55E),
      urlBuilder: () => whatsappWebLink,
    ),
    DriverQuickLink(
      id: 'instagram',
      label: 'Instagram',
      shortCode: 'IG',
      icon: FontAwesomeIcons.instagram,
      color: const Color(0xFFEC4899),
      urlBuilder: () => instaLink,
    ),
    DriverQuickLink(
      id: 'resume',
      label: 'CV PDF',
      shortCode: 'CV',
      icon: Icons.description_rounded,
      color: const Color(0xFFF59E0B),
      urlBuilder: () => resumeLink,
      isResume: true,
    ),
  ];
}

class RaceSectorMeta {
  final int index;
  final Screen screen;
  final String code;
  final String shortLabel;
  final String title;
  final String subtitle;
  final int startSegment;
  final int endSegment;
  final int checkpointSegment;
  final IconData icon;
  final String questId;
  final Offset paddockCenter;

  const RaceSectorMeta({
    required this.index,
    required this.screen,
    required this.code,
    required this.shortLabel,
    required this.title,
    required this.subtitle,
    required this.startSegment,
    required this.endSegment,
    required this.checkpointSegment,
    required this.icon,
    required this.questId,
    required this.paddockCenter,
  });

  static const List<RaceSectorMeta> sectors = [
    RaceSectorMeta(
      index: 0,
      screen: Screen.home,
      code: 'SEC-01',
      shortLabel: 'GRID',
      title: 'POLE POSITION // SIVAPRASAD NK',
      subtitle: 'Senior Flutter Architect • Starting Grid & Driver Profile',
      startSegment: 0,
      endSegment: 119,
      checkpointSegment: 8,
      icon: Icons.sports_motorsports_rounded,
      questId: 'first_scroll',
      paddockCenter: Offset(-740, -470),
    ),
    RaceSectorMeta(
      index: 1,
      screen: Screen.aboutMe,
      code: 'SEC-02',
      shortLabel: 'BIO',
      title: 'ORIGIN CHICANE // DRIVER BIO',
      subtitle: '3.7+ Yrs Flutter • Clean Architecture • Fitness & Perks',
      startSegment: 120,
      endSegment: 239,
      checkpointSegment: 125,
      icon: Icons.badge_rounded,
      questId: 'lore_reader',
      paddockCenter: Offset(740, -470),
    ),
    RaceSectorMeta(
      index: 2,
      screen: Screen.skills,
      code: 'SEC-03',
      shortLabel: 'SKILLS',
      title: 'DYNO STRAIGHT // TECH ARSENAL',
      subtitle: 'ECU Engine Tuning • Dart, Flutter, Firebase, Web',
      startSegment: 240,
      endSegment: 359,
      checkpointSegment: 245,
      icon: Icons.speed_rounded,
      questId: 'skill_inspector',
      paddockCenter: Offset(1020, 60),
    ),
    RaceSectorMeta(
      index: 3,
      screen: Screen.experience,
      code: 'SEC-04',
      shortLabel: 'CAREER',
      title: 'CHRONO HAIRPINS // PRO SEASONS',
      subtitle: 'Bayasys • Indbytes • Invenics Career Telemetry',
      startSegment: 360,
      endSegment: 479,
      checkpointSegment: 365,
      icon: Icons.flag_rounded,
      questId: 'career_chronicler',
      paddockCenter: Offset(720, 560),
    ),
    RaceSectorMeta(
      index: 4,
      screen: Screen.projects,
      code: 'SEC-05',
      shortLabel: 'PROJECTS',
      title: 'NEON SHOWROOM // CHAMPIONSHIP APPS',
      subtitle:
          'Quiz, Quotes, Portfolio, QR Studio, Arcade & YT Downloader',
      startSegment: 480,
      endSegment: 599,
      checkpointSegment: 485,
      icon: Icons.rocket_launch_rounded,
      questId: 'boss_raider',
      paddockCenter: Offset(-720, 560),
    ),
    RaceSectorMeta(
      index: 5,
      screen: Screen.contactMe,
      code: 'SEC-06',
      shortLabel: 'COMMS',
      title: 'VICTORY PADDOCK // PIT-WALL RADIO',
      subtitle: 'Direct Radio Comms, Social Paddock & CV Trophy',
      startSegment: 600,
      endSegment: 719,
      checkpointSegment: 605,
      icon: Icons.cell_tower_rounded,
      questId: 'loot_collector',
      paddockCenter: Offset(-1020, 60),
    ),
  ];

  static RaceSectorMeta forSegment(int segIndex) {
    final normalized = segIndex % CircuitBuilder.totalSegments;
    for (final s in sectors) {
      if (normalized >= s.startSegment && normalized <= s.endSegment) {
        return s;
      }
    }
    return sectors.first;
  }

  static RaceSectorMeta forScreen(Screen screen) {
    return sectors.firstWhere(
      (s) => s.screen == screen,
      orElse: () => sectors.first,
    );
  }
}

class BillboardSpec {
  final String tag;
  final String title;
  final String subtitle;
  final bool useSecondaryAccent;
  final bool showDriverPhoto;

  const BillboardSpec({
    required this.tag,
    required this.title,
    required this.subtitle,
    this.useSecondaryAccent = false,
    this.showDriverPhoto = false,
  });
}

class RoadSegment {
  final int index;
  final double z;
  final double curve;
  final double y;
  final bool isCheckered;
  final String? gantryCode;
  final String? gantryTitle;
  final String? gantrySubtitle;
  final BillboardSpec? leftBillboard;
  final BillboardSpec? rightBillboard;
  final double? boostLane;
  final String? boostSkillName;
  final bool hasLightPylon;
  final bool isTunnelZone;

  const RoadSegment({
    required this.index,
    required this.z,
    required this.curve,
    required this.y,
    this.isCheckered = false,
    this.gantryCode,
    this.gantryTitle,
    this.gantrySubtitle,
    this.leftBillboard,
    this.rightBillboard,
    this.boostLane,
    this.boostSkillName,
    this.hasLightPylon = false,
    this.isTunnelZone = false,
  });
}

class TrafficCar {
  double z;
  double lane; // -0.68 (left), 0.0 (center), 0.68 (right)
  double speed;
  final int colorVariant;
  final String label;
  bool passedRecently;

  TrafficCar({
    required this.z,
    required this.lane,
    required this.speed,
    required this.colorVariant,
    required this.label,
    this.passedRecently = false,
  });
}

class DataCrystalOrb {
  final double z;
  final double lane;
  final String label;
  bool collected;

  DataCrystalOrb({
    required this.z,
    required this.lane,
    required this.label,
    this.collected = false,
  });
}

/// Open-World Top-Down Paddock interactive models.
class PaddockLinkPortal {
  final DriverQuickLink link;
  final Offset center;
  final double radius;

  const PaddockLinkPortal({
    required this.link,
    required this.center,
    this.radius = 52.0,
  });
}

class PaddockSkidMark {
  final Offset a;
  final Offset b;
  double life; // 0.0 .. 1.0

  PaddockSkidMark({
    required this.a,
    required this.b,
    this.life = 1.0,
  });
}

class PaddockBoostStrip {
  final Offset center;
  final double angle;
  final String label;
  final String? skillName;

  const PaddockBoostStrip({
    required this.center,
    required this.angle,
    required this.label,
    this.skillName,
  });
}

class PaddockOrb {
  final Offset pos;
  final String label;
  bool collected;

  PaddockOrb({
    required this.pos,
    required this.label,
    this.collected = false,
  });
}

class PaddockWorldBuilder {
  static const double halfWidth = 1650.0;
  static const double halfHeight = 1150.0;
  static const double zoneWidth = 370.0;
  static const double zoneHeight = 230.0;

  static List<PaddockLinkPortal> buildLinkPortals() {
    final links = DriverQuickLink.all;
    const ringRadius = 295.0;
    return List<PaddockLinkPortal>.generate(links.length, (i) {
      final angle = (-math.pi / 2) + (i * 2 * math.pi / links.length);
      return PaddockLinkPortal(
        link: links[i],
        center: Offset(
          math.cos(angle) * ringRadius,
          math.sin(angle) * ringRadius,
        ),
      );
    });
  }

  static List<PaddockBoostStrip> buildBoostStrips(List<SkillDetails> skills) {
    final names = skills.isNotEmpty
        ? skills.map((s) => s.title.trim()).toList()
        : const ['Dart', 'Flutter', 'Firebase', 'HTML5', 'CSS3'];

    const spots = [
      (Offset(0, -520), 0.0),
      (Offset(960, -210), math.pi / 2),
      (Offset(960, 330), math.pi / 2),
      (Offset(0, 620), math.pi),
      (Offset(-960, 330), -math.pi / 2),
    ];

    return List<PaddockBoostStrip>.generate(spots.length, (i) {
      final skill = names[i % names.length];
      return PaddockBoostStrip(
        center: spots[i].$1,
        angle: spots[i].$2,
        label: '${skill.toUpperCase()} BOOST',
        skillName: skill,
      );
    });
  }

  static List<PaddockOrb> buildOrbs() {
    const count = 18;
    return List<PaddockOrb>.generate(count, (i) {
      final angle = (i / count) * 2 * math.pi;
      final rx = i.isEven ? 880.0 : 500.0;
      final ry = i.isEven ? 540.0 : 360.0;
      return PaddockOrb(
        pos: Offset(math.cos(angle) * rx, math.sin(angle) * ry),
        label: i.isEven ? '+NITRO' : '+XP',
      );
    });
  }
}

class CircuitBuilder {
  static const int totalSegments = 720;
  static const double segmentLength = 200.0;
  static const double trackLength = totalSegments * segmentLength;
  static const double roadWidth = 2150.0;

  static List<RoadSegment> buildCircuit({
    required List<SkillDetails> skills,
    required List<ExperienceDetails> experiences,
    required List<ProjectDetails> projects,
    required List<ContactDetails> contacts,
  }) {
    final curves = List<double>.filled(totalSegments, 0.0);
    final elevations = List<double>.filled(totalSegments, 0.0);

    void addCurve(int start, int end, double intensity) {
      final len = end - start;
      if (len <= 0) return;
      for (int i = start; i <= end && i < totalSegments; i++) {
        final t = (i - start) / len;
        final bell = math.sin(t * math.pi);
        curves[i] = intensity * bell;
      }
    }

    void addHill(int start, int end, double peakHeight) {
      final len = end - start;
      if (len <= 0) return;
      for (int i = start; i <= end && i < totalSegments; i++) {
        final t = (i - start) / len;
        elevations[i] = peakHeight * (1 - math.cos(t * 2 * math.pi)) * 0.5;
      }
    }

    // Sector 0: Gentle sweeping warm-up curve
    addCurve(32, 95, 1.4);
    addHill(45, 105, 950);

    // Sector 1 (Origin Chicane): Flowing S-Chicane
    addCurve(130, 178, -2.5);
    addCurve(182, 232, 2.6);
    addHill(140, 225, 1450);

    // Sector 2 (Skill Dyno Straight): High-speed power straight + banked turn
    addCurve(295, 352, -1.8);
    addHill(255, 340, -750);

    // Sector 3 (Career Hairpins): Technical mountain hairpins & crests
    addCurve(372, 418, 3.2);
    addCurve(424, 472, -3.1);
    addHill(368, 430, 2100);
    addHill(432, 478, 1200);

    // Sector 4 (Project Showroom): Sweeping Neon Tunnel & DRS straight
    addCurve(515, 575, 1.9);
    addHill(495, 585, 1100);

    // Sector 5 (Victory Paddock): Final Sunset Sweep to Checkered Flag
    addCurve(618, 688, -2.2);
    addHill(615, 695, 850);

    final leftBoards = <int, BillboardSpec>{};
    final rightBoards = <int, BillboardSpec>{};
    final boostLanes = <int, double>{};
    final boostSkills = <int, String>{};

    // --- SECTOR 01: STARTING GRID BILLBOARDS (WITH DRIVER PHOTO & LINKS) ---
    leftBoards[18] = const BillboardSpec(
      tag: 'DRIVER #01 // POLE POSITION',
      title: 'SIVAPRASAD NK',
      subtitle: 'GITHUB • LINKEDIN • PUB.DEV • CV',
      showDriverPhoto: true,
    );
    rightBoards[34] = const BillboardSpec(
      tag: 'CODE & PACKAGES // LIVE',
      title: 'GITHUB & PUB.DEV',
      subtitle: 'GITHUB.COM/SIVAPRASADNK',
      useSecondaryAccent: true,
    );
    leftBoards[52] = const BillboardSpec(
      tag: 'NETWORK & TOOLS // LIVE',
      title: 'LINKEDIN & VSCODE',
      subtitle: 'IN/SIVAPRASADNKOFFICIAL',
    );
    rightBoards[72] = const BillboardSpec(
      tag: 'CO-PILOT // DASH',
      title: 'CLAIM CV TROPHY',
      subtitle: 'SIVAPRASADNK.DEV/RESUME.PDF',
      useSecondaryAccent: true,
    );
    leftBoards[94] = const BillboardSpec(
      tag: 'SPAWN // KERALA',
      title: 'TRIPUNITHURA',
      subtitle: 'SENIOR FLUTTER ARCHITECT',
    );
    boostLanes[30] = 0.0;
    boostLanes[82] = 0.62;

    // --- SECTOR 02: BIO / ORIGIN CHICANE BILLBOARDS ---
    const bioSpecs = [
      BillboardSpec(
        tag: 'PERK 01 // LVL 37',
        title: '3.7+ YRS FLUTTER',
        subtitle: 'HIGH-FPS CROSS-PLATFORM UI',
        showDriverPhoto: true,
      ),
      BillboardSpec(
        tag: 'PERK 02 // S-TIER',
        title: 'CLEAN ARCHITECTURE',
        subtitle: 'BLOC • GET_IT • SOLID',
        useSecondaryAccent: true,
      ),
      BillboardSpec(
        tag: 'PERK 03 // GUILD',
        title: 'OPEN SOURCE DEV',
        subtitle: 'PUB.DEV & VS CODE THEMES',
      ),
      BillboardSpec(
        tag: 'PERK 04 // 99 STA',
        title: 'FITNESS & CATS',
        subtitle: 'DISCIPLINE & FELINTROVERT',
        useSecondaryAccent: true,
      ),
    ];
    for (int i = 0; i < bioSpecs.length; i++) {
      final seg = 140 + i * 22;
      if (i.isEven) {
        leftBoards[seg] = bioSpecs[i];
      } else {
        rightBoards[seg] = bioSpecs[i];
      }
    }
    boostLanes[176] = -0.62;

    // --- SECTOR 03: SKILLS DYNO BILLBOARDS & SKILL BOOST PADS ---
    final effectiveSkills = skills.isNotEmpty ? skills : const <SkillDetails>[];
    if (effectiveSkills.isNotEmpty) {
      for (int i = 0; i < effectiveSkills.length; i++) {
        final s = effectiveSkills[i];
        final name = s.title.trim().toUpperCase();
        final seg = 256 + i * 18;
        if (seg < 355) {
          final spec = BillboardSpec(
            tag: 'DYNO BAY 0${i + 1} // NITRO',
            title: name,
            subtitle: 'DRIVE OVER PAD TO TUNE ECU',
            useSecondaryAccent: i.isOdd,
          );
          if (i.isEven) {
            leftBoards[seg] = spec;
          } else {
            rightBoards[seg] = spec;
          }
          final lane = (i % 3 == 0) ? -0.62 : (i % 3 == 1 ? 0.0 : 0.62);
          boostLanes[seg + 4] = lane;
          boostSkills[seg + 4] = s.title.trim();
        }
      }
    } else {
      leftBoards[262] = const BillboardSpec(
        tag: 'DYNO // CORE',
        title: 'FLUTTER & DART',
        subtitle: 'ECU STAGE 5 READY',
      );
      rightBoards[292] = const BillboardSpec(
        tag: 'DYNO // CLOUD',
        title: 'FIREBASE & WEB',
        subtitle: 'HTML5 • CSS3 • REST API',
        useSecondaryAccent: true,
      );
      boostLanes[272] = 0.0;
      boostLanes[312] = 0.62;
    }

    // --- SECTOR 04: EXPERIENCE / CAREER HAIRPINS ---
    if (experiences.isNotEmpty) {
      for (int i = 0; i < experiences.length; i++) {
        final exp = experiences[i];
        final seg = 380 + i * 30;
        if (seg < 475) {
          final spec = BillboardSpec(
            tag: 'SEASON 0${i + 1} // ${exp.startDate}-${exp.endDate}',
            title: exp.orgName.split(' ').take(2).join(' ').toUpperCase(),
            subtitle: exp.title.toUpperCase(),
            useSecondaryAccent: i.isOdd,
          );
          if (i.isEven) {
            leftBoards[seg] = spec;
          } else {
            rightBoards[seg] = spec;
          }
          if (exp.detailsList.isNotEmpty) {
            final techSpec = BillboardSpec(
              tag: 'STAGE 0${i + 1} ARSENAL',
              title: exp.detailsList.first.toUpperCase(),
              subtitle:
                  exp.detailsList.skip(1).take(2).join(' • ').toUpperCase(),
              useSecondaryAccent: i.isEven,
            );
            if (i.isEven) {
              rightBoards[seg + 12] = techSpec;
            } else {
              leftBoards[seg + 12] = techSpec;
            }
          }
        }
      }
    }
    boostLanes[418] = 0.0;

    // --- SECTOR 05: PROJECTS / NEON SHOWROOM ---
    if (projects.isNotEmpty) {
      for (int i = 0; i < projects.length; i++) {
        final proj = projects[i];
        final seg = 498 + i * 16;
        if (seg < 596) {
          final spec = BillboardSpec(
            tag: 'SHOWROOM 0${i + 1} // S-RANK',
            title: proj.projName.toUpperCase(),
            subtitle: proj.techStackList.join(' • ').toUpperCase(),
            useSecondaryAccent: i.isOdd,
          );
          if (i.isEven) {
            leftBoards[seg] = spec;
          } else {
            rightBoards[seg] = spec;
          }
        }
      }
    }
    boostLanes[508] = -0.62;
    boostLanes[556] = 0.62;

    // --- SECTOR 06: CONTACT / VICTORY PADDOCK ---
    leftBoards[612] = const BillboardSpec(
      tag: 'PADDOCK CLUB // CONNECT',
      title: 'SIVAPRASAD NK',
      subtitle: 'WHATSAPP • INSTAGRAM • LINKEDIN',
      useSecondaryAccent: true,
      showDriverPhoto: true,
    );
    if (contacts.isNotEmpty) {
      for (int i = 0; i < contacts.length; i++) {
        final c = contacts[i];
        final seg = 630 + i * 22;
        if (seg < 702) {
          final cleanDetail =
              c.details.replaceAll('\n', ' ').trim().toUpperCase();
          final clipped = cleanDetail.length > 26
              ? '${cleanDetail.substring(0, 26)}…'
              : cleanDetail;
          final spec = BillboardSpec(
            tag: 'RADIO CH 0${i + 1} // ${c.title.trim().toUpperCase()}',
            title: c.title.trim().toUpperCase(),
            subtitle: clipped,
            useSecondaryAccent: i.isOdd,
          );
          if (i.isEven) {
            rightBoards[seg] = spec;
          } else {
            leftBoards[seg] = spec;
          }
        }
      }
    }
    rightBoards[694] = const BillboardSpec(
      tag: 'FINISH LINE AHEAD',
      title: 'COMPLETE GRAND PRIX LAP',
      subtitle: 'GITHUB • LINKEDIN • PUB.DEV',
      useSecondaryAccent: true,
    );
    boostLanes[676] = 0.0;

    final gantries = <int, RaceSectorMeta>{
      for (final s in RaceSectorMeta.sectors) s.checkpointSegment: s,
    };

    return List<RoadSegment>.generate(totalSegments, (i) {
      final gantry = gantries[i];
      final isFinishCheckered = i <= 3 || i >= totalSegments - 3;
      final isTunnel = i >= 492 && i <= 586;

      return RoadSegment(
        index: i,
        z: i * segmentLength,
        curve: curves[i],
        y: elevations[i],
        isCheckered: isFinishCheckered,
        gantryCode: gantry?.code,
        gantryTitle: gantry?.title,
        gantrySubtitle: gantry?.subtitle,
        leftBillboard: leftBoards[i],
        rightBillboard: rightBoards[i],
        boostLane: boostLanes[i],
        boostSkillName: boostSkills[i],
        hasLightPylon: i % 8 == 0,
        isTunnelZone: isTunnel,
      );
    });
  }

  static List<TrafficCar> buildInitialTraffic() {
    const labels = [
      'DART-VM',
      'WASM-GT',
      'BLOC-RS',
      'IMPEL-X',
      'PUB-PRO',
      'HIVE-V8',
      'CANVAS',
      'SHADER',
      'SKYLINE',
      'AERO-UI',
    ];
    const lanes = [-0.66, 0.0, 0.66];
    return List<TrafficCar>.generate(10, (i) {
      return TrafficCar(
        z: ((i + 1) * (trackLength / 11)) % trackLength,
        lane: lanes[i % lanes.length],
        speed: 95.0 + (i % 4) * 18.0,
        colorVariant: i % 4,
        label: labels[i % labels.length],
      );
    });
  }

  static List<DataCrystalOrb> buildInitialOrbs() {
    const lanes = [-0.62, 0.0, 0.62, 0.0];
    return List<DataCrystalOrb>.generate(24, (i) {
      return DataCrystalOrb(
        z: (3600.0 + i * (trackLength / 24)) % trackLength,
        lane: lanes[i % lanes.length],
        label: i.isEven ? '+NITRO' : '+XP',
      );
    });
  }
}
