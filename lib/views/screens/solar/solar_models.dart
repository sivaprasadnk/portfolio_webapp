import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spnk/data/constants.dart';
import 'package:spnk/domain/entity/contact_details.dart';
import 'package:spnk/domain/entity/experience_details.dart';
import 'package:spnk/domain/entity/project_details.dart';
import 'package:spnk/domain/entity/skill_details.dart';
import 'package:spnk/utils/string_constants.dart';

/// Current camera focus mode inside the `/v3` 3D Solar System experience.
enum SolarFocusKind {
  overview,
  star,
  planet,
  moon,
}

/// Immutable 3D vector used for orbital positions and camera smoothing.
class Vec3 {
  const Vec3(this.x, this.y, this.z);

  static const Vec3 zero = Vec3(0.0, 0.0, 0.0);

  final double x;
  final double y;
  final double z;

  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);
  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  double distanceTo(Vec3 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  static Vec3 lerp(Vec3 a, Vec3 b, double t) {
    final clamped = t.clamp(0.0, 1.0);
    return Vec3(
      a.x + (b.x - a.x) * clamped,
      a.y + (b.y - a.y) * clamped,
      a.z + (b.z - a.z) * clamped,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vec3 &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'Vec3($x, $y, $z)';
}

/// A portfolio sub-section represented as a Moon orbiting its parent Planet.
class SolarMoonData {
  const SolarMoonData({
    required this.id,
    required this.parentPlanetId,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.descriptionLines,
    required this.tags,
    required this.color,
    required this.orbitRadius,
    required this.orbitSpeed,
    required this.phaseOffset,
    required this.inclination,
    required this.radius,
    this.webUrl,
    this.playStoreUrl,
    this.copyValue,
    this.skillTitle,
  });

  final String id;
  final String parentPlanetId;
  final String title;
  final String subtitle;
  final String badge;
  final List<String> descriptionLines;
  final List<String> tags;
  final Color color;
  final double orbitRadius;
  final double orbitSpeed;
  final double phaseOffset;
  final double inclination;
  final double radius;
  final String? webUrl;
  final String? playStoreUrl;
  final String? copyValue;
  final String? skillTitle;
}

/// A top-level portfolio section represented as a 3D Planet orbiting the Star.
class SolarPlanetData {
  const SolarPlanetData({
    required this.id,
    required this.shortLabel,
    required this.title,
    required this.tagline,
    required this.summary,
    required this.icon,
    required this.color,
    required this.secondaryColor,
    required this.orbitRadius,
    required this.orbitSpeed,
    required this.initialAngle,
    required this.inclination,
    required this.radius,
    required this.hasRing,
    required this.textureStyle,
    required this.moons,
  });

  final String id;
  final String shortLabel;
  final String title;
  final String tagline;
  final String summary;
  final IconData icon;
  final Color color;
  final Color secondaryColor;
  final double orbitRadius;
  final double orbitSpeed;
  final double initialAngle;
  final double inclination;
  final double radius;
  final bool hasRing;
  final String textureStyle;
  final List<SolarMoonData> moons;
}

/// Builds the 5 Solar System planets and their orbiting moons from portfolio BLoCs.
class SolarSystemBuilder {
  static List<SolarPlanetData> build({
    required String aboutBio,
    required List<SkillDetails> skills,
    required List<ExperienceDetails> experiences,
    required List<ProjectDetails> projects,
    required List<ContactDetails> contacts,
  }) {
    final bioText = aboutBio.trim().isNotEmpty
        ? aboutBio.trim()
        : aboutMeDetailsContent.content.trim();
    final effectiveSkills = skills.isNotEmpty ? skills : skillsList;
    final effectiveExps = List<ExperienceDetails>.of(
      experiences.isNotEmpty ? experiences : expDetailsList,
    )..sort((a, b) => b.order.compareTo(a.order));
    final effectiveProjects = projects.isNotEmpty ? projects : projectList;
    final effectiveContacts =
        contacts.isNotEmpty ? contacts : contactDetailsList;

    // 1. ABOUT Planet (Emerald Terran)
    const aboutColor = Color(0xFF10B981);
    const aboutSec = Color(0xFF38BDF8);
    final aboutMoons = [
      const SolarMoonData(
        id: 'about_architect',
        parentPlanetId: 'about',
        title: 'AI & Flutter Architect',
        subtitle: '5 Years Experience',
        badge: '5+ YRS',
        descriptionLines: [
          '5 years building scalable Clean Architecture & BLoC Flutter apps, now actively focused on AI coding.',
          'Led end-to-end delivery for production mobile apps, AI tools, and cross-platform web builds.',
        ],
        tags: ['AI Coding', 'Flutter', 'Dart', 'Clean Arch'],
        color: aboutColor,
        orbitRadius: 3.6,
        orbitSpeed: 0.72,
        phaseOffset: 0.2,
        inclination: 0.14,
        radius: 0.56,
      ),
      const SolarMoonData(
        id: 'about_fitness',
        parentPlanetId: 'about',
        title: 'Endurance Athlete',
        subtitle: 'Gym & Running',
        badge: 'STAMINA',
        descriptionLines: [
          'Endurance athlete dedicated to regular gym training, consistent distance running, and daily discipline.',
        ],
        tags: ['Gym', 'Running', 'Endurance'],
        color: Color(0xFF34D399),
        orbitRadius: 4.5,
        orbitSpeed: 0.54,
        phaseOffset: 1.8,
        inclination: -0.18,
        radius: 0.50,
      ),
      const SolarMoonData(
        id: 'about_ai_focus',
        parentPlanetId: 'about',
        title: 'AI Engineering',
        subtitle: 'Agentic Workflows',
        badge: 'AI CODING',
        descriptionLines: [
          'Actively exploring AI coding, intelligent automation, and modern developer tooling.',
        ],
        tags: ['AI Coding', 'Automation', 'Deep Work'],
        color: Color(0xFFF472B6),
        orbitRadius: 5.4,
        orbitSpeed: 0.42,
        phaseOffset: 3.3,
        inclination: 0.22,
        radius: 0.52,
      ),
      SolarMoonData(
        id: 'about_kerala',
        parentPlanetId: 'about',
        title: 'Ernakulam Base',
        subtitle: 'Home Coordinates',
        badge: 'INDIA',
        descriptionLines: [
          'Based in Tripunithura, Ernakulam, Kerala — building for teams worldwide.',
          bioText,
        ],
        tags: ['Ernakulam', 'Remote Ready', 'IST'],
        color: aboutSec,
        orbitRadius: 6.3,
        orbitSpeed: 0.34,
        phaseOffset: 4.9,
        inclination: -0.12,
        radius: 0.54,
      ),
    ];

    // 2. SKILLS Planet (Cyan Plasma Ringed)
    const skillsColor = Color(0xFF00F0FF);
    const skillsSec = Color(0xFF38BDF8);
    final skillsMoons = effectiveSkills.asMap().entries.map((entry) {
      final idx = entry.key;
      final skill = entry.value;
      final name = skill.title.trim();
      return SolarMoonData(
        id: 'skill_$idx',
        parentPlanetId: 'skills',
        title: name,
        subtitle: 'Technical Orbit Module',
        badge: 'ECU STACK',
        descriptionLines: [
          'Production proficiency in $name across cross-platform architecture, UI polish, and tooling.',
          'Tap Overclock below to tune $name +15 XP.',
        ],
        tags: [name, skill.iconName.toUpperCase()],
        color: idx.isEven ? skillsColor : skillsSec,
        orbitRadius: 3.9 + idx * 0.9,
        orbitSpeed: 0.68 - idx * 0.08,
        phaseOffset: idx * ((math.pi * 2) / math.max(1, effectiveSkills.length)),
        inclination: (idx.isEven ? 1 : -1) * (0.12 + idx * 0.04),
        radius: 0.54,
        skillTitle: name,
      );
    }).toList();

    // 3. EXPERIENCE Planet (Amber Saturnian Ringed)
    const expColor = Color(0xFFF59E0B);
    const expSec = Color(0xFFFBBF24);
    final expMoons = effectiveExps.asMap().entries.map((entry) {
      final idx = entry.key;
      final exp = entry.value;
      return SolarMoonData(
        id: 'exp_$idx',
        parentPlanetId: 'experience',
        title: exp.orgName,
        subtitle: exp.title,
        badge: '${exp.startDate} — ${exp.endDate}',
        descriptionLines: exp.detailsList,
        tags: [exp.title, exp.startDate, exp.endDate],
        color: idx.isEven ? expColor : expSec,
        orbitRadius: 4.4 + idx * 1.15,
        orbitSpeed: 0.55 - idx * 0.1,
        phaseOffset: idx * ((math.pi * 2) / math.max(1, effectiveExps.length)),
        inclination: (idx.isEven ? -1 : 1) * (0.14 + idx * 0.05),
        radius: 0.64,
      );
    }).toList();

    // 4. PROJECTS Planet (Violet/Indigo Nebula World)
    const projColor = Color(0xFFA855F7);
    const projSec = Color(0xFF6366F1);
    final projMoons = effectiveProjects.asMap().entries.map((entry) {
      final idx = entry.key;
      final p = entry.value;
      return SolarMoonData(
        id: 'proj_$idx',
        parentPlanetId: 'projects',
        title: p.projName,
        subtitle: p.techStackList.join(' • '),
        badge: p.webUrl.isNotEmpty ? 'WEB LIVE' : 'PLAY STORE',
        descriptionLines:
            p.descList.map((d) => d.replaceAll('\n', ' ').trim()).toList(),
        tags: p.techStackList,
        color: idx.isEven ? projColor : projSec,
        orbitRadius: 4.2 + idx * 0.92,
        orbitSpeed: 0.62 - idx * 0.06,
        phaseOffset: idx * ((math.pi * 2) / math.max(1, effectiveProjects.length)),
        inclination: (idx.isEven ? 1 : -1) * (0.10 + idx * 0.04),
        radius: 0.58,
        webUrl: p.webUrl.isNotEmpty ? p.webUrl : null,
        playStoreUrl: p.playStoreUrl.isNotEmpty ? p.playStoreUrl : null,
      );
    }).toList();

    // 5. CONTACT Planet (Ruby/Magenta Beacon)
    const contactColor = Color(0xFFF43F5E);
    const contactSec = Color(0xFFF472B6);
    final contactMoons = <SolarMoonData>[
      ...effectiveContacts.asMap().entries.map((entry) {
        final idx = entry.key;
        final c = entry.value;
        final title = c.title.trim();
        final detail = c.details.trim().replaceAll('\n', ' ');
        return SolarMoonData(
          id: 'contact_$idx',
          parentPlanetId: 'contact',
          title: title,
          subtitle: 'Direct Uplink',
          badge: c.type.toUpperCase(),
          descriptionLines: [detail],
          tags: [title, c.type],
          color: idx.isEven ? contactColor : contactSec,
          orbitRadius: 3.8 + idx * 0.95,
          orbitSpeed: 0.64 - idx * 0.08,
          phaseOffset: idx * 1.55,
          inclination: (idx.isEven ? 1 : -1) * 0.16,
          radius: 0.56,
          webUrl: c.link.isNotEmpty ? c.link : null,
          copyValue: (c.type == 'email' || c.type == 'mobile') ? detail : null,
        );
      }),
      SolarMoonData(
        id: 'contact_social_cv',
        parentPlanetId: 'contact',
        title: 'Social & CV',
        subtitle: 'Portfolio Beacon',
        badge: 'RESUME PDF',
        descriptionLines: const [
          'Open Sivaprasad NK resume PDF or jump to GitHub, LinkedIn, Pub.dev & Instagram channels.',
        ],
        tags: const ['GitHub', 'LinkedIn', 'Pub.dev', 'Instagram'],
        color: const Color(0xFFFB7185),
        orbitRadius: 6.6,
        orbitSpeed: 0.36,
        phaseOffset: 4.8,
        inclination: -0.14,
        radius: 0.60,
        webUrl: resumeLink,
      ),
    ];

    return [
      SolarPlanetData(
        id: 'about',
        shortLabel: 'ABOUT',
        title: 'About Me World',
        tagline: 'Origin Bio & Personal Orbit',
        summary: bioText,
        icon: Icons.person_pin_circle_rounded,
        color: aboutColor,
        secondaryColor: aboutSec,
        orbitRadius: 14.5,
        orbitSpeed: 0.19,
        initialAngle: 0.4,
        inclination: 0.06,
        radius: 1.75,
        hasRing: false,
        textureStyle: 'terran',
        moons: aboutMoons,
      ),
      SolarPlanetData(
        id: 'skills',
        shortLabel: 'SKILLS',
        title: 'Skills Matrix World',
        tagline: '${skillsMoons.length} Technical Moons in Orbit',
        summary:
            'Core Flutter, Dart, Firebase, and web engineering stack powering production apps.',
        icon: Icons.bolt_rounded,
        color: skillsColor,
        secondaryColor: skillsSec,
        orbitRadius: 21.5,
        orbitSpeed: 0.14,
        initialAngle: 1.9,
        inclination: -0.09,
        radius: 2.05,
        hasRing: true,
        textureStyle: 'plasma',
        moons: skillsMoons,
      ),
      SolarPlanetData(
        id: 'experience',
        shortLabel: 'EXPERIENCE',
        title: 'Career Odyssey Giant',
        tagline: '${expMoons.length} Engineering Tenures',
        summary:
            'Leadership and production Flutter architecture across Invenics, Indbytes, and Bayasys.',
        icon: Icons.workspace_premium_rounded,
        color: expColor,
        secondaryColor: expSec,
        orbitRadius: 29.5,
        orbitSpeed: 0.105,
        initialAngle: 3.4,
        inclination: 0.11,
        radius: 2.35,
        hasRing: true,
        textureStyle: 'ringed',
        moons: expMoons,
      ),
      SolarPlanetData(
        id: 'projects',
        shortLabel: 'PROJECTS',
        title: 'Projects Nebula World',
        tagline: '${projMoons.length} Launched Applications',
        summary:
            'Interactive web utilities, mobile apps, games, and full-stack Flutter builds.',
        icon: Icons.rocket_launch_rounded,
        color: projColor,
        secondaryColor: projSec,
        orbitRadius: 38.5,
        orbitSpeed: 0.08,
        initialAngle: 4.8,
        inclination: -0.07,
        radius: 2.25,
        hasRing: false,
        textureStyle: 'nebula',
        moons: projMoons,
      ),
      SolarPlanetData(
        id: 'contact',
        shortLabel: 'CONTACT',
        title: 'Comms Relay World',
        tagline: 'Direct Channels, Links & CV',
        summary:
            'Reach Sivaprasad NK in Tripunithura, Kerala via WhatsApp, Email, LinkedIn, or Resume.',
        icon: Icons.radar_rounded,
        color: contactColor,
        secondaryColor: contactSec,
        orbitRadius: 47.5,
        orbitSpeed: 0.062,
        initialAngle: 5.7,
        inclination: 0.13,
        radius: 1.9,
        hasRing: true,
        textureStyle: 'beacon',
        moons: contactMoons,
      ),
    ];
  }
}

/// Orbital propagation and smooth center-locking camera solver.
class SolarOrbitPhysics {
  double orbitTime = 0.0;
  Vec3 cameraLookAt = Vec3.zero;
  double cameraDistance = 68.0;
  SolarFocusKind focusKind = SolarFocusKind.overview;
  String? focusedPlanetId;
  String? focusedMoonId;

  void focusOverview() {
    focusKind = SolarFocusKind.overview;
    focusedPlanetId = null;
    focusedMoonId = null;
  }

  void focusStar() {
    focusKind = SolarFocusKind.star;
    focusedPlanetId = null;
    focusedMoonId = null;
  }

  void focusPlanet(String planetId) {
    focusKind = SolarFocusKind.planet;
    focusedPlanetId = planetId;
    focusedMoonId = null;
  }

  void focusMoon(String planetId, String moonId) {
    focusKind = SolarFocusKind.moon;
    focusedPlanetId = planetId;
    focusedMoonId = moonId;
  }

  Vec3 planetPosition(SolarPlanetData planet) {
    final a = planet.initialAngle + orbitTime * planet.orbitSpeed;
    final cx = math.cos(a) * planet.orbitRadius;
    final cz = math.sin(a) * planet.orbitRadius;
    return Vec3(
      cx,
      cz * math.sin(planet.inclination),
      cz * math.cos(planet.inclination),
    );
  }

  Vec3 moonPosition(
    SolarPlanetData planet,
    SolarMoonData moon, {
    bool? isParentFocused,
  }) {
    final parentFocused = isParentFocused ?? (focusedPlanetId == planet.id);
    final expand = parentFocused ? 1.45 : 1.0;
    final a = moon.phaseOffset + orbitTime * moon.orbitSpeed;
    final r = moon.orbitRadius * expand;
    final lx = math.cos(a) * r;
    final lz = math.sin(a) * r;
    final pPos = planetPosition(planet);
    return Vec3(
      pPos.x + lx,
      pPos.y + lz * math.sin(moon.inclination),
      pPos.z + lz * math.cos(moon.inclination),
    );
  }

  SolarPlanetData? findPlanet(List<SolarPlanetData> planets, String? id) {
    if (id == null) return null;
    for (final p in planets) {
      if (p.id == id) return p;
    }
    return null;
  }

  SolarMoonData? findMoon(SolarPlanetData? planet, String? moonId) {
    if (planet == null || moonId == null) return null;
    for (final m in planet.moons) {
      if (m.id == moonId) return m;
    }
    return null;
  }

  void step(
    double dt,
    List<SolarPlanetData> planets, {
    required bool paused,
  }) {
    final safeDt = dt.clamp(0.0, 0.1);
    if (!paused) {
      final isBodyFocused = focusKind == SolarFocusKind.planet ||
          focusKind == SolarFocusKind.moon;
      orbitTime += safeDt * (isBodyFocused ? 0.22 : 1.0);
    }

    var desiredLookAt = Vec3.zero;
    var desiredDist = 68.0;

    switch (focusKind) {
      case SolarFocusKind.overview:
        desiredLookAt = Vec3.zero;
        desiredDist = 68.0;
        break;
      case SolarFocusKind.star:
        desiredLookAt = Vec3.zero;
        desiredDist = 19.0;
        break;
      case SolarFocusKind.planet:
        final p = findPlanet(planets, focusedPlanetId);
        if (p != null) {
          desiredLookAt = planetPosition(p);
          desiredDist = 14.5;
        }
        break;
      case SolarFocusKind.moon:
        final p = findPlanet(planets, focusedPlanetId);
        final m = findMoon(p, focusedMoonId);
        if (p != null && m != null) {
          desiredLookAt = moonPosition(p, m, isParentFocused: true);
          desiredDist = 6.8;
        } else if (p != null) {
          desiredLookAt = planetPosition(p);
          desiredDist = 14.5;
        }
        break;
    }

    final alpha = 1.0 - math.exp(-6.5 * safeDt);
    cameraLookAt = Vec3.lerp(cameraLookAt, desiredLookAt, alpha);
    cameraDistance = cameraDistance + (desiredDist - cameraDistance) * alpha;
  }
}
