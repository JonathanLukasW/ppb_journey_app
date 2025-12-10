import 'package:flutter/material.dart';
import 'package:ppb_journey_app/models/friends.dart';
import 'package:ppb_journey_app/screens/friends/add_friends_screen.dart';
import 'package:ppb_journey_app/screens/friends/friends_inbox_screen.dart';
import 'package:ppb_journey_app/services/friend_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendService _friendService = FriendService();
  late Future<List<Friends>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  void loadFriends() {
    setState(() {
      _friendsFuture = _friendService.getFriendList();
    });
  }

  Future<void> _confirmDelete(Friends friend) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Teman?'),
          content: Text('Apakah Anda yakin ingin menghapus ${friend.username} dari daftar teman?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Tutup dialog dulu
                await _executeDelete(friend.friendship_id); // Baru eksekusi hapus
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeDelete(String friendshipId) async {
    try {
      // Panggil service delete
      await _friendService.deleteFriend(friendshipId);
      
      // Tampilkan pesan sukses
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teman berhasil dihapus')),
        );
      }
      
      // Refresh halaman otomatis
      loadFriends();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "Friends List",
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(onPressed: ()  {
            Navigator.push(context, MaterialPageRoute(builder: (_)=> SearchUserPage()));
          }, icon: Icon(Icons.search)),
          IconButton(onPressed: () async {
            Navigator.push(context, MaterialPageRoute(builder: (_)=>FriendsInboxScreen()));
            loadFriends();
          }, icon: Icon(Icons.mail))

        ],
      ),
      body: FutureBuilder<List<Friends>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada teman :("));
          }

          final friends = snapshot.data!;

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: friend.avatar_url != null
                      ? NetworkImage(friend.avatar_url!)
                      : null,
                  child: friend.avatar_url == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(friend.username),
                trailing: IconButton(
                  icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                  onPressed: () {
                    // Panggil fungsi dialog konfirmasi
                    _confirmDelete(friend);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
