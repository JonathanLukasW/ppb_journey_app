class ChatPreview {
  final String id;
  final String title;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime time;
  final bool isGroup;

  ChatPreview({
    required this.id,
    required this.title,
    this.avatarUrl,
    required this.lastMessage,
    required this.time,
    required this.isGroup,
  });
}
