import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddEventPage extends StatefulWidget {
  const AddEventPage({Key? key}) : super(key: key);

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  late TextEditingController _titleController;
  DateTime _selectedDate = DateTime.now();
  late TextEditingController _descriptionController;
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please enter title and description.'),
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

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('events').add({
        'title': title,
        'date': _selectedDate,
        'description': description,
      });

      await _sendNotification(title, description, _selectedDate);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content:
                const Text('Event added and notification sent successfully.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to the previous page.
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to add event.'),
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendNotification(
      String title, String description, DateTime date) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> result =
          await FirebaseFirestore.instance.collection('Darvesh Classes').get();
      print("The result is :");
      print(result);

      List<String> tokens = [];
      for (var doc in result.docs) {
        print("Document data:");
        print(doc.data());

        if (doc.data().containsKey('fcmToken')) {
          tokens.add(doc.data()['fcmToken']);
        } else {
          print("Document is missing 'fcmToken' field:");
          print(doc.data());
        }
      }
      print("Tokens are:");
      print(tokens);

      if (tokens.isEmpty) {
        print("No tokens found for sending notifications.");
        return;
      }

      final formattedDate = '${date.day}/${date.month}/${date.year}';
      final payload = {
        'notification': {
          'title': 'New Event on $formattedDate: $title',
          'body': description,
        },
        'registration_ids': tokens,
      };

      final headers = {
        'Content-Type': 'application/json',
        'Authorization':
            'key=AAAAdjfDsd4:APA91bGBzOGZa1VEAssIAlxhJfVuXBZVWQD6yDjgE4RUT73Cx4RU7KS9APYl5y_wRWdX98Kfo38cjlywY5iPV_pt9EXxtHsrkOGJBUztasm0cSM1U4Tjcu86am3q58PWiJDkxaCFACl8',
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        print('FCM request for device sent successfully!');
      } else {
        print('FCM request failed with status: ${response.statusCode}');
        print('FCM response body: ${response.body}');
      }
    } catch (e) {
      // Handle notification sending errors
      print('Error sending notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside the text fields.
              _focusNode.unfocus();
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    focusNode: _focusNode,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    focusNode: _focusNode,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveEvent,
                    child: const Text('Save Event'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
