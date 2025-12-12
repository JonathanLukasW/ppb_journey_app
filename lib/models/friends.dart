class Friends {
  final String id;
  final String username;
  final String? avatar_url;

  final String friendship_id; 
  final String status;

  Friends({
    required this.id,
    required this.username,
    this.avatar_url,
    required this.friendship_id,
    required this.status
  });

  factory Friends.fromMap(Map<String, dynamic> map, String myUserId) {
    final senderId = map['sender_id'] as String;
    final friendData = (senderId == myUserId) 
        ? map['receiver'] 
        : map['sender'];

    return Friends(
      id: friendData['id'],
      username: friendData['username'] ?? 'Tanpa Nama',
      avatar_url: friendData['avatar_url'],
      friendship_id: map['id'], 
      status: map['status'] ?? 'unknown',
    );
  }
}