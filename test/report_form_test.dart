import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapor_warga/models/models.dart';
import 'package:lapor_warga/providers/app_state.dart';
import 'package:lapor_warga/screens/warga/halaman_report.dart';
import 'package:lapor_warga/theme.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('submit laporan masuk ke state dan form reset', (tester) async {
    final appState = AppState();
    appState.login('budi@lapor.com', 'password');
    final initialReportCount = appState.reports.length;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HalamanReportScreen(showBackButton: false),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Lampu taman mati',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Lampu taman dekat pos ronda mati sejak kemarin malam.',
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Penerangan Jalan').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Tinggi'));
    await tester.tap(find.text('Tinggi'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Upload atau Foto Laporan'));
    await tester.tap(find.text('Upload atau Foto Laporan'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Tentukan Titik Lokasi'));
    await tester.tap(find.text('Tentukan Titik Lokasi'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Kirim Laporan'));
    await tester.tap(find.text('Kirim Laporan'));
    await tester.pumpAndSettle();

    expect(appState.reports.length, initialReportCount + 1);
    final submittedReport = appState.reports.first;
    expect(submittedReport.title, 'Lampu taman mati');
    expect(
      submittedReport.description,
      'Lampu taman dekat pos ronda mati sejak kemarin malam.',
    );
    expect(submittedReport.category, 'Penerangan Jalan');
    expect(submittedReport.priority, ReportPriority.high);
    expect(submittedReport.reportPhotoUrl, 'mock://laporan/foto-kejadian.jpg');
    expect(
      submittedReport.locationLabel,
      'Titik laporan dipilih - RT 05 / RW 02',
    );

    expect(find.text('Laporan Anda berhasil dikirim!'), findsOneWidget);
    expect(find.text('Lampu taman mati'), findsNothing);
    expect(find.text('foto-kejadian.jpg'), findsNothing);
    expect(find.text('Lokasi Dipilih'), findsNothing);
    expect(find.text('Pilih kategori laporan'), findsOneWidget);
    expect(find.text('Upload atau Foto Laporan'), findsOneWidget);
    expect(find.text('Tentukan Titik Lokasi'), findsOneWidget);
  });
}
