import 'package:flutter/material.dart';
import 'package:ppb_journey_app/models/trip_event.dart';
import 'package:ppb_journey_app/screens/events/create_event_screen.dart';
import 'package:ppb_journey_app/screens/profile_screen.dart';
import 'package:ppb_journey_app/services/trip_service.dart';
import 'package:ppb_journey_app/services/auth_service.dart';
import 'package:ppb_journey_app/screens/events/event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final TripService _tripService = TripService();
  final AuthService _authService = AuthService();
  late Future<List<TripEvent>> _futureTrips;
  
  String? get _currentUserId => _authService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    setState(() {
      _futureTrips = _tripService.getMyTrips();
    });
  }

  Future<void> _deleteEvent(String tripId) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Event?'),
        content: const Text('Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (confirm) {
      await _tripService.deleteTrip(tripId);
      _loadTrips(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Travelers",
          style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ProfileScreen()));
                setState(() {}); 
              },
              child: const CircleAvatar(
                radius: 18,
                child: Icon(Icons.person), 
              ),
            ),
          )
        ],
      ),

      body: FutureBuilder<List<TripEvent>>(
        future: _futureTrips,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6E78F7)));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final trips = snapshot.data ?? [];

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              crossAxisSpacing: 16, 
              mainAxisSpacing: 16, 
              childAspectRatio: 0.65, 
            ),
            itemCount: trips.length + 1, 
            itemBuilder: (context, index) {
              if (index == trips.length) {
                return _buildAddCard();
              }
              return _buildTripCard(trips[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddCard() {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateEventScreen()),
        );
        _loadTrips();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEEF0F6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFBCC3FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 12),
            const Text(
              "Add New Place",
              style: TextStyle(color: Color(0xFF7A869A), fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(TripEvent trip) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(
              trip: trip, 
              onRefresh: _loadTrips
            )
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: trip.imageUrl != null && trip.imageUrl!.startsWith('http')
                    ? Image.network(
                        trip.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => 
                          Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                      )
                    : Container(
                        color: const Color(0xFFFFB7B2), 
                        child: const Icon(Icons.image, color: Colors.white, size: 40),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trip.title,
                    textAlign: TextAlign.center,
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${trip.startDate.day}",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4C5980), height: 1.0),
                  ),
                  Text(
                    _getMonthName(trip.startDate.month),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _avatar("https://i.pravatar.cc/150?img=5"),
                        const SizedBox(width: 4),
                        _avatar("https://i.pravatar.cc/150?img=9"),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String url) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        image: DecorationImage(image: NetworkImage(url)),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}