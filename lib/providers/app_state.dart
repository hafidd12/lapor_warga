import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/backend_service.dart';
import '../services/supabase_service.dart';
import '../services/warga_verification_service.dart';

class AppState with ChangeNotifier {
  AppUser? _currentUser;
  final AuthService? _authService;
  final BackendService? _backendService;
  final List<AppUser> _registeredUsers = [];
  final List<Report> _reports = [];
  final List<Announcement> _announcements = [];
  final List<Poll> _polls = [];
  final List<AdminActivity> _activities = [];
  final List<RegistrationCode> _registrationCodes = [];
  final List<AppUser> _verificationUsers = [];
  final WargaVerificationService? _verificationService;
  bool _verificationUsersLoaded = false;

  AppState({
    AuthService? authService,
    BackendService? backendService,
    WargaVerificationService? verificationService,
  }) : _authService = authService,
       _backendService = backendService,
       _verificationService = verificationService {
    _loadMockData();
  }

  AppUser? get currentUser => _currentUser;
  List<Report> get reports => List.unmodifiable(_reports);
  List<Announcement> get announcements => List.unmodifiable(_announcements);
  List<Poll> get polls => List.unmodifiable(_polls);
  List<AppUser> get registeredUsers => List.unmodifiable(_registeredUsers);
  List<AdminActivity> get activities => List.unmodifiable(_activities);
  List<RegistrationCode> get registrationCodes =>
      List.unmodifiable(_registrationCodes);

  // Warga queries
  List<AppUser> get allWarga =>
      _verificationUsersLoaded
          ? List.unmodifiable(_verificationUsers)
          : _registeredUsers.where((u) => u.role == UserRole.warga).toList();
  List<AppUser> get verifiedWarga =>
      _verificationUsersLoaded
          ? _verificationUsers
              .where((u) => u.verificationStatus == VerificationStatus.verified)
              .toList()
          : _registeredUsers
              .where(
                (u) =>
                    u.role == UserRole.warga &&
                    u.verificationStatus == VerificationStatus.verified,
              )
              .toList();
  List<AppUser> get pendingWarga =>
      _verificationUsersLoaded
          ? _verificationUsers
              .where((u) => u.verificationStatus == VerificationStatus.pending)
              .toList()
          : _registeredUsers
              .where(
                (u) =>
                    u.role == UserRole.warga &&
                    u.verificationStatus == VerificationStatus.pending,
              )
              .toList();
  List<AppUser> get rejectedWarga =>
      _verificationUsersLoaded
          ? _verificationUsers
              .where((u) => u.verificationStatus == VerificationStatus.rejected)
              .toList()
          : _registeredUsers
              .where(
                (u) =>
                    u.role == UserRole.warga &&
                    u.verificationStatus == VerificationStatus.rejected,
              )
              .toList();

  // Completed reports with photos
  List<Report> get completedReportsWithPhotos => _reports
      .where(
        (r) =>
            r.status == ReportStatus.resolved && r.completionPhotoUrl != null,
      )
      .toList();

