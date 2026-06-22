import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const LaporWargaApp(),
    ),
  );
}

class LaporWargaApp extends StatelessWidget {
  const LaporWargaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lapor Warga',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoadingScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreenWrapper(),
        '/buat-laporan': (context) => const HalamanReportScreen(),
        '/waiting-verification': (context) => const WaitingVerificationScreen(),
      },
    );
  }
}

class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({Key? key}) : super(key: key);

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  int _currentCitizenIndex = 0;
  int _currentAdminIndex = 0;

  // Admin tabs (added Warga management and Aktivitas)
  final List<Widget> _adminScreens = [
    const DashboardAdminScreen(),
    const DaftarWargaAdminScreen(),
    const AktivitasAdminScreen(),
    const ProfilAdminScreen(),
  ];

  List<Widget> get _citizenScreens {
    return [
      const DashboardWargaScreen(),
      HalamanReportScreen(
        showBackButton: false,
        onBackPressed: () => setState(() => _currentCitizenIndex = 0),
      ),
      const AktivitasLaporanScreen(),
      const ProfilWargaScreen(),
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
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              top: BorderSide(
                color: AppTheme.outlineVariantColor.withOpacity(0.35),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentCitizenIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentCitizenIndex = index;
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: AppTheme.primaryContainerColor,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(
                  Icons.home,
                  color: AppTheme.onPrimaryContainerColor,
                ),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_box_outlined),
                selectedIcon: Icon(
                  Icons.add_box,
                  color: AppTheme.onPrimaryContainerColor,
                ),
                label: 'Report',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(
                  Icons.history,
                  color: AppTheme.onPrimaryContainerColor,
                ),
                label: 'Activity',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(
                  Icons.person,
                  color: AppTheme.onPrimaryContainerColor,
                ),
                label: 'Profil',
              ),
            ],
          ),
        ),
        floatingActionButton: _currentCitizenIndex == 0
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/buat-laporan');
                },
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.add, size: 30),
              )
            : null,
      );
    } else {
      // Admin View with 4 tabs
      return Scaffold(
        body: _adminScreens[_currentAdminIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentAdminIndex,
          onTap: (index) {
            setState(() {
              _currentAdminIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondaryColor,
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
      );
    }
  }
}
