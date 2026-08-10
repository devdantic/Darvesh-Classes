import 'package:darvesh_classes/services/auth_service.dart';
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
  /// CHECK IF PROFILE EXISTS
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