import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Current Installed App Version
  static const String currentVersion = '1.0.0';
  static const int currentBuildNumber = 1;

  /// ---------------------------------------------------------
  /// CHECK FOR APP UPDATES
  /// ---------------------------------------------------------
  Future<void> checkForUpdates(BuildContext context, {bool showNoUpdateToast = false}) async {
    try {
      final response = await _client
          .from('app_updates')
          .select()
          .order('build_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        if (showNoUpdateToast && context.mounted) {
          _showToast(context, 'You are using the latest version ($currentVersion)!');
        }
        return;
      }

      final latestBuild = response['build_number'] as int? ?? 1;
      final latestVersion = response['version_name'] as String? ?? '1.0.0';
      final apkUrl = response['apk_url'] as String? ?? '';
      final releaseNotes = response['release_notes'] as String? ?? 'Performance improvements and bug fixes.';
      final isForceUpdate = response['is_force_update'] == true;

      if (latestBuild > currentBuildNumber && apkUrl.isNotEmpty) {
        if (context.mounted) {
          _showUpdateDialog(
            context: context,
            version: latestVersion,
            releaseNotes: releaseNotes,
            apkUrl: apkUrl,
            isForceUpdate: isForceUpdate,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  /// ---------------------------------------------------------
  /// PUBLISH NEW APP UPDATE (ADMIN)
  /// ---------------------------------------------------------
  Future<void> publishUpdate({
    required String versionName,
    required int buildNumber,
    required String apkUrl,
    required String releaseNotes,
    required bool isForceUpdate,
  }) async {
    await _client.from('app_updates').insert({
      'version_name': versionName,
      'build_number': buildNumber,
      'apk_url': apkUrl,
      'release_notes': releaseNotes,
      'is_force_update': isForceUpdate,
    });
  }

  void _showUpdateDialog({
    required BuildContext context,
    required String version,
    required String releaseNotes,
    required String apkUrl,
    required bool isForceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (dialogContext) {
        return PopScope(
          canPop: !isForceUpdate,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rocket Header Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: AppTheme.primaryColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'New Update Available!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Version $version',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // What's New Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's New:",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          releaseNotes,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse(apkUrl);
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Error opening update URL: $e');
                        }
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: Text(
                        'Download & Install Update',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),

                  if (!isForceUpdate) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Later',
                        style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
