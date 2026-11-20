import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:spnk/main.dart';
import 'package:spnk/utils/locator.dart';
import 'package:spnk/views/screens/home/grid/animated_characters.dart';

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    setup();
  });

  testWidgets(
    'Interactive Grid Home renders Bento UI, animating characters, filters & interactive skills/work',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 180));

      expect(find.text('Sivaprasad NK'), findsOneWidget);
      expect(find.text('3D RACER /v2'), findsOneWidget);
      expect(find.text('PLAY /v2'), findsOneWidget);

      // Verify all 5 animated characters & grid headers render
      expect(find.text('SPNK-BOT'), findsWidgets);
      expect(find.text('NEKO.DART'), findsOneWidget);
      expect(find.text('DASH'), findsOneWidget);
      expect(find.text('M3-DRIFT'), findsOneWidget);
      expect(find.text('COMMS-BOT'), findsOneWidget);

      expect(find.text('01 // COMMANDER'), findsOneWidget);
      expect(find.text('02 // V2 3D RACER'), findsOneWidget);
      expect(find.text('03 // LIVE GRID STAGE'), findsOneWidget);
      expect(find.text('04 // ABOUT ME'), findsOneWidget);
      expect(find.text('05 // WEB LABS & STATS'), findsOneWidget);
      expect(find.text('06 // SKILLS MATRIX'), findsOneWidget);
      expect(find.text('07 // EXPERIENCE'), findsOneWidget);
      expect(find.text('08 // PROJECTS GRID'), findsOneWidget);
      expect(find.text('09 // CONTACT & COMMS'), findsOneWidget);

      // Category filter switching
      await tester.tap(find.text('SKILLS'));
      await tester.pump(const Duration(milliseconds: 180));
      await tester.tap(find.text('PROJECTS'));
      await tester.pump(const Duration(milliseconds: 180));
      await tester.tap(find.text('ALL'));
      await tester.pump(const Duration(milliseconds: 180));

      // Tap a skill chip (Dart) to overclock ECU stage
      await tester.ensureVisible(find.text('Dart'));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(find.text('Dart'));
      await tester.pump(const Duration(milliseconds: 180));
      expect(find.textContaining('LVL '), findsWidgets);

      // Tap a career role to switch active experience details
      await tester.ensureVisible(find.text('Bayasys Infotech Pvt Ltd'));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(find.text('Bayasys Infotech Pvt Ltd'));
      await tester.pump(const Duration(milliseconds: 180));
      expect(find.text('Java, Postgres'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Playable 6x3 Character Grid Stage moves characters across coordinates and toggles Party Mode',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('POS [3, 2]'), findsOneWidget);
      expect(find.text('MOVES: 0'), findsOneWidget);

      // Switch active character to NEKO.DART and move to grid cell (4, 0) -> [5, 1]
      await tester.ensureVisible(find.text('NEKO.DART'));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(find.text('NEKO.DART'));
      await tester.pump(const Duration(milliseconds: 120));

      await tester.ensureVisible(find.byKey(const ValueKey('grid_cell_4_0')));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(find.byKey(const ValueKey('grid_cell_4_0')));
      await tester.pump(const Duration(milliseconds: 220));

      expect(find.text('POS [5, 1]'), findsOneWidget);
      expect(find.text('MOVES: 1'), findsOneWidget);

      // Toggle PARTY MODE to bring all 5 characters onto the 6x3 dance stage
      await tester.ensureVisible(find.text('PARTY MODE'));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(find.text('PARTY MODE'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('All 5 characters synced on stage'), findsOneWidget);
      // 5 ambient card characters + 5 party dancers = 10 instances on screen
      expect(find.byType(AnimatedPortfolioCharacter), findsNWidgets(10));

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Navigates from Interactive Grid Home (/) to 3D Racer (/v2) and back HOME',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 150));

      await tester.tap(find.text('PLAY /v2'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('MOST WANTED'), findsOneWidget);
      expect(find.text('PIT WALL'), findsOneWidget);
      expect(find.text('KM/H'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);

      // Return back to Interactive Grid Home
      await tester.tap(find.text('HOME'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Sivaprasad NK'), findsOneWidget);
      expect(find.text('PARTY MODE'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Interactive Grid Home renders cleanly on mobile 390x844 viewport with zero overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Sivaprasad NK'), findsOneWidget);
      expect(find.text('PLAY /v2'), findsOneWidget);
      expect(find.text('PARTY MODE'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Header bar uses dark glass scaffold background in dark mode and adapts to light mode',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 150));

      final headerFinder = find.byKey(const ValueKey('home_grid_header_bar'));
      expect(headerFinder, findsOneWidget);

      final darkContainer = tester.widget<Container>(headerFinder);
      final darkColor = (darkContainer.decoration! as BoxDecoration).color!;
      expect(darkColor.computeLuminance(), lessThan(0.15));

      await tester.tap(find.byIcon(Icons.light_mode));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);

      final lightContainer = tester.widget<Container>(headerFinder);
      final lightColor = (lightContainer.decoration! as BoxDecoration).color!;
      expect(lightColor.computeLuminance(), greaterThan(0.70));

      await tester.pump(const Duration(seconds: 3));
    },
  );
}
