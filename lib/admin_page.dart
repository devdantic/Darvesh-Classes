import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'check_attendance.dart';
import 'event.dart';
import 'group_message_admin.dart';
import 'send_complains_admin.dart';
import 'updateStudyMaterial.dart';
import 'verify_student_requests.dart';
import 'mark_attendance.dart';
import 'authentication_page.dart';
import 'empty_database_page.dart';
import 'view_messages_page.dart';
import 'theme.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of the Admin Console?',
          style: GoogleFonts.outfit(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await _signOut(context);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService.instance.signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthenticationPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Admin SignOut Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Robustness safeguard: verify current user is the admin
    final currentUserEmail = AuthService.instance.currentUser?.email;
    final isAdmin = currentUserEmail == 'sanjaygovindani757@gmail.com';

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_rounded, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You do not have administrator permissions to view this console.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textLight,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _signOut(context),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Navigation & Hero Banner Section 
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row with App Title & Logout Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: AppTheme.primaryColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Admin Command Console',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => _confirmAndSignOut(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Admin Hero Card Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22.0),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.intenseShadow,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            bottom: -30,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Administrator Portal',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Welcome Back, Sanjay Sir 👋',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentUserEmail ?? 'sanjaygovindani757@gmail.com',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Console Modules',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          '9 Tools Available',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Grid of Admin Cards
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  _buildAdminCard(
                    context,
                    page: const UpdateStudyMaterialPage(),
                    title: 'Study Material',
                    subtitle: 'Upload & Update PDFs',
                    icon: Icons.library_books_rounded,
                    gradientColors: [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
                  ),
                  _buildAdminCard(
                    context,
                    page: const MarkAttendancePage(),
                    title: 'Mark Attendance',
                    subtitle: 'Daily Student Registry',
                    icon: Icons.calendar_today_rounded,
                    gradientColors: [const Color(0xFFFB8C00), const Color(0xFFEF6C00)],
                  ),
                  _buildAdminCard(
                    context,
                    page: const StudentComplainsPage(),
                    title: 'Complains',
                    subtitle: 'Student Feedback',
                    icon: Icons.assignment_late_rounded,
                    gradientColors: [const Color(0xFFE53935), const Color(0xFFC62828)],
                  ),
                  _buildAdminCard(
                    context,
                    page: const AddEventPage(),
                    title: 'Calendar Events',
                    subtitle: 'Exams & Holidays',
                    icon: Icons.event_rounded,
                    gradientColors: [const Color(0xFF8E24AA), const Color(0xFF6A1B9A)],
                  ),
                  _buildAdminCard(
                    context,
                    page: const SendMessagePage(),
                    title: 'Group Message',
                    subtitle: 'Broadcast Notices',
                    icon: Icons.forum_rounded,
                    gradientColors: [const Color(0xFF43A047), const Color(0xFF2E7D32)],
                  ),
                  _buildAdminCard(
                    context,
                    page: const CheckAttendancePage(),
                    title: 'Check Report',
                    subtitle: 'Attendance Summaries',
                    icon: Icons.assignment_turned_in_rounded,
                    gradientColors: [const Color(0xFF6D4C41), const Color(0xFF4E342E)],
                  ),
                  _buildAdminCard(
                    context,
                    page: const VerifyStudentRequestsPage(),
                    title: 'Student Requests',
                    subtitle: 'Approve Registrations',
                    icon: Icons.person_add_alt_1_rounded,
                    gradientColors: [const Color(0xFF00ACC1), const Color(0xFF00838F)],
                  ),
                  _buildAdminCard(
                    context,
                    page: const ViewMessagesPage(),
                    title: 'Inbound Messages',
                    subtitle: 'Messages from Students',
                    icon: Icons.mark_chat_unread_rounded,
                    gradientColors: [const Color(0xFF3F51B5), const Color(0xFF303F9F)],
                  ),
                  _buildAdminCard(
                    context,
                    page: const EmptyDatabasePage(),
                    title: 'Reset Database',
                    subtitle: 'Clear All Records',
                    icon: Icons.delete_forever_rounded,
                    gradientColors: [const Color(0xFF546E7A), const Color(0xFF37474F)],
                    isDestructive: true,
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required Widget page,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDestructive ? Icons.warning_amber_rounded : Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

