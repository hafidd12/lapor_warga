import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _urlKey = 'SUPABASE_URL';
  static const String _publishableKey = 'SUPABASE_PUBLISHABLE_KEY';

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

    if (!_hasUsableConfig(supabaseUrl, publishableKey)) {
      return;
    }

    await Supabase.initialize(url: supabaseUrl, publishableKey: publishableKey);
    _isInitialized = true;
  }

  static bool _hasUsableConfig(String supabaseUrl, String publishableKey) {
    final uri = Uri.tryParse(supabaseUrl);

    return uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty &&
        !supabaseUrl.contains('your-supabase-url') &&
        publishableKey.isNotEmpty &&
        !publishableKey.contains('your-supabase-publishable-key');
  }
}
