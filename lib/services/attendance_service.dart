import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceService {
  AttendanceService._();

  static final AttendanceService instance = AttendanceService._();

  final SupabaseClient _client = Supabase.instance.client;

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  /// ---------------------------------------------------------
  /// SAVE BATCH ATTENDANCE
  /// ---------------------------------------------------------
  Future<void> saveBatchAttendance(List<Map<String, dynamic>> records) async {
    if (records.isEmpty) return;
    await _client.from('attendance').upsert(
      records,
      onConflict: 'student_id, attendance_date',
    );
  }

  /// ---------------------------------------------------------
  /// MARK ATTENDANCE
  /// ---------------------------------------------------------
  Future<void> markAttendance({
    required String studentId,
    required DateTime date,
    required bool present,
  }) async {
    await _client.from('attendance').insert({
      'student_id': studentId,
      'attendance_date':  _formatDate(date),
      'present': present,
    });
  }

  /// ---------------------------------------------------------
  /// UPDATE ATTENDANCE
  /// ---------------------------------------------------------
  Future<void> updateAttendance({
    required String studentId,
    required DateTime date,
    required bool present,
  }) async {
    await _client
        .from('attendance')
        .update({
      'present': present,
    })
        .eq('student_id', studentId)
        .eq('attendance_date',  _formatDate(date));
  }

  /// ---------------------------------------------------------
  /// GET ATTENDANCE OF A STUDENT
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getStudentAttendance(
      String studentId) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('student_id', studentId)
        .order('attendance_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// ---------------------------------------------------------
  /// GET CURRENT USER ATTENDANCE
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getMyAttendance() async {
    final user = _client.auth.currentUser;

    if (user == null) return [];

    return getStudentAttendance(user.id);
  }

  /// ---------------------------------------------------------
  /// GET ATTENDANCE OF PARTICULAR DATE
  /// Used by Admin
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAttendanceByDate(
      DateTime date) async {
    final response = await _client
        .from('attendance')
        .select('*, profiles(name, standard)')
        .eq('attendance_date',  _formatDate(date))
        .order('student_id');

    return List<Map<String, dynamic>>.from(response);
  }

  /// ---------------------------------------------------------
  /// GET ALL ATTENDANCE RECORDS (WITH PROFILES)
  /// Used by Admin Reports
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllAttendance() async {
    final response = await _client
        .from('attendance')
        .select('*, profiles(name, standard, image_url, phone)')
        .order('attendance_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// ---------------------------------------------------------
  /// GET ATTENDANCE BETWEEN TWO DATES
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAttendanceBetweenDates({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('student_id', studentId)
        .gte(
      'attendance_date',
      startDate.toIso8601String().split('T').first,
    )
        .lte(
      'attendance_date',
      endDate.toIso8601String().split('T').first,
    )
        .order('attendance_date');

    return List<Map<String, dynamic>>.from(response);
  }

  /// ---------------------------------------------------------
  /// DELETE ATTENDANCE
  /// ---------------------------------------------------------
  Future<void> deleteAttendance({
    required String studentId,
    required DateTime date,
  }) async {
    await _client
        .from('attendance')
        .delete()
        .eq('student_id', studentId)
        .eq('attendance_date',  _formatDate(date));
  }

  /// ---------------------------------------------------------
  /// CHECK IF ATTENDANCE EXISTS
  /// ---------------------------------------------------------
  Future<bool> attendanceExists({
    required String studentId,
    required DateTime date,
  }) async {
    final response = await _client
        .from('attendance')
        .select('id')
        .eq('student_id', studentId)
        .eq('attendance_date',  _formatDate(date))
        .maybeSingle();

    return response != null;
  }
}