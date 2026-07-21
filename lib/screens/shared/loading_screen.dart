import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen> {
  Timer? _timer;
  StreamSubscription<InstallStatus>? _installUpdateSubscription;
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _passwordRecoveryDetected = false;
  bool _recoverySnackbarShown = false;
  bool _resetPasswordNavigated = false;

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: LoadingScreen initState');
    _listenForAuthStateChanges();
    // Simulate progress load
    _startProgressSimulation();
  }

  void _listenForAuthStateChanges() {
    debugPrint('DEBUG: Auth listener attached');
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        debugPrint('DEBUG: Auth event received: ${data.event.name}');
        if (data.event != AuthChangeEvent.passwordRecovery) {
          return;
        }

        debugPrint(
          '[LoadingScreen] Password Recovery Terdeteksi: session=${data.session?.user.id ?? "null"}',
        );

        if (_passwordRecoveryDetected) return;

        setState(() {
          _passwordRecoveryDetected = true;
        });

        _showRecoveryDetectedNotice();
        _navigateToResetPassword();
      },
      onError: (error, stackTrace) {
        debugPrint('[LoadingScreen] onAuthStateChange error: $error');
        debugPrint(stackTrace.toString());
      },
    );
  }

  void _showRecoveryDetectedNotice() {
    if (_recoverySnackbarShown) return;
    _recoverySnackbarShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password Recovery Terdeteksi'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  void _navigateToResetPassword() {
    if (_resetPasswordNavigated) return;
    _resetPasswordNavigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
      );
    });
  }

  void _startProgressSimulation() {
    const int totalTicks = 50; // Ticks of progress
    int tick = 0;

    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      tick++;

      if (tick >= totalTicks) {
        timer.cancel();
        // Give a tiny buffer before navigating
        Future.delayed(const Duration(milliseconds: 300), () async {
          if (!mounted) return;
          await _runStartupFlow();
        });
      }
    });
  }

  Future<void> _runStartupFlow() async {
    if (_passwordRecoveryDetected) {
      debugPrint(
        '[LoadingScreen] Startup flow dibatalkan karena password recovery sedang aktif.',
      );
      return;
    }

    try {
      final updateHandled = await _checkAndHandleAppUpdate();
      if (!mounted || updateHandled) return;

      await _navigateAfterSessionCheck();
    } catch (_) {
      if (!mounted) return;
      _navigateToLogin();
    }
  }

  Future<bool> _checkAndHandleAppUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        return false;
      }

      if (updateInfo.flexibleUpdateAllowed) {
        final shouldUpdate = await _showUpdateDialog(
          title: 'Pembaruan Tersedia',
          message:
              'Versi baru aplikasi tersedia di Google Play. Pembaruan akan diunduh di latar belakang dan dipasang setelah selesai.',
          confirmText: 'Perbarui',
          cancelText: 'Nanti',
        );

        if (!shouldUpdate) {
          return false;
        }

        return await _startFlexibleUpdateFlow();
      }

      if (updateInfo.immediateUpdateAllowed) {
        final shouldUpdate = await _showUpdateDialog(
          title: 'Pembaruan Wajib',
          message:
              'Versi baru aplikasi tersedia dan perlu dipasang sebelum melanjutkan.',
          confirmText: 'Perbarui Sekarang',
          cancelText: 'Nanti',
        );

        if (!shouldUpdate) {
          return false;
        }

        return await _performImmediateUpdateFlow();
      }

      return false;
    } catch (error) {
      debugPrint('In-app update check failed: $error');
      return false;
    }
  }

  Future<bool> _showUpdateDialog({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
  }) async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelText),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<bool> _startFlexibleUpdateFlow() async {
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result != AppUpdateResult.success) {
        return false;
      }

      _installUpdateSubscription?.cancel();

      _installUpdateSubscription = InAppUpdate.installUpdateListener.listen(
        (status) async {
          if (status == InstallStatus.downloaded) {
            try {
              await InAppUpdate.completeFlexibleUpdate();
            } catch (error) {
              debugPrint('Complete flexible update failed: $error');
            }
          }
        },
        onError: (error) {
          debugPrint('Flexible update listener failed: $error');
        },
      );

      return false;
    } catch (error) {
      debugPrint('Flexible update failed: $error');
      return false;
    }
  }

  Future<bool> _performImmediateUpdateFlow() async {
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      return result == AppUpdateResult.success;
    } catch (error) {
      debugPrint('Immediate update failed: $error');
      return false;
    }
  }

  Future<void> _navigateAfterSessionCheck() async {
    if (!mounted) return;

    if (_passwordRecoveryDetected) {
      debugPrint(
        '[LoadingScreen] Navigasi normal dilewati karena password recovery terdeteksi.',
      );
      return;
    }

    AppState state;
    try {
      state = Provider.of<AppState>(context, listen: false);
    } catch (_) {
      _navigateToLogin();
      return;
    }

    try {
      debugPrint('DEBUG: restoreSession start');
      final hasSession = await state.restoreSession();
      debugPrint('DEBUG: restoreSession done, session exists: $hasSession');

      if (!mounted) return;

      if (_passwordRecoveryDetected) {
        debugPrint(
          '[LoadingScreen] Navigasi setelah restoreSession dilewati karena password recovery terdeteksi.',
        );
        return;
      }

      if (!hasSession) {
        _navigateToLogin();
        return;
      }

      final user = state.currentUser;
      if (user?.role == UserRole.warga &&
          user?.verificationStatus != VerificationStatus.verified) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/waiting-verification');
      } else {
        if (!mounted) return;
        debugPrint('DEBUG: Navigate Home');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (_) {
      if (!mounted) return;
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;

    debugPrint('DEBUG: Navigate Login');
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _installUpdateSubscription?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _SplashLogo(),
                const SizedBox(height: 28),
                const Text(
                  'Lapor Warga',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Suara Warga, Solusi Bersama',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      child: const Icon(Icons.eco_rounded, size: 86, color: Colors.white),
    );
  }
}
