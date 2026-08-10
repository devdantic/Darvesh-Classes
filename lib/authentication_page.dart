import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
            // While checking DB, show loading
            if (requestSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final requestData = requestSnapshot.data;

            // Logic: If status is NOT approved, show the "Pending" screen and don't allow entry
            if (requestData == null || requestData['status'] != 'approved') {
              return _buildPendingScreen();
            }

            // ONLY if approved (profiles record exists), save device token & subscribe to topics
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Verification Pending',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your account is awaiting admin approval. Please wait till the admin approves the request.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => AuthService.instance.signOut(),
                child: const Text('Back to Login / Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // Logo
                  Container(
                    height: 100, width: 100,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset('media/DC_logo_2.png', errorBuilder: (c, e, s) => const Icon(Icons.school, size: 50)),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Welcome Back', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                onPressed: () => setState(() => _obscureText = !_obscureText),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignIn,
                            child: _isLoading ? const CircularProgressIndicator() : const Text('Sign In'),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage())),
                            child: const Text('Create an Account'),
                          ),
                        ],
                      ),
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
      _showSnackBar('Please fill in all fields', Colors.amber);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // We just perform the sign in. The StreamBuilder in build() handles the navigation logic.
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}