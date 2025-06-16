import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: No user returned');
      }

      return response;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      // Sign up the user in auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Registration failed: No user returned');
      }

      // Insert the user into our users table with initial data
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': '',
        'role': 'user',
        'created_at': DateTime.now().toIso8601String(),
      });

      return response;
    } catch (e) {
      if (e.toString().contains('User already registered')) {
        throw Exception('Email already registered');
      }
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear any cached data if needed
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Get user email
  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Get user data from database
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final email = user.email;
      if (email == null) {
        throw Exception('User email is null');
      }

      final data =
          await _supabase.from('users').select().eq('email', email).single();

      return data;
    } catch (e) {
      return null;
    }
  }

  // Get user data from custom users table
  Future<Map<String, dynamic>?> getCustomUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final data =
          await _supabase.from('users').select().eq('id', user.id).single();

      return data;
    } catch (e) {
      print('Error fetching custom user data: ${e.toString()}');
      return null;
    }
  }
}
