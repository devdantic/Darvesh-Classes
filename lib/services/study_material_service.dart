import 'package:supabase_flutter/supabase_flutter.dart';

class StudyMaterialService {
  StudyMaterialService._();

  static final StudyMaterialService instance =
  StudyMaterialService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// ---------------------------------------------------------
  /// ADD STUDY MATERIAL
  /// ---------------------------------------------------------
  Future<void> addStudyMaterial({
    required int standard,
    required String subject,
    required String title,
    required String filePath,
  }) async {
    await _client.from('study_materials').insert({
      'standard': standard,
      'subject': subject,
      'title': title,
      'file_path': filePath,
    });
  }

  /// ---------------------------------------------------------
  /// GET ALL MATERIALS
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllStudyMaterials() async {
    final response = await _client
        .from('study_materials')
        .select()
        .order('standard')
        .order('subject')
        .order('uploaded_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// ---------------------------------------------------------
  /// GET MATERIALS BY STANDARD
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getStudyMaterialsByStandard(
      int standard) async {
    final response = await _client
        .from('study_materials')
        .select()
        .eq('standard', standard)
        .order('subject')
        .order('uploaded_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// ---------------------------------------------------------
  /// GET MATERIALS BY SUBJECT
  /// ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getStudyMaterialsBySubject({
    required int standard,
    required String subject,
  }) async {
    final response = await _client
        .from('study_materials')
        .select()
        .eq('standard', standard)
        .eq('subject', subject)
        .order('uploaded_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// ---------------------------------------------------------
  /// GET SINGLE MATERIAL
  /// ---------------------------------------------------------
  Future<Map<String, dynamic>?> getStudyMaterial(
      String materialId) async {
    final response = await _client
        .from('study_materials')
        .select()
        .eq('id', materialId)
        .maybeSingle();

    return response;
  }

  /// ---------------------------------------------------------
  /// UPDATE STUDY MATERIAL
  /// ---------------------------------------------------------
  Future<void> updateStudyMaterial({
    required String materialId,
    int? standard,
    String? subject,
    String? title,
    String? filePath,
  }) async {
    final Map<String, dynamic> updates = {};

    if (standard != null) updates['standard'] = standard;
    if (subject != null) updates['subject'] = subject;
    if (title != null) updates['title'] = title;
    if (filePath != null) updates['file_path'] = filePath;

    if (updates.isEmpty) return;

    await _client
        .from('study_materials')
        .update(updates)
        .eq('id', materialId);
  }

  /// ---------------------------------------------------------
  /// DELETE STUDY MATERIAL
  /// ---------------------------------------------------------
  Future<void> deleteStudyMaterial(
      String materialId) async {
    await _client
        .from('study_materials')
        .delete()
        .eq('id', materialId);
  }

  /// ---------------------------------------------------------
  /// CHECK IF MATERIAL EXISTS
  /// ---------------------------------------------------------
  Future<bool> materialExists(String materialId) async {
    final response = await _client
        .from('study_materials')
        .select('id')
        .eq('id', materialId)
        .maybeSingle();

    return response != null;
  }
}