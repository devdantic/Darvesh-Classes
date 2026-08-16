import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/message_service.dart';
import 'services/profile_service.dart';
import 'theme.dart';

class MessageToStudentPage extends StatefulWidget {
  const MessageToStudentPage({super.key});

  @override
  State<MessageToStudentPage> createState() => _MessageToStudentPageState();
}

class _MessageToStudentPageState extends State<MessageToStudentPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _announcements = [];
  String? _studentStandard;
  StreamSubscription<List<Map<String, dynamic>>>? _announcementsSubscription;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  Future<void> _initStream() async {
    try {
      final profile = await ProfileService.instance.getCurrentProfile();
      if (profile != null && mounted) {
        final stdValue = profile['standard'] ?? profile['std'];
        _studentStandard = stdValue?.toString();
      }
    } catch (_) {}

    _announcementsSubscription = MessageService.instance
        .streamAllAnnouncements()
        .listen(
      (data) {
        if (mounted) {
          setState(() {
            if (_studentStandard != null && _studentStandard!.isNotEmpty) {
              _announcements = data.where((item) {
                final itemStd = (item['standard'] as String? ?? '').toLowerCase();
                return itemStd == 'all classes' ||
                    itemStd == 'all' ||
                    itemStd.contains(_studentStandard!.toLowerCase()) ||
                    itemStd == 'std $_studentStandard';
              }).toList();
            } else {
              _announcements = data;
            }
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        debugPrint('Error streaming announcements: $e');
        _loadAnnouncements();
      },
    );
  }

  @override
  void dispose() {
    _announcementsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch current student standard
      final profile = await ProfileService.instance.getCurrentProfile();
      if (profile != null && mounted) {
        final stdValue = profile['standard'] ?? profile['std'];
        _studentStandard = stdValue?.toString();
      }

      // 2. Fetch all announcements from Supabase
      final data = await MessageService.instance.getAllAnnouncements();

      if (mounted) {
        setState(() {
          // Filter announcements: show 'All Classes' or student's standard if available
          if (_studentStandard != null && _studentStandard!.isNotEmpty) {
            _announcements = data.where((item) {
              final itemStd = (item['standard'] as String? ?? '').toLowerCase();
              return itemStd == 'all classes' ||
                  itemStd == 'all' ||
                  itemStd.contains(_studentStandard!.toLowerCase()) ||
                  itemStd == 'std $_studentStandard';
            }).toList();
          } else {
            _announcements = data;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading announcements: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      return '${dt.day} ${monthNames[dt.month - 1]} ${dt.year}, $hour:$minute $amPm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Group Broadcasts',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadAnnouncements,
          ),
        ],
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
                    'Loading announcements...',
                    style: GoogleFonts.outfit(color: AppTheme.textLight),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnnouncements,
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Academy Announcements',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _studentStandard != null
                                      ? 'Broadcasting to Std $_studentStandard & All Classes'
                                      : 'Official class notices broadcasted by Sanjay Sir',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Broadcasts',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          '${_announcements.length} Message${_announcements.length == 1 ? "" : "s"}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Empty State or List of Announcements
                    if (_announcements.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Announcements Yet',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Class announcements and broadcast messages will appear here.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _announcements.length,
                        itemBuilder: (context, index) {
                          final item = _announcements[index];
                          final title = item['title'] as String? ?? 'Announcement';
                          final content = item['content'] as String? ?? '';
                          final standard = item['standard'] as String? ?? 'All Classes';
                          final createdAt = item['created_at'] as String?;
                          final formattedTime = _formatDateTime(createdAt);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.softShadow,
                              border: Border.all(
                                color: AppTheme.primaryLight.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Standard Badge & Time
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.group_rounded,
                                              size: 14,
                                              color: Color(0xFF059669),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              standard,
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF059669),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (formattedTime.isNotEmpty)
                                        Text(
                                          formattedTime,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: AppTheme.textLight,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Announcement Title
                                  Text(
                                    title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Announcement Content
                                  Text(
                                    content,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: AppTheme.textDark.withValues(alpha: 0.85),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Sender Signature Footer
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 14,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Sent by Sanjay Sir',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
