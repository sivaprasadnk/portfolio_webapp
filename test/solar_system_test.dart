import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:spnk/main.dart';
import 'package:spnk/utils/locator.dart';
import 'package:spnk/views/screens/solar/solar_models.dart';
import 'package:spnk/views/screens/solar/solar_system_screen.dart';

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    setup();
  });

  test(
    'SolarOrbitPhysics centers camera on focused Planet & Moon and expands moon orbits',
    () {
      final planets = SolarSystemBuilder.build(
        aboutBio: '',
        skills: const [],
        experiences: const [],
        projects: const [],
        contacts: const [],
      );
      expect(planets.length, 5);
      expect(
        planets.map((p) => p.id).toList(),
        ['about', 'skills', 'experience', 'projects', 'contact'],
      );

      final physics = SolarOrbitPhysics();
      final projectsPlanet = planets.firstWhere((p) => p.id == 'projects');
      final qrMoon =
          projectsPlanet.moons.firstWhere((m) => m.title == 'QR Code Studio');

      // Moon orbit expands by 1.45x when parent planet is focused
      final unfocusDist = physics
          .moonPosition(projectsPlanet, qrMoon, isParentFocused: false)
          .distanceTo(physics.planetPosition(projectsPlanet));
      final focusDist = physics
          .moonPosition(projectsPlanet, qrMoon, isParentFocused: true)
          .distanceTo(physics.planetPosition(projectsPlanet));
      expect(focusDist, closeTo(unfocusDist * 1.45, 0.01));

      // Focus planet -> cameraLookAt converges to planetPosition
      physics.focusPlanet('projects');
      for (int i = 0; i < 80; i++) {
        physics.step(0.05, planets, paused: true);
      }
      expect(
        physics.cameraLookAt.distanceTo(physics.planetPosition(projectsPlanet)),
        lessThan(0.1),
      );
      expect(physics.cameraDistance, closeTo(14.5, 0.1));

      // Focus moon -> cameraLookAt converges to moonPosition
      physics.focusMoon('projects', qrMoon.id);
      for (int i = 0; i < 80; i++) {
        physics.step(0.05, planets, paused: true);
      }
      expect(
        physics.cameraLookAt.distanceTo(
          physics.moonPosition(projectsPlanet, qrMoon, isParentFocused: true),
        ),
        lessThan(0.1),
      );
      expect(physics.cameraDistance, closeTo(6.8, 0.1));
    },
  );

  testWidgets(
    'SolarSystemPortfolioScreen focuses Star, Planets & Moons at center and returns HOME',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp(initialRoute: '/v3'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      final solarScope = find.byType(SolarSystemPortfolioScreen);
      expect(solarScope, findsOneWidget);
      expect(find.descendant(of: solarScope, matching: find.text('STAR')), findsOneWidget);
      expect(find.descendant(of: solarScope, matching: find.text('ABOUT')), findsOneWidget);
      expect(find.descendant(of: solarScope, matching: find.text('SKILLS')), findsOneWidget);
      expect(find.descendant(of: solarScope, matching: find.text('EXPERIENCE')), findsOneWidget);
      expect(find.descendant(of: solarScope, matching: find.text('PROJECTS')), findsOneWidget);
      expect(find.descendant(of: solarScope, matching: find.text('CONTACT')), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsNothing);
      expect(find.byIcon(Icons.color_lens), findsNothing);

      // Focus PROJECTS planet
      await tester.tap(find.descendant(of: solarScope, matching: find.text('PROJECTS')));
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.text('Projects Nebula World'), findsOneWidget);
      expect(find.text('SP Quiz App'), findsOneWidget);
      expect(find.text('QR Code Studio'), findsOneWidget);
      expect(find.text('YouTube Downloader'), findsOneWidget);

      // Focus sub-section moon QR Code Studio
      await tester.ensureVisible(find.text('QR Code Studio'));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(find.text('QR Code Studio'));
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.text('BACK TO PROJECTS'), findsOneWidget);
      expect(find.text('LAUNCH WEB'), findsOneWidget);

      // Focus Central Star
      await tester.tap(find.descendant(of: solarScope, matching: find.text('STAR')));
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.text('SIVAPRASAD NK'), findsOneWidget);

      // Toggle pause/resume orbits
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('solar_toggle_orbit')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Navigate HOME
      await tester.tap(find.descendant(of: solarScope, matching: find.text('HOME')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Sivaprasad NK'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'SolarSystemPortfolioScreen renders cleanly on mobile 390x844 viewport with zero overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp(initialRoute: '/v3'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      final solarScope = find.byType(SolarSystemPortfolioScreen);
      expect(find.descendant(of: solarScope, matching: find.text('STAR')), findsOneWidget);
      expect(find.text('FOCUS CENTRAL STAR'), findsOneWidget);

      // Also check focused Planet & Moon layout on mobile
      final skillsChip = find.descendant(of: solarScope, matching: find.text('SKILLS'));
      await tester.ensureVisible(skillsChip);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(skillsChip);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Skills Matrix World'), findsOneWidget);

      final dartChip = find.descendant(of: solarScope, matching: find.text('Dart'));
      await tester.ensureVisible(dartChip);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(dartChip);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('BACK TO SKILLS'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Navigates from Interactive Grid Home (/) to 3D Solar System (/v3)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 150));

      final solarButton = find.text('3D Solar /v3').first;
      await tester.ensureVisible(solarButton);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(solarButton);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      final solarScope = find.byType(SolarSystemPortfolioScreen);
      expect(solarScope, findsOneWidget);
      expect(
        find.descendant(of: solarScope, matching: find.text('PROJECTS')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: solarScope, matching: find.text('SYSTEM')),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 3));
    },
  );
}
