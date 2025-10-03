import 'package:flutter_test/flutter_test.dart';

import 'package:qr_gate_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Since you replaced the default counter app with your QR app,
    // you probably don't have a '+' button or counter anymore.
    // Instead, just check that the login screen loads.
    expect(find.text('Login'), findsOneWidget);
  });
}
