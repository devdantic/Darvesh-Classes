import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'authentication_page.dart';
import 'firebase_message.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseApi().initNotification();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await SharedPreferences.getInstance();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  await Permission.notification.request();
  //sendNotification("Test", "TEST", 'dvMlPxG6TWy0b6e-j39cB0:APA91bF49otntJ0nbi_iDmuMA18HwuqyO2jiE6ckLKWzV0Bav_DjvLrgxeTciVLV2jYkGu23h2UyzCeUjVZxGIQxdacTan5EQUHIAkpNxhyOkU3Ma5Est7QS76hccQa9jifMc-oROBzB');
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
        primarySwatch: Colors.indigo,
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

class _DarveshClassesState extends State<DarveshClasses> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('media/DC_Intro.mp4')
      ..initialize().then((_) {
        _controller.play();
        _controller.setLooping(false);
        _controller.addListener(() {
          if (!_controller.value.isPlaying && !_controller.value.isLooping) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const AuthenticationPage(),
              ),
            );
          }
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final aspectRatio = screenSize.width / screenSize.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
