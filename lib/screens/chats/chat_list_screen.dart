import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ppb_journey_app/screens/chats/create_group_screen.dart';
import 'package:ppb_journey_app/screens/chats/group_chat_screen.dart';
import 'package:ppb_journey_app/screens/friends/friends_screen.dart';
import 'package:ppb_journey_app/services/chat_service.dart';
import 'package:ppb_journey_app/services/group_service.dart';
import 'package:ppb_journey_app/screens/chats/chat_screen.dart';
import 'package:ppb_journey_app/models/chat_preview.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final GroupService _groupService = GroupService();

  late Future<List<ChatPreview>> _allChatsFuture;

  @override
  void initState() {
    super.initState();
    _allChatsFuture = _loadAllChats();
  }

  void _refreshData() {
    setState(() {
      _allChatsFuture = _loadAllChats();
    });
  }

  // --- LOGIKA PENGGABUNGAN DATA (CORE LOGIC) ---
  Future<List<ChatPreview>> _loadAllChats() async {
    // 1. Ambil data Chat Pribadi & Grup secara paralel
    final results = await Future.wait([
      _chatService.getConversations(),
      _groupService.getMyGroups(),
    ]);

    final personalChats =
        results[0] as List<dynamic>; // Tipe aslinya List<Conversation>
    final groupChats = results[1] as List<Map<String, dynamic>>;

    List<ChatPreview> combinedList = [];

    // 2. Konversi Chat PRIBADI ke ChatPreview
    for (var chat in personalChats) {
      combinedList.add(
        ChatPreview(
          id: chat.partnerId,
          title: chat.username,
          avatarUrl: chat.avatarUrl,
          lastMessage: chat.lastMessage,
          time: chat.time,
          isGroup: false,
        ),
      );
    }

    // 3. Konversi Chat GRUP ke ChatPreview
    for (var group in groupChats) {
      // Catatan: Saat ini 'getMyGroups' mungkin belum punya data last_message
      // Kita pakai created_at grup sebagai placeholder waktu jika belum ada pesan
      final DateTime groupTime = DateTime.parse(group['created_at']).toLocal();

      combinedList.add(
        ChatPreview(
          id: group['id'],
          title: group['name'],
          avatarUrl: group['avatar_url'],
          lastMessage: "Grup: ${group['name']}", // Bisa diupdate nanti
          time: groupTime,
          isGroup: true,
        ),
      );
    }

    // 4. SORTING: Urutkan berdasarkan waktu (Terbaru di atas)
    combinedList.sort((a, b) => b.time.compareTo(a.time));

    return combinedList;
  }

  // Helper Format Waktu
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time).inDays;
    if (diff == 0) return DateFormat('HH:mm').format(time);
    if (diff == 1) return 'Kemarin';
    return DateFormat('dd/MM/yy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Pesan",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined, color: Colors.black),
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateGroupScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ChatPreview>>(
        future: _allChatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(child: Text("Belum ada pesan"));
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final chat = chats[index];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),

                // AVATAR: Beda icon untuk grup dan personal
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: chat.isGroup
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.grey[200],
                  backgroundImage: chat.avatarUrl != null
                      ? NetworkImage(chat.avatarUrl!)
                      : null,
                  child: chat.avatarUrl == null
                      ? Icon(
                          chat.isGroup ? Icons.groups : Icons.person,
                          color: chat.isGroup ? Colors.orange : Colors.grey,
                        )
                      : null,
                ),

                title: Text(
                  chat.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: Row(
                  children: [
                    // Icon kecil untuk menandai grup
                    if (chat.isGroup) ...[
                      const Icon(
                        Icons.people_alt,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        chat.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),

                trailing: Text(
                  _formatTime(chat.time),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                onTap: () async {
                  // LOGIKA NAVIGASI: Cek isGroup
                  if (chat.isGroup) {
                    // Masuk ke Halaman Grup
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatScreen(
                          groupId: chat.id,
                          groupName: chat.title,
                        ),
                      ),
                    );
                  } else {
                    // Masuk ke Halaman Pribadi
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          friendId: chat.id,
                          friendName: chat.title,
                        ),
                      ),
                    );
                  }
                  _refreshData(); // Refresh saat kembali
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.message),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FriendsScreen()),
          );
        },
      ),
    );
  }
}