  void _loadMockData() {
    // Mock registered users (warga)
    _registeredUsers.addAll([
      AppUser(
        id: 'user-1',
        name: 'Budi Santoso',
        email: 'budi@lapor.com',
        role: UserRole.warga,
        avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=Budi',
        verificationStatus: VerificationStatus.verified,
        ktpNumber: '3201234567890001',
        registrationCode: 'RT05-001',
        phone: '081234567890',
        rtRw: '005/002',
        address: 'Jl. Mawar No. 10',
        registeredAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      AppUser(
        id: 'user-2',
        name: 'Siti Rahma',
        email: 'siti@lapor.com',
        role: UserRole.warga,
        avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=Siti',
        verificationStatus: VerificationStatus.verified,
        ktpNumber: '3201234567890002',
        registrationCode: 'RT05-002',
        phone: '081234567891',
        rtRw: '005/002',
        address: 'Jl. Melati No. 5',
        registeredAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      AppUser(
        id: 'user-3',
        name: 'Rian Hidayat',
        email: 'rian@lapor.com',
        role: UserRole.warga,
        avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=Rian',
        verificationStatus: VerificationStatus.verified,
        ktpNumber: '3201234567890003',
        registrationCode: 'RT05-003',
        phone: '081234567892',
        rtRw: '005/002',
        address: 'Jl. Kenanga No. 8',
        registeredAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      AppUser(
        id: 'user-4',
        name: 'Dewi Lestari',
        email: 'dewi@lapor.com',
        role: UserRole.warga,
        avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=Dewi',
        verificationStatus: VerificationStatus.pending,
        ktpNumber: '3201234567890004',
        registrationCode: 'RT05-004',
        phone: '081234567893',
        rtRw: '005/002',
        address: 'Jl. Anggrek No. 3',
        registeredAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppUser(
        id: 'user-5',
        name: 'Ahmad Fauzi',
        email: 'ahmad@lapor.com',
        role: UserRole.warga,
        avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=Ahmad',
        verificationStatus: VerificationStatus.pending,
        ktpNumber: '3201234567890005',
        registrationCode: 'RT05-005',
        phone: '081234567894',
        rtRw: '005/002',
        address: 'Jl. Dahlia No. 12',
        registeredAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ]);

    // Mock RT admin
    _registeredUsers.add(
      AppUser(
        id: 'admin-1',
        name: 'Pak Harto',
        email: 'admin@lapor.com',
        role: UserRole.admin,
        avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=Harto',
        verificationStatus: VerificationStatus.verified,
        phone: '081200000001',
        jabatan: 'Ketua RT 05',
        rtRw: '005/002',
        registeredAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
    );

    // Mock Announcements
    _announcements.addAll([
      Announcement(
        id: 'ann-1',
        title: 'Gotong Royong Kebersihan RT 05',
        content:
            'Dihimbau kepada seluruh warga RT 05 untuk berkumpul pada hari Minggu pukul 07.00 WIB di Balai Warga untuk melaksanakan gotong royong membersihkan saluran air dan fasilitas umum guna mengantisipasi musim hujan.',
        author: 'Ketua RT 05',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Announcement(
        id: 'ann-2',
        title: 'Jadwal Imunisasi Posyandu Dahlia',
        content:
            'Pelaksanaan Posyandu balita dan pemeriksaan lansia rutin akan dilaksanakan pada hari Rabu, 10 Juni 2026 pukul 08.00 - 11.00 WIB di Poskamling RT 03. Mohon kehadiran ibu-ibu membawa KIA.',
        author: 'Kader Posyandu',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);

    // Mock Polls
    _polls.addAll([
      Poll(
        id: 'poll-1',
        question:
            'Hari apa yang paling sesuai untuk diadakan senam pagi warga bersama?',
        options: ['Sabtu Pagi', 'Minggu Pagi', 'Jumat Sore'],
        votes: {'Sabtu Pagi': 12, 'Minggu Pagi': 28, 'Jumat Sore': 5},
        userVotes: {},
      ),
      Poll(
        id: 'poll-2',
        question:
            'Setujukan Anda jika area samping balai RT dijadikan taman bermain anak?',
        options: ['Sangat Setuju', 'Setuju', 'Kurang Setuju / Ada Usulan Lain'],
        votes: {
          'Sangat Setuju': 32,
          'Setuju': 15,
          'Kurang Setuju / Ada Usulan Lain': 2,
        },
        userVotes: {},
      ),
    ]);

    // Mock Reports
    _reports.addAll([
      Report(
        id: 'rep-1',
        citizenName: 'Budi Santoso',
        title: 'Jalan Berlubang di Dekat Gapura RT 02',
        description:
            'Ada lubang yang cukup besar dan dalam di aspal tepat setelah melewati gapura masuk RT 02. Sangat membahayakan pengendara motor saat malam hari karena minim penerangan.',
        category: 'Infrastruktur',
        priority: ReportPriority.high,
        status: ReportStatus.submitted,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        votesCount: 15,
        upvotedByUserIds: ['user-2', 'user-3'],
      ),
      Report(
        id: 'rep-2',
        citizenName: 'Siti Rahma',
        title: 'Lampu Penerangan Jalan Umum Mati di Gang Mawar',
        description:
            'Sudah tiga hari lampu tiang PJU nomor 4 di Gang Mawar mati total. Gang menjadi sangat gelap dan rawan tindakan kriminal.',
        category: 'Penerangan Jalan',
        priority: ReportPriority.medium,
        status: ReportStatus.processed,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        votesCount: 8,
        upvotedByUserIds: ['user-1'],
      ),
      Report(
        id: 'rep-3',
        citizenName: 'Rian Hidayat',
        title: 'Penumpukan Sampah Liar di Lapangan Bulutangkis',
        description:
            'Banyak warga atau pihak luar membuang sampah kantong plastik di pinggir lapangan bulutangkis. Bau menyengat dan merusak pemandangan tempat bermain anak.',
        category: 'Kebersihan',
        priority: ReportPriority.low,
        status: ReportStatus.resolved,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        votesCount: 22,
        upvotedByUserIds: ['user-1', 'user-2', 'user-4'],
        completionPhotoUrl: 'https://picsum.photos/seed/cleanup1/400/300',
        completedAt: DateTime.now().subtract(const Duration(days: 3)),
        completedBy: 'Pak Harto (RT 05)',
      ),
    ]);

    // Mock Activities
    _activities.addAll([
      AdminActivity(
        id: 'act-1',
        description: 'Menyelesaikan laporan "Penumpukan Sampah Liar"',
        type: 'report_completed',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        photoUrl: 'https://picsum.photos/seed/cleanup1/400/300',
        relatedId: 'rep-3',
      ),
      AdminActivity(
        id: 'act-2',
        description: 'Memverifikasi warga baru: Rian Hidayat',
        type: 'verification',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      AdminActivity(
        id: 'act-3',
        description: 'Membuat pengumuman: Gotong Royong Kebersihan RT 05',
        type: 'announcement',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        relatedId: 'ann-1',
      ),
      AdminActivity(
        id: 'act-4',
        description: 'Membuat voting: Hari senam pagi warga',
        type: 'poll',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        relatedId: 'poll-1',
      ),
    ]);
    // Mock Registration Codes
    _registrationCodes.addAll([
      RegistrationCode(
        id: 'regcode-1',
        code: 'RT05-XY7K',
        rtRw: '005/002',
        createdBy: 'admin-1',
        createdByName: 'Pak Harto',
        createdAt: DateTime.now().subtract(const Duration(days: 50)),
        isActive: true,
      ),
      RegistrationCode(
        id: 'regcode-2',
        code: 'RT05-AB3M',
        rtRw: '005/002',
        createdBy: 'admin-1',
        createdByName: 'Pak Harto',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        isActive: true,
      ),
    ]);
  }

  // ============================================
  // Authentication Actions
  // ============================================

  AuthService get _activeAuthService => _authService ?? AuthService();
  BackendService get _activeBackendService =>
      _backendService ?? BackendService();
  WargaVerificationService get _activeVerificationService =>
      _verificationService ?? WargaVerificationService();

  void _setCurrentUser(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> refreshVerificationUsers() async {
    if (!SupabaseService.isInitialized) return;

    try {
      final users = await _activeVerificationService.fetchAllWarga();
      _verificationUsers
        ..clear()
        ..addAll(users);
      _verificationUsersLoaded = true;
      notifyListeners();
    } catch (_) {
      _verificationUsersLoaded = false;
    }
  }

  Future<void> refreshRemoteData() async {
    if (!SupabaseService.isInitialized) return;

    try {
      final snapshot = await _activeBackendService.fetchSnapshot();
      _replaceWithSnapshot(snapshot);
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrint(stackTrace.toString());
    }
  }

  void _replaceWithSnapshot(BackendSnapshot snapshot) {
    _registeredUsers
      ..clear()
      ..addAll(snapshot.users);
    _reports
      ..clear()
      ..addAll(snapshot.reports);
    _announcements
      ..clear()
      ..addAll(snapshot.announcements);
    _polls
      ..clear()
      ..addAll(snapshot.polls);
    _activities
      ..clear()
      ..addAll(snapshot.activities);
    _registrationCodes
      ..clear()
      ..addAll(snapshot.registrationCodes);

    if (_currentUser != null) {
      final matches = _registeredUsers.where((u) => u.id == _currentUser!.id);
      if (matches.isNotEmpty) {
        _currentUser = matches.first;
      }
    }

    notifyListeners();
  }

  void _runRemote(Future<void> Function() action) {
    if (!SupabaseService.isInitialized) return;

    unawaited(
      action().catchError((Object error, StackTrace stackTrace) {
        debugPrint(error.toString());
        debugPrint(stackTrace.toString());
      }),
    );
  }

  Future<Map<String, dynamic>> loginWithSupabase(
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      return {'success': false, 'message': 'Email dan password wajib diisi'};
    }

    if (!SupabaseService.isInitialized) {
      return {'success': false, 'message': 'Konfigurasi Supabase belum aktif'};
    }

    try {
      final user = await _activeAuthService.signInWithPassword(
        email: email,
        password: password,
      );
      _setCurrentUser(user);
      await refreshRemoteData();
      if (user.role == UserRole.admin) {
        await refreshVerificationUsers();
      }

      return {
        'success': true,
        'role': user.role,
        'verificationStatus': user.verificationStatus,
      };
    } on AuthServiceException catch (error) {
      return {'success': false, 'message': error.message};
    } catch (_) {
      return {'success': false, 'message': 'Login gagal. Silakan coba lagi.'};
    }
  }

  Future<bool> restoreSession() async {
    if (!SupabaseService.isInitialized) return false;

    try {
      final user = await _activeAuthService.getCurrentUserProfile();
      if (user == null) {
        _setCurrentUser(null);
        return false;
      }

      _setCurrentUser(user);
      await refreshRemoteData();
      if (user.role == UserRole.admin) {
        await refreshVerificationUsers();
      }
      return true;
    } catch (_) {
      _setCurrentUser(null);
      return false;
    }
  }

  Future<void> logoutFromSupabase() async {
    if (SupabaseService.isInitialized) {
      try {
        await _activeAuthService.signOut();
      } catch (_) {
        // Local state still needs to be cleared even if remote sign out fails.
      }
    }

    _setCurrentUser(null);
    _verificationUsersLoaded = false;
  }

  Future<String?> lookupRegistrationCodeRemote(String code) async {
    if (code.trim().isEmpty) return null;

    if (!SupabaseService.isInitialized) {
      return null;
    }

    try {
      return await _activeAuthService.lookupActiveRegistrationCodeRtRw(code);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> registerWargaWithSupabase({
    required String name,
    required String email,
    required String password,
    required String registrationCode,
    required String ktpNumber,
    required String phone,
    required String address,
    required Uint8List ktpImageBytes,
    required String ktpImageName,
  }) async {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty ||
        registrationCode.trim().isEmpty ||
        ktpNumber.trim().isEmpty ||
        phone.trim().isEmpty ||
        address.trim().isEmpty ||
        ktpImageName.trim().isEmpty ||
        ktpImageBytes.isEmpty) {
      return {'success': false, 'message': 'Semua data registrasi wajib diisi'};
    }

    if (!SupabaseService.isInitialized) {
      return {'success': false, 'message': 'Konfigurasi Supabase belum aktif'};
    }

    try {
      final user = await _activeAuthService.registerWargaWithSupabase(
        name: name,
        email: email,
        password: password,
        registrationCode: registrationCode,
        ktpNumber: ktpNumber,
        phone: phone,
        address: address,
        ktpImageBytes: ktpImageBytes,
        ktpImageName: ktpImageName,
      );
      _setCurrentUser(user);
      await refreshRemoteData();

      return {
        'success': true,
        'role': user.role,
        'verificationStatus': user.verificationStatus,
      };
    } on AuthServiceException catch (error) {
      return {'success': false, 'message': error.message};
    } catch (error) {
      return {
        'success': false,
        'message': 'Registrasi gagal. Silakan coba lagi.',
        'debugMessage': error.toString(),
      };
    }
  }

  /// Returns a map with 'success', 'role', 'verificationStatus'
  Map<String, dynamic> login(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      return {'success': false, 'message': 'Email dan password wajib diisi'};
    }

    // Find user by email
    final userIndex = _registeredUsers.indexWhere(
      (u) => u.email == email.toLowerCase(),
    );

    if (userIndex == -1) {
      return {'success': false, 'message': 'Akun tidak ditemukan'};
    }

    final user = _registeredUsers[userIndex];

    // Check verification for warga
    if (user.role == UserRole.warga &&
        user.verificationStatus != VerificationStatus.verified) {
      _currentUser = user;
      notifyListeners();
      return {
        'success': true,
        'role': user.role,
        'verificationStatus': user.verificationStatus,
        'message': user.verificationStatus == VerificationStatus.pending
            ? 'Akun menunggu verifikasi RT'
            : 'Akun ditolak oleh RT',
      };
    }

    _currentUser = user;
    notifyListeners();
    return {
      'success': true,
      'role': user.role,
      'verificationStatus': user.verificationStatus,
    };
  }

  /// Register a new warga (pending verification)
  void registerWarga({
    required String name,
    required String email,
    required String password,
    required String registrationCode,
    required String phone,
    required String rtRw,
    required String address,
    String? ktpImagePath,
  }) {
    final newUser = AppUser(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email.toLowerCase(),
      role: UserRole.warga,
      avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=$name',
      verificationStatus: VerificationStatus.pending,
      registrationCode: registrationCode,
      ktpImagePath: ktpImagePath,
      phone: phone,
      rtRw: rtRw,
      address: address,
      registeredAt: DateTime.now(),
    );
    _registeredUsers.add(newUser);
    _currentUser = newUser;
    notifyListeners();
  }

  /// Register a new RT/RW admin (immediately verified)
  void registerRT({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String jabatan,
    required String rtRw,
  }) {
    final newUser = AppUser(
      id: 'admin-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email.toLowerCase(),
      role: UserRole.admin,
      avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=$name',
      verificationStatus: VerificationStatus.verified,
      phone: phone,
      jabatan: jabatan,
      rtRw: rtRw,
      registeredAt: DateTime.now(),
    );
    _registeredUsers.add(newUser);
    _currentUser = newUser;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void updateCurrentUser({
    String? name,
    String? avatarUrl,
    String? address,
    String? phone,
    String? password,
  }) {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      name: name,
      avatarUrl: avatarUrl,
      address: address,
      phone: phone,
    );

    _currentUser = updatedUser;

    final index = _registeredUsers.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _registeredUsers[index] = updatedUser;
    }

    notifyListeners();
  }

  // ============================================
  // Registration Code Management
  // ============================================

  /// Generate a random registration code like "RT05-XY7K"
  String generateRegistrationCode(String rtRw) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final rtPart = 'RT${rtRw.split('/').first.replaceAll(RegExp(r'^0+'), '')}';
    final randomPart = String.fromCharCodes(
      Iterable.generate(
        4,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    return '$rtPart-$randomPart';
  }

  /// Add a new registration code (manual or auto-generated)
  void addRegistrationCode({required String code, required String rtRw}) {
    if (_currentUser == null) return;

    final newCode = RegistrationCode(
      id: 'regcode-${DateTime.now().millisecondsSinceEpoch}',
      code: code.toUpperCase(),
      rtRw: rtRw,
      createdBy: _currentUser!.id,
      createdByName: _currentUser!.name,
      createdAt: DateTime.now(),
      isActive: true,
    );
    _registrationCodes.add(newCode);
    notifyListeners();

    _runRemote(() async {
      await _activeBackendService.createRegistrationCode(
        code: code,
        rtRw: rtRw,
        currentUser: _currentUser!,
      );
      await refreshRemoteData();
    });
  }

  /// Look up a registration code → returns the rtRw if found and active, null otherwise
  String? lookupRegistrationCode(String code) {
    final trimmed = code.trim().toUpperCase();
    final match = _registrationCodes.where(
      (rc) => rc.code.toUpperCase() == trimmed && rc.isActive,
    );
    if (match.isNotEmpty) {
      return match.first.rtRw;
    }
    return null;
  }

  /// Get all registration codes created by the current admin
  List<RegistrationCode> get myRegistrationCodes {
    if (_currentUser == null) return [];
    return _registrationCodes
        .where((rc) => rc.createdBy == _currentUser!.id)
        .toList();
  }

  /// Toggle active status of a registration code
  void toggleRegistrationCodeActive(String codeId) {
    final index = _registrationCodes.indexWhere((rc) => rc.id == codeId);
    if (index != -1) {
      final code = _registrationCodes[index];
      _registrationCodes[index] = code.copyWith(isActive: !code.isActive);
      notifyListeners();

      _runRemote(() async {
        await _activeBackendService.setRegistrationCodeActive(
          codeId: codeId,
          isActive: !code.isActive,
        );
        await refreshRemoteData();
      });
    }
  }

  /// Delete a registration code
  void deleteRegistrationCode(String codeId) {
    _registrationCodes.removeWhere((rc) => rc.id == codeId);
    notifyListeners();

    _runRemote(() async {
      await _activeBackendService.deleteRegistrationCode(codeId);
      await refreshRemoteData();
    });
  }

  // ============================================
  // RT/Admin - Warga Management Actions
  // ============================================

  void verifyWarga(String userId) {
    final index = _registeredUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _registeredUsers[index];
      _registeredUsers[index] = user.copyWith(
        verificationStatus: VerificationStatus.verified,
      );

      _activities.insert(
        0,
        AdminActivity(
          id: 'act-${DateTime.now().millisecondsSinceEpoch}',
          description: 'Memverifikasi warga baru: ${user.name}',
          type: 'verification',
          createdAt: DateTime.now(),
        ),
      );

      notifyListeners();

      _runRemote(() async {
        await _activeBackendService.setWargaVerification(
          userId: userId,
          status: VerificationStatus.verified,
          currentUser: _currentUser!,
          wargaName: user.name,
        );
        await refreshRemoteData();
      });
    }
  }

  void rejectWarga(String userId) {
    final index = _registeredUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _registeredUsers[index];
      _registeredUsers[index] = user.copyWith(
        verificationStatus: VerificationStatus.rejected,
      );

      _activities.insert(
        0,
        AdminActivity(
          id: 'act-${DateTime.now().millisecondsSinceEpoch}',
          description: 'Menolak pendaftaran warga: ${user.name}',
          type: 'verification',
          createdAt: DateTime.now(),
        ),
      );

      notifyListeners();

      _runRemote(() async {
        await _activeBackendService.setWargaVerification(
          userId: userId,
          status: VerificationStatus.rejected,
          currentUser: _currentUser!,
          wargaName: user.name,
        );
        await refreshRemoteData();
      });
    }
  }

  void removeWarga(String userId) {
    final index = _registeredUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _registeredUsers[index];
      _registeredUsers.removeAt(index);

      _activities.insert(
        0,
        AdminActivity(
          id: 'act-${DateTime.now().millisecondsSinceEpoch}',
          description: 'Mengeluarkan warga: ${user.name}',
          type: 'warga_removed',
          createdAt: DateTime.now(),
        ),
      );

      notifyListeners();

      _runRemote(() async {
        await _activeBackendService.removeWarga(
          userId: userId,
          currentUser: _currentUser!,
          wargaName: user.name,
        );
        await refreshRemoteData();
      });
    }
  }

  // ============================================
  // Citizen Actions
  // ============================================

  void addReport(
    String title,
    String description,
    String category,
    ReportPriority priority, {
    String? reportPhotoUrl,
    String? locationLabel,
  }) {
    if (_currentUser == null) return;

    final newReport = Report(
      id: 'rep-${DateTime.now().millisecondsSinceEpoch}',
      citizenName: _currentUser!.name,
      title: title,
      description: description,
      category: category,
      priority: priority,
      status: ReportStatus.submitted,
      createdAt: DateTime.now(),
      votesCount: 0,
      upvotedByUserIds: [],
      reportPhotoUrl: reportPhotoUrl,
      locationLabel: locationLabel,
    );

    _reports.insert(0, newReport);
    notifyListeners();

    _runRemote(() async {
      await _activeBackendService.createReport(
        currentUser: _currentUser!,
        title: title,
        description: description,
        category: category,
        priority: priority,
        reportPhotoUrl: reportPhotoUrl,
        locationLabel: locationLabel,
      );
      await refreshRemoteData();
    });
  }

  void upvoteReport(String reportId) {
    if (_currentUser == null) return;
    final userId = _currentUser!.id;

    int index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      Report report = _reports[index];
      List<String> upvotes = List.from(report.upvotedByUserIds);
      int votesCount = report.votesCount;

      if (upvotes.contains(userId)) {
        upvotes.remove(userId);
        votesCount--;
      } else {
        upvotes.add(userId);
        votesCount++;
      }

      _reports[index] = report.copyWith(
        upvotedByUserIds: upvotes,
        votesCount: votesCount,
      );
      notifyListeners();

      _runRemote(() async {
        await _activeBackendService.toggleReportUpvote(
          report: report,
          userId: userId,
        );
        await refreshRemoteData();
      });
    }
  }

  void voteInPoll(String pollId, String option) {
    if (_currentUser == null) return;
    final userId = _currentUser!.id;

    int index = _polls.indexWhere((p) => p.id == pollId);
    if (index != -1) {
      Poll poll = _polls[index];
      Map<String, int> votes = Map.from(poll.votes);
      Map<String, String> userVotes = Map.from(poll.userVotes);

      // If user already voted, remove old vote
      if (userVotes.containsKey(userId)) {
        String oldOption = userVotes[userId]!;
        votes[oldOption] = (votes[oldOption] ?? 1) - 1;
      }

      // Add new vote
      userVotes[userId] = option;
      votes[option] = (votes[option] ?? 0) + 1;

      _polls[index] = poll.copyWith(votes: votes, userVotes: userVotes);
      notifyListeners();

      _runRemote(() async {
        await _activeBackendService.voteInPoll(
          pollId: pollId,
          option: option,
          userId: userId,
        );
        await refreshRemoteData();
      });
    }
  }

  // ============================================
  // Admin Actions
  // ============================================

  void updateReportStatus(String reportId, ReportStatus status) {
    int index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _reports[index] = _reports[index].copyWith(status: status);
      notifyListeners();

      _runRemote(() async {
        await _activeBackendService.setReportStatus(reportId, status);
        await refreshRemoteData();
      });
    }
  }

  /// Complete a report with a photo proof
  void completeReport(String reportId, String photoUrl) {
    int index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final report = _reports[index];
      _reports[index] = report.copyWith(
        status: ReportStatus.resolved,
        completionPhotoUrl: photoUrl,
        completedAt: DateTime.now(),
        completedBy: _currentUser?.name ?? 'Admin',
      );

      _activities.insert(
        0,
        AdminActivity(
          id: 'act-${DateTime.now().millisecondsSinceEpoch}',
          description: 'Menyelesaikan laporan "${report.title}"',
          type: 'report_completed',
          createdAt: DateTime.now(),
          photoUrl: photoUrl,
          relatedId: reportId,
        ),
      );

      notifyListeners();

      if (_currentUser != null) {
        _runRemote(() async {
          await _activeBackendService.completeReport(
            reportId: reportId,
            photoUrl: photoUrl,
            currentUser: _currentUser!,
          );
          await refreshRemoteData();
        });
      }
    }
  }

  void addAnnouncement(String title, String content) {
    final author = _currentUser?.name ?? 'Admin';
    final newAnn = Announcement(
      id: 'ann-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: content,
      author: author,
      createdAt: DateTime.now(),
    );
    _announcements.insert(0, newAnn);

    _activities.insert(
      0,
      AdminActivity(
        id: 'act-${DateTime.now().millisecondsSinceEpoch}',
        description: 'Membuat pengumuman: $title',
        type: 'announcement',
        createdAt: DateTime.now(),
        relatedId: newAnn.id,
      ),
    );

    notifyListeners();

    if (_currentUser != null) {
      _runRemote(() async {
        await _activeBackendService.createAnnouncement(
          title: title,
          content: content,
          currentUser: _currentUser!,
        );
        await refreshRemoteData();
      });
    }
  }

  void addPoll(String question, List<String> options) {
    final Map<String, int> votes = {};
    for (var opt in options) {
      votes[opt] = 0;
    }

    final newPoll = Poll(
      id: 'poll-${DateTime.now().millisecondsSinceEpoch}',
      question: question,
      options: options,
      votes: votes,
      userVotes: {},
    );
    _polls.insert(0, newPoll);

    _activities.insert(
      0,
      AdminActivity(
        id: 'act-${DateTime.now().millisecondsSinceEpoch + 1}',
        description: 'Membuat voting: $question',
        type: 'poll',
        createdAt: DateTime.now(),
        relatedId: newPoll.id,
      ),
    );

    notifyListeners();

    if (_currentUser != null) {
      _runRemote(() async {
        await _activeBackendService.createPoll(
          question: question,
          options: options,
          currentUser: _currentUser!,
        );
        await refreshRemoteData();
      });
    }
  }
}
