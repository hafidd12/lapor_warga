import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:in_app_update/in_app_update.dart';
import 'services/deep_link_service.dart';
import 'services/supabase_service.dart';
import 'theme.dart';
import 'models/models.dart';
import 'providers/app_state.dart';
import 'screens/shared/loading_screen.dart';
import 'screens/shared/login_screen.dart';
import 'screens/shared/waiting_verification_screen.dart';
import 'screens/warga/dashboard_warga.dart';
import 'screens/warga/halaman_report.dart';
import 'screens/warga/aktivitas_laporan.dart';
import 'screens/warga/profil_warga.dart';
import 'screens/admin/dashboard_admin.dart';
import 'screens/admin/daftar_warga_admin.dart';
import 'screens/admin/aktivitas_admin.dart';
import 'screens/admin/profil_admin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  debugPrint('DEBUG: Supabase initialized');
  await DeepLinkService.instance.start();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const LaporWargaApp(),
    ),
  );
}

class LaporWargaApp extends StatelessWidget {
  const LaporWargaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lapor Warga',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
      onUnknownRoute: _generateRoute,
    );
  }
}

Route<dynamic> _generateRoute(RouteSettings settings) {
  final normalizedName = _normalizeRouteName(settings.name);
  final normalizedSettings = RouteSettings(
    name: normalizedName,
    arguments: settings.arguments,
  );

  switch (normalizedName) {
    case '/':
      return MaterialPageRoute(
        builder: (context) => const AppStartupGate(child: LoadingScreen()),
        settings: normalizedSettings,
      );
    case '/login':
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
        settings: normalizedSettings,
      );
    case '/home':
      return MaterialPageRoute(
        builder: (context) => const HomeScreenWrapper(),
        settings: normalizedSettings,
      );
    case '/buat-laporan':
      return MaterialPageRoute(
        builder: (context) => const HalamanReportScreen(),
        settings: normalizedSettings,
      );
    case '/waiting-verification':
      return MaterialPageRoute(
        builder: (context) => const WaitingVerificationScreen(),
        settings: normalizedSettings,
      );
    default:
      return MaterialPageRoute(
        builder: (context) => const AppStartupGate(child: LoadingScreen()),
        settings: normalizedSettings,
      );
  }
}

String _normalizeRouteName(String? routeName) {
  final value = routeName?.trim();
  if (value == null || value.isEmpty) return '/';

  final uri = Uri.tryParse(value);
  if (uri == null) return value;

  if (uri.path.isEmpty) return '/';
  return uri.path;
}

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  bool _checkedForUpdate = false;
  StreamSubscription<InstallStatus>? _installStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkForAppUpdate();
      }
    });
  }

  @override
  void dispose() {
    _installStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkForAppUpdate() async {
    if (_checkedForUpdate) return;
    _checkedForUpdate = true;

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (updateInfo.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          _listenForFlexibleCompletion();
        }
        return;
      }

      if (updateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (_) {
      // If Play services or the install source does not support updates,
      // let the app continue normally.
    }
  }

  void _listenForFlexibleCompletion() {
    if (_installStatusSubscription != null) return;

    _installStatusSubscription = InAppUpdate.installUpdateListener.listen((
      status,
    ) async {
      if (status == InstallStatus.downloaded) {
        try {
          await InAppUpdate.completeFlexibleUpdate();
        } catch (_) {
          // Ignore completion errors and keep the app usable.
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({super.key});

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  int _currentCitizenIndex = 0;
  int _currentAdminIndex = 0;

  void _goToAdminHome() {
    setState(() => _currentAdminIndex = 0);
  }

  // Admin tabs (added Warga management and Aktivitas)
  List<Widget> get _adminScreens {
    return [
      const DashboardAdminScreen(),
      const DaftarWargaAdminScreen(),
      AktivitasAdminScreen(onBackPressed: _goToAdminHome),
      const ProfilAdminScreen(),
    ];
  }

  List<Widget> get _citizenScreens {
    return [
      DashboardWargaScreen(
        onGoToAktivitas: () => setState(() => _currentCitizenIndex = 2),
      ),
      HalamanReportScreen(
        showBackButton: false,
        onBackPressed: () => setState(() => _currentCitizenIndex = 0),
      ),
      const AktivitasLaporanScreen(),
      ProfilWargaScreen(
        onGoToAktivitas: () => setState(() => _currentCitizenIndex = 2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final user = state.currentUser;

    // Guard route: if not logged in, redirect to login page
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Guard: if warga not verified, redirect to waiting
    if (user.role == UserRole.warga &&
        user.verificationStatus != VerificationStatus.verified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/waiting-verification');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user.role == UserRole.warga) {
      return Scaffold(
        body: _citizenScreens[_currentCitizenIndex],
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.outlineVariantColor.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              selectedIndex: _currentCitizenIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentCitizenIndex = index;
                });
              },
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.12),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_rounded, color: AppTheme.outlineColor),
                  selectedIcon: Icon(
                    Icons.home_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppTheme.outlineColor,
                  ),
                  selectedIcon: Icon(
                    Icons.add_circle_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  label: 'Lapor',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.history_rounded,
                    color: AppTheme.outlineColor,
                  ),
                  selectedIcon: Icon(
                    Icons.history_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  label: 'Aktivitas',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.outlineColor,
                  ),
                  selectedIcon: Icon(
                    Icons.person_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Admin View with 4 tabs
      return Scaffold(
        body: _adminScreens[_currentAdminIndex],
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.outlineVariantColor.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomNavigationBar(
              currentIndex: _currentAdminIndex,
              onTap: (index) {
                setState(() {
                  _currentAdminIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: AppTheme.textSecondaryColor,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  activeIcon: Icon(Icons.admin_panel_settings),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Warga',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined),
                  activeIcon: Icon(Icons.history),
                  label: 'Aktivitas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle_outlined),
                  activeIcon: Icon(Icons.account_circle),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
