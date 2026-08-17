import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  final SupabaseClient _client = Supabase.instance.client;

  static const String avatarBucket = 'avatars';
  static const String studyMaterialBucket = 'study-materials';
  static const String messageAttachmentBucket = 'message-attachments';

  /// ---------------------------------------------------------
  /// UPLOAD PROFILE IMAGE
  /// Returns storage path
  /// ---------------------------------------------------------
  Future<String> uploadProfileImage({
    required String userId,
    required File image,
  }) async {
    final extension = path.extension(image.path);

    final filePath = '$userId/profile$extension';

    await _client.storage
        .from(avatarBucket)
        .upload(
      filePath,
      image,
      fileOptions: const FileOptions(
        upsert: true,
      ),
    );

    return filePath;
  }

  /// ---------------------------------------------------------
  /// DELETE PROFILE IMAGE
  /// ---------------------------------------------------------
  Future<void> deleteProfileImage(String filePath) async {
    await _client.storage
        .from(avatarBucket)
        .remove([filePath]);
  }

  /// ---------------------------------------------------------
  /// UPLOAD STUDY MATERIAL
  /// Returns storage path
  /// ---------------------------------------------------------
  Future<String> uploadStudyMaterial({
    required int standard,
    required String subject,
    required File file,
  }) async {
    final fileName = path.basename(file.path);

    final filePath =
        '$standard/$subject/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage
        .from(studyMaterialBucket)
        .upload(
      filePath,
      file,
      fileOptions: const FileOptions(
        upsert: true,
      ),
    );

    return filePath;
  }

  /// ---------------------------------------------------------
  /// UPLOAD MESSAGE ATTACHMENT
  /// Returns public URL of the uploaded file
  /// ---------------------------------------------------------
  Future<String> uploadMessageAttachment({
    required String pathPrefix,
    required File file,
  }) async {
    final fileName = path.basename(file.path);
    final filePath = '$pathPrefix/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    try {
      await _client.storage.from(messageAttachmentBucket).upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return _client.storage.from(messageAttachmentBucket).getPublicUrl(filePath);
    } catch (_) {
      // Fallback to studyMaterialBucket if messageAttachmentBucket isn't created yet
      await _client.storage.from(studyMaterialBucket).upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return _client.storage.from(studyMaterialBucket).getPublicUrl(filePath);
    }
  }

  /// ---------------------------------------------------------
  /// DELETE STUDY MATERIAL
  /// ---------------------------------------------------------
  Future<void> deleteStudyMaterial(String filePath) async {
    await _client.storage
        .from(studyMaterialBucket)
        .remove([filePath]);
  }

  /// ---------------------------------------------------------
  /// GET PROFILE IMAGE URL
  /// ---------------------------------------------------------
  String getProfileImageUrl(String filePath) {
    return _client.storage
        .from(avatarBucket)
        .getPublicUrl(filePath);
  }

  /// ---------------------------------------------------------
  /// GET STUDY MATERIAL URL
  /// ---------------------------------------------------------
  String getStudyMaterialUrl(String filePath) {
    return _client.storage
        .from(studyMaterialBucket)
        .getPublicUrl(filePath);
  }

  /// ---------------------------------------------------------
  /// CHECK FILE EXISTS
  /// ---------------------------------------------------------
  Future<bool> fileExists({
    required String bucket,
    required String filePath,
  }) async {
    try {
      final folders = path.dirname(filePath);
      final fileName = path.basename(filePath);

      final files = await _client.storage
          .from(bucket)
          .list(path: folders);

      return files.any((file) => file.name == fileName);
    } catch (_) {
      return false;
    }
  }
}