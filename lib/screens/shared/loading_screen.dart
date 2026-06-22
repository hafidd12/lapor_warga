import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import 'login_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  
  double _progressValue = 0.0;
  int _textIndex = 0;
  Timer? _timer;

  final List<String> _loadingTexts = [
    "Menyiapkan modul pelaporan...",
    "Menghubungkan ke pusat data...",
    "Memverifikasi identitas warga...",
    "Menghubungkan komunitas...",
    "Hampir selesai...",
    "Sistem Siap"
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Simulate progress load
    _startProgressSimulation();
  }

  void _startProgressSimulation() {
    const int totalTicks = 50; // Ticks of progress
    int tick = 0;
    
    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      tick++;
      setState(() {
        _progressValue = tick / totalTicks;
        
        // Update texts based on progress range
        if (_progressValue < 0.2) {
          _textIndex = 0;
        } else if (_progressValue < 0.4) {
          _textIndex = 1;
        } else if (_progressValue < 0.6) {
          _textIndex = 2;
        } else if (_progressValue < 0.8) {
          _textIndex = 3;
        } else if (_progressValue < 0.95) {
          _textIndex = 4;
        } else {
          _textIndex = 5;
        }
      });

      if (tick >= totalTicks) {
        timer.cancel();
        // Give a tiny buffer before navigating
        Future.delayed(const Duration(milliseconds: 300), () async {
          if (!mounted) return;
          await _navigateAfterSessionCheck();
        });
      }
    });
  }

  Future<void> _navigateAfterSessionCheck() async {
    AppState state;
    try {
      state = Provider.of<AppState>(context, listen: false);
    } catch (_) {
      _navigateToLogin();
      return;
    }

    final hasSession = await state.restoreSession();

    if (!mounted) return;

    if (!hasSession) {
      _navigateToLogin();
      return;
    }

    final user = state.currentUser;
    if (user?.role == UserRole.warga &&
        user?.verificationStatus != VerificationStatus.verified) {
      Navigator.of(context).pushReplacementNamed('/waiting-verification');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;

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
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryContainerColor,
      body: Stack(
        children: [
          // Background soft spots
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryFixed.withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox(),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tertiaryFixed.withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    ScaleTransition(
                      scale: _glowAnimation,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.eco,
                            size: 80,
                            color: AppTheme.primaryContainerColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App Title
                    Text(
                      'Lapor Warga',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      'MENUJU LINGKUNGAN YANG LEBIH BAIK',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 72),

                    // Progress Track Concept
                    SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _progressValue,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryFixed,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryFixed.withOpacity(0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _loadingTexts[_textIndex],
                              key: ValueKey<int>(_textIndex),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _textIndex == 5
                                    ? AppTheme.primaryFixed
                                    : Colors.white.withOpacity(0.7),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.public, color: Colors.white54, size: 16),
                SizedBox(width: 8),
                Text(
                  'SUARA WARGA, SOLUSI BERSAMA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
