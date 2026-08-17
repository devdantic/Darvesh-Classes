import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_message.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
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
/// APP INITIALIZER (Zero-Delay Splash with Background Core Services Setup)
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
    // Launch ultra-premium animated splash screen instantly
    return const SplashScreen();
  }
}