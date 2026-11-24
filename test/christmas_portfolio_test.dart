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

  test('ChristmasThemeConfig countdown calculates days until Dec 25 accurately', () {
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
  });

  testWidgets(
    'Root route (/) renders Christmas Edition portfolio with all sections and toggles',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 160));

      expect(find.text('Merry Christmas & Happy New Year!'), findsOneWidget);
      expect(find.text('Sivaprasad NK'), findsOneWidget);
      expect(find.text('About Me'), findsOneWidget);
      expect(find.text('Experience'), findsWidgets);
      expect(find.text('Projects'), findsWidgets);
      expect(find.text('Skills & Technologies'), findsOneWidget);
      expect(find.text('Get In Touch'), findsOneWidget);
      expect(find.text('CLASSIC /v4'), findsOneWidget);

      // Toggle Let It Snow
      expect(find.text('Let It Snow: ON'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('let_it_snow_toggle')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Let It Snow: OFF'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('let_it_snow_toggle')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Let It Snow: ON'), findsOneWidget);

      // Navigate to /v4 Classic Grid Home
      await tester.tap(find.text('CLASSIC /v4'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('01 // COMMANDER'), findsOneWidget);
      expect(find.text('PARTY MODE'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'Christmas Edition portfolio renders cleanly on mobile 390x844 viewport',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 160));

      expect(find.text('Merry Christmas & Happy New Year!'), findsOneWidget);
      expect(find.text('Sivaprasad NK'), findsOneWidget);
      expect(find.byKey(const ValueKey('let_it_snow_toggle')), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    },
  );
}
