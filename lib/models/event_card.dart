import 'package:flutter/material.dart';
import 'base_card.dart';

class EventCard extends BaseCard {
  @override
  final String title;
  final String subtitle;
  final int numMatches;
  final String location;
  final DateTime startDateTime;
  final DateTime endDateTime;
  @override
  final IconData icon;
  @override
  final Color color;

  const EventCard({
    required this.title,
    required this.subtitle,
    required this.numMatches,
    required this.location,
    required this.startDateTime,
    required this.endDateTime,
    required this.icon,
    required this.color,
  });
}

// dummy cards
var recCards = [
  EventCard(
    title: 'Cookie Making',
    subtitle: 'Baking Society',
    numMatches: 2,
    location: 'ACEX',
    startDateTime: DateTime.utc(2026, 6, 3, 18),
    endDateTime: DateTime.utc(2026, 6, 3, 20),
    icon: Icons.cloud,
    color: Color(0XFFFED766),
  ),
  EventCard(
    title: 'Fight Club',
    subtitle: 'Boxing Society',
    numMatches: 3,
    location: 'Queens Lawn',
    startDateTime: DateTime.utc(2026, 6, 4, 18),
    endDateTime: DateTime.utc(2026, 6, 4, 19),
    icon: Icons.cloud,
    color: Color(0XFFFED766),
  ),
  EventCard(
    title: 'Listening Party',
    subtitle: 'Alternative Music Society',
    numMatches: 1,
    location: 'Huxley 145',
    startDateTime: DateTime.utc(2026, 6, 5, 19),
    endDateTime: DateTime.utc(2026, 6, 5, 21),
    icon: Icons.cloud,
    color: Color(0XFFFED766),
  ),
  EventCard(
    title: 'Off the Hook',
    subtitle: 'KnitSock',
    numMatches: 1,
    location: 'RSM 147',
    startDateTime: DateTime.utc(2026, 6, 8, 18),
    endDateTime: DateTime.utc(2026, 6, 8, 20),
    icon: Icons.cloud,
    color: Color(0XFFFED766),
  ),
];
