import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmptyDatabasePage extends StatefulWidget {
  const EmptyDatabasePage({Key? key}) : super(key: key);

  @override
  _EmptyDatabasePageState createState() => _EmptyDatabasePageState();
}

class _EmptyDatabasePageState extends State<EmptyDatabasePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _students = [];
  List<bool> _selectedStudents = [];
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await _firestore.collection('Darvesh Classes').get();

      List<Map<String, dynamic>> students = [];
      querySnapshot.docs.forEach((doc) {
        students.add({
          'id': doc.id,
          'name': doc.data()['name'],
        });
      });

      setState(() {
        _students = students;
        _selectedStudents = List<bool>.filled(students.length, false);
      });
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  Future<void> _deleteStudents() async {
    try {
      List<String> studentsToDelete = [];
      for (int i = 0; i < _students.length; i++) {
        if (_selectedStudents[i]) {
          studentsToDelete.add(_students[i]['id']);
        }
      }

      for (String studentId in studentsToDelete) {
        await _firestore.collection('Darvesh Classes').doc(studentId).delete();
      }

      setState(() {
        _fetchStudents();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected students have been deleted.')),
      );
    } catch (e) {
      print('Error deleting students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting students.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empty Database'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectAll,
                    onChanged: (bool? value) {
                      setState(() {
                        _selectAll = value ?? false;
                        for (int i = 0; i < _selectedStudents.length; i++) {
                          _selectedStudents[i] = _selectAll;
                        }
                      });
                    },
                  ),
                  const Text('Select All'),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _deleteStudents,
                    child: const Text('Delete Selected Students'),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Checkbox(
                    value: _selectedStudents[index],
                    onChanged: (bool? value) {
                      setState(() {
                        _selectedStudents[index] = value ?? false;
                      });
                    },
                  ),
                  title: Text(_students[index]['name']),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
