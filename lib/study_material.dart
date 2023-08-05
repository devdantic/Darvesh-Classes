import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class StudentStudyMaterialPage extends StatefulWidget {
  const StudentStudyMaterialPage({Key? key}) : super(key: key);

  @override
  _StudentStudyMaterialPageState createState() =>
      _StudentStudyMaterialPageState();
}

class _StudentStudyMaterialPageState extends State<StudentStudyMaterialPage> {
  late String? _selectedStandard;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _studyMaterialStream;
  List<DocumentSnapshot<Map<String, dynamic>>> studyMaterials = [];

  @override
  void initState() {
    super.initState();
    _selectedStandard = 'Std 5';
    _studyMaterialStream = FirebaseFirestore.instance
        .collection('studyMaterial')
        .where('standard', isEqualTo: _selectedStandard)
        .snapshots();

    _studyMaterialStream.listen((snapshot) {
      setState(() {
        studyMaterials = snapshot.docs.toList();
      });
    });
  }

  @override
  void dispose() {
    _studyMaterialStream.drain();
    super.dispose();
  }

  void _onStandardChanged(String? selectedStandard) {
    setState(() {
      _selectedStandard = selectedStandard;
      _studyMaterialStream = FirebaseFirestore.instance
          .collection('studyMaterial')
          .where('standard', isEqualTo: _selectedStandard)
          .snapshots();
    });
  }

  Future<void> _launchFileUrl(String fileUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = fileUrl.split('/').last;
      final filePath = '${tempDir.path}/$fileName';

      final ref = firebase_storage.FirebaseStorage.instance.refFromURL(fileUrl);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const AlertDialog(
            title: Text('Download Progress'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text('Downloading File...'),
              ],
            ),
          );
        },
      );
      await ref.writeToFile(File(filePath));
      Navigator.pop(context);
      await OpenFile.open(filePath);
    } catch (e) {
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to open file.'),
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
        title: const Text('Study Material'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStandard,
              onChanged: _onStandardChanged,
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
            Expanded(
              child: SingleChildScrollView(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _studyMaterialStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    var studyMaterials = snapshot.data!.docs;

                    if (studyMaterials.isEmpty) {
                      return const Text(
                          'No study material available for the selected standard.');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: studyMaterials.length,
                      itemBuilder: (context, index) {
                        var studyMaterial = studyMaterials[index];
                        String title = studyMaterial['title'];
                        String description = studyMaterial['description'];
                        String? fileUrl = studyMaterial['fileUrl'];

                        return Card(
                          child: ListTile(
                            title: Text(title),
                            subtitle: Text(description),
                            onTap: () {
                              if (fileUrl != null) {
                                _launchFileUrl(fileUrl);
                              }
                            },
                            trailing: fileUrl != null
                                ? ElevatedButton(
                                    onPressed: () {
                                      _launchFileUrl(fileUrl);
                                    },
                                    child: const Text('Download File'),
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
