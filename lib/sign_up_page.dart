import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'theme.dart';
import 'firebase_message.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  String? _selectedStandard;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _isLoading = false;
  late XFile? _selectedImage = null;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String name = _nameController.text.trim();
      String? std = _selectedStandard;
      String address = _addressController.text.trim();
      String phoneNumber = _phoneNumberController.text.trim();

      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        String imageUrl = _selectedImage != null
            ? await uploadImageToFirebaseStorage(_selectedImage!.path)
            : '';

        // Save user details to Firestore
        await FirebaseFirestore.instance
            .collection('Darvesh Classes')
            .doc(user.uid)
            .set({
          'name': name,
          'emailID': email,
          'std': std,
          'address': address,
          'phoneNumber': phoneNumber,
          'imageUrl': imageUrl,
          'fcmToken': fcmToken,
        });

        await FirebaseFirestore.instance
            .collection('student_requests')
            .doc(user.uid)
            .set({
          'name': name,
          'emailID': email,
          'std': std,
          'address': address,
          'phoneNumber': phoneNumber,
          'imageUrl': imageUrl,
          'fcmToken': fcmToken,
          'request_timestamp': FieldValue.serverTimestamp(),
        });

        const String adminFCMToken =
            "dvMlPxG6TWy0b6e-j39cB0:APA91bF49otntJ0nbi_iDmuMA18HwuqyO2jiE6ckLKWzV0Bav_DjvLrgxeTciVLV2jYkGu23h2UyzCeUjVZxGIQxdacTan5EQUHIAkpNxhyOkU3Ma5Est7QS76hccQa9jifMc-oROBzB";

        await _sendNotification(
          'New Account Verification Pending',
          'A new account verification request is pending. Please review.',
          adminFCMToken,
        );

        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Success'),
                content: const Text(
                    "Sign-up successful.\nNow you can Sign In with Email & Password"),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to login screen
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';

      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'The account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red[700],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sign-up failed'),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendNotification(
      String title, String body, String token) async {
    const String serverKey = FcmConfig.serverKey;
    const String url = 'https://fcm.googleapis.com/fcm/send';

    final Map<String, dynamic> payload = {
      'notification': {
        'title': title,
        'body': body,
        'sound': 'default',
      },
      'priority': 'high',
      'data': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      'to': token,
    };

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    try {
      final http.Response response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<String> uploadImageToFirebaseStorage(String imagePath) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      firebase_storage.Reference ref =
          firebase_storage.FirebaseStorage.instance.ref().child(fileName);
      firebase_storage.UploadTask uploadTask = ref.putFile(File(imagePath));
      firebase_storage.TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == firebase_storage.TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception('Image upload failed');
      }
    } catch (e) {
      throw Exception('Image upload failed');
    }
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Styled Portrait Picker Button
              Center(
                child: GestureDetector(
                  onTap: _selectImage,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: _selectedImage != null
                          ? FileImage(File(_selectedImage!.path))
                          : null,
                      child: _selectedImage == null
                          ? const Icon(
                              Icons.add_a_photo_outlined,
                              size: 40,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _selectedImage == null
                      ? 'Tap icon to upload profile photo'
                      : 'Tap photo to change photo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              // Card container for fields
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Standard Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedStandard,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStandard = newValue;
                          });
                        },
                        items: <String>[
                          'Std 5',
                          'Std 6',
                          'Std 7',
                          'Std 8',
                          'Std 9',
                          'Std 10',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: 'Standard',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your standard';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Phone Number
                      TextFormField(
                        controller: _phoneNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUpWithEmailAndPassword,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Register'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Go Back Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Already have an account? Sign In'),
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

