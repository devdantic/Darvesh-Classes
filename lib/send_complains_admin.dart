import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/complaint_service.dart';
import 'services/profile_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';

class StudentComplainsPage extends StatefulWidget {
  const StudentComplainsPage({super.key});

  @override
  State<StudentComplainsPage> createState() => _StudentComplainsPageState();
}

class _StudentComplainsPageState extends State<StudentComplainsPage> {
  final TextEditingController _complaintController = TextEditingController();
  
  bool _isLoadingStudents = true;
  bool _isSending = false;
  
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedStudent;

  final List<String> _presetTopics = [
    'Disciplinary Warning',
    'Low Attendance Warning',
    'Homework Not Submitted',
    'Parent Consultation Required',
    'General Notice',
  ];
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      final profiles = await ProfileService.instance.getAllProfiles();
      if (mounted) {
        setState(() {
          _students = profiles;
          if (_students.isNotEmpty) {
            _selectedStudent = _students.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      if (mounted) {
        _showSnackBar('Error loading students list', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStudents = false);
      }
    }
  }

  Future<void> _sendComplaint() async {
    if (_selectedStudent == null) {
      _showSnackBar('Please select a student first.', Colors.amber[800]!);
      return;
    }

    final complaintText = _complaintController.text.trim();
    if (complaintText.isEmpty) {
      _showSnackBar('Please enter complaint details.', Colors.amber[800]!);
      return;
    }

    final studentId = _selectedStudent!['id'] as String?;
    final studentName = _selectedStudent!['name'] as String? ?? 'Student';

    if (studentId == null) {
      _showSnackBar('Invalid student record selected.', Colors.red);
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1. Insert complaint into Supabase 'complaints' table
      final fullContent = _selectedPreset != null
          ? '[$_selectedPreset]\n$complaintText'
          : complaintText;

      await ComplaintService.instance.addComplaint(
        studentId: studentId,
        complaint: fullContent,
      );

      // Trigger push notification via Supabase Edge Function
      NotificationService.instance.sendUserNotification(
        userId: studentId,
        title: 'New Complaint Notice',
        body: fullContent,
        data: {'type': 'complaint'},
      );

      if (mounted) {
        _showSnackBar('Complaint recorded & sent to $studentName! 📩', const Color(0xFF10B981));
        _complaintController.clear();
        setState(() {
          _selectedPreset = null;
        });
      }
    } catch (e) {
      debugPrint('Error sending complaint: $e');
      if (mounted) {
        _showSnackBar('Failed to send complaint: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
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
    final studentStd = (_selectedStudent?['standard'] ?? _selectedStudent?['std'])?.toString() ?? 'N/A';
    final studentAvatar = (_selectedStudent?['image_url'] ?? _selectedStudent?['imageUrl']) as String?;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Send Complaints',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: _isLoadingStudents
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading students...',
                    style: GoogleFonts.outfit(color: AppTheme.textLight),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Card Banner
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
                            Icons.assignment_late_rounded,
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
                                'Issue Student Notice',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Send official complaints directly to a student portal inbox.',
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
                  const SizedBox(height: 24),

                  // 1. Select Student Section
                  Text(
                    'Target Student',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                      border: Border.all(
                        color: AppTheme.primaryLight.withValues(alpha: 0.4),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _selectedStudent,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_circle_rounded, color: AppTheme.primaryColor),
                        items: _students.map((student) {
                          final name = student['name'] as String? ?? 'Unnamed';
                          final std = (student['standard'] ?? student['std'])?.toString() ?? 'N/A';
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: student,
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 20, color: AppTheme.primaryColor),
                                const SizedBox(width: 10),
                                Text(
                                  '$name (Std $std)',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedStudent = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected Student Card Preview
                  if (_selectedStudent != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryColor,
                            backgroundImage: studentAvatar != null && studentAvatar.isNotEmpty
                                ? NetworkImage(studentAvatar)
                                : null,
                            child: studentAvatar == null || studentAvatar.isEmpty
                                ? const Icon(Icons.person, color: Colors.white, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedStudent!['name'] as String? ?? 'Student',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  'Class Std $studentStd • ${_selectedStudent!['phone'] ?? _selectedStudent!['email'] ?? "Active Student"}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Preset Topic Chips (Optional Shortcut)
                  Text(
                    'Topic Category (Optional)',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetTopics.map((topic) {
                      final isSelected = _selectedPreset == topic;
                      return ChoiceChip(
                        label: Text(topic, style: GoogleFonts.outfit(fontSize: 12)),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedPreset = selected ? topic : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Complaint Detail Input Field
                  Text(
                    'Complaint Message',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _complaintController,
                    minLines: 4,
                    maxLines: 8,
                    style: GoogleFonts.outfit(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Enter detailed complaint note for the student...',
                      alignLabelWithHint: true,
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isSending ? null : _sendComplaint,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _isSending ? 'Sending Complaint...' : 'Send Complaint Notice',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

