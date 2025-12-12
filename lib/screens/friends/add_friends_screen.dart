import 'package:flutter/material.dart';
import 'package:ppb_journey_app/models/friend_search_results.dart';
import 'package:ppb_journey_app/services/friend_service.dart';

class SearchUserPage extends StatefulWidget {
  const SearchUserPage({super.key});

  @override
  State<SearchUserPage> createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();
  
  List<FriendSearchResults> _results = [];
  bool _isLoading = false;

  void _onSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final data = await _friendService.searchFriends(query);
      setState(() => _results = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onAddFriend(FriendSearchResults user) async {
    try {
      await _friendService.sendFriendRequest(user.id);

      setState(() {
        user.status = FriendStatus.sent;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim request')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cari Teman")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Ketik username...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _onSearch(_searchController.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: _onSearch,
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.avatar_url != null 
                              ? NetworkImage(user.avatar_url!) 
                              : null,
                          child: user.avatar_url == null 
                              ? Text(user.username[0]) 
                              : null,
                        ),
                        title: Text(user.username),
                        trailing: _buildActionButton(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(FriendSearchResults user) {
    switch (user.status) {
      case FriendStatus.friend:
        return const Chip(
          label: Text("Teman"), 
          backgroundColor: Colors.green, 
          labelStyle: TextStyle(color: Colors.white)
        );
      
      case FriendStatus.sent:
        return const Chip(
          label: Text("Terkirim"), 
          backgroundColor: Colors.grey
        ); 
        
      case FriendStatus.received:
        return ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text("Terima"),
        );
        
      case FriendStatus.none:
      return ElevatedButton.icon(
          onPressed: () => _onAddFriend(user),
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text("Tambah"),
        );
    }
  }
}