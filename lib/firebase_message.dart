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
