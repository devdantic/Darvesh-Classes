import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'student_chat_page.dart';
import 'theme.dart';

class MessageToSirPage extends StatefulWidget {
  const MessageToSirPage({super.key});

  @override
  State<MessageToSirPage> createState() => _MessageToSirPageState();
}

class _MessageToSirPageState extends State<MessageToSirPage> {
  bool _isLoading = true;
  String? _userId;
  String _userName = 'Student';
  String? _userStd;
  String? _userAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        _userId = user.id;
        final profile = await ProfileService.instance.getProfile(user.id);
        if (mounted && profile != null) {
          setState(() {
            _userName = profile['name'] as String? ?? 'Student';
            _userStd = profile['standard']?.toString();
            _userAvatarUrl = profile['image_url'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading student profile for chat: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('Message to Sanjay Sir')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userId == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('Message to Sanjay Sir')),
        body: const Center(child: Text('User not logged in.')),
      );
    }

    return StudentChatPage(
      studentId: _userId!,
      studentName: _userName,
      studentStd: _userStd,
      studentAvatarUrl: _userAvatarUrl,
      isAdminView: false,
    );
  }
}
