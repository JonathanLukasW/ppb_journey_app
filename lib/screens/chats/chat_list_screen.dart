import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Jangan lupa tambahkan intl di pubspec.yaml
import 'package:ppb_journey_app/models/conversation.dart'; // Sesuaikan import
import 'package:ppb_journey_app/services/chat_service.dart';
import 'package:ppb_journey_app/screens/chats/chat_screen.dart'; // Sesuaikan lokasi ChatScreen

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  late Future<List<Conversation>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    setState(() {
      _conversationsFuture = _chatService.getConversations();
    });
  }

  // Fungsi helper format waktu (misal: "10:30" atau "Kemarin")
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time).inDays;

    if (diff == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (diff == 1) {
      return 'Kemarin';
    } else {
      return DateFormat('dd/MM/yy').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Pesan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Conversation>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          
          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Belum ada pesan", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final chat = chats[index];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () async {
                  // Navigasi ke ChatScreen
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        friendId: chat.partnerId,
                        friendName: chat.username,
                      ),
                    ),
                  );
                  // Refresh list saat kembali (siapa tahu ada pesan baru)
                  _loadConversations();
                },
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: chat.avatarUrl != null 
                      ? NetworkImage(chat.avatarUrl!) 
                      : null,
                  child: chat.avatarUrl == null 
                      ? Text(chat.username[0].toUpperCase()) 
                      : null,
                ),
                title: Text(
                  chat.username,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Row(
                  children: [
                    if (chat.isMe) ...[
                      const Icon(Icons.done_all, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        chat.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // Potong teks panjang dengan ...
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(chat.time),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    // Jika ingin fitur "unread count", bisa ditambahkan di sini nanti
                  ],
                ),
              );
            },
          );
        },
      ),
      // Tombol Floating Action Button untuk memulai chat baru
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.message),
        onPressed: () {
          // Arahkan ke halaman Cari Teman atau Daftar Teman
          // Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
        },
      ),
    );
  }
}