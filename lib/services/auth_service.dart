import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signInWithEmail({
    required String email, 
    required String password
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Login gagal: Cek email atau password Anda.');
      
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}