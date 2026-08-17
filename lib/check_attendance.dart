import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/attendance_service.dart';
import 'services/profile_service.dart';
import 'theme.dart';

class CheckAttendancePage extends StatefulWidget {
  const CheckAttendancePage({super.key});

  @override
  State<CheckAttendancePage> createState() => _CheckAttendancePageState();
}

class _CheckAttendancePageState extends State<CheckAttendancePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allAttendance = [];
  List<Map<String, dynamic>> _students = [];

  String? _selectedStudentId = 'ALL'; // 'ALL' = Overall Darvesh Classes
  String _selectedStandardFilter = 'All';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final attendanceData = await AttendanceService.instance.getAllAttendance();
      final profilesData = await ProfileService.instance.getAllProfiles();

      if (mounted) {
        setState(() {
          _allAttendance = attendanceData;
          _students = profilesData;
        });
      }
    } catch (e) {
      debugPrint('Error loading attendance report: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAttendance(String studentId, String dateStr, bool currentPresent) async {
    try {
      final date = DateTime.parse(dateStr);
      await AttendanceService.instance.updateAttendance(
        studentId: studentId,
        date: date,
        present: !currentPresent,
      );
      if (mounted) {
        _showSnackBar('Attendance updated!', const Color(0xFF10B981));
        _loadData();
      }
    } catch (e) {
      debugPrint('Error updating attendance: $e');
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

  String _formatDate(String? rawIso) {
    if (rawIso == null) return '';
    try {
      final dt = DateTime.parse(rawIso);
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${dayNames[dt.weekday - 1]}, ${dt.day} ${monthNames[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return rawIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Attendance Reports & Check',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
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
                    'Generating attendance report...',
                    style: GoogleFonts.outfit(color: AppTheme.textLight),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Smart Selector Bar
                    Text(
                      'Report Scope / Target Student',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStudentId,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_circle_rounded, color: AppTheme.primaryColor),
                          items: [
                            DropdownMenuItem(
                              value: 'ALL',
                              child: Row(
                                children: [
                                  const Icon(Icons.apartment_rounded, color: AppTheme.primaryColor, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Overall Darvesh Classes (All Students)',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            ..._students.map((s) {
                              final name = s['name'] as String? ?? 'Student';
                              final std = (s['standard'] ?? s['std'])?.toString() ?? 'N/A';
                              return DropdownMenuItem(
                                value: s['id']?.toString() ?? '',
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded, size: 18, color: AppTheme.primaryColor),
                                    const SizedBox(width: 10),
                                    Text(
                                      '$name (Std $std)',
                                      style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textDark),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedStudentId = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Content Rendering based on Selection Mode
                    if (_selectedStudentId == 'ALL')
                      _buildOverallAcademyReport()
                    else
                      _buildSingleStudentReport(_selectedStudentId!),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------
  // OVERALL ACADEMY REPORT (DEFAULT)
  // ---------------------------------------------------------
  Widget _buildOverallAcademyReport() {
    // Filter records by standard if standard filter selected
    final filteredAttendance = _allAttendance.where((r) {
      if (_selectedStandardFilter == 'All') return true;
      final profile = r['profiles'] as Map<String, dynamic>?;
      final std = (profile?['standard'] ?? profile?['std'])?.toString();
      return std == _selectedStandardFilter;
    }).toList();

    int totalPresent = 0;
    int totalAbsent = 0;

    for (var r in filteredAttendance) {
      if (r['present'] == true) {
        totalPresent++;
      } else {
        totalAbsent++;
      }
    }

    final totalCount = totalPresent + totalAbsent;
    final overallPct = totalCount > 0 ? (totalPresent / totalCount) * 100 : 0.0;

    // Calculate per-student attendance percentage stats
    final Map<String, Map<String, dynamic>> studentStats = {};
    for (var s in _students) {
      final sId = s['id']?.toString() ?? '';
      studentStats[sId] = {
        'profile': s,
        'present': 0,
        'absent': 0,
      };
    }

    for (var r in _allAttendance) {
      final sId = r['student_id']?.toString() ?? '';
      if (studentStats.containsKey(sId)) {
        if (r['present'] == true) {
          studentStats[sId]!['present'] = (studentStats[sId]!['present'] as int) + 1;
        } else {
          studentStats[sId]!['absent'] = (studentStats[sId]!['absent'] as int) + 1;
        }
      }
    }

    final studentStatsList = studentStats.values.where((st) {
      final profile = st['profile'] as Map<String, dynamic>?;
      final name = (profile?['name'] as String? ?? '').toLowerCase();
      final std = (profile?['standard'] ?? profile?['std'])?.toString() ?? '';

      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
      final matchesStd = _selectedStandardFilter == 'All' || std == _selectedStandardFilter;

      return matchesSearch && matchesStd;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Banner
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
                  Icons.analytics_rounded,
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
                      'Darvesh Classes Summary',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Overall academy attendance rate is ${overallPct.toStringAsFixed(1)}% across $totalCount sessions.',
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

        // Metrics Summary Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Total Sessions',
                value: '$totalCount',
                icon: Icons.event_available_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                label: 'Total Present',
                value: '$totalPresent',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                label: 'Total Absent',
                value: '$totalAbsent',
                icon: Icons.cancel_rounded,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Pie Chart Visual Analytics
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
              children: [
                Text(
                  'Academy Attendance Ratio',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 170,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: [
                        if (totalPresent > 0)
                          PieChartSectionData(
                            color: const Color(0xFF10B981),
                            value: totalPresent.toDouble(),
                            title: '${overallPct.toStringAsFixed(0)}%',
                            radius: 45,
                            titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        if (totalAbsent > 0)
                          PieChartSectionData(
                            color: Colors.red,
                            value: totalAbsent.toDouble(),
                            title: '${(100 - overallPct).toStringAsFixed(0)}%',
                            radius: 45,
                            titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Class Standard Filter Chips
        Text(
          'Filter by Class Standard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ['All', '5', '6', '7', '8', '9', '10'].map((stdStr) {
              final isSelected = _selectedStandardFilter == stdStr;
              final label = stdStr == 'All' ? 'All Classes' : 'Std $stdStr';
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(label),
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
                      _selectedStandardFilter = stdStr;
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

        // Search Bar for Students
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search student by name...',
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

        // Student Roster List with Individual Attendance %
        Text(
          'Student Roster & Individual Standing',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 12),

        if (studentStatsList.isEmpty)
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
                'No student records matching criteria.',
                style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 14),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: studentStatsList.length,
            itemBuilder: (context, index) {
              final st = studentStatsList[index];
              final profile = st['profile'] as Map<String, dynamic>;
              final sId = profile['id']?.toString() ?? '';
              final name = profile['name'] as String? ?? 'Student';
              final std = (profile['standard'] ?? profile['std'])?.toString() ?? 'N/A';
              final avatar = profile['image_url'] as String?;

              final pCount = st['present'] as int;
              final aCount = st['absent'] as int;
              final tCount = pCount + aCount;
              final rate = tCount > 0 ? (pCount / tCount) * 100 : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Std $std',
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    tCount > 0 ? '$pCount Present • $aCount Absent' : 'No records logged yet',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: rate >= 85
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : rate >= 75
                              ? Colors.amber.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tCount > 0 ? '${rate.toStringAsFixed(0)}%' : 'N/A',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rate >= 85
                            ? const Color(0xFF10B981)
                            : rate >= 75
                                ? Colors.amber[900]
                                : Colors.red,
                      ),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedStudentId = sId;
                    });
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  // ---------------------------------------------------------
  // SINGLE STUDENT REPORT VIEW
  // ---------------------------------------------------------
  Widget _buildSingleStudentReport(String studentId) {
    final studentProfile = _students.firstWhere(
      (s) => s['id']?.toString() == studentId,
      orElse: () => {},
    );

    final name = studentProfile['name'] as String? ?? 'Student';
    final std = (studentProfile['standard'] ?? studentProfile['std'])?.toString() ?? 'N/A';
    final phone = studentProfile['phone'] as String? ?? '';
    final avatar = studentProfile['image_url'] as String?;

    final studentRecords = _allAttendance
        .where((r) => r['student_id']?.toString() == studentId)
        .toList();

    int pCount = 0;
    int aCount = 0;
    for (var r in studentRecords) {
      if (r['present'] == true) {
        pCount++;
      } else {
        aCount++;
      }
    }
    final tCount = pCount + aCount;
    final rate = tCount > 0 ? (pCount / tCount) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Info Card Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow,
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryColor),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Class Std $std ${phone.isNotEmpty ? "• 📞 $phone" : ""}',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  setState(() {
                    _selectedStudentId = 'ALL';
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text('All Summary', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Metrics Summary Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Present Days',
                value: '$pCount',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                label: 'Absent Days',
                value: '$aCount',
                icon: Icons.cancel_rounded,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                label: 'Attendance Rate',
                value: '${rate.toStringAsFixed(0)}%',
                icon: Icons.analytics_rounded,
                color: rate >= 85
                    ? const Color(0xFF10B981)
                    : rate >= 75
                        ? Colors.amber[800]!
                        : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Student Specific Pie Chart
        if (tCount > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                Text(
                  'Individual Attendance Proportion ($name)',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 36,
                      sections: [
                        if (pCount > 0)
                          PieChartSectionData(
                            color: const Color(0xFF10B981),
                            value: pCount.toDouble(),
                            title: '${rate.toStringAsFixed(0)}%',
                            radius: 40,
                            titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        if (aCount > 0)
                          PieChartSectionData(
                            color: Colors.red,
                            value: aCount.toDouble(),
                            title: '${(100 - rate).toStringAsFixed(0)}%',
                            radius: 40,
                            titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Daily Attendance Log List
        Row(
          children: [
            Expanded(
              child: Text(
                'Attendance Session History',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ),
            Text(
              'Tap entry to toggle status',
              style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textLight),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (studentRecords.isEmpty)
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
                'No attendance logged for $name yet.',
                style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 14),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: studentRecords.length,
            itemBuilder: (context, index) {
              final r = studentRecords[index];
              final dateStr = r['attendance_date']?.toString() ?? '';
              final isPresent = r['present'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(
                    color: isPresent
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Icon(
                    isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isPresent ? const Color(0xFF10B981) : Colors.red,
                    size: 22,
                  ),
                  title: Text(
                    _formatDate(dateStr),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                  ),
                  subtitle: Text(
                    'Tap to change to ${isPresent ? "ABSENT" : "PRESENT"}',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textLight),
                  ),
                  trailing: Switch(
                    value: isPresent,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (newVal) => _toggleAttendance(studentId, dateStr, isPresent),
                  ),
                  onTap: () => _toggleAttendance(studentId, dateStr, isPresent),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
