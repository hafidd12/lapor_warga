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

    final supabaseUrl = dotenv.env[_urlKey]?.trim() ?? '';
    final publishableKey = dotenv.env[_publishableKey]?.trim() ?? '';
    final anonKey = dotenv.env[_anonKey]?.trim() ?? '';
    final supabaseKey = publishableKey.isNotEmpty ? publishableKey : anonKey;

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
}
