import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ShowAttendancePage extends StatefulWidget {
  const ShowAttendancePage({Key? key}) : super(key: key);

  @override
  _ShowAttendancePageState createState() => _ShowAttendancePageState();
}

class _ShowAttendancePageState extends State<ShowAttendancePage> {
  double _presentDays = 0;
  double _absentDays = 0;
  bool _hasAttendanceData = false;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(user!.uid)
          .get();

      if (attendanceSnapshot.exists) {
        final attendanceData =
            attendanceSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _presentDays = (attendanceData['presentDays'] ?? 0).toDouble();
          _absentDays = (attendanceData['absentDays'] ?? 0).toDouble();
          _hasAttendanceData = true;
        });
      } else {
        setState(() {
          _hasAttendanceData = false;
        });
      }
    } catch (e) {
      //print('Error fetching attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalDays = _presentDays + _absentDays;
    double presentDays = (totalDays > 0) ? (_presentDays / totalDays) * 100 : 0;
    double absentDays = (totalDays > 0) ? (_absentDays / totalDays) * 100 : 0;

    String warningMessage = '';
    if (presentDays < 90) {
      warningMessage =
          'Warning: Your attendance is below 90%. Please attend the classes regularly to improve it.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_hasAttendanceData)
              SizedBox(
                width: 200,
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        color: Colors.green,
                        value: presentDays,
                        title: '${presentDays.toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.red,
                        value: absentDays,
                        title: '${absentDays.toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    centerSpaceRadius: 50,
                  ),
                ),
              )
            else
              const Text(
                'No attendance data available.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Present'),
                const SizedBox(width: 20),
                _buildLegendItem(Colors.red, 'Absent'),
              ],
            ),
            if (warningMessage.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  warningMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
