class Conversation {
  final String partnerId;
  final String username;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime time;
  final bool isMe;

  Conversation({
    required this.partnerId,
    required this.username,
    this.avatarUrl,
    required this.lastMessage,
    required this.time,
    required this.isMe,
  });

  factory Conversation.fromMap(Map<String, dynamic> map, String myId) {
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
