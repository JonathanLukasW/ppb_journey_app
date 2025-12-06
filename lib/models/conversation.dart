class Conversation {
  final String partnerId;
  final String username;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime time;
  final bool isMe; // Apakah saya pengirim pesan terakhir?

  Conversation({
    required this.partnerId,
    required this.username,
    this.avatarUrl,
    required this.lastMessage,
    required this.time,
    required this.isMe,
  });

  factory Conversation.fromMap(Map<String, dynamic> map, String myId) {
    // Data profil teman diambil dari relasi (lihat service di bawah)
    final partner = map['partner'] ?? {};

    return Conversation(
      partnerId: map['partner_id'],
      username: map['username'] ?? 'Tanpa Nama',
      avatarUrl: map['avatar_url'],
      lastMessage: map['content'] ?? '',
      time: DateTime.parse(map['created_at']).toLocal(),
      isMe: map['sender_id'] == myId,
    );
  }
}
