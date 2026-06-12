import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapor_warga/main.dart';

void main() {
  testWidgets('Splash screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LaporWargaApp());

    // Verify that splash screen loading text is found.
    expect(find.text('Lapor Warga'), findsOneWidget);

    // Pump the timer forward by 3 seconds so the splash screen timer finishes and navigates.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
