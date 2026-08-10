import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  MessageService._();

  static final MessageService instance = MessageService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// ---------------------------------------------------------
  /// SEND MESSAGE
  /// ---------------------------------------------------------
  Future<void> sendMessage({
    required String studentId,
    required String message,
  }) async {
    await _client.from('messages').insert({
      'student_id': studentId,
      'message': message,
    });
  }

  /// ---------------------------------------------------------
  /// GET ALL MESSAGES
  /// Used by Admin
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllMessages() async {
    final response = await _client
        .from('messages')
        .select('*, profiles(name, standard)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);

  }

  /// ---------------------------------------------------------
  /// GET MESSAGES OF A STUDENT
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getStudentMessages(
      String studentId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// ---------------------------------------------------------
  /// GET CURRENT USER MESSAGES
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getMyMessages() async {
    final user = _client.auth.currentUser;

    if (user == null) return [];

    return getStudentMessages(user.id);
  }

  /// ---------------------------------------------------------
  /// GET SINGLE MESSAGE
  /// ---------------------------------------------------------
  Future<Map<String, dynamic>?> getMessage(
      String messageId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('id', messageId)
        .maybeSingle();

    return response;
  }

  /// ---------------------------------------------------------
  /// DELETE MESSAGE
  /// ---------------------------------------------------------
  Future<void> deleteMessage(String messageId) async {
    await _client
        .from('messages')
        .delete()
        .eq('id', messageId);
  }
}