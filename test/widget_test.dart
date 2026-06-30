import 'package:flutter_test/flutter_test.dart';
import 'package:lapor_warga/main.dart';

void main() {
  testWidgets('Splash screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const LaporWargaApp());

    expect(find.text('Lapor Warga'), findsOneWidget);
  });
}
