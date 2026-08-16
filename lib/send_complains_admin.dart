import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/complaint_service.dart';
import 'services/profile_service.dart';
import 'theme.dart';

class StudentComplainsPage extends StatefulWidget {
  const StudentComplainsPage({super.key});

  @override
  State<StudentComplainsPage> createState() => _StudentComplainsPageState();
}

class _StudentComplainsPageState extends State<StudentComplainsPage> {
  final TextEditingController _complaintController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoadingStudents = true;
  bool _isLoadingComplaints = true;
  bool _isSending = false;

  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedStudent;

  List<Map<String, dynamic>> _allComplaints = [];
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  String? _selectedStudentFilterId = 'All';

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
    _fetchComplaints();
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _searchController.dispose();
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
    } finally {
      if (mounted) {
        setState(() => _isLoadingStudents = false);
      }
    }
  }

  Future<void> _fetchComplaints() async {
    setState(() => _isLoadingComplaints = true);
    try {
      final data = await ComplaintService.instance.getAllComplaints();
      if (mounted) {
        setState(() {
          _allComplaints = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching complaints: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingComplaints = false);
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
      final fullContent = _selectedPreset != null
          ? '[$_selectedPreset]\n$complaintText'
          : complaintText;

      await ComplaintService.instance.addComplaint(
        studentId: studentId,
        complaint: fullContent,
      );

      if (mounted) {
        _showSnackBar('Complaint notice sent to $studentName! 📩', const Color(0xFF10B981));
        _complaintController.clear();
        setState(() {
          _selectedPreset = null;
        });
        _fetchComplaints();
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

  Future<void> _deleteComplaint(String complaintId, String studentName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Notice', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this notice for $studentName?', style: GoogleFonts.outfit()),
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

    try {
      await ComplaintService.instance.deleteComplaint(complaintId);
      if (mounted) {
        _showSnackBar('Complaint deleted', Colors.red);
        _fetchComplaints();
      }
    } catch (e) {
      debugPrint('Error deleting complaint: $e');
    }
  }

  void _showEditDialog(String complaintId, String currentText) {
    String? topic;
    String bodyText = currentText;
    if (currentText.startsWith('[') && currentText.contains(']')) {
      final endIdx = currentText.indexOf(']');
      topic = currentText.substring(1, endIdx);
      bodyText = currentText.substring(endIdx + 1).trim();
    }

    final TextEditingController editController = TextEditingController(text: bodyText);
    String? selectedTopic = topic;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Edit Complaint Notice', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category Topic', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedTopic,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      hint: Text('Select Category', style: GoogleFonts.outfit(fontSize: 13)),
                      items: _presetTopics.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.outfit(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedTopic = val),
                    ),
                    const SizedBox(height: 14),
                    Text('Notice Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: editController,
                      maxLines: 4,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  onPressed: () async {
                    final newText = editController.text.trim();
                    if (newText.isNotEmpty) {
                      final updatedContent = selectedTopic != null ? '[$selectedTopic]\n$newText' : newText;
                      await ComplaintService.instance.updateComplaint(
                        complaintId: complaintId,
                        complaint: updatedContent,
                      );
                      if (mounted) {
                        _showSnackBar('Complaint updated successfully!', const Color(0xFF10B981));
                        _fetchComplaints();
                      }
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text('Save Changes', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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

  String _formatDateTime(String? rawIso) {
    if (rawIso == null) return '';
    try {
      final dt = DateTime.parse(rawIso).toLocal();
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${monthNames[dt.month - 1]}, $hour:$minute $amPm';
    } catch (_) {
      return '';
    }
  }

  Map<String, int> _calculateCategoryCounts() {
    final Map<String, int> counts = {
      'Disciplinary Warning': 0,
      'Low Attendance Warning': 0,
      'Homework Not Submitted': 0,
      'Parent Consultation Required': 0,
      'General Notice': 0,
    };

    for (var item in _allComplaints) {
      final text = item['complaint'] as String? ?? '';
      if (text.startsWith('[') && text.contains(']')) {
        final endIdx = text.indexOf(']');
        final topic = text.substring(1, endIdx);
        if (counts.containsKey(topic)) {
          counts[topic] = counts[topic]! + 1;
        } else {
          counts['General Notice'] = (counts['General Notice'] ?? 0) + 1;
        }
      } else {
        counts['General Notice'] = (counts['General Notice'] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Discipline & Complaints Hub',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                _fetchStudents();
                _fetchComplaints();
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textLight,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(icon: Icon(Icons.add_comment_rounded), text: 'Issue Notice'),
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Analytics & History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Issue Notice (Form)
            _buildIssueNoticeTab(),
            // Tab 2: Analytics & History (CRUD & Charts)
            _buildAnalyticsAndHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueNoticeTab() {
    final studentStd = (_selectedStudent?['standard'] ?? _selectedStudent?['std'])?.toString() ?? 'N/A';
    final studentAvatar = (_selectedStudent?['image_url'] ?? _selectedStudent?['imageUrl']) as String?;

    return _isLoadingStudents
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
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

                // Select Student Section
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

                // Selected Student Preview
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

                // Preset Topic Chips
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

                // Submit Button
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
          );
  }

  Widget _buildAnalyticsAndHistoryTab() {
    if (_isLoadingComplaints) {
      return const Center(child: CircularProgressIndicator());
    }

    final categoryCounts = _calculateCategoryCounts();
    final totalCount = _allComplaints.length;

    // Unique students flagged
    final uniqueStudentIds = _allComplaints.map((c) => c['student_id']?.toString()).whereType<String>().toSet();

    // Filter complaints list
    final filteredComplaints = _allComplaints.where((c) {
      final text = (c['complaint'] as String? ?? '').toLowerCase();
      final profile = c['profiles'] as Map<String, dynamic>?;
      final studentName = (profile?['name'] as String? ?? '').toLowerCase();
      final studentId = c['student_id']?.toString() ?? '';

      final matchesQuery = _searchQuery.isEmpty ||
          studentName.contains(_searchQuery.toLowerCase()) ||
          text.contains(_searchQuery.toLowerCase());

      bool matchesCat = true;
      if (_selectedCategoryFilter != 'All') {
        final catLower = _selectedCategoryFilter.toLowerCase();
        matchesCat = text.contains('[$catLower]') || text.contains(catLower);
      }

      bool matchesStudent = true;
      if (_selectedStudentFilterId != 'All' && _selectedStudentFilterId != null) {
        matchesStudent = studentId == _selectedStudentFilterId;
      }

      return matchesQuery && matchesCat && matchesStudent;
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchComplaints,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Remarks',
                    value: totalCount.toString(),
                    icon: Icons.assignment_late_rounded,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Flagged Students',
                    value: uniqueStudentIds.length.toString(),
                    icon: Icons.people_outline_rounded,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pie Chart Visual Analytics Card
            if (totalCount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Breakdown',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 40,
                          sections: [
                            if (categoryCounts['Disciplinary Warning']! > 0)
                              PieChartSectionData(
                                color: Colors.red,
                                value: categoryCounts['Disciplinary Warning']!.toDouble(),
                                title: '${categoryCounts['Disciplinary Warning']}',
                                radius: 45,
                                titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (categoryCounts['Low Attendance Warning']! > 0)
                              PieChartSectionData(
                                color: Colors.orange,
                                value: categoryCounts['Low Attendance Warning']!.toDouble(),
                                title: '${categoryCounts['Low Attendance Warning']}',
                                radius: 45,
                                titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (categoryCounts['Homework Not Submitted']! > 0)
                              PieChartSectionData(
                                color: Colors.amber.shade700,
                                value: categoryCounts['Homework Not Submitted']!.toDouble(),
                                title: '${categoryCounts['Homework Not Submitted']}',
                                radius: 45,
                                titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (categoryCounts['Parent Consultation Required']! > 0)
                              PieChartSectionData(
                                color: Colors.blue,
                                value: categoryCounts['Parent Consultation Required']!.toDouble(),
                                title: '${categoryCounts['Parent Consultation Required']}',
                                radius: 45,
                                titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (categoryCounts['General Notice']! > 0)
                              PieChartSectionData(
                                color: Colors.purple,
                                value: categoryCounts['General Notice']!.toDouble(),
                                title: '${categoryCounts['General Notice']}',
                                radius: 45,
                                titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chart Legend
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildLegendItem('Disciplinary', Colors.red),
                        _buildLegendItem('Attendance', Colors.orange),
                        _buildLegendItem('Homework', Colors.amber.shade700),
                        _buildLegendItem('Parent Meet', Colors.blue),
                        _buildLegendItem('General', Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Search & Filter Header
            Text(
              'Disciplinary Log & History',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 10),

            // Student Filter Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Student:',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStudentFilterId,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryColor),
                        items: [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text(
                              'All Students (${_students.length})',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          ..._students.map((s) {
                            final name = s['name'] as String? ?? 'Student';
                            final std = (s['standard'] ?? s['std'])?.toString();
                            final stdStr = std != null ? ' (Std $std)' : '';
                            return DropdownMenuItem(
                              value: s['id']?.toString() ?? '',
                              child: Text(
                                '$name$stdStr',
                                style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedStudentFilterId = val;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search TextField
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by student name or remark content...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['All', ..._presetTopics].map((cat) {
                  final isSelected = _selectedCategoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.outfit(
                        color: isSelected ? Colors.white : AppTheme.textDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryFilter = cat;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Complaints Log List
            if (filteredComplaints.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Center(
                  child: Text(
                    'No complaints found matching criteria.',
                    style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 14),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredComplaints.length,
                itemBuilder: (context, index) {
                  final item = filteredComplaints[index];
                  final complaintId = item['id']?.toString() ?? '';
                  final text = item['complaint'] as String? ?? '';
                  final createdAt = item['created_at']?.toString();

                  final profile = item['profiles'] as Map<String, dynamic>?;
                  final studentName = profile?['name'] as String? ?? 'Student';
                  final standard = profile?['standard']?.toString() ?? 'N/A';
                  final imageUrl = profile?['image_url'] as String?;

                  String? topic;
                  String bodyMessage = text;
                  if (text.startsWith('[') && text.contains(']')) {
                    final endIdx = text.indexOf(']');
                    topic = text.substring(1, endIdx);
                    bodyMessage = text.substring(endIdx + 1).trim();
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.softShadow,
                      border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                              child: imageUrl == null
                                  ? Text(
                                      studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          studentName,
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Std $standard',
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _formatDateTime(createdAt),
                                    style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textLight),
                                  ),
                                ],
                              ),
                            ),

                            // CRUD Action Buttons
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                              onPressed: () => _showEditDialog(complaintId, text),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              onPressed: () => _deleteComplaint(complaintId, studentName),
                            ),
                          ],
                        ),
                        const Divider(height: 16),

                        if (topic != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              topic,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        Text(
                          bodyMessage,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.textDark,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textDark),
        ),
      ],
    );
  }
}
