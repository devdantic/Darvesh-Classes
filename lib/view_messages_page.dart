import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/message_service.dart';
import 'services/profile_service.dart';
import 'student_chat_page.dart';
import 'theme.dart';

class ViewMessagesPage extends StatefulWidget {
  const ViewMessagesPage({super.key});

  @override
  State<ViewMessagesPage> createState() => _ViewMessagesPageState();
}

class _ViewMessagesPageState extends State<ViewMessagesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchMessages(isAutoPoll: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMessages({bool isAutoPoll = false}) async {
    if (!isAutoPoll) {
      setState(() => _isLoading = true);
    }
    try {
      final data = await MessageService.instance.getAllMessages();
      if (mounted) {
        setState(() {
          _messages = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching student messages: $e');
    } finally {
      if (mounted && !isAutoPoll) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openChatWithStudent(String studentId, String name, String? std, String? avatarUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentChatPage(
          studentId: studentId,
          studentName: name,
          studentStd: std,
          studentAvatarUrl: avatarUrl,
          isAdminView: true,
        ),
      ),
    ).then((_) => _fetchMessages());
  }

  void _showNewMessageDialog() async {
    try {
      final profiles = await ProfileService.instance.getAllProfiles();
      if (!mounted) return;

      if (profiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No approved student profiles found.', style: GoogleFonts.outfit()),
            backgroundColor: Colors.amber[800],
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Student to Message',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final p = profiles[index];
                      final id = p['id'] as String? ?? '';
                      final name = p['name'] as String? ?? 'Student';
                      final std = p['standard']?.toString();
                      final avatar = p['image_url'] as String?;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        subtitle: Text(std != null ? 'Standard $std' : '', style: GoogleFonts.outfit(fontSize: 12)),
                        onTap: () {
                          Navigator.pop(context);
                          _openChatWithStudent(id, name, std, avatar);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error fetching profiles for chat: $e');
    }
  }

  String _formatDateTime(String? rawIso) {
    if (rawIso == null) return '';
    try {
      final dt = DateTime.parse(rawIso).toLocal();
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${monthNames[dt.month - 1]}, $hour:$minute $amPm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group messages by student_id to show conversation threads
    final Map<String, Map<String, dynamic>> conversationThreads = {};
    for (var msg in _messages) {
      final studentId = msg['student_id'] as String?;
      if (studentId != null && !conversationThreads.containsKey(studentId)) {
        conversationThreads[studentId] = msg;
      }
    }
    final threadsList = conversationThreads.values.toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Student Direct Chats',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchMessages,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: _showNewMessageDialog,
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: Text('New Chat', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading conversations...',
                    style: GoogleFonts.outfit(color: AppTheme.textLight),
                  ),
                ],
              ),
            )
          : threadsList.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No direct messages yet.',
                          style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _showNewMessageDialog,
                          icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
                          label: Text('Start Direct Message', style: GoogleFonts.outfit(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: threadsList.length,
                  itemBuilder: (context, index) {
                    final msg = threadsList[index];
                    final studentId = msg['student_id'] as String? ?? '';
                    final content = msg['message'] as String? ?? '';
                    final isFromAdmin = msg['is_from_admin'] as bool? ?? false;
                    final createdAt = msg['created_at']?.toString();

                    final profile = msg['profiles'] as Map<String, dynamic>?;
                    final studentName = profile?['name'] as String? ?? 'Student';
                    final standard = profile?['standard']?.toString() ?? 'N/A';
                    final imageUrl = profile?['image_url'] as String?;

                    return InkWell(
                      onTap: () => _openChatWithStudent(studentId, studentName, standard, imageUrl),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppTheme.softShadow,
                          border: Border.all(
                            color: AppTheme.primaryLight.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                              child: imageUrl == null
                                  ? Text(
                                      studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                        fontSize: 16,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          studentName,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Std $standard',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isFromAdmin
                                        ? 'You: ${content.isNotEmpty ? content : '📁 Attachment'}'
                                        : (content.isNotEmpty ? content : '📁 Attachment'),
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: AppTheme.textLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatDateTime(createdAt),
                                  style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textLight),
                                ),
                                const SizedBox(height: 6),
                                const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
