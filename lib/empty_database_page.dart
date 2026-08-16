import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/attendance_service.dart';
import 'services/notification_service.dart';
import 'services/profile_service.dart';
import 'theme.dart';

class EmptyDatabasePage extends StatefulWidget {
  const EmptyDatabasePage({super.key});

  @override
  State<EmptyDatabasePage> createState() => _EmptyDatabasePageState();
}

class _EmptyDatabasePageState extends State<EmptyDatabasePage> {
  bool _isLoading = true;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _students = [];

  // Tab 2 Selection State
  final Set<String> _selectedStudentIds = {};
  bool _selectAll = false;

  // Batch Promotion State
  int _batchFromStandard = 9;
  int _batchToStandard = 10;

  final List<int> _availableStandards = [5, 6, 7, 8, 9, 10, 11];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await ProfileService.instance.getAllProfiles();
      if (mounted) {
        setState(() {
          // Exclude Admin (Sanjay Sir) from deletion/migration lists to protect admin credentials
          _students = profiles.where((p) {
            final email = (p['email'] as String? ?? '').toLowerCase();
            final name = (p['name'] as String? ?? '').toLowerCase();
            return email != 'sanjaygovindani757@gmail.com' && !name.contains('sanjay');
          }).toList();
          _selectedStudentIds.clear();
          _selectAll = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching students for management: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------
  // ANNUAL MASS PROMOTION (Std 5->6, 6->7, 7->8, 8->9, 9->10)
  // ---------------------------------------------------------
  Future<void> _runAnnualMassPromotion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Advance All Students to Next Grade', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'This will promote all active students to their next consecutive class grade (Std 5➔6, 6➔7, 7➔8, 8➔9, 9➔10).\n\nAll student metadata, chat history, attendance, and records will remain 100% intact.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Advance All Students', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Get all student IDs to clear attendance for new academic session
      final studentIds = _students.map((s) => s['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();

      // 2. Clear attendance logs for the promoted students so their new grade starts fresh at 0%
      await AttendanceService.instance.clearAttendanceForStudentList(studentIds);

      // 3. Promote in reverse order (9->10, 8->9, 7->8, 6->7, 5->6) to avoid double promotion
      for (int std = 9; std >= 5; std--) {
        await ProfileService.instance.promoteStandardBatch(std, std + 1);

        // Send push notification to target promoted class topic
        try {
          await NotificationService.instance.sendTopicNotification(
            topic: 'std_${std + 1}',
            title: '🎉 Grade Promotion Announced!',
            body: 'Congratulations! You have been promoted to Std ${std + 1}.',
            data: {'type': 'promotion'},
          );
        } catch (_) {}
      }

      if (mounted) {
        _showSnackBar('Annual Mass Promotion & Attendance Reset completed! 🎓', const Color(0xFF10B981));
        _fetchStudents();
      }
    } catch (e) {
      debugPrint('Error running mass promotion: $e');
      if (mounted) {
        _showSnackBar('Promotion failed: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ---------------------------------------------------------
  // BATCH STANDARD PROMOTION
  // ---------------------------------------------------------
  Future<void> _runBatchStandardPromotion() async {
    if (_batchFromStandard == _batchToStandard) {
      _showSnackBar('Source and Target standards must be different.', Colors.amber[800]!);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Promote Std $_batchFromStandard to Std $_batchToStandard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to promote all Std $_batchFromStandard students to Std $_batchToStandard?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Promote Batch', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Get student IDs of the batch to clear attendance
      final batchStudentIds = _students
          .where((s) => (s['standard'] ?? s['std']) == _batchFromStandard)
          .map((s) => s['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (batchStudentIds.isNotEmpty) {
        await AttendanceService.instance.clearAttendanceForStudentList(batchStudentIds);
      }

      // 2. Promote standard batch
      await ProfileService.instance.promoteStandardBatch(_batchFromStandard, _batchToStandard);

      // Notify target class topic
      try {
        await NotificationService.instance.sendTopicNotification(
          topic: 'std_$_batchToStandard',
          title: '🎉 Grade Promotion Update!',
          body: 'Your class has been promoted to Std $_batchToStandard. Attendance has been reset for the new session.',
          data: {'type': 'promotion'},
        );
      } catch (_) {}

      if (mounted) {
        _showSnackBar('Std $_batchFromStandard promoted to Std $_batchToStandard & attendance reset!', const Color(0xFF10B981));
        _fetchStudents();
      }
    } catch (e) {
      debugPrint('Error promoting batch: $e');
      if (mounted) {
        _showSnackBar('Batch promotion failed: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ---------------------------------------------------------
  // INDIVIDUAL STUDENT GRADE MIGRATION
  // ---------------------------------------------------------
  void _showIndividualMigrationDialog(Map<String, dynamic> student) {
    final studentId = student['id']?.toString() ?? '';
    final name = student['name'] as String? ?? 'Student';
    final currentStd = (student['standard'] ?? student['std']) is int ? (student['standard'] ?? student['std']) as int : 10;

    int selectedNewStd = currentStd;
    bool resetAttendance = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Migrate Grade: $name', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Grade: Std $currentStd', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textLight)),
                  const SizedBox(height: 14),
                  Text('Select New Grade Standard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: selectedNewStd,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _availableStandards.map((std) {
                      return DropdownMenuItem(value: std, child: Text(std == 11 ? 'Std 11 (Graduated/Alumni)' : 'Std $std', style: GoogleFonts.outfit(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedNewStd = val ?? selectedNewStd),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: resetAttendance,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) => setDialogState(() => resetAttendance = val ?? true),
                      ),
                      Expanded(
                        child: Text(
                          'Reset attendance for new grade',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  onPressed: () async {
                    if (resetAttendance) {
                      await AttendanceService.instance.clearStudentAttendance(studentId);
                    }
                    await ProfileService.instance.promoteStudent(studentId, selectedNewStd);
                    if (mounted) {
                      _showSnackBar('$name migrated to Std $selectedNewStd! ${resetAttendance ? "(Attendance reset)" : ""}', const Color(0xFF10B981));
                      _fetchStudents();
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text('Migrate Grade', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------
  // DELETE SELECTED STUDENTS
  // ---------------------------------------------------------
  Future<void> _deleteSelectedStudents() async {
    if (_selectedStudentIds.isEmpty) {
      _showSnackBar('Please select at least one student profile to delete.', Colors.amber[800]!);
      return;
    }

    final count = _selectedStudentIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Student Profiles', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete $count selected student profile(s)? This will cascade and purge their chat history, attendance, and records.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      for (final id in _selectedStudentIds) {
        await ProfileService.instance.deleteProfile(id);
      }

      if (mounted) {
        _showSnackBar('$count student profile(s) deleted successfully.', Colors.red);
        _fetchStudents();
      }
    } catch (e) {
      debugPrint('Error deleting students: $e');
      if (mounted) {
        _showSnackBar('Error deleting profiles: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Academic Grade & Database Ops',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetchStudents,
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textLight,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(icon: Icon(Icons.school_rounded), text: 'Grade Progression'),
              Tab(icon: Icon(Icons.cleaning_services_rounded), text: 'Reset & Cleanup'),
            ],
          ),
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading student records...',
                      style: GoogleFonts.outfit(color: AppTheme.textLight),
                    ),
                  ],
                ),
              )
            : TabBarView(
                children: [
                  _buildGradeProgressionTab(),
                  _buildResetCleanupTab(),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------
  // TAB 1: GRADE PROGRESSION & MIGRATION
  // ---------------------------------------------------------
  Widget _buildGradeProgressionTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Annual Academic Promotion',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Promote students to next grade while preserving 100% of their chat history, attendance, and records.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Annual Mass Promotion Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_mode_rounded, color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Annual Mass Promotion (All Classes)',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Promotes all students across Std 5➔6, 6➔7, 7➔8, 8➔9, 9➔10 in 1 tap.',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isProcessing ? null : _runAnnualMassPromotion,
                    icon: const Icon(Icons.rocket_launch_rounded),
                    label: Text(
                      _isProcessing ? 'Promoting...' : 'Run Annual Mass Promotion',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Batch Standard Migration Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promote Specific Class Standard',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From Class', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<int>(
                            value: _batchFromStandard,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: [5, 6, 7, 8, 9, 10].map((std) {
                              return DropdownMenuItem(value: std, child: Text('Std $std', style: GoogleFonts.outfit(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) => setState(() => _batchFromStandard = val ?? _batchFromStandard),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryColor),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('To Target Class', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<int>(
                            value: _batchToStandard,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: [6, 7, 8, 9, 10, 11].map((std) {
                              return DropdownMenuItem(
                                value: std,
                                child: Text(std == 11 ? 'Std 11 (Alumni)' : 'Std $std', style: GoogleFonts.outfit(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _batchToStandard = val ?? _batchToStandard),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isProcessing ? null : _runBatchStandardPromotion,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(
                      'Promote Std $_batchFromStandard ➔ Std $_batchToStandard',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Individual Student Grade List
          Text(
            'Individual Student Roster & Grade Migration',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),

          if (_students.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
              ),
              child: Center(
                child: Text('No active student profiles found.', style: GoogleFonts.outfit(color: AppTheme.textLight)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final name = student['name'] as String? ?? 'Student';
                final std = (student['standard'] ?? student['std'])?.toString() ?? 'N/A';
                final avatar = student['image_url'] as String?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow,
                    border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'S',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            )
                          : null,
                    ),
                    title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                    subtitle: Text('Current: Std $std', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight)),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        foregroundColor: AppTheme.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => _showIndividualMigrationDialog(student),
                      icon: const Icon(Icons.school_rounded, size: 16),
                      label: Text('Migrate', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // TAB 2: RESET & CLEANUP
  // ---------------------------------------------------------
  Widget _buildResetCleanupTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cascading Cleanup Active',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Deleting a student profile automatically purges all their messages, complaints, and attendance logs. Admin (Sanjay Sir) is protected.',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top Controls Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Checkbox(
                  activeColor: AppTheme.primaryColor,
                  value: _selectAll,
                  onChanged: (bool? value) {
                    setState(() {
                      _selectAll = value ?? false;
                      if (_selectAll) {
                        _selectedStudentIds.addAll(_students.map((s) => s['id']?.toString() ?? ''));
                      } else {
                        _selectedStudentIds.clear();
                      }
                    });
                  },
                ),
                Text(
                  'Select All (${_students.length})',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: _isProcessing || _selectedStudentIds.isEmpty ? null : _deleteSelectedStudents,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: Text(
                    _isProcessing ? 'Deleting...' : 'Delete Selected (${_selectedStudentIds.length})',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Student Profiles List
          Expanded(
            child: _students.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 50, color: Colors.grey[350]),
                        const SizedBox(height: 12),
                        Text(
                          'Database Reset Complete',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No active student profiles currently in Supabase.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final id = student['id']?.toString() ?? '';
                      final name = student['name'] as String? ?? 'Student';
                      final std = (student['standard'] ?? student['std'])?.toString() ?? 'N/A';
                      final avatar = student['image_url'] as String?;
                      final isSelected = _selectedStudentIds.contains(id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.softShadow,
                          border: Border.all(
                            color: isSelected
                                ? Colors.red.withValues(alpha: 0.5)
                                : AppTheme.primaryLight.withValues(alpha: 0.3),
                          ),
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            activeColor: Colors.red,
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedStudentIds.add(id);
                                } else {
                                  _selectedStudentIds.remove(id);
                                }
                                _selectAll = _selectedStudentIds.length == _students.length;
                              });
                            },
                          ),
                          title: Text(
                            name,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                          ),
                          subtitle: Text(
                            'Class Std $std',
                            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight),
                          ),
                          trailing: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                            child: avatar == null
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 12),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
