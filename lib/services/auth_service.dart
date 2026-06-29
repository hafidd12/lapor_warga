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

  Session? get currentSession => _client.auth.currentSession;

  Future<AppUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
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
}
