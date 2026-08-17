import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'authentication_page.dart';
import 'theme.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? _user;
  String? _displayName;
  String? _displaySTD;
  String? _phone;
  String? _address;
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = AuthService.instance.currentUser;
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profileData = await ProfileService.instance.getCurrentProfile();

      if (profileData != null && mounted) {
        setState(() {
          _displayName = profileData['name'] as String?;
          final stdValue = profileData['standard'] ?? profileData['std'];
          _displaySTD = stdValue?.toString();
          _profileImageUrl = (profileData['image_url'] ?? profileData['imageUrl']) as String?;
          _phone = profileData['phone'] as String?;
          _address = profileData['address'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmAndSignOut() async {
    final shouldLogout = await showDialog<bool>(
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
              child: const Icon(Icons.logout, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: GoogleFonts.outfit(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _signOut();
    }
  }

  Future<void> _signOut() async {
    try {
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthenticationPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Sign Out Error: $e');
    }
  }

  void _copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
                    'Loading profile...',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header with SliverAppBar & Floating Avatar
                SliverAppBar(
                  expandedHeight: 260.0,
                  pinned: true,
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      tooltip: 'Logout',
                      onPressed: _confirmAndSignOut,
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Subtle background decorative circles
                          Positioned(
                            top: -40,
                            right: -40,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: -50,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          // Content in Hero Header
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 36),
                              // Avatar Container with Border Glow
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: AppTheme.intenseShadow,
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppTheme.primaryLight,
                                  backgroundImage: _profileImageUrl != null &&
                                          _profileImageUrl!.isNotEmpty
                                      ? NetworkImage(_profileImageUrl!)
                                      : null,
                                  child: _profileImageUrl == null ||
                                          _profileImageUrl!.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 55,
                                          color: AppTheme.primaryDark,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // User Display Name
                              Text(
                                _displayName ?? 'Student Profile',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Email / Role
                              Text(
                                _user?.email ?? '',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Profile Details Body Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats / Info Chips Banner
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoChip(
                                icon: Icons.school_rounded,
                                label: 'Class',
                                value: _displaySTD != null ? 'Std $_displaySTD' : 'N/A',
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoChip(
                                icon: Icons.verified_user_rounded,
                                label: 'Status',
                                value: 'Active Student',
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section Header: Personal Details
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Personal Information',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Details Card
                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: AppTheme.primaryLight.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Column(
                              children: [
                                _buildDetailTile(
                                  icon: Icons.person_outline_rounded,
                                  label: 'Full Name',
                                  value: _displayName ?? 'N/A',
                                ),
                                const Divider(height: 1, indent: 56),
                                _buildDetailTile(
                                  icon: Icons.school_outlined,
                                  label: 'Standard / Class',
                                  value: _displaySTD != null ? 'Std $_displaySTD' : 'N/A',
                                ),
                                const Divider(height: 1, indent: 56),
                                _buildDetailTile(
                                  icon: Icons.email_outlined,
                                  label: 'Email Address',
                                  value: _user?.email ?? 'N/A',
                                  onTap: _user?.email != null
                                      ? () => _copyToClipboard('Email', _user!.email!)
                                      : null,
                                ),
                                if (_phone != null && _phone!.isNotEmpty) ...[
                                  const Divider(height: 1, indent: 56),
                                  _buildDetailTile(
                                    icon: Icons.phone_outlined,
                                    label: 'Phone Number',
                                    value: _phone!,
                                    onTap: () => _copyToClipboard('Phone', _phone!),
                                  ),
                                ],
                                if (_address != null && _address!.isNotEmpty) ...[
                                  const Divider(height: 1, indent: 56),
                                  _buildDetailTile(
                                    icon: Icons.location_on_outlined,
                                    label: 'Residential Address',
                                    value: _address!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Logout Action Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[600],
                              side: BorderSide(
                                color: Colors.red.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.red.withValues(alpha: 0.04),
                            ),
                            onPressed: _confirmAndSignOut,
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: Text(
                              'Sign Out from Account',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.copy_rounded,
                size: 18,
                color: AppTheme.textLight.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}


