import 'package:supabase_flutter/supabase_flutter.dart';

class GroupService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createGroup(String groupName, List<String> memberIds) async {
    final myId = _supabase.auth.currentUser!.id;
    final groupData = await _supabase
        .from('groups')
        .insert({'name': groupName, 'created_by': myId})
        .select()
        .single();

    final String groupId = groupData['id'];
    List<Map<String, dynamic>> members = [
      {'group_id': groupId, 'user_id': myId},
    ];
    for (var id in memberIds) {
      members.add({'group_id': groupId, 'user_id': id});
    }

    await _supabase.from('group_members').insert(members);
  }

  Future<List<Map<String, dynamic>>> getMyGroups() async {
    final response = await _supabase
        .from('groups')
        .select('*, group_members!inner(user_id)')
        .eq('group_members.user_id', _supabase.auth.currentUser!.id);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> sendGroupMessage(String groupId, String content) async {
    await _supabase.from('group_messages').insert({
      'group_id': groupId,
      'sender_id': _supabase.auth.currentUser!.id,
      'content': content,
    });
  }

  Stream<List<Map<String, dynamic>>> getGroupMessagesStream(String groupId) {
    return _supabase
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .map((data) => data);
  }

  Future<Map<String, Map<String, dynamic>>> getGroupMembersProfile(
    String groupId,
  ) async {
    try {
      // LANGKAH 1: Ambil daftar User ID saja dari grup
      final membersResponse = await _supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);

      // Kumpulkan ID menjadi List bersih
      final List<String> userIds = (membersResponse as List)
          .map((e) => e['user_id'] as String)
          .toList();

      if (userIds.isEmpty) return {};

      // LANGKAH 2: Ambil data Profile berdasarkan List ID tadi
      // Ini mem-bypass masalah relasi foreign key yang rumit
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, username, avatar_url')
          .filter(
            'id',
            'in',
            userIds,
          ); // Ambil profile dimana ID-nya ada di list userIds

      // Masukkan ke Map untuk akses cepat
      final Map<String, Map<String, dynamic>> membersMap = {};
      for (var p in profilesResponse) {
        membersMap[p['id']] = p;
      }

      return membersMap;
    } catch (e) {
      print("Error get members: $e");
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> searchGlobalUsers(String query) async {
    final myId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('profiles')
        .select('id, username, avatar_url')
        .ilike('username', '%$query%')
        .neq('id', myId)
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }
}
