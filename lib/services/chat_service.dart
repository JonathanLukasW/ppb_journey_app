import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ppb_journey_app/models/messages.dart';
import 'package:ppb_journey_app/models/conversation.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Kirim Pesan
  Future<void> sendMessage({required String content, required String receiverId}) async {
    final myUserId = _supabase.auth.currentUser!.id;
    
    await _supabase.from('messages').insert({
      'sender_id': myUserId,
      'receiver_id': receiverId,
      'content': content,
    });
  }

  // 2. Stream Pesan (Realtime Listener)
  // Fungsi ini akan terus 'hidup' mendengarkan perubahan database
  Stream<List<Message>> getMessageStream(String friendId) {
    final myUserId = _supabase.auth.currentUser!.id;

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id']) // Wajib isi primary key
        .order('created_at', ascending: true) // Urutkan dari terlama ke terbaru
        .map((data) {
          // Filter manual di sisi aplikasi (karena stream query Supabase terbatas)
          // Ambil pesan yang melibatkan SAYA dan TEMAN tersebut
          return data.where((msg) => 
            (msg['sender_id'] == myUserId && msg['receiver_id'] == friendId) ||
            (msg['sender_id'] == friendId && msg['receiver_id'] == myUserId)
          ).map((item) => Message.fromMap(item, myUserId)).toList();
        });
  }

  Future<List<Conversation>> getConversations() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return [];

    try {
      final List<dynamic> response = await _supabase
          .from('my_conversations')
          .select() // Join ke tabel profile
          .order('created_at', ascending: false); // Urutkan chat terbaru di atas

      return response.map((e) => Conversation.fromMap(e, myId)).toList();
    } catch (e) {
      throw Exception('Gagal memuat chat: $e');
    }
  }
}