import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ppb_journey_app/models/trip_event.dart';
import 'package:ppb_journey_app/services/auth_service.dart';

class TripService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  Future<String?> _uploadImage(File imageFile, String userId) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'events/$fileName';
      await _supabase.storage.from('trip_images').upload(path, imageFile);
      final imageUrl = _supabase.storage.from('trip_images').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      throw Exception('Gagal upload gambar: $e');
    }
  }

  Future<void> createNewTrip({
    required String title,
    required String destination,
    required DateTime startDate,
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
    );

    await _supabase.from('trips').insert(newTrip.toMap());
  }

  Future<List<TripEvent>> getMyTrips() async {
    try {
      final response = await _supabase
          .from('trips')
          .select('*')
          .order('start_date', ascending: true);

      final List<TripEvent> trips = (response as List<dynamic>)
          .map((data) => TripEvent.fromMap(data as Map<String, dynamic>))
          .toList();

      return trips;
    } catch (e) {
      return [];
    }
  }
  
  Future<void> deleteTrip(String tripId) async {
    await _supabase.from('trips').delete().eq('id', tripId);
  }
}