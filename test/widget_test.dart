import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lapor_warga/main.dart';

class _MockEmptyLocalStorage extends LocalStorage {
  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<bool> hasAccessToken() async => false;

  @override
  Future<void> persistSession(String persistSessionString) async {}

  @override
  Future<void> removePersistedSession() async {}
}

class _MockAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> getItem({required String key}) async => _store[key];

  @override
  Future<void> removeItem({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _store[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Supabase.initialize(
      url: 'http://127.0.0.1',
      publishableKey: 'test-publishable-key',
      authOptions: FlutterAuthClientOptions(
        localStorage: _MockEmptyLocalStorage(),
        pkceAsyncStorage: _MockAsyncStorage(),
      ),
    );
  });

  tearDownAll(() async {
    await Supabase.instance.dispose();
  });

  testWidgets('Splash screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const LaporWargaApp());

    expect(find.text('Lapor Warga'), findsOneWidget);
  });
}
