import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_card.dart';

class EventMatchesScreen extends StatelessWidget {
  final EventCard event;

  const EventMatchesScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFF5F0F6),
      appBar: AppBar(
        title: Text(event.title),
        backgroundColor: event.color,
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Event Info Card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(event.icon, color: const Color(0xFF222222), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event.subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: const Color(0xFF222222).withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF222222), thickness: 0.3),
                const SizedBox(height: 8),
                // Date & Time
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color(0xFF222222),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat(
                        'EEEE, d MMMM yyyy',
                      ).format(event.startDateTime),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Color(0xFF222222),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('HH:mm').format(event.startDateTime)} - ${DateFormat('HH:mm').format(event.endDateTime)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Color(0xFF222222),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Matches Section ──
          Text(
            '${event.numMatches} ${event.numMatches == 1 ? 'Match' : 'Matches'}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 8),

          // placeholder — replace with real match cards later
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Your matches for this event will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
