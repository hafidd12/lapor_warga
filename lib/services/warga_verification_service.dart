import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'supabase_service.dart';

class WargaVerificationServiceException implements Exception {
  final String message;

  const WargaVerificationServiceException(this.message);

  @override
  String toString() => message;
}

class WargaVerificationService {
  WargaVerificationService({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  static const String _ktpBucket = 'ktp-images';
  static const String _profileColumns =
      'id, name, email, role, avatar_url, verification_status, ktp_number, registration_code, ktp_image_path, phone, rt_rw, address, jabatan, registered_at, created_at, updated_at';

  Future<List<AppUser>> fetchWargaByStatus(
    VerificationStatus status, {
    String? rtRw,
  }) async {
    debugPrint(
      '[WargaVerificationService] CALL fetchWargaByStatus status=${status.name} rtRw="${rtRw ?? ""}"',
    );
    var query = _client
        .from('profiles')
        .select(_profileColumns)
        .eq('role', 'warga')
        .eq('verification_status', _statusValue(status));

    final normalizedRtRw = rtRw?.trim() ?? '';
    if (normalizedRtRw.isNotEmpty) {
      query = query.eq('rt_rw', normalizedRtRw);
    }

    debugPrint(
      '[WargaVerificationService] SUPABASE QUERY fetchWargaByStatus select=$_profileColumns.eq(role, warga).eq(verification_status, ${_statusValue(status)})${normalizedRtRw.isNotEmpty ? '.eq(rt_rw, "$normalizedRtRw")' : ""}.order(created_at desc)',
    );
    final rows = await query.order('created_at', ascending: false);
    debugPrint(
      '[WargaVerificationService] SUPABASE QUERY RESULT fetchWargaByStatus count=${rows.length} rtRws=${rows.map((row) => (row as Map)['rt_rw']?.toString() ?? "-").toList()}',
    );

    return _mapRows(rows);
  }

  Future<List<AppUser>> fetchAllWarga({String? rtRw}) async {
    debugPrint(
      '[WargaVerificationService] CALL fetchAllWarga rtRw="${rtRw ?? ""}"',
    );
    var query = _client
        .from('profiles')
        .select(_profileColumns)
        .eq('role', 'warga');

    final normalizedRtRw = rtRw?.trim() ?? '';
    if (normalizedRtRw.isNotEmpty) {
      query = query.eq('rt_rw', normalizedRtRw);
    }

    debugPrint(
      '[WargaVerificationService] SUPABASE QUERY fetchAllWarga select=$_profileColumns.eq(role, warga)${normalizedRtRw.isNotEmpty ? '.eq(rt_rw, "$normalizedRtRw")' : ""}.order(created_at desc)',
    );
    final rows = await query.order('created_at', ascending: false);
    debugPrint(
      '[WargaVerificationService] SUPABASE QUERY RESULT fetchAllWarga count=${rows.length} rtRws=${rows.map((row) => (row as Map)['rt_rw']?.toString() ?? "-").toList()}',
    );

    return _mapRows(rows);
  }

  Future<AppUser?> getWargaById(String id) async {
    final row = await _client
        .from('profiles')
        .select(_profileColumns)
        .eq('id', id)
        .eq('role', 'warga')
        .maybeSingle();

    if (row == null) return null;
    return AppUser.fromProfileRow(Map<String, dynamic>.from(row));
  }

  Future<String?> getKtpSignedUrl(String? ktpImagePath) async {
    final normalizedPath = ktpImagePath?.trim() ?? '';
    if (normalizedPath.isEmpty) return null;

    final signedUrl = await _client.storage
        .from(_ktpBucket)
        .createSignedUrl(normalizedPath, 60 * 15);

    return signedUrl;
  }

  Future<AppUser> approveWarga(String id) {
    return updateVerificationStatus(id, VerificationStatus.verified);
  }

  Future<AppUser> rejectWarga(String id) {
    return updateVerificationStatus(id, VerificationStatus.rejected);
  }

  Future<AppUser> updateVerificationStatus(
    String id,
    VerificationStatus status,
  ) async {
    final updatedAt = DateTime.now().toUtc().toIso8601String();
    final row = await _client
        .from('profiles')
        .update({
          'verification_status': _statusValue(status),
          'updated_at': updatedAt,
        })
        .eq('id', id)
        .eq('role', 'warga')
        .select(_profileColumns)
        .single();

    return AppUser.fromProfileRow(Map<String, dynamic>.from(row));
  }

  List<AppUser> _mapRows(List<dynamic> rows) {
    return rows
        .map((row) => AppUser.fromProfileRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  String _statusValue(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pending => 'pending',
      VerificationStatus.verified => 'verified',
      VerificationStatus.rejected => 'rejected',
    };
  }
}
