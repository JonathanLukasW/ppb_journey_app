import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
  
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      Provider.google,
      redirectTo: 'io.supabase.flutter://login-callback/', 
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}