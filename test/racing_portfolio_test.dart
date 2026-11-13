import 'package:flutter/material.dart';
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
    'Racing portfolio renders cleanly on desktop and opens Pit-Wall Dossier',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MyApp());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 250));

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
    'Racing portfolio renders touch pedals cleanly on mobile viewport',
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

      // Flush any initial timers cleanly
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Hyper-warp navigation, cruise toggle, and brightness switch work smoothly',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1520, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MyApp());
      await tester.pump(const Duration(milliseconds: 150));

      // Trigger Hyper-Warp to Career sector
      await tester.tap(find.text('CAREER'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Toggle Cruise Auto-Pilot button
      await tester.tap(find.text('CRUISE: ON'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('CRUISE: OFF'), findsOneWidget);

      // Toggle Light / Dark mode while 3D track painter is active
      // (BrightnessSwitch uses onDoubleTap so wait >300ms kDoubleTapTimeout)
      await tester.tap(find.byIcon(Icons.light_mode));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);

      // Switch car & track livery style (Spatial / Cyber)
      await tester.ensureVisible(find.text('CYBER'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('CYBER'));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.pump(const Duration(seconds: 3));
    },
  );
}
