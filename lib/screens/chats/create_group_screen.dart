import 'package:flutter/material.dart';
import 'package:ppb_journey_app/models/friends.dart';
import 'package:ppb_journey_app/services/friend_service.dart';
import 'package:ppb_journey_app/services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FriendService _friendService = FriendService();
  final GroupService _groupService = GroupService();

  List<Friends> _friends = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  void _loadFriends() async {
    final data = await _friendService.getFriendList();
    setState(() => _friends = data);
  }

  void _createGroup() async {
    if (_nameController.text.isEmpty || _selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama grup dan anggota wajib diisi")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _groupService.createGroup(
        _nameController.text,
        _selectedIds.toList(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Grup berhasil dibuat!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Grup Baru")),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _createGroup,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nama Grup",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Pilih Anggota:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final friend = _friends[index];
                final isSelected = _selectedIds.contains(friend.id);

                return CheckboxListTile(
                  value: isSelected,
                  title: Text(friend.username),
                  secondary: CircleAvatar(child: Text(friend.username[0])),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedIds.add(friend.id);
                      } else {
                        _selectedIds.remove(friend.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
