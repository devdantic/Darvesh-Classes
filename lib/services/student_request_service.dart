import 'package:supabase_flutter/supabase_flutter.dart';

class StudentRequestService {
  StudentRequestService._();

  static final StudentRequestService instance =
  StudentRequestService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// -------------------------------------------------------------
  /// CREATE REQUEST
  /// -------------------------------------------------------------
  Future<void> createRequest({
    required String authUserId,
    required String name,
    required String email,
    required String phone,
    required String address,
    required int standard,
    String? imageUrl,
    String? fcmToken,
  }) async {
    await _client.from('student_requests').insert({
      'auth_user_id': authUserId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'standard': standard,
      'image_url': imageUrl,
      'fcm_token': fcmToken,
      'status': 'pending',
      'requested_at': DateTime.now().toIso8601String(),
    });
  }

  /// -------------------------------------------------------------
  /// GET REQUEST STATUS
  /// Returns:
  /// pending
  /// approved
  /// rejected
  /// null (request not found)
  /// -------------------------------------------------------------
  Future<String?> getRequestStatus(String authUserId) async {
    final response = await _client
        .from('student_requests')
        .select('status')
        .eq('auth_user_id', authUserId)
        .maybeSingle();

    if (response == null) return null;

    return response['status'] as String?;
  }

  /// -------------------------------------------------------------
  /// CHECK IF REQUEST EXISTS
  /// -------------------------------------------------------------
  Future<bool> requestExists(String authUserId) async {
    final response = await _client
        .from('student_requests')
        .select('id')
        .eq('auth_user_id', authUserId)
        .maybeSingle();

    return response != null;
  }

  /// -------------------------------------------------------------
  /// APPROVE REQUEST
  /// -------------------------------------------------------------
  Future<void> approveRequest(String authUserId) async {
    await _client
        .from('student_requests')
        .update({
      'status': 'approved',
      'reviewed_at': DateTime.now().toIso8601String(),
    })
        .eq('auth_user_id', authUserId);
  }

  /// -------------------------------------------------------------
  /// REJECT REQUEST
  /// -------------------------------------------------------------
  Future<void> rejectRequest(String authUserId) async {
    await _client
        .from('student_requests')
        .update({
      'status': 'rejected',
      'reviewed_at': DateTime.now().toIso8601String(),
    })
        .eq('auth_user_id', authUserId);
  }

  /// -------------------------------------------------------------
  /// DELETE REQUEST
  /// -------------------------------------------------------------
  Future<void> deleteRequest(String authUserId) async {
    await _client
        .from('student_requests')
        .delete()
        .eq('auth_user_id', authUserId);
  }

  /// -------------------------------------------------------------
  /// GET ALL PENDING REQUESTS
  /// Used in Admin Page
  /// -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final response = await _client
        .from('student_requests')
        .select()
        .eq('status', 'pending')
        .order('requested_at');

    return List<Map<String, dynamic>>.from(response);
  }

  /// -------------------------------------------------------------
  /// GET SINGLE REQUEST
  /// -------------------------------------------------------------
  Future<Map<String, dynamic>?> getRequest(String authUserId) async {
    final response = await _client
        .from('student_requests')
        .select()
        .eq('auth_user_id', authUserId)
        .maybeSingle();

    return response;
  }
}