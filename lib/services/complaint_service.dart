import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class ComplaintService {
  ComplaintService._();

  static final ComplaintService instance = ComplaintService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// ---------------------------------------------------------
  /// ADD COMPLAINT & NOTIFY STUDENT
  /// ---------------------------------------------------------
  Future<void> addComplaint({
    required String studentId,
    required String complaint,
  }) async {
    await _client.from('complaints').insert({
      'student_id': studentId,
      'complaint': complaint,
    });

    // Automatically send instant push notification to the student
    try {
      await NotificationService.instance.sendUserNotification(
        userId: studentId,
        title: '⚠️ Notice / Remark from Sanjay Sir',
        body: complaint,
        data: {'type': 'complaint'},
      );
    } catch (e) {
      debugPrint('Error sending complaint push notification: $e');
    }
  }

  /// ---------------------------------------------------------
  /// GET ALL COMPLAINTS
  /// Used by Admin
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllComplaints() async {
    final response = await _client
        .from('complaints')
        .select('*, profiles(name, standard)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// ---------------------------------------------------------
  /// GET COMPLAINTS OF A STUDENT
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getStudentComplaints(
      String studentId) async {
    final response = await _client
        .from('complaints')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// ---------------------------------------------------------
  /// GET CURRENT USER COMPLAINTS
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getMyComplaints() async {
    final user = _client.auth.currentUser;

    if (user == null) return [];

    return getStudentComplaints(user.id);
  }

  /// ---------------------------------------------------------
  /// STREAM CURRENT USER COMPLAINTS (REALTIME)
  /// ---------------------------------------------------------
  Stream<List<Map<String, dynamic>>> streamMyComplaints() {
    final user = _client.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _client
        .from('complaints')
        .stream(primaryKey: ['id'])
        .eq('student_id', user.id)
        .order('created_at', ascending: false);
  }

  /// ---------------------------------------------------------
  /// UPDATE COMPLAINT
  /// ---------------------------------------------------------
  Future<void> updateComplaint({
    required String complaintId,
    required String complaint,
  }) async {
    await _client
        .from('complaints')
        .update({'complaint': complaint})
        .eq('id', complaintId);
  }

  /// ---------------------------------------------------------
  /// DELETE COMPLAINT
  /// ---------------------------------------------------------
  Future<void> deleteComplaint(String complaintId) async {
    await _client
        .from('complaints')
        .delete()
        .eq('id', complaintId);
  }

  /// ---------------------------------------------------------
  /// GET SINGLE COMPLAINT
  /// ---------------------------------------------------------
  Future<Map<String, dynamic>?> getComplaint(
      String complaintId) async {
    final response = await _client
        .from('complaints')
        .select()
        .eq('id', complaintId)
        .maybeSingle();

    return response;
  }
}