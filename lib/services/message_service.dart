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
  /// INDIVIDUAL & DIRECT MESSAGES (2-WAY CHAT)
  /// ---------------------------------------------------------

  /// Send a direct message (supports text, file attachments, and isFromAdmin flag)
  Future<void> sendDirectMessage({
    required String studentId,
    String? message,
    String? fileUrl,
    String? fileName,
    bool isFromAdmin = false,
  }) async {
    await _client.from('messages').insert({
      'student_id': studentId,
      'message': message ?? '',
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileName != null) 'file_name': fileName,
      'is_from_admin': isFromAdmin,
    });
  }

  /// Backward compatible sendMessage
  Future<void> sendMessage({
    required String studentId,
    required String message,
  }) async {
    await sendDirectMessage(studentId: studentId, message: message, isFromAdmin: false);
  }

  /// Get WhatsApp-style conversation thread between Admin & Student (ordered oldest to newest)
  Future<List<Map<String, dynamic>>> getConversation(String studentId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Stream WhatsApp-style chat thread in real-time
  Stream<List<Map<String, dynamic>>> streamConversation(String studentId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('created_at', ascending: true);
  }

  /// Get all individual student messages (Used by Admin)
  Future<List<Map<String, dynamic>>> getAllMessages() async {
    final response = await _client
        .from('messages')
        .select('*, profiles(name, standard, phone, image_url)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get individual messages of a student
  Future<List<Map<String, dynamic>>> getStudentMessages(String studentId) async {
    return getConversation(studentId);
  }

  /// Get current user's individual messages
  Future<List<Map<String, dynamic>>> getMyMessages() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    return getConversation(user.id);
  }

  /// Delete an individual message
  Future<void> deleteMessage(String messageId) async {
    await _client.from('messages').delete().eq('id', messageId);
  }
}