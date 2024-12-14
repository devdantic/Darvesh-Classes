import 'package:darvesh_classes/check_attendance.dart';
import 'package:darvesh_classes/event.dart';
import 'package:darvesh_classes/group_message_admin.dart';
import 'package:darvesh_classes/send_complains_admin.dart';
import 'package:darvesh_classes/student_analysis.dart';
import 'package:darvesh_classes/updateStudyMaterial.dart';
import 'package:darvesh_classes/verify_student_requests.dart';
import 'package:flutter/material.dart';
import 'package:darvesh_classes/mark_attendance.dart';
import 'package:darvesh_classes/authentication_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'empty_database_page.dart';
import 'view_messages_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Page'),
        actions: [
          IconButton(
            onPressed: () {
              _signOut(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Welcome, Sanjay Sir!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                padding: const EdgeInsets.all(10),
                children: [
                  buildButton(
                    context,
                    const UpdateStudyMaterialPage(),
                    'Update Study Material',
                    Icons.library_books,
                    Colors.blue,
                  ),
                  buildButton(
                    context,
                    const MarkAttendancePage(),
                    'Mark Attendance',
                    Icons.calendar_today,
                    Colors.orange,
                  ),
                  buildButton(
                    context,
                    const StudentComplainsPage(),
                    'Send Complains',
                    Icons.notifications,
                    Colors.green,
                  ),
                  buildButton(
                    context,
                    const AddEventPage(),
                    'Add Events in the Calendar',
                    Icons.event,
                    Colors.purple,
                  ),
                  buildButton(
                    context,
                    const SendMessagePage(),
                    'Send Group Messages',
                    Icons.message,
                    Colors.red,
                    fullWidth: true,
                  ),
                  buildButton(
                    context,
                    const CheckAttendancePage(),
                    'Check Attendance',
                    Icons.verified_user_rounded,
                    Colors.brown,
                  ),
                  buildButton(
                    context,
                    const Analysis(),
                    "Student's Analysis",
                    Icons.analytics,
                    Colors.indigoAccent,
                  ),
                  buildButton(
                    context,
                    const EmptyDatabasePage(),
                    // New button for emptying the database
                    'Empty Database',
                    Icons.delete,
                    Colors.grey,
                    fullWidth: true,
                  ),
                  buildButton(
                    context,
                    const VerifyStudentRequestsPage(),
                    'Verify Student Requests',
                    Icons.verified_user_outlined,
                    Colors.teal,
                    fullWidth: true,
                  ),
                  buildButton(
                    context,
                    const ViewMessagesPage(), // New button for viewing messages
                    'View Messages',
                    Icons.message_outlined,
                    Colors.blueGrey,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(BuildContext context, Widget page, String label,
      IconData icon, Color color,
      {bool fullWidth = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: color,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
      await _firebaseAuth.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthenticationPage(),
        ),
      );
    } catch (e) {
      // Handle sign out error
    }
  }
}
