import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StudentComplainsPage extends StatefulWidget {
  const StudentComplainsPage({Key? key}) : super(key: key);

  @override
  _StudentComplainsPageState createState() => _StudentComplainsPageState();
}

class _StudentComplainsPageState extends State<StudentComplainsPage> {
  final TextEditingController _complaintController = TextEditingController();
  String? _selectedStudentName;
  String? _selectedStudentUid;
  List<String> _studentNames = [];
  Map<String, String> _nameToUidMap = {};
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('Darvesh Classes').get();

      List<String> studentNames = [];
      Map<String, String> nameToUidMap = {};
      for (var doc in querySnapshot.docs) {
        String name = doc.data()['name'];
        String uid = doc.id;
        studentNames.add(name);
        nameToUidMap[name] = uid;
      }

      setState(() {
        _studentNames = studentNames;
        _nameToUidMap = nameToUidMap;
        if (_studentNames.isNotEmpty) {
          _selectedStudentName = _studentNames.first;
          _selectedStudentUid = _nameToUidMap[_selectedStudentName];
        }
      });
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  Future<void> _sendNotification(
      String title, String body, String token) async {
    final String serverKey =
        'AAAAdjfDsd4:APA91bGBzOGZa1VEAssIAlxhJfVuXBZVWQD6yDjgE4RUT73Cx4RU7KS9APYl5y_wRWdX98Kfo38cjlywY5iPV_pt9EXxtHsrkOGJBUztasm0cSM1U4Tjcu86am3q58PWiJDkxaCFACl8'; // Your FCM server key from Firebase Console
    final String url = 'https://fcm.googleapis.com/fcm/send';

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
        setState(() {
          _successMessage =
              'Complaint sent successfully to $_selectedStudentName';
        });
      } else {
        setState(() {
          _successMessage =
              'Failed to send notification to $_selectedStudentName';
        });
      }
    } catch (e) {
      print('Error sending notification: $e');
      setState(() {
        _successMessage = 'Error sending notification to $_selectedStudentName';
      });
    }
  }

  Future<void> _sendComplaint() async {
    if (_selectedStudentUid != null) {
      String title = 'Complaint Received!';
      String body = _complaintController.text;
      String token = await _fetchFCMToken(_selectedStudentUid!);

      if (token.isNotEmpty) {
        await _sendNotification(title, body, token);

        // Store the complaint in Firestore
        await FirebaseFirestore.instance.collection('complains').add({
          'sender': 'Sanjay Sir',
          'receiver': _selectedStudentUid,
          'complaint': body,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _complaintController.clear();
          _successMessage =
              'Complaint sent successfully for $_selectedStudentName';
        });
      } else {
        setState(() {
          _successMessage = 'FCM token not found for $_selectedStudentName';
        });
      }
    } else {
      setState(() {
        _successMessage = 'Please select a student';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Complaints'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Student:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_studentNames.isNotEmpty)
              DropdownButton<String>(
                value: _selectedStudentName,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStudentName = newValue!;
                    _selectedStudentUid = _nameToUidMap[_selectedStudentName];
                  });
                },
                items:
                    _studentNames.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              )
            else
              const Text('No students found'),
            const SizedBox(height: 20),
            TextField(
              controller: _complaintController,
              decoration: InputDecoration(
                labelText: 'Complaint',
                border: OutlineInputBorder(),
              ),
              minLines: 5,
              maxLines: 10,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendComplaint,
              child: const Text('Send Complaint'),
            ),
            const SizedBox(height: 20),
            if (_successMessage.isNotEmpty)
              Text(
                _successMessage,
                style: TextStyle(
                  color: _successMessage.contains('successfully')
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<String> _fetchFCMToken(String studentUid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await FirebaseFirestore.instance
              .collection('Darvesh Classes')
              .doc(studentUid)
              .get();
      if (docSnapshot.exists) {
        return docSnapshot['fcmToken'];
      } else {
        return '';
      }
    } catch (e) {
      print('Error fetching FCM token: $e');
      return '';
    }
  }
}
