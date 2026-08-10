import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/student_request_service.dart';
import 'theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedStandard;
  XFile? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// 1. Upload logic (Internal to page or move to a StorageService later)
  Future<String?> _uploadProfileImage(String userId) async {
    if (_selectedImage == null) return null;
    try {
      final file = File(_selectedImage!.path);
      final fileExt = _selectedImage!.path.split('.').last;
      final fileName = '$userId/profile.$fileExt'; // Organizes by userId folder

      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      return Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Upload Error: $e');
      return null;
    }
  }

  /// 3. Main Sign Up Logic
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // A. Create the Auth User
      final authResponse = await AuthService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = authResponse.user;
      if (user != null) {
        // B. Upload Image if selected & get FCM token
        String? imageUrl = await _uploadProfileImage(user.id);
        String? fcmToken;
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } catch (e) {
          debugPrint('Error getting FCM token: $e');
        }

        // C. Create Student Request using your Service
        await StudentRequestService.instance.createRequest(
          authUserId: user.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          standard: int.parse(_selectedStandard!.replaceAll(RegExp(r'[^0-9]'), '')), // Extracts 10 from "Std 10"
          imageUrl: imageUrl,
          fcmToken: fcmToken,
        );

        // D. Trigger Edge Function Notification to Admin
        NotificationService.instance.sendTopicNotification(
          topic: 'admin_notifications',
          title: 'New Student Registration',
          body: '${_nameController.text.trim()} requested to join Darvesh Classes.',
        );

        if (mounted) _showSuccessDialog();
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message, Colors.red);
    } catch (e) {
      debugPrint("Error: $e");
      _showSnackBar('An error occurred during registration.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registration Sent'),
        content: const Text('Your account is pending admin approval. You will be able to log in once verified.'),
        actions: [
          ElevatedButton(
            onPressed: () async {
              // 1. Sign out to clear the session created during sign up
              await AuthService.instance.signOut();

              if (mounted) {
                // 2. Return to the Login Screen
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) setState(() => _selectedImage = image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Darvesh Classes')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Profile Picture Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _selectedImage != null ? FileImage(File(_selectedImage!.path)) : null,
                    child: _selectedImage == null ? const Icon(Icons.camera_alt, color: AppTheme.primaryColor) : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                        validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedStandard,
                        decoration: const InputDecoration(labelText: 'Standard', prefixIcon: Icon(Icons.school)),
                        items: ['Std 5', 'Std 6', 'Std 7', 'Std 8', 'Std 9', 'Std 10']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _selectedStandard = val),
                        validator: (v) => v == null ? 'Select your standard' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                        validator: (v) => v!.isEmpty ? 'Enter phone number' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'Full Address',
                            prefixIcon: Icon(Icons.home)
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter your address' : null,
                      ),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                        validator: (v) => v!.isEmpty ? 'Enter email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                        validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Request Registration'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}