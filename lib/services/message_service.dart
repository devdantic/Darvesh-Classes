import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  MessageService._();

  static final MessageService instance = MessageService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// ---------------------------------------------------------
  /// ANNOUNCEMENTS (GROUP BROADCASTS)
  /// ---------------------------------------------------------

  /// Send Group Broadcast Announcement
  Future<void> sendGroupMessage({
    required String title,
    required String content,
    required String standard,
  }) async {
    await _client.from('announcements').insert({
      'title': title,
      'content': content,
      'standard': standard,
    });
  }

  /// Get All Group Announcements (Ordered newest first)
  Future<List<Map<String, dynamic>>> getAllAnnouncements() async {
    final response = await _client
        .from('announcements')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update Group Announcement
  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String content,
  }) async {
    await _client.from('announcements').update({
      'title': title,
      'content': content,
    }).eq('id', id);
  }

  /// Delete Group Announcement
  Future<void> deleteAnnouncement(String id) async {
    await _client.from('announcements').delete().eq('id', id);
  }

  /// ---------------------------------------------------------
  /// INDIVIDUAL STUDENT MESSAGES
  /// ---------------------------------------------------------

  /// Send message to an individual student
  Future<void> sendMessage({
    required String studentId,
    required String message,
  }) async {
    await _client.from('messages').insert({
      'student_id': studentId,
      'message': message,
    });
  }

  /// Get all individual student messages (Used by Admin)
  Future<List<Map<String, dynamic>>> getAllMessages() async {
    final response = await _client
        .from('messages')
        .select('*, profiles(name, standard)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get individual messages of a student
  Future<List<Map<String, dynamic>>> getStudentMessages(String studentId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get current user's individual messages
  Future<List<Map<String, dynamic>>> getMyMessages() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    return getStudentMessages(user.id);
  }

  /// Delete an individual message
  Future<void> deleteMessage(String messageId) async {
    await _client.from('messages').delete().eq('id', messageId);
  }
}