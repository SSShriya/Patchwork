import 'package:flutter/material.dart';
import 'base_card.dart';

class EventCard extends BaseCard {
  final String eventId;
  final String societyId;
  @override
  final String title;
  final String subtitle;
  final int numMatches;
  final String location;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final double cost;
  @override
  final IconData icon;
  @override
  final Color color;
  @override
  final String imageUrl;

  const EventCard({
    required this.eventId,
    required this.title,
    required this.subtitle,
    required this.numMatches,
    required this.location,
    required this.startDateTime,
    required this.endDateTime,
    required this.cost,
    required this.icon,
    required this.color,
    required this.societyId, // make required in future, default is for backwards compatibility
    this.imageUrl = '',
  });

  factory EventCard.fromJson(Map<String, dynamic> json) => EventCard(
    eventId: json['event_id'],
    societyId: json['society_id'],
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    numMatches: json['num_matches'] ?? 0,
    location: json['location'] ?? '',
    startDateTime: DateTime.parse(json['start_date_time']),
    endDateTime: DateTime.parse(json['end_date_time']),
    cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
    icon: Icons.event, 
    color: const Color(0xFF000000), 
    imageUrl: json['image_url'] ?? '',
  );
}
