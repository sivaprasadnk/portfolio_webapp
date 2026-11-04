import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_studio_mobile/main.dart';

void main() {
  testWidgets(
      'QR Code Studio mobile app renders tabs, footer, drawer, version, and backgrounds',
      (WidgetTester tester) async {
    await tester.pumpWidget(const QrCodeStudioApp());

    expect(find.text('QR Code Studio'), findsOneWidget);
    expect(find.text('Generator'), findsOneWidget);
    expect(find.text('Scanner'), findsOneWidget);
    expect(find.text('Type any text above to generate QR'), findsOneWidget);
    expect(find.text('sivaprasadnk.dev'), findsOneWidget);

    // Open navigation drawer
    final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('DYNAMIC BACKGROUND'), findsOneWidget);
    expect(find.text('Aurora Orbs'), findsOneWidget);
    expect(find.text('Cyber Grid'), findsOneWidget);
    expect(find.text('Cosmic Stars'), findsOneWidget);
    expect(find.text('Neon Waves'), findsOneWidget);
    expect(find.text('Constellation'), findsOneWidget);
    expect(find.text('Check for Updates'), findsOneWidget);
    expect(find.textContaining('v1.0.0'), findsWidgets);
  });
}
