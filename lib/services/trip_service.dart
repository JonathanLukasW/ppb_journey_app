import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ppb_journey_app/models/trip_event.dart';
import 'package:ppb_journey_app/services/auth_service.dart';

class TripService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService(); 

  Future<void> createNewTrip({
    required String title,
    required String destination,
    required DateTime startDate,
    String? imageUrl,
  }) async {
    final user = _authService.getCurrentUser();
    if (user == null) {
      throw Exception("UNAUTHENTICATED_ERROR: Pengguna belum login.");
    }

    try {
      final newTrip = TripEvent(
        id: '', 
        title: title,
        destination: destination,
        startDate: startDate,
        ownerId: user.id, 
        imageUrl: imageUrl, 
      );

      await _supabase.from('trips').insert(newTrip.toMap());

    } on PostgrestException catch (e) {
      throw Exception('Gagal membuat Trip: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan tak terduga: $e');
    }
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
      throw Exception('Error saat mengambil trip: $e');
    }
  }
}