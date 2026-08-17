import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/student_request_service.dart';
import 'services/profile_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';

class VerifyStudentRequestsPage extends StatefulWidget {
  const VerifyStudentRequestsPage({super.key});

  @override
  State<VerifyStudentRequestsPage> createState() =>
      _VerifyStudentRequestsPageState();
}

class _VerifyStudentRequestsPageState extends State<VerifyStudentRequestsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];
  final Map<String, bool> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await StudentRequestService.instance.getPendingRequests();
      if (mounted) {
        setState(() {
          _requests = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching student requests: $e');
      if (mounted) {
        _showSnackBar('Failed to load student requests', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveStudent(Map<String, dynamic> request) async {
    final authUserId = request['auth_user_id'] as String?;
    final studentName = request['name'] as String? ?? 'Student';
    if (authUserId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Approve Student',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to approve $studentName to access Darvesh Classes portal?',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: AppTheme.textLight, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Approve', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processingIds[authUserId] = true);

    try {
      // 1. Update request status in student_requests table
      await StudentRequestService.instance.approveRequest(authUserId);

      // 2. Ensure profile exists in profiles table
      final profileExists = await ProfileService.instance.profileExists(authUserId);
      if (!profileExists) {
        final stdValue = request['standard'];
        final intStd = stdValue is int ? stdValue : int.tryParse(stdValue?.toString() ?? '10') ?? 10;
        
        await ProfileService.instance.createProfile(
          id: authUserId,
          name: request['name'] ?? '',
          phone: request['phone'] ?? '',
          address: request['address'] ?? '',
          standard: intStd,
          imageUrl: request['image_url'],
        );
      }

      // 3. Save student FCM token to device_tokens table
      final fcmToken = (request['fcm_token'] ?? request['fcmToken']) as String?;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await NotificationService.instance.saveDeviceToken(
          studentId: authUserId,
          token: fcmToken,
        );
      }

      // 4. Send Push Notification to Student
      NotificationService.instance.sendUserNotification(
        userId: authUserId,
        title: 'Registration Approved! 🎉',
        body: 'Congratulations $studentName! Your registration for Darvesh Classes has been approved.',
        data: {'type': 'approval'},
      );

      _showSnackBar('$studentName approved successfully! 🎉', const Color(0xFF10B981));
      _fetchRequests();
    } catch (e) {
      debugPrint('Error approving student: $e');
      _showSnackBar('Failed to approve request: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(authUserId));
      }
    }
  }

  Future<void> _rejectStudent(Map<String, dynamic> request) async {
    final authUserId = request['auth_user_id'] as String?;
    final studentName = request['name'] as String? ?? 'Student';
    if (authUserId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Reject Request',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reject registration for $studentName?',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: AppTheme.textLight, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reject', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processingIds[authUserId] = true);

    try {
      await StudentRequestService.instance.rejectRequest(authUserId);
      _showSnackBar('Request for $studentName rejected.', Colors.orange);
      _fetchRequests();
    } catch (e) {
      debugPrint('Error rejecting student: $e');
      _showSnackBar('Failed to reject request: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(authUserId));
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Student Verification',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh List',
            onPressed: _fetchRequests,
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
                    'Loading pending requests...',
                    style: GoogleFonts.outfit(color: AppTheme.textLight),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchRequests,
              color: AppTheme.primaryColor,
              child: _requests.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.75,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                size: 64,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'All Caught Up!',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'There are no pending student verification requests at this time.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        final authUserId = request['auth_user_id'] as String? ?? '';
                        final isProcessing = _processingIds[authUserId] == true;
                        final imageUrl = request['image_url'] as String?;
                        final name = request['name'] as String? ?? 'Unnamed Student';
                        final email = request['email'] as String? ?? 'No Email';
                        final phone = request['phone'] as String? ?? 'N/A';
                        final address = request['address'] as String? ?? 'N/A';
                        final standard = request['standard']?.toString() ?? 'N/A';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppTheme.softShadow,
                            border: Border.all(
                              color: AppTheme.primaryLight.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Student Header Row
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: AppTheme.primaryLight,
                                      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                                          ? NetworkImage(imageUrl)
                                          : null,
                                      child: imageUrl == null || imageUrl.isEmpty
                                          ? const Icon(Icons.person, color: AppTheme.primaryColor, size: 28)
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.outfit(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            email,
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Class Chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Std $standard',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const Divider(height: 1),
                                const SizedBox(height: 12),

                                // Additional Details Row
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textLight),
                                    const SizedBox(width: 6),
                                    Text(
                                      phone,
                                      style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textDark),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textLight),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textDark),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Approve / Reject Action Buttons
                                if (isProcessing)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () => _rejectStudent(request),
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          label: Text(
                                            'Reject',
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10B981),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () => _approveStudent(request),
                                          icon: const Icon(Icons.check_rounded, size: 18),
                                          label: Text(
                                            'Approve',
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                          ),
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
            ),
    );
  }
}

