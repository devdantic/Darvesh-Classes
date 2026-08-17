import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_page.dart';
import 'authentication_page.dart';
import 'firebase_message.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  await Supabase.initialize(
    url: 'https://ulxemdfldbybyrxqsghh.supabase.co',
    publishableKey: 'sb_publishable_7KgMpezYOS2r-IiR_QdWGg_CemimK0w',
  );

  runApp(const IntroPage());
}

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Darvesh Classes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppInitializer(),
    );
  }
}

/// --------------------------------------------------------------------------
/// APP INITIALIZER
/// --------------------------------------------------------------------------
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Run background Firebase & notification setup asynchronously without delaying splash screen launch
    _initializeInBackground();
  }

  Future<void> _initializeInBackground() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidPlayIntegrityProvider(),
        );
      } catch (_) {}
      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      await _setupNotifications(messaging);
    } catch (e) {
      debugPrint('Background initialization warning: $e');
    }
  }

  Future<void> _setupNotifications(FirebaseMessaging messaging) async {
    try {
      await Permission.notification.request();
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Launch splash screen instantly with zero delay!
    return const ScenicSplashIntroScreen();
  }
}

/// --------------------------------------------------------------------------
/// SCENIC & SMOOTH ANIMATED SPLASH INTRO SCREEN
/// --------------------------------------------------------------------------
class ScenicSplashIntroScreen extends StatefulWidget {
  const ScenicSplashIntroScreen({super.key});

  @override
  State<ScenicSplashIntroScreen> createState() => _ScenicSplashIntroScreenState();
}

class _ScenicSplashIntroScreenState extends State<ScenicSplashIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _glowPulse;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 1. Logo Scale & Fade
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // 2. Title Slide & Fade
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeIn),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Subtitle & Glow Pulse
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _mainController.forward();

    // Automatically navigate after intro completes (3.2 seconds total)
    _navigationTimer = Timer(const Duration(milliseconds: 3200), () {
      _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    _navigationTimer?.cancel();
    if (!mounted) return;

    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final profile = await ProfileService.instance.getCurrentProfile();
        if (!mounted) return;

        if (profile != null) {
          final email = (profile['email'] as String? ?? user.email ?? '').trim().toLowerCase();
          final role = (profile['role'] as String? ?? '').trim().toLowerCase();
          final name = (profile['name'] as String? ?? '').trim().toLowerCase();

          final bool isAdmin = email == 'sanjaygovindani757@gmail.com' ||
              role == 'admin' ||
              name.contains('sanjay');

          final Widget targetPage = isAdmin ? const AdminPage() : const HomePage();

          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, _, _) => targetPage,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Error routing active user session: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const AuthenticationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Scenic Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0B132B), // Midnight Deep Navy
                  Color(0xFF1C2541), // Rich Sapphire Blue
                  Color(0xFF3A506B), // Ambient Dusk Blue
                ],
              ),
            ),
          ),

          // Glowing Ambient Radial Backdrop behind Logo
          Center(
            child: AnimatedBuilder(
              animation: _glowPulse,
              builder: (context, child) {
                return Transform.scale(
                  scale: _glowPulse.value,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main Center Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated Logo
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _logoFade,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 4,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'media/DC_logo_2.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Animated Title
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Column(
                      children: [
                        Text(
                          'DARVESH CLASSES',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                offset: const Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Animated Subtitle
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    'Empowering Excellence in Education',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Bottom Loading Indicator & Branding
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'DARVESH CLASSES ACADEMY',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top-Right Skip Intro Button
          Positioned(
            top: 50,
            right: 20,
            child: FadeTransition(
              opacity: _subtitleFade,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: _navigateNext,
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                label: Text(
                  'Skip',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}