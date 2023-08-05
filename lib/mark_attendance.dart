import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({Key? key}) : super(key: key);

  @override
  _MarkAttendancePageState createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _students = [];
  final Map<String, Map<String, bool>> _attendanceStatus = {};
  DateTime _selectedDate = DateTime.now();
  String _lastAttendanceDate = 'N/A';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _getLastAttendanceDate();
  }

  Future<void> _getLastAttendanceDate() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      try {
        DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await FirebaseFirestore.instance
                .collection('admins')
                .doc(userId)
                .get();
        if (userSnapshot.exists) {
          String? lastAttendanceDate =
              userSnapshot.data()?['lastAttendanceDate'];
          if (lastAttendanceDate != null) {
            setState(() {
              _lastAttendanceDate = lastAttendanceDate;
            });
          }
        }
      } catch (e) {
        e;
      }
    }
  }

  Future<void> _fetchStudents() async {
    try {
      final snapshot = await _firestore.collection('Darvesh Classes').get();
      setState(() {
        _students = snapshot.docs.map((doc) {
          return {'studentID': doc.id, ...doc.data()};
        }).toList();
      });
    } catch (e) {
      // print('Error fetching students: $e');
    }
  }

  void _markAttendance(String studentID, bool isPresent) {
    setState(() {
      _attendanceStatus[studentID] ??= {};
      final formattedDate = _selectedDate.toLocal().toString().split(' ')[0];
      _attendanceStatus[studentID]![formattedDate] = isPresent;
    });
  }

  Future<void> _updateAttendance() async {
    final WriteBatch batch = _firestore.batch();
    for (var student in _students) {
      final studentID = student['studentID'].toString();

      final attendanceData = _attendanceStatus[studentID];
      if (attendanceData != null) {
        final DocumentReference attendanceRef =
            _firestore.collection('Attendance').doc(studentID);

        batch.set(
          attendanceRef,
          {
            'name': student['name'],
            'attendanceData': attendanceData,
          },
          SetOptions(merge: true),
        );
      }
    }

    try {
      await batch.commit();
      final formattedDate = _selectedDate.toLocal().toString().split(' ')[0];
      setState(() {
        _lastAttendanceDate = formattedDate;
      });
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('admins').doc(userId).set(
          {
            'lastAttendanceDate': _lastAttendanceDate,
          },
          SetOptions(merge: true),
        );
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastAttendanceDate', _lastAttendanceDate);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance updated successfully!')),
      );
    } catch (e) {
      //print('Error updating attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update attendance. Please try again.')),
      );
    }
  }

  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2021),
      lastDate: DateTime(2095),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                ListTile(
                  title: Text('Last Attendance Date: $_lastAttendanceDate'),
                  trailing: ElevatedButton(
                    onPressed: _selectDate,
                    child: const Text('Select Date for marking Attendance'),
                  ),
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final student = _students[index];
                final studentID = student['studentID'].toString();

                final attendanceData = _attendanceStatus[studentID];

                return ListTile(
                  title: Text(student['name'].toString()),
                  trailing: Checkbox(
                    value: attendanceData?[
                            _selectedDate.toLocal().toString().split(' ')[0]] ??
                        false,
                    onChanged: (bool? value) {
                      _markAttendance(studentID, value ?? false);
                    },
                  ),
                );
              },
              childCount: _students.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateAttendance,
        child: const Icon(Icons.save),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
