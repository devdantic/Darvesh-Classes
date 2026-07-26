import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}

class FirebaseApi {
  Future<void> initNotification() async {
    const selectedStandard = "Std 5";
    final QuerySnapshot<Map<String, dynamic>> ans = await FirebaseFirestore
        .instance
        .collection('Darvesh Classes')
        .where('standard', isEqualTo: selectedStandard)
        .get();
    print(ans);
  }
}

class FcmConfig {
  static const String serverKey =
      'AAAAdjfDsd4:APA91bGBzOGZa1VEAssIAlxhJfVuXBZVWQD6yDjgE4RUT73Cx4RU7KS9APYl5y_wRWdX98Kfo38cjlywY5iPV_pt9EXxtHsrkOGJBUztasm0cSM1U4Tjcu86am3q58PWiJDkxaCFACl8';
}
