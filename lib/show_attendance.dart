import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/attendance_service.dart';
import 'theme.dart';

class ShowAttendancePage extends StatefulWidget {
  const ShowAttendancePage({super.key});

  @override
  State<ShowAttendancePage> createState() => _ShowAttendancePageState();
}

class _ShowAttendancePageState extends State<ShowAttendancePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _attendanceRecords = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchAttendance(isAutoPoll: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAttendance({bool isAutoPoll = false}) async {
    if (!isAutoPoll) {
      setState(() => _isLoading = true);
    }
    try {
      final data = await AttendanceService.instance.getMyAttendance();
      if (mounted) {
        setState(() {
          _attendanceRecords = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching student attendance: $e');
    } finally {
      if (mounted && !isAutoPoll) {
        setState(() => _isLoading = false);
      }
    }
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
    int presentCount = 0;
    int absentCount = 0;

    for (var r in _attendanceRecords) {
      final isPresent = r['present'] == true;
      if (isPresent) {
        presentCount++;
      } else {
        absentCount++;
      }
    }

    final totalDays = presentCount + absentCount;
    final presentPct = totalDays > 0 ? (presentCount / totalDays) * 100 : 0.0;
    final absentPct = totalDays > 0 ? (absentCount / totalDays) * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Attendance Record',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _fetchAttendance(),
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
                    'Loading attendance history...',
                    style: GoogleFonts.outfit(color: AppTheme.textLight),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchAttendance(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Banner Card
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
                              Icons.fact_check_rounded,
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
                                  'Attendance Overview',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  totalDays > 0
                                      ? 'Your current attendance standing is ${presentPct.toStringAsFixed(1)}%.'
                                      : 'No attendance records logged yet.',
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

                    // Metrics Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            label: 'Present Days',
                            value: '$presentCount',
                            subtitle: '${presentPct.toStringAsFixed(1)}%',
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            label: 'Absent Days',
                            value: '$absentCount',
                            subtitle: '${absentPct.toStringAsFixed(1)}%',
                            icon: Icons.cancel_rounded,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Attendance Status Warning Banner
                    if (totalDays > 0) ...[
                      if (presentPct < 75)
                        _buildStatusBanner(
                          title: 'Critical Warning!',
                          message: 'Your attendance is below 75%. Please attend classes regularly to avoid missing important topics.',
                          color: Colors.red,
                          icon: Icons.warning_amber_rounded,
                        )
                      else if (presentPct < 85)
                        _buildStatusBanner(
                          title: 'Attendance Notice',
                          message: 'Your attendance is between 75% and 85%. Try to maintain consistent attendance.',
                          color: Colors.amber.shade800,
                          icon: Icons.info_outline_rounded,
                        )
                      else
                        _buildStatusBanner(
                          title: 'Excellent Standing! 🎉',
                          message: 'Great job maintaining high attendance! Keep up the good work.',
                          color: const Color(0xFF10B981),
                          icon: Icons.verified_rounded,
                        ),
                      const SizedBox(height: 20),

                      // Pie Chart Card
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
                              'Attendance Proportion',
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
                                    if (presentCount > 0)
                                      PieChartSectionData(
                                        color: const Color(0xFF10B981),
                                        value: presentCount.toDouble(),
                                        title: '${presentPct.toStringAsFixed(0)}%',
                                        radius: 45,
                                        titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    if (absentCount > 0)
                                      PieChartSectionData(
                                        color: Colors.red,
                                        value: absentCount.toDouble(),
                                        title: '${absentPct.toStringAsFixed(0)}%',
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

                    // Attendance History List Header
                    Text(
                      'Daily Attendance History',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 12),

                    if (_attendanceRecords.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey[350]),
                            const SizedBox(height: 12),
                            Text(
                              'No Attendance Records',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Attendance marked by Sanjay Sir will appear here.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _attendanceRecords.length,
                        itemBuilder: (context, index) {
                          final record = _attendanceRecords[index];
                          final dateStr = record['attendance_date']?.toString();
                          final isPresent = record['present'] == true;

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
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPresent
                                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: isPresent ? const Color(0xFF10B981) : Colors.red,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                _formatDate(dateStr),
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPresent
                                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isPresent ? 'PRESENT' : 'ABSENT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPresent ? const Color(0xFF10B981) : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($subtitle)',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
                Text(
                  label,
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
    );
  }

  Widget _buildStatusBanner({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
