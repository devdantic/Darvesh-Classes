import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UpdateStudyMaterialPage extends StatefulWidget {
  const UpdateStudyMaterialPage({Key? key}) : super(key: key);

  @override
  _UpdateStudyMaterialPageState createState() =>
      _UpdateStudyMaterialPageState();
}

class _UpdateStudyMaterialPageState extends State<UpdateStudyMaterialPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String? _selectedStandard;
  File? _selectedFile;
  bool _isLoading = false;
  String? _selectedMaterialId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedStandard = null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = File(result.files.first.path!);
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('File Selected'),
            content: Text('Selected File: ${_selectedFile!.path}'),
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

  void _uploadFile() async {
    String title = _titleController.text;
    String description = _descriptionController.text;

    if (_selectedStandard == null || title.isEmpty || description.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please fill in all the details.'),
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
      String? fileUrl;
      if (_selectedFile != null) {
        // Upload the file to Firebase Storage
        String fileName = _selectedFile!.path.split('/').last;
        Reference storageReference =
            FirebaseStorage.instance.ref().child('study_materials/$fileName');
        UploadTask uploadTask = storageReference.putFile(_selectedFile!);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
        fileUrl = await taskSnapshot.ref.getDownloadURL();
      }

      // Save or update the study material details to Firestore
      if (_selectedMaterialId == null) {
        await FirebaseFirestore.instance.collection('studyMaterial').add({
          'standard': _selectedStandard,
          'title': title,
          'description': description,
          'fileUrl': fileUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('studyMaterial')
            .doc(_selectedMaterialId)
            .update({
          'standard': _selectedStandard,
          'title': title,
          'description': description,
          'fileUrl': fileUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Send notification to the selected standard
      await _sendNotification();

      // Show a success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Study material uploaded successfully.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Clear the form and selected file after successful upload
                  _titleController.clear();
                  _descriptionController.clear();
                  setState(() {
                    _selectedFile = null;
                    _selectedStandard = null;
                    _selectedMaterialId = null;
                  });
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Show an error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to upload study material.'),
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

  Future<void> _sendNotification() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> result =
          await FirebaseFirestore.instance.collection('Darvesh Classes').get();

      List<String> tokens = [];
      for (var doc in result.docs) {
        if (doc.data().containsKey('std') &&
            doc.data().containsKey('fcmToken')) {
          if (doc.data()['std'] == _selectedStandard) {
            tokens.add(doc.data()['fcmToken']);
          }
        }
      }

      if (tokens.isEmpty) {
        throw Exception('No tokens found for the selected standard');
      }

      const String serverKey =
          'AAAAdjfDsd4:APA91bGBzOGZa1VEAssIAlxhJfVuXBZVWQD6yDjgE4RUT73Cx4RU7KS9APYl5y_wRWdX98Kfo38cjlywY5iPV_pt9EXxtHsrkOGJBUztasm0cSM1U4Tjcu86am3q58PWiJDkxaCFACl8'; // Replace with your actual server key
      final Uri url = Uri.parse('https://fcm.googleapis.com/fcm/send');

      final Map<String, dynamic> payload = {
        'registration_ids': tokens,
        'notification': {
          'title': 'New Study Material',
          'body': 'Study material posted. Check it out!',
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
        print('FCM request failed with status: ${response.statusCode}');
        print('FCM response body: ${response.body}');
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      // Handle notification sending errors
      print('Error sending notification: $e');
      print(_selectedStandard);
      throw Exception('Failed to send notification');
    }
  }

  Future<void> _deleteMaterial(String materialId) async {
    try {
      await FirebaseFirestore.instance
          .collection('studyMaterial')
          .doc(materialId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study material deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete study material')),
      );
    }
  }

  Future<void> _editMaterial(DocumentSnapshot material) async {
    setState(() {
      _selectedMaterialId = material.id;
      _selectedStandard = material['standard'];
      _titleController.text = material['title'];
      _descriptionController.text = material['description'];
      // File handling should be done if there's a need to update the file
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Study Material'),
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
                  _selectedStandard = newValue;
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
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
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
              onPressed: _selectFile,
              child: const Text('Select File'),
            ),
            if (_selectedFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('Selected File: ${_selectedFile!.path}'),
              ),
            ElevatedButton(
              onPressed: _uploadFile,
              child: const Text('Upload Study Material'),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('studyMaterial')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading study materials'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No study materials available'));
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['title'] ?? 'No Title'),
                        subtitle: Text(data['description'] ?? 'No Description'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editMaterial(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteMaterial(doc.id),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
