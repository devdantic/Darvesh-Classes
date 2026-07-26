import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'authentication_page.dart';
import 'theme.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? _user;
  String? _displayName;
  String? _displaySTD;
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = _firebaseAuth.currentUser;
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('Darvesh Classes')
          .doc(_user!.uid)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> userData = snapshot.data()!;
        setState(() {
          _displayName = userData['name'];
          _displaySTD = userData['std'];
          _profileImageUrl = userData['imageUrl'];
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _firebaseAuth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthenticationPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      //print('Sign Out Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Centered Circular Avatar with subtle shadow border
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryColor,
                        backgroundImage: _profileImageUrl != null &&
                                _profileImageUrl!.isNotEmpty
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null ||
                                _profileImageUrl!.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // User Information details in a sleek styled card
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _buildProfileRow(
                            Icons.person,
                            'Name',
                            _displayName ?? 'N/A',
                          ),
                          const Divider(height: 32, thickness: 1),
                          _buildProfileRow(
                            Icons.school,
                            'Standard',
                            _displaySTD ?? 'N/A',
                          ),
                          const Divider(height: 32, thickness: 1),
                          _buildProfileRow(
                            Icons.email,
                            'Email',
                            _user?.email ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
