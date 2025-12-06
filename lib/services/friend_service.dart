import 'package:ppb_journey_app/models/friend_search_results.dart';
import 'package:ppb_journey_app/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ppb_journey_app/models/friends.dart';

class FriendService {
  final supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  Future<List<Friends>> getFriendList() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    final List<dynamic> response = await supabase
        .from('friendships')
        .select('''
        id,
        status,
        sender_id,
        receiver_id,
        sender:sender_id ( id, username, avatar_url ),
        receiver:receiver_id ( id, username, avatar_url )
      ''')
        .or('status.eq.accepted')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId');

    return response.map((item) => Friends.fromMap(item, userId)).toList();
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    final currentUser = _authService.currentUser?.id;

    if (currentUser == null) {
      throw Exception('User belum login');
    }

    if (currentUser == targetUserId) {
      throw Exception('Tidak bisa menambah diri sendiri');
    }

    try {
      final List<dynamic> existingCheck = await supabase
          .from('friendships')
          .select()
          .or(
            'and(sender_id.eq.$currentUser,receiver_id.eq.$targetUserId),and(sender_id.eq.$targetUserId,receiver_id.eq.$currentUser)',
          );

      if (existingCheck.isNotEmpty) {
        throw Exception('Permintaan sudah dikirim atau anda sudah berteman');
      }

      await supabase.from('friendships').insert({
        'sender_id': currentUser,
        'receiver_id': targetUserId,
        'status': 'pending',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FriendSearchResults>> searchFriends(String query) async {
    final myId = _authService.currentUser?.id;
    if (myId == null || query.isEmpty) return [];

    try{
      final List<dynamic> profiles = await supabase.from('profiles').select().ilike('username', '%$query%').neq('id', myId).limit(20);
      if (profiles.isEmpty) return [];
      final List<dynamic> myRelations = await supabase
          .from('friendships')
          .select()
          .or('sender_id.eq.$myId,receiver_id.eq.$myId');

      // 3. Gabungkan & Tentukan Status (Logic Mapping)
      return profiles.map((profile) {
        final userId = profile['id'];

        // Cari hubungan spesifik dengan user ini
        final relation = myRelations.cast<Map<String, dynamic>>().where(
          (r) =>
              (r['sender_id'] == userId && r['receiver_id'] == myId) ||
              (r['sender_id'] == myId && r['receiver_id'] == userId),
        ).firstOrNull;

        // Tentukan Enum Status
        FriendStatus status = FriendStatus.none;
        
        if (relation != null) {
          if (relation['status'] == 'accepted') {
            status = FriendStatus.friend;
          } else if (relation['sender_id'] == myId) {
            status = FriendStatus.sent;     // Kita yang kirim
          } else {
            status = FriendStatus.received; // Kita yang terima
          }
        }

        return FriendSearchResults.fromProfile(profile, status);
      }).toList();

    } catch (e) {
      throw Exception('Gagal mencari user: $e');
    }
  }

  Future<List<Friends>> getIncomingRequests() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    final List<dynamic> response = await supabase
        .from('friendships')
        .select('''
          id,
          status,
          sender_id,
          receiver_id,
          sender:sender_id ( id, username, avatar_url ),
          receiver:receiver_id ( id, username, avatar_url )
        ''')
        .eq('status', 'pending')       // Hanya yang pending
        .eq('receiver_id', userId);    // Hanya yang dikirim KE saya

    return response.map((item) => Friends.fromMap(item, userId)).toList();
  }

  Future<void> acceptRequest(String friendshipId) async {
    await supabase
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', friendshipId);
  }

  Future<void> rejectRequest(String friendshipId) async {
    await supabase
        .from('friendships')
        .delete()
        .eq('id', friendshipId);
  }

  Future<List<Friends>> getSentRequests() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    final List<dynamic> response = await supabase
        .from('friendships')
        .select('''
          id,
          status,
          sender_id,
          receiver_id,
          sender:sender_id ( id, username, avatar_url ),
          receiver:receiver_id ( id, username, avatar_url )
        ''')
        .eq('status', 'pending')       // Hanya yang pending
        .eq('sender_id', userId);      // Hanya yang SAYA kirim

    return response.map((item) => Friends.fromMap(item, userId)).toList();
  }

  Future<void> cancelRequest(String friendshipId) async {
    await rejectRequest(friendshipId); // Hapus baris dari database
  }

  Future<void> deleteFriend(String friendshipId) async {
    // Menghapus baris pertemanan berdasarkan ID unik friendship
    await supabase.from('friendships').delete().eq('id', friendshipId);
  }
}
