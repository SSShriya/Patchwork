import 'package:flutter/material.dart';
import 'base_card.dart';

class EventCard extends BaseCard {
  final String eventId;
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
  });
}
