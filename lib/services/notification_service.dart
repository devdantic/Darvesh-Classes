import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// -------------------------------------------------------------
  /// SEND NOTIFICATION TO A SPECIFIC USER BY USER ID
  /// -------------------------------------------------------------
  Future<bool> sendUserNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-fcm-notification',
        body: {
          'user_id': userId,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );

      return response.status == 200;
    } catch (e) {
      debugPrint('Error sending user notification: $e');
      return false;
    }
  }

  /// -------------------------------------------------------------
  /// SEND NOTIFICATION TO A TOPIC (e.g., 'all_students', 'admin_notifications')
  /// -------------------------------------------------------------
  Future<bool> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-fcm-notification',
        body: {
          'topic': topic,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );

      return response.status == 200;
    } catch (e) {
      debugPrint('Error sending topic notification: $e');
      return false;
    }
  }

  /// -------------------------------------------------------------
  /// SAVE / UPDATE USER DEVICE FCM TOKEN IN 'device_tokens' TABLE
  /// -------------------------------------------------------------
  Future<void> saveDeviceToken({
    required String studentId,
    required String token,
  }) async {
    try {
      await _client.from('device_tokens').upsert({
        'student_id': studentId,
        'token': token,
      }, onConflict: 'token');
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        // Foreign key violation: student profile doesn't exist yet (e.g. pending registration approval)
        debugPrint('Profile not yet created for student $studentId. Token will be saved upon account approval.');
      } else {
        debugPrint('PostgrestException saving device token: ${e.message}');
      }
    } catch (e) {
      debugPrint('Error saving device token: $e');
    }
  }

  /// -------------------------------------------------------------
  /// DELETE DEVICE TOKEN BY TOKEN VALUE
  /// -------------------------------------------------------------
  Future<void> deleteDeviceToken(String token) async {
    try {
      await _client.from('device_tokens').delete().eq('token', token);
    } catch (e) {
      debugPrint('Error deleting device token: $e');
    }
  }

  /// -------------------------------------------------------------
  /// DELETE ALL TOKENS FOR A STUDENT (e.g., ON LOGOUT)
  /// -------------------------------------------------------------
  Future<void> deleteStudentTokens(String studentId) async {
    try {
      await _client.from('device_tokens').delete().eq('student_id', studentId);
    } catch (e) {
      debugPrint('Error deleting student tokens: $e');
    }
  }

  /// -------------------------------------------------------------
  /// SUBSCRIBE DEVICE TO A TOPIC (e.g., 'admin_notifications', 'all_students')
  /// -------------------------------------------------------------
  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('Subscribed to FCM topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to FCM topic $topic: $e');
    }
  }

  /// -------------------------------------------------------------
  /// UNSUBSCRIBE DEVICE FROM A TOPIC
  /// -------------------------------------------------------------
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from FCM topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from FCM topic $topic: $e');
    }
  }
}

