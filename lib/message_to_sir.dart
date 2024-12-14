import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MessageToSirPage extends StatefulWidget {
  const MessageToSirPage({Key? key}) : super(key: key);

  @override
  _MessageToSirPageState createState() => _MessageToSirPageState();
}

class _MessageToSirPageState extends State<MessageToSirPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String? _currentUserName;

  Future<void> _getCurrentUserName() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('Darvesh Classes')
          .doc(currentUser.uid)
          .get();

      setState(() {
        _currentUserName = userDoc.data()?['name'] ?? 'Unknown User';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentUserName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message to Sir'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _currentUserName != null
                ? Text(
                    'Sending as: $_currentUserName',
                    style: const TextStyle(fontSize: 16),
                  )
                : const CircularProgressIndicator(),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Your Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendMessage,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text;
    Timestamp time = Timestamp.now();

    if (_currentUserName == null || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the message field')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Store the message in Firestore
      await FirebaseFirestore.instance.collection('messages_by_students').add({
        'name': _currentUserName,
        'time': time,
        'message': message,
      });

      // Send notification to admin
      const String adminFCMToken =
          "dvMlPxG6TWy0b6e-j39cB0:APA91bF49otntJ0nbi_iDmuMA18HwuqyO2jiE6ckLKWzV0Bav_DjvLrgxeTciVLV2jYkGu23h2UyzCeUjVZxGIQxdacTan5EQUHIAkpNxhyOkU3Ma5Est7QS76hccQa9jifMc-oROBzB";

      await _sendNotification(
        'New Message from $_currentUserName',
        'You have received a new message from a student. Check it out!',
        adminFCMToken,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully')),
      );

      // Clear the form
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendNotification(
      String title, String body, String token) async {
    const String serverKey =
        'AAAAdjfDsd4:APA91bGBzOGZa1VEAssIAlxhJfVuXBZVWQD6yDjgE4RUT73Cx4RU7KS9APYl5y_wRWdX98Kfo38cjlywY5iPV_pt9EXxtHsrkOGJBUztasm0cSM1U4Tjcu86am3q58PWiJDkxaCFACl8';
    const String url = 'https://fcm.googleapis.com/fcm/send';

    final Map<String, dynamic> payload = {
      'notification': {
        'title': title,
        'body': body,
        'sound': 'default',
      },
      'priority': 'high',
      'data': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      'to': token,
    };

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    try {
      final http.Response response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
