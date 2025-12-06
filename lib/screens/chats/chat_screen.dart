import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ppb_journey_app/models/messages.dart';
import 'package:ppb_journey_app/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String friendId;
  final String friendName; // Untuk judul AppBar

  const ChatScreen({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear(); // Langsung clear agar responsif
    try {
      await _chatService.sendMessage(
        content: text,
        receiverId: widget.friendId,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal kirim: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.friendName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        
      ),
      body: Column(
        children: [
          // --- BAGIAN 1: LIST PESAN ---
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessageStream(widget.friendId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(child: Text("Mulai percakapan!"));
                }

                // ListView dibalik (reverse: true) agar mulai dari bawah
                // Kita perlu membalik urutan list messages juga
                final reversedMessages = messages.reversed.toList();

                return ListView.builder(
                  reverse: true, // Scroll mulai dari bawah
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final msg = reversedMessages[index];
                    return _buildChatBubble(msg);
                  },
                );
              },
            ),
          ),

          // --- BAGIAN 2: INPUT FIELD ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Tulis pesan...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Balon Chat
  Widget _buildChatBubble(Message msg) {
    return Align(
      alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: msg.isMine ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(msg.isMine ? 12 : 0),
            bottomRight: Radius.circular(msg.isMine ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: msg.isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(msg.content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              "${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 10, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}
