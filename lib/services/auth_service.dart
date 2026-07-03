import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'supabase_service.dart';

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;
  static const String _ktpBucket = 'ktp-images';
  static const String _emailRateLimitMessage =
      'Terlalu banyak percobaan registrasi. Silakan tunggu beberapa saat lalu coba lagi.';
  static const String _emailAlreadyRegisteredMessage =
      'Email ini sudah terdaftar. Silakan masuk atau gunakan email lain.';
  static final RegExp _rtRegistrationCodePattern = RegExp(
    r'^RT(\d{2})-(\d{2})$',
    caseSensitive: false,
  );
  static final RegExp _emailPattern = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");

  Session? get currentSession => _client.auth.currentSession;

  Future<AppUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: _normalizeEmail(email),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthServiceException('Login gagal. User tidak ditemukan.');
      }

      return getProfileByUserId(user.id);
    } on AuthException catch (error) {
      throw AuthServiceException(error.message);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<String?> lookupActiveRegistrationCodeRtRw(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    _logRegistrationLookup(
      'lookupActiveRegistrationCodeRtRw input="$code" normalized="$normalizedCode"',
    );
    if (normalizedCode.isEmpty) return null;

    final lookup = await _lookupRegistrationCode(
      normalizedCode,
      registrationType: RegistrationCodeType.warga,
    );
    _logRegistrationLookup(
      'lookupActiveRegistrationCodeRtRw result=${lookup == null ? "null" : lookup.rtRw}',
    );
    return lookup?.rtRw;
  }

  Future<RegistrationCodeLookupResult?> lookupActiveAdminRegistrationCode(
    String code,
  ) async {
    final normalizedCode = code.trim().toUpperCase();
    debugPrint(
      'CALL AuthService lookup input="$code" normalized="$normalizedCode"',
    );
    _logRegistrationLookup(
      'lookupActiveAdminRegistrationCode input="$code" normalized="$normalizedCode"',
    );
    if (normalizedCode.isEmpty) return null;

    final patternMatch = _rtRegistrationCodePattern.hasMatch(normalizedCode);
    _logRegistrationLookup(
      'lookupActiveAdminRegistrationCode patternMatch=$patternMatch pattern=${_rtRegistrationCodePattern.pattern}',
    );
    if (!patternMatch) {
      _logRegistrationLookup(
        'lookupActiveAdminRegistrationCode returning null: code format mismatch',
      );
      return null;
    }

    final lookup = await _lookupRegistrationCode(
      normalizedCode,
      registrationType: RegistrationCodeType.admin,
    );
    _logRegistrationLookup(
      'lookupActiveAdminRegistrationCode result=${lookup == null ? "null" : lookup.code}',
    );
    return lookup;
  }

  Future<String> uploadKtpImage({
    required Uint8List imageBytes,
    required String sourceName,
    required String storagePrefix,
  }) async {
    if (imageBytes.isEmpty) {
      throw const AuthServiceException('File KTP tidak valid.');
    }

    final extension = _extractFileExtension(sourceName);
    final sanitizedPrefix = _normalizeStoragePrefix(storagePrefix);
    final storagePath =
        '$sanitizedPrefix/${DateTime.now().millisecondsSinceEpoch}$extension';

    await _client.storage
        .from(_ktpBucket)
        .uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return storagePath;
  }

  Future<AppUser> registerWargaWithSupabase({
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
    final normalizedEmail = _normalizeEmail(email);
    final normalizedName = name.trim();
    final normalizedCode = registrationCode.trim().toUpperCase();
    final normalizedKtpNumber = ktpNumber.trim();
    final normalizedPhone = phone.trim();
    final normalizedAddress = address.trim();

    try {
      if (!_emailPattern.hasMatch(normalizedEmail)) {
        throw const AuthServiceException(
          'Format email tidak valid. Periksa kembali alamat email Anda.',
        );
      }

      final rtRw = await lookupActiveRegistrationCodeRtRw(normalizedCode);
      if (rtRw == null) {
        throw const AuthServiceException(
          'Kode registrasi tidak ditemukan atau tidak aktif.',
        );
      }

      final authResponse = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'name': normalizedName,
          'role': 'warga',
          'phone': normalizedPhone,
          'rt_rw': rtRw,
          'address': normalizedAddress,
          'registration_code': normalizedCode,
        },
      );

      final authUser = authResponse.user;
      if (authUser == null) {
        throw const AuthServiceException(
          'Registrasi gagal. User tidak terbentuk.',
        );
      }

      if (authResponse.session == null && _client.auth.currentSession == null) {
        throw const AuthServiceException(
          'Akun sudah dibuat, tetapi email confirmation aktif sehingga sesi belum tersedia. '
          'Untuk registrasi warga yang menyimpan foto KTP dan profil ke Supabase, nonaktifkan email confirmation '
          'atau gunakan trigger database untuk membuat profil setelah email terverifikasi.',
        );
      }

      final uploadedKtpPath = await uploadKtpImage(
        imageBytes: ktpImageBytes,
        sourceName: ktpImageName,
        storagePrefix: 'registrations/${authUser.id}',
      );

      final nowIso = DateTime.now().toUtc().toIso8601String();
      await _client.from('profiles').upsert({
        'id': authUser.id,
        'name': normalizedName,
        'email': normalizedEmail,
        'role': 'warga',
        'avatar_url':
            'https://api.dicebear.com/7.x/adventurer/svg?seed=$normalizedName',
        'verification_status': 'pending',
        'ktp_number': normalizedKtpNumber,
        'registration_code': normalizedCode,
        'ktp_image_path': uploadedKtpPath,
        'phone': normalizedPhone,
        'rt_rw': rtRw,
        'address': normalizedAddress,
        'registered_at': nowIso,
        'created_at': nowIso,
        'updated_at': nowIso,
      }, onConflict: 'id');

      return getProfileByUserId(authUser.id);
    } on AuthException catch (error) {
      throw AuthServiceException(_mapAuthErrorMessage(error.toString()));
    } catch (error) {
      throw AuthServiceException(
        _mapRegistrationErrorMessage(error.toString()),
      );
    }
  }

  Future<AppUser> registerRTWithSupabase({
    required String name,
    required String email,
    required String password,
    required String registrationCode,
    required String phone,
    required String jabatan,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final normalizedName = name.trim();
    final normalizedCode = registrationCode.trim().toUpperCase();
    final normalizedPhone = phone.trim();
    final normalizedJabatan = jabatan.trim();

    try {
      if (!_emailPattern.hasMatch(normalizedEmail)) {
        throw const AuthServiceException(
          'Format email tidak valid. Periksa kembali alamat email Anda.',
        );
      }

      if (!_rtRegistrationCodePattern.hasMatch(normalizedCode)) {
        throw const AuthServiceException(
          'Format kode registrasi RT tidak valid. Gunakan format RT01-01.',
        );
      }

      final codeLookup = await lookupActiveAdminRegistrationCode(
        normalizedCode,
      );
      _logRegistrationLookup(
        'registerRTWithSupabase codeLookup=${codeLookup == null ? "null" : "${codeLookup.code} rt=${codeLookup.rt} rw=${codeLookup.rw} type=${codeLookup.registrationType.name} active=${codeLookup.isActive}"}',
      );
      if (codeLookup == null) {
        throw const AuthServiceException(
          'Kode registrasi RT tidak ditemukan, tidak valid, atau sudah digunakan.',
        );
      }

      if (codeLookup.rt.isEmpty || codeLookup.rw.isEmpty) {
        throw const AuthServiceException(
          'Kode registrasi RT tidak memiliki data RT/RW yang lengkap.',
        );
      }

      final rtRw = codeLookup.rtRw.isEmpty
          ? '${codeLookup.rt}/${codeLookup.rw}'
          : codeLookup.rtRw;

      final authResponse = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'name': normalizedName,
          'role': 'admin',
          'phone': normalizedPhone,
          'jabatan': normalizedJabatan,
          'rt_rw': rtRw,
          'rt': codeLookup.rt,
          'rw': codeLookup.rw,
          'registration_code': normalizedCode,
          'registration_type': 'admin',
        },
      );

      final authUser = authResponse.user;
      if (authUser == null) {
        throw const AuthServiceException(
          'Registrasi gagal. User tidak terbentuk.',
        );
      }

      if (authResponse.session == null && _client.auth.currentSession == null) {
        throw const AuthServiceException(
          'Akun sudah dibuat, tetapi email confirmation aktif sehingga sesi belum tersedia. '
          'Registrasi RT membutuhkan sesi login untuk menandai kode registrasi sebagai terpakai.',
        );
      }

      final nowIso = DateTime.now().toUtc().toIso8601String();
      final profilePayload = {
        'id': authUser.id,
        'name': normalizedName,
        'email': normalizedEmail,
        'role': 'admin',
        'avatar_url':
            'https://api.dicebear.com/7.x/adventurer/svg?seed=$normalizedName',
        'verification_status': 'verified',
        'ktp_number': null,
        'registration_code': normalizedCode,
        'ktp_image_path': null,
        'phone': normalizedPhone,
        'rt_rw': rtRw,
        'address': null,
        'jabatan': normalizedJabatan,
        'registered_at': nowIso,
        'created_at': nowIso,
        'updated_at': nowIso,
      };
      _logRegistrationLookup(
        'registerRTWithSupabase profilePayload=$profilePayload',
      );

      final profileData = await _client
          .from('profiles')
          .upsert(profilePayload, onConflict: 'id')
          .select(
            'id, name, email, role, avatar_url, verification_status, ktp_number, registration_code, ktp_image_path, phone, rt_rw, address, jabatan, registered_at, created_at, updated_at',
          )
          .single();

      _logRegistrationLookup(
        'registerRTWithSupabase profileUpsertResult=${profileData.toString()}',
      );
      final profile = AppUser.fromProfileRow(
        Map<String, dynamic>.from(profileData),
      );
      _logRegistrationLookup(
        'registerRTWithSupabase created profile id=${profile.id} rtRw=${profile.rtRw} role=${profile.role.name}',
      );

      return profile;
    } on AuthException catch (error) {
      debugPrint('registerRTWithSupabase AuthException: ${error.toString()}');
      throw AuthServiceException(_mapAuthErrorMessage(error.toString()));
    } on PostgrestException catch (error) {
      debugPrint(
        'registerRTWithSupabase PostgrestException: message=${error.message} details=${error.details} hint=${error.hint} code=${error.code}',
      );
      rethrow;
    } catch (error) {
      debugPrint('registerRTWithSupabase error: $error');
      rethrow;
    }
  }

  Future<void> markRegistrationCodeAsUsed(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw const AuthServiceException('Kode registrasi RT wajib diisi.');
    }

    _logRegistrationLookup(
      'markRegistrationCodeAsUsed input="$code" normalized="$normalizedCode"',
    );

    try {
      await _client
          .from('registration_codes')
          .update({
            'is_active': false,
            'used_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('code', normalizedCode)
          .eq('registration_type', 'admin')
          .eq('is_active', true);

      _logRegistrationLookup(
        'markRegistrationCodeAsUsed marked code as used code=$normalizedCode',
      );
    } catch (error, stackTrace) {
      _logRegistrationLookup(
        'markRegistrationCodeAsUsed error=${error.runtimeType}: $error',
      );
      _logRegistrationLookup(stackTrace.toString());
      rethrow;
    }
  }

  String _mapRegistrationErrorMessage(String rawMessage) {
    final normalized = rawMessage.toLowerCase();

    if (normalized.contains('format kode registrasi rt tidak valid')) {
      return 'Format kode registrasi RT tidak valid. Gunakan format RT01-01.';
    }

    if (normalized.contains('kode registrasi rt tidak ditemukan') ||
        normalized.contains('kode registrasi rt tidak memiliki data rt/rw')) {
      return rawMessage;
    }

    if (normalized.contains('row-level security') ||
        normalized.contains('rls') ||
        normalized.contains('permission denied')) {
      return 'Supabase menolak akses saat menyimpan data registrasi. Periksa RLS policy pada tabel profiles dan bucket ktp-images.';
    }

    if (normalized.contains('relation "profiles" does not exist') ||
        normalized.contains('table "profiles" does not exist')) {
      return 'Tabel profiles belum ada di Supabase.';
    }

    if (normalized.contains('bucket not found') ||
        (normalized.contains('ktp-images') &&
            normalized.contains('not found'))) {
      return 'Bucket storage ktp-images belum ada di Supabase.';
    }

    if (normalized.contains('session') &&
        normalized.contains('null') &&
        normalized.contains('email confirmation')) {
      return 'Email confirmation aktif. Registrasi warga butuh sesi login untuk mengupload KTP dan menyimpan profil.';
    }

    if (normalized.contains('user already registered')) {
      return _emailAlreadyRegisteredMessage;
    }

    return 'Registrasi gagal. Silakan coba lagi.';
  }

  Future<AppUser?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return getProfileByUserId(user.id);
  }

  Future<AppUser> getProfileByUserId(String userId) async {
    final data = await _client
        .from('profiles')
        .select(
          'id, name, email, role, avatar_url, verification_status, ktp_number, registration_code, ktp_image_path, phone, rt_rw, address, jabatan, registered_at, created_at, updated_at',
        )
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      throw const AuthServiceException('Profil user tidak ditemukan.');
    }

    return AppUser.fromProfileRow(Map<String, dynamic>.from(data));
  }

  String _extractFileExtension(String filePath) {
    final index = filePath.lastIndexOf('.');
    if (index == -1 || index == filePath.length - 1) {
      return '.jpg';
    }
    return filePath.substring(index).toLowerCase();
  }

  String _normalizeStoragePrefix(String value) {
    final normalized = value.trim().replaceAll('\\', '/');
    final cleaned = normalized.replaceAll(RegExp(r'[^a-zA-Z0-9/_-]+'), '_');
    return cleaned
        .replaceAll(RegExp(r'/+'), '/')
        .replaceAll(RegExp(r'^/+|/+$'), '');
  }

  String _mapAuthErrorMessage(String rawMessage) {
    final normalized = rawMessage.toLowerCase();

    if (normalized.contains('over_email_send_rate_limit') ||
        normalized.contains('email rate limit exceeded') ||
        normalized.contains('statuscode: 429') ||
        normalized.contains('status code: 429') ||
        normalized.contains('too many requests')) {
      return _emailRateLimitMessage;
    }

    if (normalized.contains('email_address_invalid') ||
        normalized.contains('email address') &&
            normalized.contains('invalid') ||
        normalized.contains('invalid email')) {
      return 'Format email tidak valid. Periksa kembali alamat email Anda.';
    }

    if (normalized.contains('user already registered') ||
        normalized.contains('already been registered') ||
        normalized.contains('email already exists')) {
      return _emailAlreadyRegisteredMessage;
    }

    return 'Registrasi gagal. Silakan coba lagi.';
  }

  String _normalizeEmail(String email) {
    return email
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .trim()
        .toLowerCase();
  }

  Future<RegistrationCodeLookupResult?> _lookupRegistrationCode(
    String normalizedCode, {
    RegistrationCodeType? registrationType,
  }) async {
    _logRegistrationLookup(
      '_lookupRegistrationCode start code="$normalizedCode" registrationType=${registrationType?.name ?? "any"}',
    );

    var query = _client
        .from('registration_codes')
        .select('code, rt, rw, rt_rw, registration_type, used_at, is_active')
        .eq('code', normalizedCode)
        .eq('is_active', true)
        .isFilter('used_at', null);

    if (registrationType != null) {
      query = query.eq(
        'registration_type',
        _registrationTypeValue(registrationType),
      );
    }

    try {
      final data = await query.maybeSingle();
      debugPrint(
        'SUPABASE QUERY RESULT ${data == null ? "null" : data.toString()}',
      );
      _logRegistrationLookup(
        '_lookupRegistrationCode rawResult=${data == null ? "null" : data.toString()}',
      );
      if (data == null) return null;

      final parsed = RegistrationCodeLookupResult.fromRow(
        Map<String, dynamic>.from(data),
      );
      _logRegistrationLookup(
        '_lookupRegistrationCode parsed code=${parsed.code} type=${parsed.registrationType.name} rt=${parsed.rt} rw=${parsed.rw} rtRw=${parsed.rtRw} active=${parsed.isActive} usedAt=${parsed.usedAt}',
      );
      return parsed;
    } catch (error, stackTrace) {
      _logRegistrationLookup(
        '_lookupRegistrationCode error=${error.runtimeType}: $error',
      );
      _logRegistrationLookup(stackTrace.toString());
      rethrow;
    }
  }

  String _registrationTypeValue(RegistrationCodeType type) {
    return switch (type) {
      RegistrationCodeType.warga => 'warga',
      RegistrationCodeType.admin => 'admin',
    };
  }

  void _logRegistrationLookup(String message) {
    debugPrint('[AuthService][registration_codes] $message');
  }
}
