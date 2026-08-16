import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// ---------------------------------------------------------
  /// CREATE PROFILE
  /// ---------------------------------------------------------
  Future<void> createProfile({
    required String id,
    required String name,
    required String phone,
    required String address,
    required int standard,
    String? imageUrl,
  }) async {
    await _client.from('profiles').insert({
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'standard': standard,
      'image_url': imageUrl,
    });
  }

  /// ---------------------------------------------------------
  /// GET PROFILE
  /// ---------------------------------------------------------
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  /// ---------------------------------------------------------
  /// GET CURRENT PROFILE
  /// ---------------------------------------------------------
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) return null;

    return getProfile(user.id);
  }

  /// ---------------------------------------------------------
  /// UPDATE PROFILE
  /// ---------------------------------------------------------
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? address,
    int? standard,
    String? imageUrl,
  }) async {
    final Map<String, dynamic> updates = {};

    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (address != null) updates['address'] = address;
    if (standard != null) updates['standard'] = standard;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (updates.isEmpty) return;

    await _client
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }

  /// ---------------------------------------------------------
  /// DELETE PROFILE
  /// ---------------------------------------------------------
  Future<void> deleteProfile(String userId) async {
    await _client
        .from('profiles')
        .delete()
        .eq('id', userId);
  }

  /// ---------------------------------------------------------
  /// CHECK IF PROFILE EXISTS BY USER ID
  /// ---------------------------------------------------------
  Future<bool> profileExists(String userId) async {
    final response = await _client
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    return response != null;
  }

  /// ---------------------------------------------------------
  /// CHECK IF PROFILE EXISTS BY EMAIL
  /// ---------------------------------------------------------
  Future<bool> profileExistsByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail == 'sanjaygovindani757@gmail.com') return true;

    final response = await _client
        .from('profiles')
        .select('id')
        .ilike('email', cleanEmail)
        .maybeSingle();

    if (response != null) return true;

    final reqResponse = await _client
        .from('student_requests')
        .select('id')
        .ilike('email', cleanEmail)
        .maybeSingle();

    return reqResponse != null;
  }

  /// ---------------------------------------------------------
  /// GET ALL STUDENTS
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final response = await _client
        .from('profiles')
        .select()
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// ---------------------------------------------------------
  /// PROMOTE BATCH OF STUDENTS TO NEXT STANDARD
  /// ---------------------------------------------------------
  Future<void> promoteStandardBatch(int fromStandard, int toStandard) async {
    await _client
        .from('profiles')
        .update({'standard': toStandard})
        .eq('standard', fromStandard);
  }

  /// ---------------------------------------------------------
  /// PROMOTE SINGLE STUDENT
  /// ---------------------------------------------------------
  Future<void> promoteStudent(String userId, int newStandard) async {
    await _client
        .from('profiles')
        .update({'standard': newStandard})
        .eq('id', userId);
  }

  /// ---------------------------------------------------------
  /// SEARCH STUDENTS
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> searchProfiles(
      String query) async {
    final response = await _client
        .from('profiles')
        .select()
        .ilike('name', '%$query%');

    return List<Map<String, dynamic>>.from(response);
  }
}