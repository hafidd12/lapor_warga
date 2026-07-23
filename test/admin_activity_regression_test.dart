import 'package:flutter_test/flutter_test.dart';

import 'package:lapor_warga/models/models.dart';
import 'package:lapor_warga/providers/app_state.dart';

void main() {
  late AppState state;

  setUp(() {
    state = AppState();
    state.registerRT(
      name: 'Ketua RT',
      email: 'rt@example.com',
      password: 'password123',
      phone: '081200000001',
      jabatan: 'Ketua RT 05',
      rtRw: '005/002',
    );
  });

  test('membuat pengumuman menambahkan aktivitas RT', () async {
    final before = state.activities.length;

    await state.createAnnouncement(
      title: 'Kerja Bakti',
      content: 'Mari kerja bakti pada hari Minggu pagi.',
    );

    expect(state.activities.length, before + 1);
    expect(state.activities.first.type, 'announcement');
    expect(state.activities.first.description, contains('Membuat pengumuman'));
  });

  test('mengubah data pengumuman tetap terjaga di daftar aktivitas', () async {
    await state.createAnnouncement(
      title: 'Pengumuman Awal',
      content: 'Isi pengumuman awal.',
    );
    final announcementId = state.announcements.first.id;
    final before = state.activities.length;

    await state.updateAnnouncement(
      id: announcementId,
      title: 'Pengumuman Revisi',
      content: 'Isi pengumuman yang sudah direvisi.',
    );

    expect(state.activities.length, before);
    expect(state.announcements.first.title, 'Pengumuman Revisi');
  });

  test('menghapus pengumuman langsung mengubah state daftar', () async {
    await state.createAnnouncement(
      title: 'Pengumuman Hapus',
      content: 'Isi pengumuman untuk dihapus.',
    );
    final announcementId = state.announcements.first.id;

    await state.deleteAnnouncement(announcementId);

    expect(
      state.announcements.where(
        (announcement) => announcement.id == announcementId,
      ),
      isEmpty,
    );
  });

  test('membuat voting menambahkan aktivitas RT', () async {
    final before = state.activities.length;

    await state.createPoll(
      question: 'Apakah warga setuju kerja bakti?',
      options: const ['Setuju', 'Tidak'],
    );

    expect(state.activities.length, before + 1);
    expect(state.activities.first.type, 'poll');
    expect(state.activities.first.description, contains('Membuat voting'));
  });

  test('menyetujui warga menambahkan aktivitas verifikasi', () async {
    final warga = state.registeredUsers.firstWhere(
      (user) =>
          user.role == UserRole.warga &&
          user.verificationStatus == VerificationStatus.pending,
    );
    final before = state.activities.length;

    await state.verifyWarga(warga.id);

    expect(state.activities.length, before + 1);
    expect(state.activities.first.type, 'verification');
    expect(state.activities.first.description, contains('Memverifikasi warga'));
    expect(
      state.registeredUsers
          .firstWhere((user) => user.id == warga.id)
          .verificationStatus,
      VerificationStatus.verified,
    );
  });

  test('menolak warga menambahkan aktivitas verifikasi', () async {
    final warga = state.registeredUsers.firstWhere(
      (user) =>
          user.role == UserRole.warga &&
          user.verificationStatus == VerificationStatus.pending,
    );
    final before = state.activities.length;

    await state.rejectWarga(warga.id);

    expect(state.activities.length, before + 1);
    expect(state.activities.first.type, 'verification');
    expect(
      state.activities.first.description,
      contains('Menolak pendaftaran warga'),
    );
    expect(
      state.registeredUsers
          .firstWhere((user) => user.id == warga.id)
          .verificationStatus,
      VerificationStatus.rejected,
    );
  });

  test('menyelesaikan laporan menambahkan aktivitas laporan', () async {
    await state.addReport(
      'Lampu Jalan Mati',
      'Lampu jalan di depan gang mati sejak semalam.',
      'Penerangan Jalan',
      ReportPriority.medium,
    );
    final reportId = state.reports.first.id;
    final before = state.activities.length;

    state.completeReport(reportId, 'https://example.com/completion-photo.jpg');

    expect(state.activities.length, before + 1);
    expect(state.activities.first.type, 'report_completed');
    expect(
      state.activities.first.description,
      contains('Menyelesaikan laporan'),
    );
    expect(
      state.reports.firstWhere((report) => report.id == reportId).status,
      ReportStatus.resolved,
    );
  });
}
