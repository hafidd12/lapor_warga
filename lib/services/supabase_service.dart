import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _urlKey = 'SUPABASE_URL';
  static const String _publishableKey = 'SUPABASE_PUBLISHABLE_KEY';
  static const String _anonKey = 'SUPABASE_ANON_KEY';

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError('Supabase has not been initialized.');
    }
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final supabaseUrl = _normalizeSupabaseUrl(dotenv.env[_urlKey]);
    final supabaseKey = _firstNonEmpty(
      dotenv.env[_publishableKey],
      dotenv.env[_anonKey],
    );

    if (!_hasUsableConfig(supabaseUrl, supabaseKey)) {
      return;
    }

    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
    _isInitialized = true;
  }

  static bool _hasUsableConfig(String supabaseUrl, String supabaseKey) {
    final uri = Uri.tryParse(supabaseUrl);

    return uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty &&
        !supabaseUrl.contains('your-supabase-url') &&
        supabaseKey.isNotEmpty &&
        !supabaseKey.contains('your-supabase-publishable-key') &&
        !supabaseKey.contains('your-supabase-anon-key');
  }

  static String _normalizeSupabaseUrl(String? rawUrl) {
    final value = rawUrl?.trim() ?? '';
    if (value.isEmpty) return '';

    final withoutRestPath = value.replaceFirst(RegExp(r'/rest/v1/?$'), '');
    return withoutRestPath;
  }

  static String _firstNonEmpty(String? primary, String? fallback) {
    final primaryValue = primary?.trim() ?? '';
    if (primaryValue.isNotEmpty) return primaryValue;
    return fallback?.trim() ?? '';
  }
}
