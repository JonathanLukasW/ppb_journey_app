import 'package:flutter/material.dart';
import 'package:ppb_journey_app/models/trip_event.dart';
import 'package:ppb_journey_app/services/trip_service.dart';
import 'package:ppb_journey_app/services/auth_service.dart';

class EventDetailScreen extends StatelessWidget {
  final TripEvent trip;
  final VoidCallback? onRefresh; 

  const EventDetailScreen({super.key, required this.trip, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final TripService tripService = TripService();

    final bool isOwner = authService.currentUser?.id == trip.ownerId;

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
        await tripService.deleteTrip(trip.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event dihapus")));
          Navigator.pop(context);
          if (onRefresh != null) onRefresh!(); 
        }
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(trip.destination, 
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)]
                )
              ),
              background: trip.imageUrl != null 
                ? Image.network(trip.imageUrl!, fit: BoxFit.cover)
                : Container(color: Colors.teal),
            ),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.delete, color: Colors.red),
                  ),
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
                    Text(trip.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text("Tanggal: ${trip.startDate.day}-${trip.startDate.month}-${trip.startDate.year}"),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    const Divider(),

                    const Text("Deskripsi Event", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text(
                      "Ini adalah event trip ke bali, cuma 50k saja, dollar tapi. sbb deskripsi masih sama smua belum dimasukin ke create",
                      style: TextStyle(color: Colors.grey, height: 1.5),
                    ),

                    const SizedBox(height: 30),

                    const Text("Participants (3)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildAvatar("https://i.pravatar.cc/150?img=10"),
                        const SizedBox(width: 10),
                        _buildAvatar("https://i.pravatar.cc/150?img=12"),
                        const SizedBox(width: 10),
                        _buildAvatar("https://i.pravatar.cc/150?img=3"),
                      ],
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: isOwner 
                        ? ElevatedButton(
                            onPressed: () {}, 
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            child: const Text("Edit Event", style: TextStyle(color: Colors.white)),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Join coming soon!")));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E78F7)),
                            child: const Text("Join Event", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
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

  Widget _buildAvatar(String url) {
    return CircleAvatar(radius: 20, backgroundImage: NetworkImage(url));
  }
}