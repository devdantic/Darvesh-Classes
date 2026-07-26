import 'package:darvesh_classes/check_attendance.dart';
import 'package:darvesh_classes/event.dart';
import 'package:darvesh_classes/group_message_admin.dart';
import 'package:darvesh_classes/send_complains_admin.dart';
import 'package:darvesh_classes/updateStudyMaterial.dart';
import 'package:darvesh_classes/verify_student_requests.dart';
import 'package:flutter/material.dart';
import 'package:darvesh_classes/mark_attendance.dart';
import 'package:darvesh_classes/authentication_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'empty_database_page.dart';
import 'view_messages_page.dart';
import 'theme.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
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
            // Admin Welcome Header Card
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 36,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back,',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textLight.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Sanjay Sir',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Admin Hub Menu Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                padding: const EdgeInsets.all(24),
                children: [
                  _buildAdminCard(
                    context,
                    const UpdateStudyMaterialPage(),
                    'Study Material',
                    Icons.library_books_outlined,
                    const [Color(0xFF1E88E5), Color(0xFF1976D2)],
                  ),
                  _buildAdminCard(
                    context,
                    const MarkAttendancePage(),
                    'Attendance',
                    Icons.calendar_today_outlined,
                    const [Color(0xFFFB8C00), Color(0xFFF57C00)],
                  ),
                  _buildAdminCard(
                    context,
                    const StudentComplainsPage(),
                    'Complains',
                    Icons.assignment_late_outlined,
                    const [Color(0xFFE53935), Color(0xFFC62828)],
                  ),
                  _buildAdminCard(
                    context,
                    const AddEventPage(),
                    'Calendar Events',
                    Icons.event_outlined,
                    const [Color(0xFF8E24AA), Color(0xFF7B1FA2)],
                  ),
                  _buildAdminCard(
                    context,
                    const SendMessagePage(),
                    'Group Message',
                    Icons.forum_outlined,
                    const [Color(0xFF43A047), Color(0xFF2E7D32)],
                  ),
                  _buildAdminCard(
                    context,
                    const CheckAttendancePage(),
                    'Check Report',
                    Icons.assignment_turned_in_outlined,
                    const [Color(0xFF6D4C41), Color(0xFF4E342E)],
                  ),
                  _buildAdminCard(
                    context,
                    const VerifyStudentRequestsPage(),
                    'Student Requests',
                    Icons.people_outline,
                    const [Color(0xFF00ACC1), Color(0xFF00838F)],
                  ),
                  _buildAdminCard(
                    context,
                    const ViewMessagesPage(),
                    'Inbound Messages',
                    Icons.chat_bubble_outline,
                    const [Color(0xFF3F51B5), Color(0xFF303F9F)],
                  ),
                  _buildAdminCard(
                    context,
                    const EmptyDatabasePage(),
                    'Reset Database',
                    Icons.delete_outline,
                    const [Color(0xFF757575), Color(0xFF616161)],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, Widget page, String label,
      IconData icon, List<Color> gradientColors) {
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
            color: gradientColors[0].withValues(alpha: 0.3),
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
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

  Future<void> _signOut(BuildContext context) async {
    try {
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      await firebaseAuth.signOut();
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
