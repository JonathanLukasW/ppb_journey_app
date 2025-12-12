import 'package:flutter/material.dart';
import 'package:ppb_journey_app/models/trip_event.dart';
import 'package:ppb_journey_app/services/trip_service.dart';
import 'package:ppb_journey_app/services/auth_service.dart';
import 'package:ppb_journey_app/screens/events/edit_event_screen.dart';
class EventDetailScreen extends StatefulWidget {
  final TripEvent trip;
  final VoidCallback? onRefresh;

  const EventDetailScreen({super.key, required this.trip, this.onRefresh});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final AuthService _authService = AuthService();
  final TripService _tripService = TripService();
  
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() => _isLoading = true);
    final data = await _tripService.getTripParticipants(widget.trip.id);
    final myId = _authService.currentUser?.id;

    setState(() {
      _participants = data;
      _isJoined = data.any((p) => p['id'] == myId);
      _isLoading = false;
    });
  }

  Future<void> _handleJoin() async {
    setState(() => _isLoading = true);
    try {
      await _tripService.joinTrip(widget.trip.id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil Join!"), backgroundColor: Colors.green));
      _loadParticipants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLeave() async {
    setState(() => _isLoading = true);
    try {
      await _tripService.leaveTrip(widget.trip.id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anda keluar dari event."), backgroundColor: Colors.orange));
      _loadParticipants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent() async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Event?'),
        content: const Text('Event ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (confirm) {
      await _tripService.deleteTrip(widget.trip.id);
      if (mounted) {
        Navigator.pop(context); 
        if (widget.onRefresh != null) widget.onRefresh!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = _authService.currentUser?.id == widget.trip.ownerId;
    final bool isFull = _participants.length >= widget.trip.maxParticipants;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.trip.destination, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 10)])
              ),
              background: widget.trip.imageUrl != null 
                ? Image.network(widget.trip.imageUrl!, fit: BoxFit.cover)
                : Container(color: Colors.teal),
            ),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.delete, color: Colors.red)),
                  onPressed: _deleteEvent,
                )
            ],
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.trip.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text("Tanggal: ${widget.trip.startDate.day}-${widget.trip.startDate.month}-${widget.trip.startDate.year}"),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFull ? Colors.red[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(
                            "${_participants.length} / ${widget.trip.maxParticipants} Peserta",
                            style: TextStyle(color: isFull ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    
                    const Text("Deskripsi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      widget.trip.description.isNotEmpty ? widget.trip.description : "Tidak ada deskripsi.",
                      style: const TextStyle(color: Colors.grey, height: 1.5),
                    ),

                    const SizedBox(height: 30),

                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text("Daftar Peserta", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      initiallyExpanded: true,
                      children: [
                        if (_participants.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text("Belum ada peserta.", style: TextStyle(color: Colors.grey))),
                        ..._participants.map((user) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                            child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(user['username']),
                          trailing: user['id'] == widget.trip.ownerId ? const Chip(label: Text("Owner")) : null,
                        )),
                      ],
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _buildActionButton(isOwner, isFull),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isOwner, bool isFull) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (isOwner) {
      return ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditEventScreen(trip: widget.trip)),
          );

          if (result == true) {
            _loadParticipants();
            if (widget.onRefresh != null) widget.onRefresh!();
            Navigator.pop(context);
          }
        }, 
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), 
        child: const Text("Edit Event", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }

    if (_isJoined) {
      return ElevatedButton(
        onPressed: _handleLeave,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
        child: const Text("Batal Join (Leave)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }

    if (isFull) {
      return ElevatedButton(
        onPressed: null, 
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
        child: const Text("Kuota Penuh", style: TextStyle(color: Colors.grey)),
      );
    }

    return ElevatedButton(
      onPressed: _handleJoin,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E78F7)),
      child: const Text("Join Event Ini", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}