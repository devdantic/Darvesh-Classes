import 'package:darvesh_classes/show_attendance.dart';
import 'package:darvesh_classes/student_calendar.dart';
import 'package:darvesh_classes/study_material.dart';
import 'package:darvesh_classes/user_profile.dart';
import 'package:flutter/material.dart';

import 'complain_page.dart';
import 'message_to_sir.dart'; // Import the new page
import 'message_to_students.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfilePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildButton(
              context,
              'Study Material',
              Icons.book,
              Colors.blue,
              const StudentStudyMaterialPage(),
            ),
            _buildButton(
              context,
              'Messages',
              Icons.message,
              Colors.green,
              const MessageToStudentPage(),
            ),
            _buildButton(
              context,
              'View Attendance',
              Icons.data_exploration,
              Colors.orange,
              const ShowAttendancePage(),
            ),
            _buildButton(
              context,
              'View Complains',
              Icons.warning,
              Colors.red,
              const ComplainPage(),
            ),
            _buildButton(
              context,
              'Important Dates',
              Icons.date_range,
              Colors.purple,
              const StudentCalendarPage(),
            ),
            _buildButton(
              context,
              'Message to Sir',
              Icons.mail_outline,
              Colors.teal,
              const MessageToSirPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, IconData icon,
      Color color, Widget page) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => page,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
