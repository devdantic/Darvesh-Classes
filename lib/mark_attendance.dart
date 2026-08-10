import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/attendance_service.dart';
import 'services/profile_service.dart';
import 'theme.dart';

class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({super.key});

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  final Map<String, bool> _attendanceMap = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';
  String? _selectedStandardFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch all student profiles
      final students = await ProfileService.instance.getAllProfiles();
      
      // 2. Fetch existing attendance for selected date
      final existingAttendance = await AttendanceService.instance.getAttendanceByDate(_selectedDate);

      // Populate attendance map
      final Map<String, bool> tempMap = {};
      for (var record in existingAttendance) {
        final studentId = record['student_id'] as String?;
        final isPresent = record['present'] as bool?;
        if (studentId != null && isPresent != null) {
          tempMap[studentId] = isPresent;
        }
      }

      if (mounted) {
        setState(() {
          _allStudents = students;
          _attendanceMap.clear();
          _attendanceMap.addAll(tempMap);
          _applyFilters();
        });
      }
    } catch (e) {
      debugPrint('Error loading attendance data: $e');
      if (mounted) {
        _showSnackBar('Error loading students or attendance records', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final name = (student['name'] ?? '').toString().toLowerCase();
        final matchesQuery = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
        
        final stdValue = (student['standard'] ?? student['std'])?.toString();
        final matchesStd = _selectedStandardFilter == null || stdValue == _selectedStandardFilter;

        return matchesQuery && matchesStd;
      }).toList();
    });
  }

  List<String> _getAvailableStandards() {
    final Set<String> stds = {};
    for (var s in _allStudents) {
      final stdVal = (s['standard'] ?? s['std'])?.toString();
      if (stdVal != null && stdVal.isNotEmpty) {
        stds.add(stdVal);
      }
    }
    final sorted = stds.toList()..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    return sorted;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  void _markAll(bool isPresent) {
    setState(() {
      for (var student in _filteredStudents) {
        final id = student['id'] as String?;
        if (id != null) {
          _attendanceMap[id] = isPresent;
        }
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (_attendanceMap.isEmpty) {
      _showSnackBar('No attendance records to save.', Colors.amber);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final List<Map<String, dynamic>> records = [];

      _attendanceMap.forEach((studentId, isPresent) {
        records.add({
          'student_id': studentId,
          'attendance_date': dateStr,
          'present': isPresent,
        });
      });

      await AttendanceService.instance.saveBatchAttendance(records);

      if (mounted) {
        _showSnackBar('Attendance saved successfully for ${records.length} students! 🎉', const Color(0xFF10B981));
      }
    } catch (e) {
      debugPrint('Error saving attendance: $e');
      if (mounted) {
        _showSnackBar('Failed to save attendance: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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

  String _formatDisplayDate(DateTime date) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekDays[date.weekday - 1]}, ${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDateStr = _formatDisplayDate(_selectedDate);
    final presentCount = _attendanceMap.values.where((v) => v == true).length;
    final absentCount = _attendanceMap.values.where((v) => v == false).length;
    final unmarkedCount = _allStudents.length - _attendanceMap.length;
    final standards = _getAvailableStandards();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Mark Attendance',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload',
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
                    'Loading students...',
                    style: GoogleFonts.outfit(color: AppTheme.textLight),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Hero Date Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance Date',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formattedDateStr,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _selectDate,
                        icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                        label: Text(
                          'Change',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Statistics Banner
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total', '${_allStudents.length}', AppTheme.textDark),
                      _buildStatItem('Present', '$presentCount', const Color(0xFF10B981)),
                      _buildStatItem('Absent', '$absentCount', Colors.red),
                      _buildStatItem('Unmarked', '$unmarkedCount', Colors.amber[800]!),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Search & Filter & Batch Buttons Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        onChanged: (val) {
                          _searchQuery = val;
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search student by name...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Standards & Batch Action Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Class Filter Chips
                            ChoiceChip(
                              label: Text('All Classes', style: GoogleFonts.outfit(fontSize: 12)),
                              selected: _selectedStandardFilter == null,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedStandardFilter = null);
                                  _applyFilters();
                                }
                              },
                              selectedColor: AppTheme.primaryColor,
                              labelStyle: TextStyle(
                                color: _selectedStandardFilter == null ? Colors.white : AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            for (var std in standards) ...[
                              ChoiceChip(
                                label: Text('Std $std', style: GoogleFonts.outfit(fontSize: 12)),
                                selected: _selectedStandardFilter == std,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStandardFilter = selected ? std : null;
                                  });
                                  _applyFilters();
                                },
                                selectedColor: AppTheme.primaryColor,
                                labelStyle: TextStyle(
                                  color: _selectedStandardFilter == std ? Colors.white : AppTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],

                            const SizedBox(width: 12),
                            // Quick Action Buttons
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF10B981),
                                side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              onPressed: () => _markAll(true),
                              icon: const Icon(Icons.done_all_rounded, size: 16),
                              label: Text('All Present', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              onPressed: () => _markAll(false),
                              icon: const Icon(Icons.remove_done_rounded, size: 16),
                              label: Text('All Absent', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Student List
                Expanded(
                  child: _filteredStudents.isEmpty
                      ? Center(
                          child: Text(
                            'No students found.',
                            style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            final studentId = student['id'] as String? ?? '';
                            final name = student['name'] as String? ?? 'Unnamed Student';
                            final std = (student['standard'] ?? student['std'])?.toString() ?? 'N/A';
                            final imageUrl = (student['image_url'] ?? student['imageUrl']) as String?;
                            final isPresent = _attendanceMap[studentId];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppTheme.softShadow,
                                border: Border.all(
                                  color: isPresent == true
                                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                      : isPresent == false
                                          ? Colors.red.withValues(alpha: 0.3)
                                          : Colors.grey.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppTheme.primaryLight,
                                      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                                          ? NetworkImage(imageUrl)
                                          : null,
                                      child: imageUrl == null || imageUrl.isEmpty
                                          ? const Icon(Icons.person, color: AppTheme.primaryColor, size: 22)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),

                                    // Name & Std
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.outfit(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Class Std $std',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Present / Absent Buttons Toggle
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _attendanceMap[studentId] = true;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isPresent == true
                                                  ? const Color(0xFF10B981)
                                                  : Colors.grey.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_rounded,
                                                  size: 16,
                                                  color: isPresent == true ? Colors.white : AppTheme.textLight,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Present',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isPresent == true ? Colors.white : AppTheme.textLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _attendanceMap[studentId] = false;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isPresent == false
                                                  ? Colors.red
                                                  : Colors.grey.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.close_rounded,
                                                  size: 16,
                                                  color: isPresent == false ? Colors.white : AppTheme.textLight,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Absent',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isPresent == false ? Colors.white : AppTheme.textLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Save Attendance Bottom Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: AppTheme.intenseShadow,
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveAttendance,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _isSaving ? 'Saving Attendance...' : 'Save Attendance Records',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }
}