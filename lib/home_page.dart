import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/profile_service.dart';
import 'services/update_service.dart';
import 'show_attendance.dart';
import 'student_calendar.dart';
import 'study_material.dart';
import 'user_profile.dart';
import 'complain_page.dart';
import 'message_to_sir.dart';
import 'message_to_students.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _studentName;
  String? _studentStd;
  String? _profileImageUrl;
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    try {
      final profile = await ProfileService.instance.getCurrentProfile();
      if (profile != null && mounted) {
        setState(() {
          _studentName = profile['name'] as String?;
          final stdValue = profile['standard'] ?? profile['std'];
          _studentStd = stdValue?.toString();
          _profileImageUrl = (profile['image_url'] ?? profile['imageUrl']) as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading student profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingName = false;
        });
        // Check for app updates without Play Store
        UpdateService.instance.checkForUpdates(context);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning ☀️';
    } else if (hour < 17) {
      return 'Good Afternoon 🌤️';
    } else {
      return 'Good Evening 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom Top Navigation Bar & Hero Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Navigation Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Darvesh Classes',
                                  style: GoogleFonts.outfit(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textDark,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  'Student Portal',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppTheme.textLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Profile Avatar Button
                        InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserProfilePage(),
                              ),
                            );
                            _loadStudentProfile();
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryColor, const Color(0xFF38BDF8)],
                              ),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primaryLight,
                              backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                  ? NetworkImage(_profileImageUrl!)
                                  : null,
                              child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 22,
                                      color: AppTheme.primaryColor,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Scenic Hero Welcome Card Banner
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
                          // Background Ambient Decorative Circles
                          Positioned(
                            right: -25,
                            bottom: -35,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 40,
                            top: -20,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _isLoadingName
                                    ? 'Welcome back!'
                                    : 'Welcome, ${_studentName ?? "Student"}! 👋',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _studentStd != null
                                    ? 'Class Standard $_studentStd • Academic Workspace'
                                    : 'Student Hub • Darvesh Classes Academy',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Title Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Learning Dashboard',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '6 Active Modules',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Dashboard Grid Options
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.94,
                children: [
                  _buildDashboardCard(
                    context,
                    title: 'Study Material',
                    subtitle: 'Course Notes & PDFs',
                    icon: Icons.import_contacts_rounded,
                    gradientColors: [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
                    page: const StudentStudyMaterialPage(),
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Group Messages',
                    subtitle: 'Read Broadcasts',
                    icon: Icons.campaign_rounded,
                    gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
                    page: const MessageToStudentPage(),
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Attendance',
                    subtitle: 'Records & Analytics',
                    icon: Icons.analytics_rounded,
                    gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                    page: const ShowAttendancePage(),
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Complaints',
                    subtitle: 'Notices & Discipline',
                    icon: Icons.assignment_late_rounded,
                    gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    page: const ComplainPage(),
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Important Dates',
                    subtitle: 'Exams, Holidays and more',
                    icon: Icons.event_note_rounded,
                    gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
                    page: const StudentCalendarPage(),
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Chat with Sir',
                    subtitle: 'Raise your concerns here',
                    icon: Icons.mark_chat_read_rounded,
                    gradientColors: [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
                    page: const MessageToSirPage(),
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

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Widget page,
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
            color: gradientColors[0].withValues(alpha: 0.35),
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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => page,
              ),
            );
            _loadStudentProfile();
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon Header & Arrow
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
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                // Labels
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
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
                        color: Colors.white.withValues(alpha: 0.85),
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
