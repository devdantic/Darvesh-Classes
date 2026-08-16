import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/message_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme.dart';

class StudentChatPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String? studentStd;
  final String? studentAvatarUrl;
  final bool isAdminView;

  const StudentChatPage({
    super.key,
    required this.studentId,
    required this.studentName,
    this.studentStd,
    this.studentAvatarUrl,
    required this.isAdminView,
  });

  @override
  State<StudentChatPage> createState() => _StudentChatPageState();
}

class _StudentChatPageState extends State<StudentChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = true;
  bool _isSending = false;
  File? _attachedFile;
  String? _attachedFileName;

  List<Map<String, dynamic>> _messages = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchConversation();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchConversation(isAutoPoll: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchConversation({bool isAutoPoll = false}) async {
    try {
      final data = await MessageService.instance.getConversation(widget.studentId);
      if (mounted) {
        final hasNewMessages = data.length != _messages.length;
        setState(() {
          _messages = data;
          _isLoading = false;
        });
        if (hasNewMessages || !isAutoPoll) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error fetching conversation: $e');
      if (mounted && !isAutoPoll) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _attachedFile = File(picked.path);
          _attachedFileName = picked.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachedFile = File(result.files.single.path!);
          _attachedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _showAttachmentPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Attach Media or Document',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.image_rounded, color: Colors.purple, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text('Photo', style: GoogleFonts.outfit(fontSize: 13)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.insert_drive_file_rounded, color: Colors.blue, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text('Document / PDF', style: GoogleFonts.outfit(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _attachedFile == null) return;

    setState(() => _isSending = true);

    try {
      String? fileUrl;
      String? fileName;

      // 1. Upload attachment if present
      if (_attachedFile != null) {
        fileUrl = await StorageService.instance.uploadMessageAttachment(
          pathPrefix: widget.studentId,
          file: _attachedFile!,
        );
        fileName = _attachedFileName ?? 'attachment';
      }

      // 2. Insert into Supabase 'messages' table
      await MessageService.instance.sendDirectMessage(
        studentId: widget.studentId,
        message: text,
        fileUrl: fileUrl,
        fileName: fileName,
        isFromAdmin: widget.isAdminView,
      );

      // 3. Send Push Notification
      final displayContent = text.isNotEmpty ? text : '📁 Attached: ${fileName ?? 'File'}';
      if (widget.isAdminView) {
        // Admin sending to student
        await NotificationService.instance.sendUserNotification(
          userId: widget.studentId,
          title: '💬 Message from Sanjay Sir',
          body: displayContent,
          data: {'type': 'direct_message'},
        );
      } else {
        // Student sending to Admin
        final stdInfo = widget.studentStd != null ? ' (Std ${widget.studentStd})' : '';
        await NotificationService.instance.sendTopicNotification(
          topic: 'admin_notifications',
          title: '💬 Message from ${widget.studentName}$stdInfo',
          body: displayContent,
          data: {'type': 'direct_message', 'student_id': widget.studentId},
        );
      }

      _textController.clear();
      setState(() {
        _attachedFile = null;
        _attachedFileName = null;
      });

      _fetchConversation();
    } catch (e) {
      debugPrint('Error sending direct message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e', style: GoogleFonts.outfit()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _openAttachmentUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch attachment url: $url');
      }
    } catch (e) {
      debugPrint('Error opening attachment: $e');
    }
  }

  String _formatTime(String? rawIso) {
    if (rawIso == null) return '';
    try {
      final dt = DateTime.parse(rawIso).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute $amPm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleName = widget.isAdminView ? widget.studentName : 'Sanjay Sir';
    final subtitleText = widget.isAdminView
        ? (widget.studentStd != null ? 'Student • Standard ${widget.studentStd}' : 'Student')
        : 'Darvesh Classes • Online';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: widget.studentAvatarUrl != null ? NetworkImage(widget.studentAvatarUrl!) : null,
              child: widget.studentAvatarUrl == null
                  ? Text(
                      titleName.isNotEmpty ? titleName[0].toUpperCase() : 'S',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleName,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    subtitleText,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
            onPressed: _fetchConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Real-time Chat Thread View
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: MessageService.instance.streamConversation(widget.studentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.hasData ? snapshot.data! : _messages;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(
                          'No messages yet. Start a conversation!',
                          style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isFromAdmin = msg['is_from_admin'] as bool? ?? false;
                          final isMe = widget.isAdminView ? isFromAdmin : !isFromAdmin;

                          final text = msg['message'] as String? ?? '';
                          final fileUrl = msg['file_url'] as String?;
                          final fileName = msg['file_name'] as String? ?? 'Attachment';
                          final timeStr = _formatTime(msg['created_at']?.toString());

                          final isImage = fileUrl != null &&
                              (fileUrl.endsWith('.jpg') ||
                                  fileUrl.endsWith('.jpeg') ||
                                  fileUrl.endsWith('.png') ||
                                  fileUrl.endsWith('.webp'));

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.78,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? AppTheme.primaryColor : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Attachment Section
                                  if (fileUrl != null) ...[
                                    GestureDetector(
                                      onTap: () => _openAttachmentUrl(fileUrl),
                                      child: isImage
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.network(
                                                fileUrl,
                                                height: 180,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: isMe
                                                    ? Colors.white.withValues(alpha: 0.2)
                                                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.insert_drive_file_rounded,
                                                    color: isMe ? Colors.white : AppTheme.primaryColor,
                                                    size: 22,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      fileName,
                                                      style: GoogleFonts.outfit(
                                                        color: isMe ? Colors.white : AppTheme.textDark,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.open_in_new_rounded,
                                                    color: isMe ? Colors.white70 : AppTheme.primaryColor,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                    if (text.isNotEmpty) const SizedBox(height: 6),
                                  ],

                                  // Text Message
                                  if (text.isNotEmpty)
                                    Text(
                                      text,
                                      style: GoogleFonts.outfit(
                                        color: isMe ? Colors.white : AppTheme.textDark,
                                        fontSize: 15,
                                        height: 1.3,
                                      ),
                                    ),
                                  const SizedBox(height: 4),

                                  // Time Indicator
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      timeStr,
                                      style: GoogleFonts.outfit(
                                        color: isMe ? Colors.white70 : AppTheme.textLight,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ),

          // Attachment Banner Preview
          if (_attachedFile != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attached: ${_attachedFileName ?? 'File'}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.amber, size: 20),
                    onPressed: () {
                      setState(() {
                        _attachedFile = null;
                        _attachedFileName = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: AppTheme.primaryColor),
                  onPressed: _showAttachmentPickerOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    style: GoogleFonts.outfit(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.outfit(color: AppTheme.textLight),
                      fillColor: const Color(0xFFF3F4F6),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppTheme.primaryColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isSending ? null : _sendMessage,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
