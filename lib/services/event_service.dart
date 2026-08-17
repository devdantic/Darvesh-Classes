import 'package:supabase_flutter/supabase_flutter.dart';

class EventService {
  EventService._();

  static final EventService instance = EventService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// -------------------------------------------------------------
  /// ADD EVENT
  /// -------------------------------------------------------------
  Future<void> addEvent({
    required String title,
    required DateTime date,
    required String description,
    String? category,
  }) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await _client.from('events').insert({
      'title': title,
      'date': dateStr,
      'description': description,
      if (category != null) 'category': category,
    });
  }

  /// -------------------------------------------------------------
  /// GET ALL EVENTS
  /// -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final response = await _client
        .from('events')
        .select()
        .order('date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// -------------------------------------------------------------
  /// DELETE EVENT
  /// -------------------------------------------------------------
  Future<void> deleteEvent(String id) async {
    await _client.from('events').delete().eq('id', id);
  }
}
