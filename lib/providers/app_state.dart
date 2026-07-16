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
  final List<Report> _myReports = [];
  final List<Report> _adminReports = [];
  final List<Announcement> _announcements = [];
  final List<Poll> _polls = [];
  final List<AdminActivity> _activities = [];
  final List<RegistrationCode> _registrationCodes = [];
  RegistrationCodeLookupResult? _pendingRtRegistrationCode;
  final List<AppUser> _pendingVerificationUsers = [];
  final List<AppUser> _verifiedVerificationUsers = [];
  final List<AppUser> _rejectedVerificationUsers = [];
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
  List<Report> get myReports => List.unmodifiable(_myReports);
  List<Report> get adminReports => List.unmodifiable(_adminReports);
  List<Announcement> get announcements => List.unmodifiable(_announcements);
  List<Poll> get polls => List.unmodifiable(_polls);
  List<AppUser> get registeredUsers => List.unmodifiable(_registeredUsers);
  List<AdminActivity> get activities => List.unmodifiable(_activities);
  List<RegistrationCode> get registrationCodes =>
      List.unmodifiable(_registrationCodes);
  bool get reportsLoading => _reportsLoading;
  String? get reportsError => _reportsError;
  bool get announcementsLoading => _announcementsLoading;
  String? get announcementsError => _announcementsError;
  bool get pollsLoading => _pollsLoading;
  String? get pollsError => _pollsError;
  RegistrationCodeLookupResult? get pendingRtRegistrationCode =>
      _pendingRtRegistrationCode;

  // Warga queries
  List<AppUser> get allWarga => _verificationUsersLoaded
      ? List.unmodifiable([
          ..._pendingVerificationUsers,
          ..._verifiedVerificationUsers,
          ..._rejectedVerificationUsers,
        ])
      : const [];
  List<AppUser> get verifiedWarga => _verificationUsersLoaded
      ? List.unmodifiable(_verifiedVerificationUsers)
      : const [];
  List<AppUser> get pendingWarga => _verificationUsersLoaded
      ? List.unmodifiable(_pendingVerificationUsers)
      : const [];
  List<AppUser> get rejectedWarga => _verificationUsersLoaded
      ? List.unmodifiable(_rejectedVerificationUsers)
      : const [];

  // Completed reports with photos
  List<Report> get completedReportsWithPhotos => _reports
      .where(
        (r) =>
            r.status == ReportStatus.resolved && r.completionPhotoUrl != null,
      )
      .toList();

  bool _reportsLoading = false;
  String? _reportsError;
  bool _announcementsLoading = false;
  String? _announcementsError;
  bool _pollsLoading = false;
  String? _pollsError;

  void _setReports(List<Report> reports) {
    _reports
      ..clear()
      ..addAll(reports);
    _syncReportCacheForCurrentRole();
  }

  void _syncReportCacheForCurrentRole() {
    final target = switch (_currentUser?.role) {
      UserRole.admin => _adminReports,
      UserRole.warga => _myReports,
      null => null,
    };

    if (target == null) return;

    target
      ..clear()
      ..addAll(_reports);
  }

  void _setReportLoadState({required bool isLoading, String? error}) {
    _reportsLoading = isLoading;
    _reportsError = error;
  }

  void _clearReportState() {
    _reports.clear();
    _myReports.clear();
    _adminReports.clear();
    _reportsLoading = false;
    _reportsError = null;
  }

  void _setAnnouncementLoadState({required bool isLoading, String? error}) {
    _announcementsLoading = isLoading;
    _announcementsError = error;
  }

  void _setPollLoadState({required bool isLoading, String? error}) {
    _pollsLoading = isLoading;
    _pollsError = error;
  }

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

    // Mock Activities
    _activities.addAll([
      AdminActivity(
        id: 'act-1',
        description: 'Memverifikasi warga baru: Rian Hidayat',
        type: 'verification',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      AdminActivity(
        id: 'act-2',
        description: 'Membuat pengumuman',
        type: 'announcement',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AdminActivity(
        id: 'act-3',
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
    final currentRtRw = _currentUser?.rtRw?.trim() ?? '';
    debugPrint(
      '[AppState][verification] refreshVerificationUsers currentUserId=${_currentUser?.id ?? "null"} currentUserRole=${_currentUser?.role.name ?? "null"} currentUser.rtRw=${_currentUser?.rtRw ?? "null"} normalizedRtRw="$currentRtRw"',
    );
    if (currentRtRw.isEmpty) {
      _clearVerificationUsers();
      _verificationUsersLoaded = false;
      debugPrint(
        '[AppState][verification] refreshVerificationUsers skipped because rtRw is empty',
      );
      return;
    }

    try {
      final users = await _activeVerificationService.fetchAllWarga(
        rtRw: currentRtRw,
      );
      final pendingUsers = users
          .where(
            (user) => user.verificationStatus == VerificationStatus.pending,
          )
          .toList();
      final verifiedUsers = users
          .where(
            (user) => user.verificationStatus == VerificationStatus.verified,
          )
          .toList();
      final rejectedUsers = users
          .where(
            (user) => user.verificationStatus == VerificationStatus.rejected,
          )
          .toList();
      debugPrint(
        '[AppState][verification] refreshVerificationUsers received=${users.length} rtRws=${users.map((u) => u.rtRw ?? "-").toList()} pending=${pendingUsers.length} verified=${verifiedUsers.length} rejected=${rejectedUsers.length}',
      );
      _pendingVerificationUsers
        ..clear()
        ..addAll(pendingUsers);
      _verifiedVerificationUsers
        ..clear()
        ..addAll(verifiedUsers);
      _rejectedVerificationUsers
        ..clear()
        ..addAll(rejectedUsers);
      _verificationUsersLoaded = true;
      debugPrint(
        '[AppState][verification] refreshVerificationUsers loaded=$_verificationUsersLoaded sentToUI=${users.length}',
      );
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
        '[AppState][verification] refreshVerificationUsers error=${error.runtimeType}: $error',
      );
      debugPrint(stackTrace.toString());
      _clearVerificationUsers();
      _verificationUsersLoaded = false;
    }
  }

  Future<void> refreshRemoteData() async {
    if (!SupabaseService.isInitialized) return;

    try {
      final snapshot = await _activeBackendService.fetchSnapshot(
        rtRw: _currentUser?.rtRw,
      );
      _replaceWithSnapshot(snapshot);
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> refreshAnnouncements() async {
    if (!SupabaseService.isInitialized) {
      _setAnnouncementLoadState(isLoading: false, error: null);
      notifyListeners();
      return;
    }

    final currentRtRw = _currentUser?.rtRw?.trim() ?? '';
    if (currentRtRw.isEmpty) {
      _setAnnouncementLoadState(isLoading: false, error: null);
      notifyListeners();
      return;
    }

    _setAnnouncementLoadState(isLoading: true, error: null);
    notifyListeners();

    try {
      final announcements = await _activeBackendService.fetchAnnouncements(
        rtRw: currentRtRw,
      );
      _announcements
        ..clear()
        ..addAll(announcements);
      _setAnnouncementLoadState(isLoading: false, error: null);
    } catch (error, stackTrace) {
      debugPrint(
        '[AppState][announcement] refreshAnnouncements error=${error.runtimeType}: $error',
      );
      debugPrint(stackTrace.toString());
      _announcements.clear();
      _setAnnouncementLoadState(
        isLoading: false,
        error: 'Gagal memuat pengumuman.',
      );
      rethrow;
    }

    notifyListeners();
  }

  Future<void> refreshPolls() async {
    if (!SupabaseService.isInitialized) {
      _polls.clear();
      _setPollLoadState(isLoading: false, error: null);
      notifyListeners();
      return;
    }

    final currentRtRw = _currentUser?.rtRw?.trim() ?? '';
    if (currentRtRw.isEmpty) {
      _polls.clear();
      _setPollLoadState(isLoading: false, error: null);
      notifyListeners();
      return;
    }

    _setPollLoadState(isLoading: true, error: null);
    notifyListeners();

    try {
      final polls = await _activeBackendService.fetchPolls();
      _polls
        ..clear()
        ..addAll(polls);
    } catch (error, stackTrace) {
      debugPrint(
        '[AppState][poll] refreshPolls error=${error.runtimeType}: $error',
      );
      debugPrint(stackTrace.toString());
      _polls.clear();
      _setPollLoadState(isLoading: false, error: 'Gagal memuat voting.');
      rethrow;
    } finally {
      _setPollLoadState(isLoading: false, error: _pollsError);
      notifyListeners();
    }
  }

  void _replaceWithSnapshot(BackendSnapshot snapshot) {
    _registeredUsers
      ..clear()
      ..addAll(snapshot.users);
    _announcements
      ..clear()
      ..addAll(snapshot.announcements);
    _setAnnouncementLoadState(isLoading: false, error: null);
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

  Future<void> refreshMyReports() async {
    if (_currentUser == null || _currentUser!.role != UserRole.warga) {
      _myReports.clear();
      _setReports(const []);
      _setReportLoadState(isLoading: false, error: null);
      notifyListeners();
      return;
    }

    if (!SupabaseService.isInitialized) {
      _myReports.clear();
      _setReports(const []);
      _setReportLoadState(isLoading: false, error: null);
      notifyListeners();
      return;
    }

    _setReportLoadState(isLoading: true, error: null);
    notifyListeners();

    try {
      final reports = await _activeBackendService.fetchReportsForCurrentUser(
        _currentUser!.id,
      );
      _myReports
        ..clear()
        ..addAll(reports);
      _setReports(reports);
      _setReportLoadState(isLoading: false, error: null);
    } catch (e, st) {
      debugPrint('REPORT ERROR: ${e.runtimeType}');
      debugPrint(e.toString());
      debugPrint(st.toString());
      _myReports.clear();
      _setReports(const []);
      _setReportLoadState(
        isLoading: false,
        error: 'Gagal memuat laporan warga.',
      );
      rethrow;
    }

    notifyListeners();
  }

  Future<void> refreshAdminReports() async {
    final rtRw = _currentUser?.rtRw?.trim() ?? '';
    if (_currentUser == null || _currentUser!.role != UserRole.admin) {
      _adminReports.clear();
      _setReports(const []);
      _setReportLoadState(isLoading: false, error: null);
      notifyListeners();
      return;
    }

    if (!SupabaseService.isInitialized || rtRw.isEmpty) {
      _adminReports.clear();
      _setReports(const []);
      _setReportLoadState(isLoading: false, error: null);
      notifyListeners();
      return;
    }

    _setReportLoadState(isLoading: true, error: null);
    notifyListeners();

    try {
      final reports = await _activeBackendService.fetchReportsForAdminRtRw(
        rtRw,
      );
      _adminReports
        ..clear()
        ..addAll(reports);
      _setReports(reports);
      _setReportLoadState(isLoading: false, error: null);
    } catch (_) {
      _adminReports.clear();
      _setReports(const []);
      _setReportLoadState(
        isLoading: false,
        error: 'Gagal memuat laporan admin.',
      );
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

  void _logRegistrationLookup(String message) {
    debugPrint('[AppState][registration_codes] $message');
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
      debugPrint(
        '[AppState][verification] loginWithSupabase currentUser.rtRw=${_currentUser?.rtRw ?? "null"}',
      );
      await refreshRemoteData();
      await refreshAnnouncements();
      if (user.role == UserRole.admin) {
        await refreshAdminReports();
      } else {
        await refreshMyReports();
      }
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
      debugPrint(
        '[AppState][verification] restoreSession currentUser.rtRw=${_currentUser?.rtRw ?? "null"}',
      );
      await refreshRemoteData();
      await refreshAnnouncements();
      if (user.role == UserRole.admin) {
        await refreshAdminReports();
      } else {
        await refreshMyReports();
      }
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
    _clearVerificationUsers();
    _clearReportState();
    _announcements.clear();
    _setAnnouncementLoadState(isLoading: false, error: null);
    _verificationUsersLoaded = false;
    _pendingRtRegistrationCode = null;
    notifyListeners();
  }

  void _clearVerificationUsers() {
    _pendingVerificationUsers.clear();
    _verifiedVerificationUsers.clear();
    _rejectedVerificationUsers.clear();
  }

  Future<String?> lookupRegistrationCodeRemote(String code) async {
    if (code.trim().isEmpty) return null;

    if (!SupabaseService.isInitialized) {
      return null;
    }

    try {
      final rtRw = await _activeAuthService.lookupActiveRegistrationCodeRtRw(
        code,
      );
      _logRegistrationLookup(
        'lookupRegistrationCodeRemote input="$code" result=${rtRw ?? "null"}',
      );
      return rtRw;
    } catch (error, stackTrace) {
      _logRegistrationLookup(
        'lookupRegistrationCodeRemote error=${error.runtimeType}: $error',
      );
      _logRegistrationLookup(stackTrace.toString());
      return null;
    }
  }

  Future<RegistrationCodeLookupResult?> lookupRtRegistrationCodeRemote(
    String code,
  ) async {
    _logRegistrationLookup(
      'lookupRtRegistrationCodeRemote input="$code" initialized=${SupabaseService.isInitialized}',
    );
    if (code.trim().isEmpty) {
      _pendingRtRegistrationCode = null;
      notifyListeners();
      _logRegistrationLookup(
        'lookupRtRegistrationCodeRemote returning null: empty input',
      );
      return null;
    }

    if (!SupabaseService.isInitialized) {
      _pendingRtRegistrationCode = null;
      notifyListeners();
      _logRegistrationLookup(
        'lookupRtRegistrationCodeRemote returning null: Supabase not initialized',
      );
      return null;
    }

    try {
      _logRegistrationLookup('CALL AppState lookup input="$code"');
      final lookup = await _activeAuthService.lookupActiveAdminRegistrationCode(
        code,
      );
      _pendingRtRegistrationCode = lookup;
      notifyListeners();
      _logRegistrationLookup(
        'lookupRtRegistrationCodeRemote result=${lookup == null ? "null" : "${lookup.code} rt=${lookup.rt} rw=${lookup.rw} type=${lookup.registrationType.name}"}',
      );
      return lookup;
    } catch (error, stackTrace) {
      _pendingRtRegistrationCode = null;
      notifyListeners();
      _logRegistrationLookup(
        'lookupRtRegistrationCodeRemote error=${error.runtimeType}: $error',
      );
      _logRegistrationLookup(stackTrace.toString());
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
      debugPrint('registerRTWithSupabase error: $error');
      return {
        'success': false,
        'message': error.toString(),
        'debugMessage': error.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> registerRTWithSupabase({
    required String name,
    required String email,
    required String password,
    required String registrationCode,
    required String phone,
    required String jabatan,
  }) async {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty ||
        registrationCode.trim().isEmpty ||
        phone.trim().isEmpty ||
        jabatan.trim().isEmpty) {
      return {'success': false, 'message': 'Semua data registrasi wajib diisi'};
    }

    if (!SupabaseService.isInitialized) {
      return {'success': false, 'message': 'Konfigurasi Supabase belum aktif'};
    }

    try {
      final user = await _activeAuthService.registerRTWithSupabase(
        name: name,
        email: email,
        password: password,
        registrationCode: registrationCode,
        phone: phone,
        jabatan: jabatan,
      );
      _setCurrentUser(user);

      if (user.rtRw == null || user.rtRw!.trim().isEmpty) {
        return {
          'success': false,
          'message':
              'Registrasi RT berhasil, tetapi RT/RW tidak tersedia untuk generate kode warga.',
        };
      }

      final generatedWargaCode = await _activeBackendService
          .createOrGetWargaRegistrationCode(
            currentUser: user,
            rtRw: user.rtRw!,
          );

      await _activeAuthService.markRegistrationCodeAsUsed(registrationCode);

      try {
        await refreshRemoteData();
        if (user.role == UserRole.admin) {
          await refreshVerificationUsers();
        }
      } catch (error, stackTrace) {
        debugPrint('refresh after RT registration failed: $error');
        debugPrint(stackTrace.toString());
      }

      _pendingRtRegistrationCode = null;
      notifyListeners();

      return {
        'success': true,
        'role': user.role,
        'verificationStatus': user.verificationStatus,
        'rtRw': user.rtRw,
        'wargaRegistrationCode': generatedWargaCode.code,
        'wargaRegistrationType': generatedWargaCode.registrationType,
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

  Future<Map<String, dynamic>> generateWargaRegistrationCodeForRt(
    String rtRw,
  ) async {
    if (rtRw.trim().isEmpty) {
      return {'success': false, 'message': 'Nomor RT/RW wajib diisi'};
    }

    try {
      final generatedCode = _activeBackendService.generateWargaRegistrationCode(
        rtRw,
      );
      return {
        'success': true,
        'code': generatedCode,
        'registrationType': RegistrationCodeType.warga,
        'rtRw': rtRw,
      };
    } on BackendServiceException catch (error) {
      return {'success': false, 'message': error.message};
    } catch (error) {
      return {
        'success': false,
        'message': 'Gagal membuat kode daftar warga.',
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

  (String, String) _splitRtRw(String rtRw) {
    final parts = rtRw.split('/');
    final rt = parts.isNotEmpty ? parts.first.trim() : '';
    final rw = parts.length > 1 ? parts[1].trim() : '';
    return (rt, rw);
  }

  /// Add a new registration code (manual or auto-generated)
  void addRegistrationCode({required String code, required String rtRw}) {
    if (_currentUser == null) return;

    final splitRtRw = _splitRtRw(rtRw);
    final newCode = RegistrationCode(
      id: 'regcode-${DateTime.now().millisecondsSinceEpoch}',
      code: code.toUpperCase(),
      rtRw: rtRw,
      rt: splitRtRw.$1,
      rw: splitRtRw.$2,
      createdBy: _currentUser!.id,
      createdByName: _currentUser!.name,
      registrationType: RegistrationCodeType.warga,
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
        registrationType: RegistrationCodeType.warga,
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

  Future<void> addReport(
    String title,
    String description,
    String category,
    ReportPriority priority, {
    Uint8List? reportPhotoBytes,
    String? reportPhotoName,
    String? reportPhotoUrl,
    String? locationLabel,
  }) async {
    if (_currentUser == null) return;

    if (SupabaseService.isInitialized) {
      final createdReport = await _activeBackendService.createReport(
        currentUser: _currentUser!,
        title: title,
        description: description,
        category: category,
        priority: priority,
        reportPhotoBytes: reportPhotoBytes,
        reportPhotoName: reportPhotoName,
        reportPhotoUrl: reportPhotoUrl,
        locationLabel: locationLabel,
      );

      _reports.insert(0, createdReport);
      _syncReportCacheForCurrentRole();
      notifyListeners();
      return;
    }

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
    _syncReportCacheForCurrentRole();
    notifyListeners();
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
      _syncReportCacheForCurrentRole();
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
    unawaited(submitVote(pollId: pollId, optionLabel: option));
  }

  Future<void> submitVote({
    required String pollId,
    required String optionLabel,
  }) async {
    final currentUser = _currentUser;
    if (currentUser == null) return;

    final pollIndex = _polls.indexWhere((poll) => poll.id == pollId);
    if (pollIndex == -1) return;

    final poll = _polls[pollIndex];
    final userId = currentUser.id;
    final alreadyVotedLocally = poll.userVotes.containsKey(userId);
    final optionIndex = poll.options.indexOf(optionLabel);
    if (optionIndex == -1) return;

    if (!SupabaseService.isInitialized) {
      if (alreadyVotedLocally) return;

      final votes = Map<String, int>.from(poll.votes);
      final userVotes = Map<String, String>.from(poll.userVotes);
      votes[optionLabel] = (votes[optionLabel] ?? 0) + 1;
      userVotes[userId] = optionLabel;

      _polls[pollIndex] = poll.copyWith(votes: votes, userVotes: userVotes);
      notifyListeners();
      return;
    }

    final optionId = poll.optionIdForLabel(optionLabel);
    if (optionId == null) {
      return;
    }

    if (alreadyVotedLocally) {
      return;
    }

    try {
      final alreadyVoted = await _activeBackendService.hasUserVoted(
        pollId: pollId,
        userId: userId,
      );
      if (alreadyVoted) {
        return;
      }

      await _activeBackendService.submitVote(
        pollId: pollId,
        optionId: optionId,
        userId: userId,
      );

      _polls[pollIndex] = poll.copyWith(
        userVotes: Map<String, String>.from(poll.userVotes)
          ..[userId] = optionLabel,
      );
      notifyListeners();
      await refreshPolls();
    } catch (error, stackTrace) {
      debugPrint(
        '[AppState][poll] submitVote error=${error.runtimeType}: $error',
      );
      debugPrint(stackTrace.toString());
    }
  }

  // ============================================
  // Admin Actions
  // ============================================

  void updateReportStatus(String reportId, ReportStatus status) {
    int index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _reports[index] = _reports[index].copyWith(status: status);
      _syncReportCacheForCurrentRole();
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
        completedById: _currentUser?.id,
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

      _syncReportCacheForCurrentRole();
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
    unawaited(createAnnouncement(title: title, content: content));
  }

  Future<void> createAnnouncement({
    required String title,
    required String content,
  }) async {
    final currentUser = _currentUser;
    if (currentUser == null || currentUser.role != UserRole.admin) {
      return;
    }

    final now = DateTime.now();
    final localAnnouncement = Announcement(
      id: 'ann-${now.microsecondsSinceEpoch}',
      title: title,
      content: content,
      authorId: currentUser.id,
      authorName: currentUser.name,
      rtRw: currentUser.rtRw ?? '',
      createdAt: now,
      updatedAt: now,
    );

    _announcements.insert(0, localAnnouncement);
    _activities.insert(
      0,
      AdminActivity(
        id: 'act-${now.microsecondsSinceEpoch}',
        description: 'Membuat pengumuman: $title',
        type: 'announcement',
        createdAt: now,
        relatedId: localAnnouncement.id,
      ),
    );
    notifyListeners();

    if (!SupabaseService.isInitialized) {
      return;
    }

    try {
      await _activeBackendService.createAnnouncement(
        title: title,
        content: content,
        currentUser: currentUser,
      );
      await refreshRemoteData();
    } catch (error, stackTrace) {
      debugPrint(
        '[AppState][announcement] createAnnouncement error=${error.runtimeType}: $error',
      );
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String content,
  }) async {
    final currentUser = _currentUser;
    if (currentUser == null || currentUser.role != UserRole.admin) {
      return;
    }

    final index = _announcements.indexWhere(
      (announcement) => announcement.id == id,
    );
    if (index == -1) return;

    final now = DateTime.now();
    _announcements[index] = _announcements[index].copyWith(
      title: title,
      content: content,
      updatedAt: now,
    );
    notifyListeners();

    if (!SupabaseService.isInitialized) {
      return;
    }

    try {
      await _activeBackendService.updateAnnouncement(
        id: id,
        title: title,
        content: content,
      );
      await refreshRemoteData();
    } catch (error, stackTrace) {
      debugPrint(
        '[AppState][announcement] updateAnnouncement error=${error.runtimeType}: $error',
      );
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    final currentUser = _currentUser;
    if (currentUser == null || currentUser.role != UserRole.admin) {
      return;
    }

    final index = _announcements.indexWhere(
      (announcement) => announcement.id == id,
    );
    if (index == -1) return;

    final removedAnnouncement = _announcements.removeAt(index);
    notifyListeners();

    if (!SupabaseService.isInitialized) {
      return;
    }

    try {
      await _activeBackendService.deleteAnnouncement(id);
      await refreshRemoteData();
    } catch (error, stackTrace) {
      debugPrint(
        '[AppState][announcement] deleteAnnouncement error=${error.runtimeType}: $error',
      );
      debugPrint(stackTrace.toString());
      _announcements.insert(index, removedAnnouncement);
      notifyListeners();
    }
  }

  void addPoll(String question, List<String> options) {
    unawaited(createPoll(question: question, options: options));
  }

  Future<void> createPoll({
    required String question,
    required List<String> options,
  }) async {
    final currentUser = _currentUser;
    if (currentUser == null || currentUser.role != UserRole.admin) {
      return;
    }

    final normalizedQuestion = question.trim();
    final normalizedOptions = options
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList();
    if (normalizedQuestion.isEmpty || normalizedOptions.length < 2) {
      return;
    }

    final now = DateTime.now();
    final tempOptionIds = List<String>.generate(
      normalizedOptions.length,
      (index) => 'temp-option-${now.microsecondsSinceEpoch}-$index',
    );
    final newPoll = Poll(
      id: 'poll-${now.microsecondsSinceEpoch}',
      question: normalizedQuestion,
      options: normalizedOptions,
      optionIds: tempOptionIds,
      votes: {for (final opt in normalizedOptions) opt: 0},
      userVotes: {},
      isActive: true,
    );
    _polls.insert(0, newPoll);

    _activities.insert(
      0,
      AdminActivity(
        id: 'act-${now.microsecondsSinceEpoch + 1}',
        description: 'Membuat voting: $normalizedQuestion',
        type: 'poll',
        createdAt: now,
        relatedId: newPoll.id,
      ),
    );

    notifyListeners();

    if (!SupabaseService.isInitialized) {
      return;
    }

    try {
      await _activeBackendService.createPoll(
        question: normalizedQuestion,
        options: normalizedOptions,
        currentUser: currentUser,
      );
      await refreshRemoteData();
    } catch (error, stackTrace) {
      debugPrint(
        '[AppState][poll] createPoll error=${error.runtimeType}: $error',
      );
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> updatePoll({
    required String pollId,
    required String question,
    required bool isActive,
    required List<String> options,
  }) async {
    final currentUser = _currentUser;
    if (currentUser == null || currentUser.role != UserRole.admin) {
      return;
    }

    final index = _polls.indexWhere((poll) => poll.id == pollId);
    if (index == -1) return;

    final normalizedQuestion = question.trim();
    final normalizedOptions = options
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList();
    if (normalizedQuestion.isEmpty || normalizedOptions.length < 2) {
      return;
    }

    final poll = _polls[index];
    _polls[index] = poll.copyWith(
      question: normalizedQuestion,
      options: normalizedOptions,
      isActive: isActive,
    );
    notifyListeners();

    if (!SupabaseService.isInitialized) {
      return;
    }

    try {
      await _activeBackendService.updatePoll(
        pollId: pollId,
        question: normalizedQuestion,
        isActive: isActive,
        options: normalizedOptions,
      );
      await refreshPolls();
    } catch (error, stackTrace) {
      debugPrint(
        '[AppState][poll] updatePoll error=${error.runtimeType}: $error',
      );
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> deletePoll(String pollId) async {
    final currentUser = _currentUser;
    if (currentUser == null || currentUser.role != UserRole.admin) {
      return;
    }

    final index = _polls.indexWhere((poll) => poll.id == pollId);
    if (index == -1) return;

    final removedPoll = _polls.removeAt(index);
    notifyListeners();

    if (!SupabaseService.isInitialized) {
      return;
    }

    try {
      await _activeBackendService.deletePoll(pollId);
      await refreshRemoteData();
    } catch (error, stackTrace) {
      debugPrint(
        '[AppState][poll] deletePoll error=${error.runtimeType}: $error',
      );
      debugPrint(stackTrace.toString());
      _polls.insert(index, removedPoll);
      notifyListeners();
    }
  }
}
