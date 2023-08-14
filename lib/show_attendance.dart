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
  bool _hasData = false;

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
        final attendanceData = attendanceSnapshot.data()?['attendanceData']
            as Map<String, dynamic>;

        if (attendanceData != null) {
          int presentDays = 0;
          int absentDays = 0;

          attendanceData.forEach((date, isPresent) {
            if (isPresent == true) {
              presentDays++;
            } else {
              absentDays++;
            }
          });

          setState(() {
            _presentDays = presentDays.toDouble();
            _absentDays = absentDays.toDouble();
            _hasData = true;
          });
        } else {
          setState(() {
            _hasData = false;
          });
        }
      } else {
        setState(() {
          _hasData = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasData = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    if (!_hasData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Attendance'),
        ),
        body: const Center(
          child: Text(
            'No Data Available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    double totalDays = _presentDays + _absentDays;
    double presentDaysPercentage =
        (totalDays > 0) ? (_presentDays / totalDays) * 100 : 0;
    double absentDaysPercentage =
        (totalDays > 0) ? (_absentDays / totalDays) * 100 : 0;

    String warningMessage = '';
    if (presentDaysPercentage < 90) {
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
            SizedBox(
              width: 200,
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: presentDaysPercentage,
                      title: '${presentDaysPercentage.toStringAsFixed(1)}%',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: absentDaysPercentage,
                      title: '${absentDaysPercentage.toStringAsFixed(1)}%',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 50,
                ),
              ),
            ),
            const SizedBox(height: 75),
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
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
