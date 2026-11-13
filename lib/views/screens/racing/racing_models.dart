import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spnk/domain/entity/contact_details.dart';
import 'package:spnk/domain/entity/experience_details.dart';
import 'package:spnk/domain/entity/project_details.dart';
import 'package:spnk/domain/entity/skill_details.dart';
import 'package:spnk/utils/screen_type.dart';

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
    ),
    RaceSectorMeta(
      index: 4,
      screen: Screen.projects,
      code: 'SEC-05',
      shortLabel: 'PROJECTS',
      title: 'NEON SHOWROOM // CHAMPIONSHIP APPS',
      subtitle: 'Quiz, Quotes, Portfolio, QR Studio & SPNK Arcade Hub',
      startSegment: 480,
      endSegment: 599,
      checkpointSegment: 485,
      icon: Icons.rocket_launch_rounded,
      questId: 'boss_raider',
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

  const BillboardSpec({
    required this.tag,
    required this.title,
    required this.subtitle,
    this.useSecondaryAccent = false,
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
        // Smooth ease-in-out bell curve for road curvature
        final bell = math.sin(t * math.pi);
        curves[i] = intensity * bell;
      }
    }

    void addHill(int start, int end, double peakHeight) {
      final len = end - start;
      if (len <= 0) return;
      for (int i = start; i <= end && i < totalSegments; i++) {
        final t = (i - start) / len;
        // Smooth cosine hill returning cleanly to 0
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

    // Prepare billboards by segment index
    final leftBoards = <int, BillboardSpec>{};
    final rightBoards = <int, BillboardSpec>{};
    final boostLanes = <int, double>{};
    final boostSkills = <int, String>{};

    // --- SECTOR 01: STARTING GRID BILLBOARDS ---
    leftBoards[22] = const BillboardSpec(
      tag: 'DRIVER_01 // POLE',
      title: 'SIVAPRASAD NK',
      subtitle: 'SENIOR FLUTTER ARCHITECT',
    );
    rightBoards[38] = const BillboardSpec(
      tag: 'ENGINE // 98%',
      title: 'FLUTTER & DART',
      subtitle: 'ANDROID • IOS • WEB • WASM',
      useSecondaryAccent: true,
    );
    leftBoards[56] = const BillboardSpec(
      tag: 'ARCHITECTURE // 95%',
      title: 'CLEAN ARCH & BLOC',
      subtitle: 'DOMAIN-DRIVEN TELEMETRY',
    );
    rightBoards[76] = const BillboardSpec(
      tag: 'CO-PILOT // DASH',
      title: 'CLAIM CV TROPHY',
      subtitle: 'PRESS [E] FOR PIT-STOP',
      useSecondaryAccent: true,
    );
    leftBoards[96] = const BillboardSpec(
      tag: 'SPAWN // KERALA',
      title: 'TRIPUNITHURA',
      subtitle: 'ERNAKULAM, INDIA',
    );
    boostLanes[30] = 0.0;
    boostLanes[82] = 0.62;

    // --- SECTOR 02: BIO / ORIGIN CHICANE BILLBOARDS ---
    const bioSpecs = [
      BillboardSpec(
        tag: 'PERK 01 // LVL 37',
        title: '3.7+ YRS FLUTTER',
        subtitle: 'HIGH-FPS CROSS-PLATFORM UI',
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
        final seg = 498 + i * 19;
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
    if (contacts.isNotEmpty) {
      for (int i = 0; i < contacts.length; i++) {
        final c = contacts[i];
        final seg = 622 + i * 24;
        if (seg < 705) {
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
            leftBoards[seg] = spec;
          } else {
            rightBoards[seg] = spec;
          }
        }
      }
    }
    rightBoards[690] = const BillboardSpec(
      tag: 'FINISH LINE AHEAD',
      title: 'COMPLETE GRAND PRIX LAP',
      subtitle: 'GITHUB • LINKEDIN • PUB.DEV',
      useSecondaryAccent: true,
    );
    boostLanes[676] = 0.0;

    // Map checkpoint gantries from RaceSectorMeta
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
