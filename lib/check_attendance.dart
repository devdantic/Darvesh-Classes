import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CheckAttendancePage extends StatelessWidget {
  const CheckAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Attendance'),
      ),
      body: const StudentAttendanceList(),
    );
  }
}

class StudentAttendanceList extends StatelessWidget {
  const StudentAttendanceList({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Attendance').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final attendanceDocs = snapshot.data!.docs;

        if (attendanceDocs.isEmpty) {
          return const Center(child: Text('No attendance data available.'));
        }
        final Map<String, List<Map<String, dynamic>>> groupedStudents = {};
        for (var doc in attendanceDocs) {
          final studentData = doc.data() as Map<String, dynamic>;
          final studentName = studentData['name'] as String? ?? 'N/A';
          final initial =
              studentName.isNotEmpty ? studentName[0].toUpperCase() : '#';

          groupedStudents.putIfAbsent(initial, () => []);
          groupedStudents[initial]!.add(studentData);
        }
        final sortedInitials = groupedStudents.keys.toList()..sort();

        return ListView.builder(
          itemCount: sortedInitials.length,
          itemBuilder: (context, index) {
            final initial = sortedInitials[index];
            final students = groupedStudents[initial]!;

            return ExpansionTile(
              title: Text(initial,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              children: students.map((studentData) {
                final studentName = studentData['name'] as String? ?? 'N/A';
                final attendanceData =
                    studentData['attendanceData'] as Map<String, dynamic>?;

                return ListTile(
                  title: Text(studentName),
                  subtitle: StudentAttendanceDatesList(attendanceData ?? {}),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class StudentAttendanceDatesList extends StatefulWidget {
  final Map<String, dynamic> attendanceData;

  const StudentAttendanceDatesList(this.attendanceData, {super.key});

  @override
  _StudentAttendanceDatesListState createState() =>
      _StudentAttendanceDatesListState();
}

class _StudentAttendanceDatesListState
    extends State<StudentAttendanceDatesList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final attendanceDates = widget.attendanceData.keys.toList();
    const int maxVisibleDates = 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attendance Dates:', style: TextStyle(fontSize: 14)),
        for (var i = 0;
            i < (_expanded ? attendanceDates.length : maxVisibleDates);
            i++)
          Row(
            children: [
              Text(attendanceDates[i]),
              const SizedBox(width: 10),
              widget.attendanceData[attendanceDates[i]] == true
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        if (attendanceDates.length > maxVisibleDates)
          TextButton(
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Text(
              _expanded ? 'Show Less' : 'Show All',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
      ],
    );
  }
}
