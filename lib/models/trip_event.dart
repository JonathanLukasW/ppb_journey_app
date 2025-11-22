import 'package:flutter/material.dart';

class TripEvent {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final String ownerId;
  final String? imageUrl; 

  TripEvent({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.ownerId,
    this.imageUrl, 
  });

  factory TripEvent.fromMap(Map<String, dynamic> data) {
    return TripEvent(
      id: data['id'] as String,
      title: data['title'] as String,
      destination: data['destination'] as String,
      startDate: DateTime.parse(data['start_date'] as String), 
      ownerId: data['owner_id'] as String,
      imageUrl: data['cover_image_url'] as String?, 
    );
  }
    return {
      'title': title,
      'destination': destination,
      'start_date': startDate.toIso8601String().split('T').first,
      'owner_id': ownerId,
      'cover_image_url': imageUrl,
    };
  }
}