import 'package:ppb_journey_app/models/friend_search_results.dart';
import 'package:ppb_journey_app/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ppb_journey_app/models/friends.dart';

class FriendService {
  final supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  Future<List<FriendSearchResults>> searchFriends(String query) async {
    final myId = _authService.currentUser?.id;
    if (myId == null || query.isEmpty) return [];

    try {
      final List<dynamic> profiles = await supabase
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .neq('id', myId)
          .limit(20);

      if (profiles.isEmpty) return [];

      final List<dynamic> myRelations = await supabase
          .from('friendships')
          .select()
          .or('sender_id.eq.$myId,receiver_id.eq.$myId');

      return profiles.map((profile) {
        final userId = profile['id'];

        final relation = myRelations.cast<Map<String, dynamic>>().firstWhere(
          (r) => (r['sender_id'] == userId && r['receiver_id'] == myId) ||
                 (r['sender_id'] == myId && r['receiver_id'] == userId),
          orElse: () => {},
        );

        FriendStatus status = FriendStatus.none;
        if (relation.isNotEmpty) {
          if (relation['status'] == 'accepted') {
            status = FriendStatus.friend;
          } else if (relation['sender_id'] == myId) {
            status = FriendStatus.sent;
          } else {
            status = FriendStatus.received;
          }
        }

        return FriendSearchResults.fromProfile(profile, status);
      }).toList();
    } catch (e) {
      throw Exception('Gagal mencari user: $e');
    }
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    final currentUser = _authService.currentUser?.id;
    if (currentUser == null) throw Exception('Login dulu');

    try {
      await supabase.from('friendships').insert({
        'sender_id': currentUser,
        'receiver_id': targetUserId,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Gagal mengirim request: $e');
    }
  }

  Future<List<Friends>> getFriendList() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await supabase
          .from('friendships')
          .select('''
            id, status, sender_id, receiver_id,
            sender:sender_id(id, username, avatar_url),
            receiver:receiver_id(id, username, avatar_url)
          ''')
          .eq('status', 'accepted')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId');

      return (response as List).map((item) => Friends.fromMap(item, userId)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Friends>> getIncomingRequests() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('friendships')
        .select('id, status, sender_id, receiver_id, sender:sender_id(id, username, avatar_url), receiver:receiver_id(id, username, avatar_url)')
        .eq('status', 'pending')
        .eq('receiver_id', userId); 
    return (response as List).map((item) => Friends.fromMap(item, userId)).toList();
  }

  Future<List<Friends>> getSentRequests() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('friendships')
        .select('id, status, sender_id, receiver_id, sender:sender_id(id, username, avatar_url), receiver:receiver_id(id, username, avatar_url)')
        .eq('status', 'pending')
        .eq('sender_id', userId); 

    return (response as List).map((item) => Friends.fromMap(item, userId)).toList();
  }

  Future<void> acceptRequest(String friendshipId) async {
    await supabase.from('friendships').update({'status': 'accepted'}).eq('id', friendshipId);
  }

  Future<void> deleteFriend(String friendshipId) async {
    await supabase.from('friendships').delete().eq('id', friendshipId);
  }

  Future<void> rejectRequest(String friendshipId) async {
    await deleteFriend(friendshipId);
  }

  Future<void> cancelRequest(String friendshipId) async {
    await deleteFriend(friendshipId);
  }
}