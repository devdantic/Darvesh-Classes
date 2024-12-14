import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SendMessagePage extends StatefulWidget {
  const SendMessagePage({Key? key}) : super(key: key);

  @override
  _SendMessagePageState createState() => _SendMessagePageState();
}

class _SendMessagePageState extends State<SendMessagePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedStandard = 'Std 5';

  Future<void> _sendNotification(
      List<String> tokens, String title, String message) async {
    const String serverKey =
        'AAAAdjfDsd4:APA91bGBzOGZa1VEAssIAlxhJfVuXBZVWQD6yDjgE4RUT73Cx4RU7KS9APYl5y_wRWdX98Kfo38cjlywY5iPV_pt9EXxtHsrkOGJBUztasm0cSM1U4Tjcu86am3q58PWiJDkxaCFACl8'; // Replace with your FCM server key
    final Uri url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final Map<String, dynamic> payload = {
      'registration_ids': tokens,
      'notification': {
        'title': title,
        'body': message,
      },
      'data': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send notification');
    }
  }

  Future<void> _sendMessage() async {
    String title = _titleController.text;
    String content = _contentController.text;
    String sender = "Sanjay Sir";

    // Fetch students' FCM tokens based on the selected standard
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('Darvesh Classes')
        .where('std', isEqualTo: _selectedStandard)
        .get();

    List<String> tokens = [];
    for (var doc in querySnapshot.docs) {
      tokens.add(doc.data()['fcmToken']);
    }

    if (tokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No students found for the selected standard')),
      );
      return;
    }

    try {
      await _sendNotification(tokens, title, content);

      // Add message to Firestore
      await FirebaseFirestore.instance.collection('messages').add({
        'title': title,
        'message': content,
        'sender': sender,
        'timestamp': FieldValue.serverTimestamp(),
        'standard': _selectedStandard,
      });

      _titleController.clear();
      _contentController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending message')),
      );
      print('Error sending message: $e');
    }
  }

  Future<void> _editMessage(
      String messageId, String newTitle, String newContent) async {
    try {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(messageId)
          .update({
        'title': newTitle,
        'message': newContent,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating message')),
      );
      print('Error updating message: $e');
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(messageId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting message')),
      );
      print('Error deleting message: $e');
    }
  }

  void _showEditDialog(
      String messageId, String currentTitle, String currentContent) {
    final TextEditingController editTitleController =
        TextEditingController(text: currentTitle);
    final TextEditingController editContentController =
        TextEditingController(text: currentContent);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editTitleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: editContentController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _editMessage(messageId, editTitleController.text,
                    editContentController.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return ListTile(
              title: Text(message['title']),
              subtitle: Text(message['message']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _showEditDialog(
                          message.id, message['title'], message['message']);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteMessage(message.id);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Message'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStandard,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStandard = newValue!;
                });
              },
              items: [
                'Std 5',
                'Std 6',
                'Std 7',
                'Std 8',
                'Std 9',
                'Std 10',
              ].map((String standard) {
                return DropdownMenuItem<String>(
                  value: standard,
                  child: Text(standard),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Select Standard',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration:
                  const InputDecoration(labelText: 'Message Description'),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('Send Message'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sent Messages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildMessageList()),
          ],
        ),
      ),
    );
  }
}
