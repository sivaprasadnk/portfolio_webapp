import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:spnk/main.dart';
import 'package:spnk/utils/locator.dart';

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    setup();
  });

  testWidgets(
    'Displays driver photo & live links on HUD and navigates Pit-Wall Dossier',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MyApp());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 250));

      // Verify driver identity, photo & live clickable quick-links on windshield HUD
      expect(find.text('SIVAPRASAD NK'), findsOneWidget);
      expect(find.text('GH'), findsOneWidget);
      expect(find.text('IN'), findsOneWidget);
      expect(find.text('PUB'), findsOneWidget);
      expect(find.text('VSC'), findsOneWidget);
      expect(find.text('WA'), findsOneWidget);
      expect(find.text('IG'), findsOneWidget);
      expect(find.text('CV'), findsOneWidget);
      expect(
        find.image(const AssetImage('assets/images/propic3.png')),
        findsOneWidget,
      );

      // Verify core racing HUD elements render without layout overflow
      expect(find.text('PIT WALL'), findsOneWidget);
      expect(find.text('KM/H'), findsOneWidget);
      expect(find.text('CRUISE: ON'), findsOneWidget);
      expect(find.text('SKILLS'), findsOneWidget);
      expect(find.text('PROJECTS'), findsOneWidget);

      // Tap PIT WALL button to open full telemetry dossier
      await tester.tap(find.text('PIT WALL'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Sivaprasad NK'), findsOneWidget);

      // Navigate across Dossier sector tabs
      await tester.tap(find.text('02 • BIO'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('CHASSIS TUNING PERKS'), findsOneWidget);

      await tester.tap(find.text('03 • SKILLS'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('ECU DYNO BENCH'), findsOneWidget);

      await tester.tap(find.text('04 • CAREER'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.textContaining('CONSTRUCTOR CHAMPIONSHIP HISTORY'),
        findsOneWidget,
      );

      await tester.tap(find.text('05 • PROJECTS'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('CHAMPIONSHIP GARAGE'), findsOneWidget);

      await tester.ensureVisible(find.text('06 • COMMS'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('06 • COMMS'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('PIT-WALL RADIO ARRAY'), findsOneWidget);

      // Close modal & flush gamification toast timer
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Racing portfolio renders touch pedals, photo & links cleanly on mobile viewport',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MyApp());
      await tester.pump(const Duration(milliseconds: 150));

      // Verify mobile touch pedals & compact HUD render with zero overflow
      expect(find.text('LEFT'), findsOneWidget);
      expect(find.text('RIGHT'), findsOneWidget);
      expect(find.text('GAS'), findsOneWidget);
      expect(find.text('NITRO'), findsOneWidget);
      expect(find.text('BRAKE'), findsOneWidget);
      expect(find.text('DOSSIER'), findsOneWidget);
      expect(find.text('SIVAPRASAD NK'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Switches smoothly across all 3 gameplay modes and all 3 visual themes',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1520, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MyApp());
      await tester.pump(const Duration(milliseconds: 150));

      // 1. Switch across all 3 Gameplay Modes: 3D HORIZON -> OPEN WORLD -> HIGHWAY
      expect(find.text('3D HORIZON'), findsOneWidget);
      expect(find.text('OPEN WORLD'), findsOneWidget);
      expect(find.text('HIGHWAY'), findsOneWidget);

      await tester.tap(find.text('OPEN WORLD'));
      await tester.pump(const Duration(milliseconds: 400));

      // Trigger GPS navigation to Career sector in Open-World Paddock
      await tester.tap(find.text('CAREER'));
      await tester.pump(const Duration(milliseconds: 400));

      // Switch to Vertical Highway Lane Racer mode
      await tester.tap(find.text('HIGHWAY'));
      await tester.pump(const Duration(milliseconds: 400));

      // Switch back to 3D Horizon Racer mode
      await tester.tap(find.text('3D HORIZON'));
      await tester.pump(const Duration(milliseconds: 300));

      // 2. Switch across all 3 Visual Themes: NEON CYBER -> F1 PIT-WALL -> SYNTHWAVE
      await tester.ensureVisible(find.text('F1 PIT-WALL'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('F1 PIT-WALL'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.ensureVisible(find.text('SYNTHWAVE'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('SYNTHWAVE'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.ensureVisible(find.text('NEON CYBER'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('NEON CYBER'));
      await tester.pump(const Duration(milliseconds: 200));

      // Toggle Cruise Auto-Pilot & Light/Dark brightness
      await tester.tap(find.text('CRUISE: ON'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('CRUISE: OFF'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.light_mode));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Selects across all 5 user vehicle types in 3D Garage & updates HUD',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1520, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MyApp());
      await tester.pump(const Duration(milliseconds: 150));

      // Default vehicle pill should be SUPERCAR
      expect(find.text('SUPERCAR'), findsOneWidget);

      // Open 3D Vehicle Garage
      await tester.ensureVisible(find.text('SUPERCAR'));
      await tester.tap(find.text('SUPERCAR'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.text('3D VEHICLE GARAGE // SELECT CHASSIS'),
        findsOneWidget,
      );
      expect(find.text('APEX GT-01'), findsWidgets);
      expect(find.text('FORMULA-X'), findsOneWidget);
      expect(find.text('CYBER-BIKE'), findsOneWidget);
      expect(find.text('TITAN-6X'), findsOneWidget);
      expect(find.text('AERO-HOVER'), findsOneWidget);

      // Choose CYBER-BIKE and deploy
      await tester.tap(find.text('CYBER-BIKE'));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.text('DEPLOY CYBER-BIKE'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('3D VEHICLE GARAGE // SELECT CHASSIS'),
        findsNothing,
      );
      expect(find.text('MOTO BIKE'), findsOneWidget);

      // Cycle vehicle via keyboard shortcut V -> TITAN-6X (CYBER SUV)
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('CYBER SUV'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Pops interactive 3D Destination Hologram projecting About Me, Projects & Contact Us',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1520, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MyApp());
      await tester.pump(const Duration(milliseconds: 150));

      // Open current Hologram via top bar HOLOGRAM button
      await tester.ensureVisible(find.text('HOLOGRAM'));
      await tester.tap(find.text('HOLOGRAM'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.text('HOLOGRAM PROJECTION // HOME BASE'),
        findsOneWidget,
      );

      // Step forward to ABOUT ME destination hologram
      await tester.tap(find.byTooltip('Next Destination'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.text('HOLOGRAM PROJECTION // ABOUT ME'),
        findsOneWidget,
      );
      expect(find.textContaining('Clean Arch & BLoC'), findsWidgets);

      // Step to SKILLS -> EXPERIENCE -> PROJECTS
      await tester.tap(find.byTooltip('Next Destination'));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.byTooltip('Next Destination'));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.byTooltip('Next Destination'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.text('HOLOGRAM PROJECTION // PROJECTS'),
        findsOneWidget,
      );
      expect(find.text('SP Quiz App'), findsOneWidget);
      expect(find.text('QR Code Studio'), findsOneWidget);

      // Step to CONTACT US destination hologram
      await tester.tap(find.byTooltip('Next Destination'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.text('HOLOGRAM PROJECTION // CONTACT US'),
        findsOneWidget,
      );
      expect(find.text('TRANSMIT'), findsWidgets);

      // Dismiss hologram with RESUME DRIVE
      await tester.tap(find.text('RESUME DRIVE'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.text('HOLOGRAM PROJECTION // CONTACT US'),
        findsNothing,
      );

      await tester.pump(const Duration(seconds: 3));
    },
  );
}
