import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'sign_up_page.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'theme.dart';
import 'services/student_request_service.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveFcmToken(String userId) {
    FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) {
        NotificationService.instance.saveDeviceToken(
          studentId: userId,
          token: token,
        );
      }
    }).catchError((e) {
      debugPrint('Error fetching/saving FCM token: $e');
    });
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: AppTheme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text('Reset Password', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your registered email address and we will send you a password reset link.',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.outfit(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Registered Email',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isResetting
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty) {
                            _showSnackBar('Please enter your email address', Colors.amber[800]!);
                            return;
                          }

                          setDialogState(() => isResetting = true);
                          try {
                            await AuthService.instance.resetPassword(email);
                            if (mounted) {
                              _showSnackBar('Password reset link sent! Check your inbox / spam.', const Color(0xFF10B981));
                            }
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                          } on AuthException catch (e) {
                            _showSnackBar(e.message, Colors.red);
                          } catch (e) {
                            _showSnackBar('Failed to send reset link: $e', Colors.red);
                          } finally {
                            if (dialogContext.mounted) setDialogState(() => isResetting = false);
                          }
                        },
                  child: isResetting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Send Link', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen to the stream of Auth changes
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        final user = session?.user;

        if (user == null) {
          return _buildLoginForm();
        }

        // 2. Immediate Admin Check
        if (user.email == 'sanjaygovindani757@gmail.com') {
          _saveFcmToken(user.id);
          NotificationService.instance.subscribeToTopic('admin_notifications');
          return const AdminPage();
        }

        // 3. Handle Student Approval Status
        return FutureBuilder<Map<String, dynamic>?>(
          future: StudentRequestService.instance.getRequest(user.id),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: AppTheme.backgroundColor,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
                      const SizedBox(height: 16),
                      Text('Verifying credentials...', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                    ],
                  ),
                ),
              );
            }

            final requestData = requestSnapshot.data;

            // Logic: If status is NOT approved, show the "Pending" screen
            if (requestData == null || requestData['status'] != 'approved') {
              return _buildPendingScreen();
            }

            // ONLY if approved, save device token & subscribe to topics
            _saveFcmToken(user.id);
            NotificationService.instance.subscribeToTopic('all_students');
            final std = requestData['standard']?.toString();
            if (std != null && std.isNotEmpty) {
              NotificationService.instance.subscribeToTopic('std_$std');
            }
            return const HomePage();
          },
        );
      },
    );
  }

  Widget _buildPendingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, size: 56, color: Colors.amber),
                ),
                const SizedBox(height: 20),
                Text(
                  'Verification Pending',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your account request is currently awaiting admin verification by Sanjay Sir. You will gain full access once approved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textLight, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppTheme.primaryColor),
                    ),
                    onPressed: () => AuthService.instance.signOut(),
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.primaryColor, size: 18),
                    label: Text('Back to Login / Logout', style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E3A8A),
              Color(0xFF1E40AF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  // Shield Logo
                  Container(
                    height: 110,
                    width: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 3,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      'media/DC_logo_2.png',
                      errorBuilder: (c, e, s) => const Icon(Icons.school, size: 50, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'DARVESH CLASSES',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Empowering Excellence in Education',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sign In to Your Account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.outfit(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          style: GoogleFonts.outfit(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppTheme.textLight,
                              ),
                              onPressed: () => setState(() => _obscureText = !_obscureText),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _showForgotPasswordDialog,
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sign In Button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            onPressed: _isLoading ? null : _handleSignIn,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Sign In',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Create Account Link Button
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: const BorderSide(color: AppTheme.primaryColor),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUpPage()),
                            ),
                            child: Text(
                              'Create Student Account',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields', Colors.amber[800]!);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signIn(email: email, password: password);
    } on AuthException catch (e) {
      _showSnackBar(e.message, Colors.red);
    } catch (e) {
      _showSnackBar('An unexpected error occurred.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}