import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // 1. Private Constructor for Singleton pattern
  AuthService._();

  // 2. Static instance
  static final AuthService instance = AuthService._();

  // 3. Supabase Client reference
  final SupabaseClient _client = Supabase.instance.client;

  // --- Getters ---

  /// Get the currently logged-in user
  User? get currentUser => _client.auth.currentUser;

  /// Get the current session
  Session? get session => _client.auth.currentSession;

  /// Get the current user ID
  String? get userId => currentUser?.id;

  /// Get the current user Email
  String? get email => currentUser?.email;

  // --- Methods ---

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up a new user
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send a password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}