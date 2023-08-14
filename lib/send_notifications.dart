import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({Key? key}) : super(key: key);

  @override
  _SendNotificationPageState createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  late String _selectedName;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _selectedName = '';
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String?> getEmailFromName(String? name) async {
    if (name == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('Darvesh Classes')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      return data['emailID'] as String?;
    }

    return null;
  }

  Future<String?> getFCMToken(String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Darvesh Classes')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      return data['fcmToken'] as String?;
    }

    return null;
  }

  void _sendNotification() async {
    String description = _descriptionController.text;
    String? name = _selectedName;
    String? token = await getFCMToken(name);
    String? senderEmail = await getEmailFromName(name);
    String? receiverEmail = await getEmailFromName(name);

    if (senderEmail == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to find email for selected student'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (token == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to find FCM token for selected name'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }
    var notification = {
      'title': 'Complain Received',
      'body': description,
    };

    var message = {
      'message': {
        'token': token,
        'notification': {
          'title': 'Complain Received',
          'body': description,
        },
        'data': {
          'email': senderEmail,
        },
      },
    };
    var complaint = {
      'receiver': receiverEmail,
      'sender': 'Sanjay Sir',
      'timestamp': FieldValue.serverTimestamp(),
      'message': description,
    };

    await FirebaseFirestore.instance.collection('complains').add(complaint);
    // Load the service account credentials
    final serviceAccountJson =
        await rootBundle.loadString('media/serviceAccount.json');
    final serviceAccountCredentials =
        ServiceAccountCredentials.fromJson(serviceAccountJson);

    // Obtain an access token
    final client = await clientViaServiceAccount(serviceAccountCredentials,
        ['https://www.googleapis.com/auth/firebase.messaging']);
    final accessToken = client.credentials.accessToken.data;

    // Send the notification using the FCM API
    var response = await http.post(
      Uri.parse(
          'https://fcm.googleapis.com/v1/projects/darvesh-classes-ac86c/messages:send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(message),
    );

    if (kDebugMode) {
      print('FCM Response: ${response.body}');
    }

    if (response.statusCode == 200) {
      // Show a confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Notification Sent'),
            content: Text('Notification sent to $_selectedName'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Handle the failure case
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to send notification'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Darvesh Classes')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                List<String> names = snapshot.data!.docs.fold<List<String>>([],
                    (List<String> previousValue, DocumentSnapshot document) {
                  final dynamic nameData =
                      (document.data() as Map<String, dynamic>)['name'];
                  if (nameData is String) {
                    previousValue.add(nameData);
                  } else if (nameData is List<dynamic>) {
                    previousValue.addAll(nameData.whereType<String>());
                  }

                  return previousValue;
                });

                return DropdownButtonFormField<String>(
                  value: _selectedName.isNotEmpty ? _selectedName : null,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedName = newValue!;
                    });
                  },
                  items: names.map((String name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Select Name',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _sendNotification();
              },
              child: const Text('Send Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
