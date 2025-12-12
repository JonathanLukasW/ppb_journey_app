class TripEvent {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final String ownerId;
  final String? imageUrl;

  final String description; 
  final int maxParticipants; 

  TripEvent({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.ownerId,
    this.imageUrl,
    this.description = '',
    this.maxParticipants = 10,
  });

  factory TripEvent.fromMap(Map<String, dynamic> data) {
    return TripEvent(
      id: data['id'] as String,
      title: data['title'] as String,
      destination: data['destination'] as String,
      startDate: DateTime.parse(data['start_date'] as String),
      ownerId: data['owner_id'] as String,
      imageUrl: data['cover_image_url'] as String?,
      description: data['description'] ?? '',
      maxParticipants: data['max_participants'] ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'destination': destination,
      'start_date': startDate.toIso8601String().split('T').first,
      'owner_id': ownerId,
      'cover_image_url': imageUrl,
      'description': description,
      'max_participants': maxParticipants,
    };
  }
}