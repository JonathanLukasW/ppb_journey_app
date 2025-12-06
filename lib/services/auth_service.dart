import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signInWithPassword({
    required String email, 
    required String password
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Login gagal: Email atau password salah.');
    }
  }

  Future<void> signUp({
    required String email, 
    required String password,
    required String username,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email, 
        password: password,
      );
    } catch (e) {
      throw Exception('Gagal daftar: $e');
    }
  }

  Future<void> verifySignUpOtp({required String email, required String token}) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.signup, 
        token: token,
        email: email,
      );
      
      if (response.session != null) {
        await _createProfile(
          response.user!.id, 
          response.user!.userMetadata?['username']
        );
      }
    } catch (e) {
      throw Exception('Kode OTP salah atau kadaluarsa.');
    }
  }

  Future<void> _createProfile(String userId, String? username) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'username': username ?? 'User Baru',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;
      
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final userId = currentUser!.id;
      final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'avatars/$fileName'; 

      await _supabase.storage.from('trip_images').upload(path, imageFile);
      final imageUrl = _supabase.storage.from('trip_images').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      throw Exception('Gagal upload avatar: $e');
    }
  }

  Future<void> updateProfile({required String username, String? avatarUrl}) async {
    final userId = currentUser!.id;
    
    final updates = {
      'id': userId,
      'username': username,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }

    try {
      await _supabase.from('profiles').upsert(updates);
    } catch (e) {
      throw Exception('Gagal update profile: $e');
    }
  }
}