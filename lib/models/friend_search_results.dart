enum FriendStatus { none, sent, received, friend }

class FriendSearchResults {
  final String id;
  final String username;
  final String? avatar_url;
  FriendStatus status;

  FriendSearchResults({
    required this.id,
    required this.username,
    this.avatar_url,
    required this.status,
  });

  factory FriendSearchResults.fromProfile(
    Map<String, dynamic> profile,
    FriendStatus status,
  ) {
    return FriendSearchResults(
      id: profile['id'],
      username: profile['username'] ?? 'Tanpa Nama',
      avatar_url: profile['avatar_url'],
      status: status,
    );
  }
}
