import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'authentication_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await SharedPreferences.getInstance();

  await Permission.notification.request();

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    //print('User granted permission for notifications');
  } else {
    //print('User declined permission for notifications');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //print('Foreground message received: ${message.notification?.body}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // print('Background/Terminated message received: ${message.notification?.body}');
  });

  runApp(const IntroPage());
}

class IntroPage extends StatelessWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intro',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const DarveshClasses(),
    );
  }
}

class DarveshClasses extends StatefulWidget {
  const DarveshClasses({Key? key}) : super(key: key);

  @override
  _DarveshClassesState createState() => _DarveshClassesState();
}

class _DarveshClassesState extends State<DarveshClasses>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final double _imageSize = 200.0;
  String _welcomeText = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animationController.addListener(() {
      setState(() {
        if (_animationController.status == AnimationStatus.completed) {
          _welcomeText = 'Welcome to';
        }
      });
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _welcomeText,
              style: const TextStyle(
                color: Colors.teal,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedBuilder(
              animation: _animationController,
              builder: (BuildContext context, Widget? child) {
                return Transform.scale(
                  scale: 1.0 + _animationController.value * 0.2,
                  child: Image.asset(
                    'media/DC_logo_2.png',
                    width: _imageSize,
                    height: _imageSize,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AuthenticationPage(),
                  ),
                );
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
