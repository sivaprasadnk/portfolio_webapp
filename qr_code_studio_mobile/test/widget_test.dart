import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_studio_mobile/main.dart';

void main() {
  testWidgets('QR Code Studio mobile app renders Generator and Scanner tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const QrCodeStudioApp());

    expect(find.text('QR Code Studio'), findsOneWidget);
    expect(find.text('Generator'), findsOneWidget);
    expect(find.text('Scanner'), findsOneWidget);
    expect(find.text('Type any text above to generate QR'), findsOneWidget);
  });
}
