import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'authentication_page.dart';
import 'firebase_message.dart';
import 'theme.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Catches any error during widget build so the app doesn't grey-screen
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
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
/// APP INITIALIZER (Updated for seamless transition)
/// --------------------------------------------------------------------------
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isReady = false;
  String _status = 'Preparing your learning space...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await FirebaseAppCheck.instance.activate(
        AndroidProvider: AndroidProvider.debug
      );
      await FirebaseApi().initNotification();
      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      await _setupNotifications(messaging);

      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      if (mounted) setState(() => _status = 'Setup failed. Please restart.');
    }
  }

  Future<void> _setupNotifications(FirebaseMessaging messaging) async {
    await Permission.notification.request();
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_rounded, size: 48, color: AppTheme.primaryColor),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(_status, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
    }
    return const CinematicIntroScreen();
  }
}

/// --------------------------------------------------------------------------
/// CINEMATIC INTRO SCREEN
/// --------------------------------------------------------------------------
class CinematicIntroScreen extends StatefulWidget {
  const CinematicIntroScreen({super.key});

  @override
  State<CinematicIntroScreen> createState() => _CinematicIntroScreenState();
}

class _CinematicIntroScreenState extends State<CinematicIntroScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.asset('media/DC_Intro.mp4');
      await _controller!.initialize();
      if (!mounted) return;

      setState(() => _isInitialized = true);
      _controller!.play();
      _fadeController.forward();
      _controller!.addListener(_onVideoProgress);
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
        _goToAuth();
      }
    }
  }

  void _onVideoProgress() {
    if (_controller == null) return;
    if (_controller!.value.position >= _controller!.value.duration - const Duration(milliseconds: 500)) {
      _controller!.removeListener(_onVideoProgress);
      _goToAuth();
    }
  }

  void _goToAuth() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const AuthenticationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use the AppTheme.bgGradient here as well so the background never "flashes" black
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // FULLSCREEN VIDEO LOGIC
            if (_isInitialized && _controller != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover, // This removes the black bars
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),

            // Cinematic Gradients
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),

            // Branding Text
            Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: FadeTransition(
                opacity: _fadeAnimation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}