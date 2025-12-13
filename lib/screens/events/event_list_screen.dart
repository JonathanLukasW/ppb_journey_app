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

  List<TripEvent> _allTrips = [];
  List<TripEvent> _filteredTrips = [];
  Set<String> _myJoinedTripIds = {};

  bool _isLoading = true;
  String? _myAvatarUrl;

  String _searchQuery = '';
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _tripService.getMyTrips(),
      _tripService.getJoinedTripIds(),
      _authService.getProfile(),
    ]);

    final trips = results[0] as List<TripEvent>;
    final joinedIds = results[1] as List<String>;
    final profile = results[2] as Map<String, dynamic>?;

    if (mounted) {
      setState(() {
        _allTrips = trips;
        _myJoinedTripIds = joinedIds.toSet();
        _filteredTrips = trips;
        _myAvatarUrl = profile?['avatar_url'];
        _isLoading = false;
      });
      _applyFilter();
    }
  }

  void _applyFilter() {
    final myId = _authService.currentUser?.id;

    setState(() {
      _filteredTrips = _allTrips.where((trip) {
        final matchSearch =
            trip.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            trip.destination.toLowerCase().contains(_searchQuery.toLowerCase());
        bool matchTab = true;
        if (_selectedFilterIndex == 1) {
          final isOwner = (trip.ownerId == myId);
          final isParticipant = _myJoinedTripIds.contains(trip.id);

          matchTab = isOwner || isParticipant;
        }

        return matchSearch && matchTab;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6E78F7)),
                  )
                : _filteredTrips.isEmpty
                ? _buildEmptyState()
                : _buildGridList(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        "Travelers",
        style: TextStyle(
          color: Color(0xFF2C3E50),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          onPressed: () async => await _authService.signOut(),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
              );
              _loadData();
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              backgroundImage: _myAvatarUrl != null
                  ? NetworkImage(_myAvatarUrl!)
                  : null,
              child: _myAvatarUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        onChanged: (val) {
          _searchQuery = val;
          _applyFilter();
        },
        decoration: InputDecoration(
          hintText: "Cari event atau lokasi...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          _buildTabChip("Explore", 0),
          const SizedBox(width: 10),
          _buildTabChip("My Trips", 1),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilterIndex = index);
        _applyFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6E78F7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGridList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        itemCount: _filteredTrips.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildAddCard();
          return _buildTripCard(_filteredTrips[index - 1]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text("Tidak ada event", style: TextStyle(color: Colors.grey[400])),
    );
  }

  Widget _buildAddCard() {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateEventScreen()),
        );
        _loadData();
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
              "Buat Event",
              style: TextStyle(
                color: Color(0xFF7A869A),
                fontWeight: FontWeight.w500,
              ),
            ),
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
            builder: (context) =>
                EventDetailScreen(trip: trip, onRefresh: _loadData),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child:
                    trip.imageUrl != null && trip.imageUrl!.startsWith('http')
                    ? Image.network(trip.imageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFFFFB7B2),
                        child: const Icon(
                          Icons.image,
                          color: Colors.white,
                          size: 40,
                        ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${trip.startDate.day} ${_getMonthName(trip.startDate.month)} - ${trip.endDate.day} ${_getMonthName(trip.endDate.month)}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4C5980),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
