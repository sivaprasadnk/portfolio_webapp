import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:spnk/main.dart';
import 'package:spnk/utils/locator.dart';
import 'package:spnk/views/screens/christmas/christmas_theme_config.dart';

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    setup();
  });

  test('ChristmasThemeConfig countdown and day/night local-time checks', () {
    expect(
      ChristmasThemeConfig.daysUntilChristmas(DateTime(2026, 12, 20)),
      5,
    );
    expect(
      ChristmasThemeConfig.countdownLabel(DateTime(2026, 12, 25)),
      'Merry Christmas Today!',
    );
    expect(
      ChristmasThemeConfig.countdownLabel(DateTime(2026, 12, 24)),
      '1 Day Until Christmas',
    );
    expect(
      ChristmasThemeConfig.daysUntilChristmas(DateTime(2026, 12, 26)),
      364,
    );

    expect(ChristmasThemeConfig.isDayTime(DateTime(2026, 12, 20, 5, 59)), false);
    expect(ChristmasThemeConfig.isDayTime(DateTime(2026, 12, 20, 6, 0)), true);
    expect(ChristmasThemeConfig.isDayTime(DateTime(2026, 12, 20, 12, 0)), true);
    expect(ChristmasThemeConfig.isDayTime(DateTime(2026, 12, 20, 17, 59)), true);
    expect(ChristmasThemeConfig.isDayTime(DateTime(2026, 12, 20, 18, 0)), false);
    expect(ChristmasThemeConfig.isDayTime(DateTime(2026, 12, 20, 23, 0)), false);
  });

  testWidgets(
    'Root route (/) renders 2D Horizontal Santa Village with section boards, sub-boards, forward/back walk & /v5',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 180));

      // Fixed SP glass snow globe & main character Santa Claus
      expect(find.byKey(const ValueKey('sp_snow_globe')), findsOneWidget);
      expect(find.byKey(const ValueKey('santa_character')), findsOneWidget);
      expect(find.byKey(const ValueKey('santa_walk_forward')), findsOneWidget);
      expect(find.byKey(const ValueKey('santa_walk_back')), findsOneWidget);

      // Floating cloud navigation destinations
      for (final id in [
        'home',
        'about',
        'experience',
        'projects',
        'skills',
        'contact',
      ]) {
        expect(find.byKey(ValueKey('cloud_nav_$id')), findsOneWidget);
      }

      // Main section boards & sub-boards content
      expect(find.text('Merry Christmas & Happy New Year!'), findsOneWidget);
      expect(find.text('Sivaprasad NK'), findsOneWidget);
      expect(find.text('Ernakulam, Kerala'), findsOneWidget);
      expect(find.text('About Me'), findsOneWidget);
      expect(find.text('AI Coding & Craft'), findsOneWidget);
      expect(find.text('Endurance Athlete'), findsOneWidget);
      expect(find.text('Experience'), findsWidgets);
      expect(find.text('Projects'), findsWidgets);
      expect(find.text('Skills & Technologies'), findsOneWidget);
      expect(find.text('Get In Touch'), findsOneWidget);
      expect(find.text('CLASSIC /v4'), findsOneWidget);
      expect(find.text('3D VILLAGE /v5'), findsOneWidget);

      // Walk Santa forward & backward
      await tester.tap(find.byKey(const ValueKey('santa_walk_forward')));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.tap(find.byKey(const ValueKey('santa_walk_back')));
      await tester.pump(const Duration(milliseconds: 450));

      // Day / Night toggle
      final dayNightToggle = find.byKey(const ValueKey('day_night_toggle'));
      expect(dayNightToggle, findsOneWidget);
      final wasDayInitially = ChristmasThemeConfig.isDayTime(DateTime.now());
      expect(find.text(wasDayInitially ? 'Day' : 'Night'), findsOneWidget);
      await tester.tap(dayNightToggle);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text(wasDayInitially ? 'Night' : 'Day'), findsOneWidget);
      await tester.tap(dayNightToggle);
      await tester.pump(const Duration(milliseconds: 250));

      // Toggle Let It Snow
      expect(find.text('Let It Snow: ON'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('let_it_snow_toggle')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Let It Snow: OFF'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('let_it_snow_toggle')));
      await tester.pump(const Duration(milliseconds: 150));

      // Verify floating navbar clouds actually move horizontally over time
      final cloudBefore = tester.getTopLeft(
        find.byKey(const ValueKey('cloud_nav_home')),
      );
      await tester.pump(const Duration(milliseconds: 900));
      final cloudAfter = tester.getTopLeft(
        find.byKey(const ValueKey('cloud_nav_home')),
      );
      expect(cloudAfter.dx, greaterThan(cloudBefore.dx));

      // Navigate via cloud nav & SP snow globe
      await tester.tap(find.byKey(const ValueKey('cloud_nav_projects')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const ValueKey('sp_snow_globe')));
      await tester.pump(const Duration(milliseconds: 400));

      // Navigate to 3D Winter Village /v5
      await tester.tap(find.byKey(const ValueKey('village_3d_v5_btn')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2D Santa /'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'Route /v5 renders 3D Christmas Winter Village cleanly with /v4 navigation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp(initialRoute: '/v5'));
      await tester.pump(const Duration(milliseconds: 160));

      expect(find.byKey(const ValueKey('sp_snow_globe')), findsOneWidget);
      expect(find.text('Sivaprasad NK'), findsOneWidget);
      expect(find.text('2D Santa /'), findsOneWidget);
      expect(find.text('CLASSIC /v4'), findsOneWidget);

      await tester.tap(find.text('CLASSIC /v4'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('01 // COMMANDER'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    '2D Horizontal Santa Village renders cleanly on mobile 390x844 viewport without overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 180));

      expect(find.byKey(const ValueKey('sp_snow_globe')), findsOneWidget);
      expect(find.byKey(const ValueKey('santa_character')), findsOneWidget);
      expect(find.byKey(const ValueKey('santa_walk_forward')), findsOneWidget);
      expect(find.byKey(const ValueKey('santa_walk_back')), findsOneWidget);
      expect(find.byKey(const ValueKey('day_night_toggle')), findsOneWidget);
      expect(find.byKey(const ValueKey('let_it_snow_toggle')), findsOneWidget);
      expect(find.byKey(const ValueKey('cloud_nav_home')), findsOneWidget);
      expect(find.text('Sivaprasad NK'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    },
  );
}
