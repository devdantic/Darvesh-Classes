import 'package:darvesh_classes/show_attendance.dart';
import 'package:darvesh_classes/student_calendar.dart';
import 'package:darvesh_classes/study_material.dart';
import 'package:darvesh_classes/user_profile.dart';
import 'package:flutter/material.dart';
import 'theme.dart';

import 'complain_page.dart';
import 'message_to_sir.dart';
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
        title: const Text('Student Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Welcome Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textLight.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Student Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            // Dashboard Buttons Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                padding: const EdgeInsets.all(24),
                children: [
                  _buildDashboardBar(
                    context,
                    'Study Material',
                    Icons.import_contacts_outlined,
                    const [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                    const StudentStudyMaterialPage(),
                  ),
                  _buildDashboardBar(
                    context,
                    'Messages',
                    Icons.forum_outlined,
                    const [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    const MessageToStudentPage(),
                  ),
                  _buildDashboardBar(
                    context,
                    'Attendance',
                    Icons.analytics_outlined,
                    const [Color(0xFFEF6C00), Color(0xFFFF9800)],
                    const ShowAttendancePage(),
                  ),
                  _buildDashboardBar(
                    context,
                    'All Complains',
                    Icons.assignment_late_outlined,
                    const [Color(0xFFC62828), Color(0xFFE57373)],
                    const ComplainPage(),
                  ),
                  _buildDashboardBar(
                    context,
                    'Important Dates',
                    Icons.event_note_outlined,
                    const [Color(0xFF6A1B9A), Color(0xFFBA68C8)],
                    const StudentCalendarPage(),
                  ),
                  _buildDashboardBar(
                    context,
                    'Message to Sir',
                    Icons.contact_mail_outlined,
                    const [Color(0xFF00838F), Color(0xFF00ACC1)],
                    const MessageToSirPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardBar(BuildContext context, String label, IconData icon,
      List<Color> gradientColors, Widget page) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => page,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
