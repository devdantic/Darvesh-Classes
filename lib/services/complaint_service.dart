import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintService {
  ComplaintService._();

  static final ComplaintService instance = ComplaintService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// ---------------------------------------------------------
  /// ADD COMPLAINT
  /// ---------------------------------------------------------
  Future<void> addComplaint({
    required String studentId,
    required String complaint,
  }) async {
    await _client.from('complaints').insert({
      'student_id': studentId,
      'complaint': complaint,
    });
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