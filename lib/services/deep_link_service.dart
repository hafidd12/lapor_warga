import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _started = false;
  String? _initialLinkString;

  Future<void> start({void Function(Uri uri)? onDeepLinkReceived}) async {
    if (_started) return;
    _started = true;

    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _emitUri(initialLink, onDeepLinkReceived);
        _initialLinkString = initialLink.toString();
      }

      _subscription = _appLinks.uriLinkStream.listen(
        (uri) {
          if (_initialLinkString != null &&
              uri.toString() == _initialLinkString) {
            _initialLinkString = null;
            return;
          }

          _emitUri(uri, onDeepLinkReceived);
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('DEBUG: Deep Link error: $error');
          debugPrint(stackTrace.toString());
        },
      );
    } catch (error, stackTrace) {
      debugPrint('DEBUG: Deep Link error: $error');
      debugPrint(stackTrace.toString());
    }
  }

  void _emitUri(Uri uri, void Function(Uri uri)? onDeepLinkReceived) {
    debugPrint('DEBUG: Deep Link URI = $uri');

    if (uri.scheme == 'com.ti23a4.laporwarga' && uri.host == 'reset-password') {
      debugPrint('DEBUG: Password Recovery Deep Link Received');
    }

    onDeepLinkReceived?.call(uri);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
    _initialLinkString = null;
  }
}
