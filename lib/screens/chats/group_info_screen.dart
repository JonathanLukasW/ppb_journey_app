import 'package:flutter/material.dart';
import 'package:ppb_journey_app/services/group_service.dart';
import 'package:ppb_journey_app/screens/friends/add_friends_screen.dart'; 
import 'package:ppb_journey_app/services/friend_service.dart';
import 'package:ppb_journey_app/models/friends.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupInfoScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final GroupService _groupService = GroupService();
  final FriendService _friendService = FriendService();

  Map<String, Map<String, dynamic>> _members = {};
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final membersData = await _groupService.getGroupMembersProfile(widget.groupId);
    final isAdmin = await _groupService.isGroupAdmin(widget.groupId);
    
    if (mounted) {
      setState(() {
        _members = membersData;
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    }
  }

  Future<void> _leaveGroup() async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Keluar Grup?"),
        content: const Text("Anda tidak akan menerima pesan dari grup ini lagi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Keluar", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (confirm) {
      await _groupService.leaveGroup(widget.groupId);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _showAddMemberDialog() async {
    final friends = await _friendService.getFriendList();
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Tambah Anggota", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (ctx, i) {
                  final friend = friends[i];
                  final isAlreadyMember = _members.containsKey(friend.id);

                  return ListTile(
                    leading: CircleAvatar(backgroundImage: friend.avatar_url != null ? NetworkImage(friend.avatar_url!) : null),
                    title: Text(friend.username),
                    trailing: isAlreadyMember
                      ? const Text("Sudah Bergabung", style: TextStyle(color: Colors.grey, fontSize: 12))
                      : IconButton(
                          icon: const Icon(Icons.person_add, color: Colors.blue),
                          onPressed: () async {
                            await _groupService.addMember(widget.groupId, friend.id);
                            Navigator.pop(context);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${friend.username} ditambahkan!")));
                          },
                        ),
                  );
                },
              ),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Info Grup")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(radius: 40, backgroundColor: Colors.orange.withOpacity(0.2), child: const Icon(Icons.groups, size: 40, color: Colors.orange)),
                    const SizedBox(height: 10),
                    Text(widget.groupName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("${_members.length} Anggota", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              if (_isAdmin)
                ElevatedButton.icon(
                  onPressed: _showAddMemberDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Anggota"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E78F7), foregroundColor: Colors.white),
                ),
              
              const SizedBox(height: 20),
              const Text("Anggota", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),

              ..._members.values.map((m) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: m['avatar_url'] != null ? NetworkImage(m['avatar_url']) : null,
                  child: m['avatar_url'] == null ? const Icon(Icons.person) : null,
                ),
                title: Text(m['username'] ?? 'Unknown'),
              )),

              const SizedBox(height: 40),

              OutlinedButton(
                onPressed: _leaveGroup,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                child: const Text("Keluar Grup"),
              ),
            ],
          ),
    );
  }
}