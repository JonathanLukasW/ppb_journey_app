import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ppb_journey_app/models/trip_event.dart';
import 'package:ppb_journey_app/services/auth_service.dart';

class TripService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();
  
  Future<void> joinTrip(String tripId) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) throw Exception("Harus login");

    try {
      await _supabase.from('trip_participants').insert({
        'trip_id': tripId,
        'user_id': userId,
        'status': 'joined', 
        'joined_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        print("User sudah terdaftar, skip insert.");
        return; 
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal join event: $e');
    }
  }

  Future<void> leaveTrip(String tripId) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) throw Exception("Harus login");

    try {
      await _supabase.from('trip_participants').delete().match({
        'trip_id': tripId,
        'user_id': userId,
      });
    } catch (e) {
      throw Exception('Gagal keluar event: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTripParticipants(String tripId) async {
    try {
      print("🔍 Fetching participants for Trip ID: $tripId");

      final response = await _supabase
          .from('trip_participants')
          .select('status, profiles!fk_participant_profile(id, username, avatar_url)') 
          .eq('trip_id', tripId);
      
      print("📦 Raw Data dari Supabase: $response");

      return List<Map<String, dynamic>>.from(response.map((item) {
        final profile = item['profiles'] ?? {};
        if (profile == null || profile.isEmpty) {
           return {
            'id': 'unknown',
            'username': 'Unknown User',
            'avatar_url': null,
            'status': item['status'],
          };
        }

        return {
          'id': profile['id'],
          'username': profile['username'] ?? 'Tanpa Nama',
          'avatar_url': profile['avatar_url'],
          'status': item['status'],
        };
      }));
    } catch (e) {
      print("❌ ERROR GET PARTICIPANTS: $e");
      return [];
    }
  }
  
  Future<void> createNewTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    required String description, 
    required int maxParticipants, 
    File? imageFile,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception("Unauthorized");

    String? publicImageUrl;
    if (imageFile != null) {
      publicImageUrl = await _uploadImage(imageFile, user.id);
    }

    final newTrip = TripEvent(
      id: '',
      title: title,
      destination: destination,
      startDate: startDate,
      ownerId: user.id,
      imageUrl: publicImageUrl,
      description: description, 
      maxParticipants: maxParticipants, 
    );

    final response = await _supabase.from('trips').insert(newTrip.toMap()).select();

    final newTripId = response[0]['id'];

    await _supabase.from('trip_participants').insert({
      'trip_id': newTripId,
      'user_id': user.id,
      'status': 'joined',
      'joined_at': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> updateTrip(TripEvent trip, File? newImageFile) async {
    final user = _authService.currentUser;
    if (user == null || user.id != trip.ownerId) throw Exception("Hanya owner yang bisa edit");

    String? imageUrl = trip.imageUrl;

    if (newImageFile != null) {
      imageUrl = await _uploadImage(newImageFile, user.id);
    }

    final updates = {
      'title': trip.title,
      'destination': trip.destination,
      'start_date': trip.startDate.toIso8601String().split('T').first,
      'description': trip.description,
      'max_participants': trip.maxParticipants,
      'cover_image_url': imageUrl,
    };

    await _supabase.from('trips').update(updates).eq('id', trip.id);
  }

  Future<String?> _uploadImage(File imageFile, String userId) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'events/$fileName';
      await _supabase.storage.from('trip_images').upload(path, imageFile);
      return _supabase.storage.from('trip_images').getPublicUrl(path);
    } catch (e) {
      throw Exception('Gagal upload gambar: $e');
    }
  }

  Future<List<TripEvent>> getMyTrips() async {
    try {
      final response = await _supabase.from('trips').select('*').order('start_date', ascending: true);
      return (response as List).map((data) => TripEvent.fromMap(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteTrip(String tripId) async {
    await _supabase.from('trips').delete().eq('id', tripId);
  }
}