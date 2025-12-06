import 'package:flutter/material.dart';
import 'package:ppb_journey_app/models/friends.dart';
import 'package:ppb_journey_app/services/friend_service.dart';

class FriendsInboxScreen extends StatefulWidget {
  const FriendsInboxScreen({super.key});

  @override
  State<FriendsInboxScreen> createState() => _FriendsInboxScreenState();
}

class _FriendsInboxScreenState extends State<FriendsInboxScreen>
    with SingleTickerProviderStateMixin {
  final FriendService _friendService = FriendService();

  // Future untuk dua tab
  late Future<List<Friends>> _incomingFuture;
  late Future<List<Friends>> _sentFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _incomingFuture = _friendService.getIncomingRequests();
      _sentFuture = _friendService.getSentRequests();
    });
  }

  // Handle Accept/Reject (Untuk Tab Masuk)
  Future<void> _handleIncomingAction(String friendshipId, bool isAccept) async {
    try {
      if (isAccept) {
        await _friendService.acceptRequest(friendshipId);
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Pertemanan diterima!")));
      } else {
        await _friendService.rejectRequest(friendshipId);
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Permintaan dihapus.")));
      }
      _refreshData(); // Reload kedua tab
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }

  // Handle Cancel (Untuk Tab Terkirim)
  Future<void> _handleCancelAction(String friendshipId) async {
    try {
      await _friendService.cancelRequest(friendshipId);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Permintaan dibatalkan.")));
      _refreshData();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // DefaultTabController membungkus Scaffold untuk mengaktifkan TabBar
    return DefaultTabController(
      length: 2, // Jumlah Tab
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "Status Permintaan",
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF2C3E50),
            labelColor: Color(0xFF2C3E50),
            tabs: [
              Tab(text: "Masuk", icon: Icon(Icons.inbox)),
              Tab(text: "Terkirim", icon: Icon(Icons.outbox)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Permintaan Masuk
            _buildRequestList(future: _incomingFuture, isIncoming: true),

            // TAB 2: Permintaan Terkirim
            _buildRequestList(future: _sentFuture, isIncoming: false),
          ],
        ),
      ),
    );
  }

  // Widget Builder yang Reusable untuk kedua list
  Widget _buildRequestList({
    required Future<List<Friends>> future,
    required bool isIncoming,
  }) {
    return FutureBuilder<List<Friends>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isIncoming ? Icons.mark_email_read : Icons.send,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  isIncoming
                      ? "Tidak ada permintaan masuk"
                      : "Tidak ada permintaan terkirim",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: req.avatar_url != null
                      ? NetworkImage(req.avatar_url!)
                      : null,
                  child: req.avatar_url == null
                      ? Text(req.username[0].toUpperCase())
                      : null,
                ),
                title: Text(
                  req.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isIncoming
                      ? "Ingin berteman dengan Anda"
                      : "Menunggu konfirmasi...",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: isIncoming
                    ? Row(
                        // Tombol untuk Tab Masuk (Terima/Tolak)
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                _handleIncomingAction(req.friendship_id, false),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () =>
                                _handleIncomingAction(req.friendship_id, true),
                          ),
                        ],
                      )
                    : TextButton(
                        // Tombol untuk Tab Terkirim (Batalkan)
                        onPressed: () => _handleCancelAction(req.friendship_id),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        child: const Text("Batal"),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
