import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class UpdateStudyMaterialPage extends StatefulWidget {
  const UpdateStudyMaterialPage({Key? key}) : super(key: key);

  @override
  _UpdateStudyMaterialPageState createState() =>
      _UpdateStudyMaterialPageState();
}

class _UpdateStudyMaterialPageState extends State<UpdateStudyMaterialPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedStandard;
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedStandard = 'Std 5';
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

    if (title.isEmpty || description.isEmpty) {
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

      // Save the study material details to Firestore
      await FirebaseFirestore.instance.collection('studyMaterial').add({
        'standard': _selectedStandard,
        'title': title,
        'description': description,
        'fileUrl': fileUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

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
                  });
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      //print('Error uploading study material: $e');
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
    }
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
          ],
        ),
      ),
    );
  }
}
