import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> sendOtp(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true, 
      );
    } catch (e) {
      throw Exception('Gagal mengirim OTP: $e');
    }
  }

  Future<void> verifyOtp({required String email, required String token}) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        token: token,
        email: email,
      );
      
      if (response.session == null) {
        throw Exception('Kode OTP salah atau kadaluarsa.');
      }
    } catch (e) {
      throw Exception('Verifikasi Gagal: $e');
    }
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
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    try {
      await _supabase.from('profiles').upsert(updates);
    } catch (e) {
      throw Exception('Gagal update profile: $e');
    }
  }
}