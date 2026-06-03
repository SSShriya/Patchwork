// lib/services/event_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_card.dart';

final supabase = Supabase.instance.client;

class EventService {
  final String currentUserId = '5f7e9d61-3865-47b2-9155-202267ee947f';

  Future<List<EventCard>> getInterestedEvents() async {
    // get interested events
    final rows = await supabase
        .from('interested_events')
        .select(
          'events(event_id, event_name, start_day, start_time, end_day, end_time, location, cost, description, image_url)',
        )
        .eq('user_id', currentUserId);

    final eventIds = (rows as List)
        .map((r) => (r['events'] as Map<String, dynamic>)['event_id'] as String)
        .toList();

    if (eventIds.isEmpty) return [];

    // fetch all confirmed match counts
    final matchCounts = await supabase
        .from('matches')
        .select('event_id')
        .inFilter('event_id', eventIds)
        .eq('user1_accepted', true)
        .eq('user2_accepted', true)
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    // build a map of eventId to count
    final countMap = <String, int>{};
    for (final row in matchCounts as List) {
      final eventId = row['event_id'] as String;
      countMap[eventId] = (countMap[eventId] ?? 0) + 1;
    }

    // build EventCards using the count map
    return rows.map((row) {
      final e = row['events'] as Map<String, dynamic>;
      final eventId = e['event_id'] as String;

      return EventCard(
        title: e['event_name'] ?? '',
        subtitle: e['description'] ?? '',
        numMatches: countMap[eventId] ?? 0,
        startDateTime: _parseDateTime(e['start_day'], e['start_time']),
        endDateTime: _parseDateTime(e['end_day'], e['end_time']),
        location: e['location'] ?? '',
        cost: (e['cost'] as num?)?.toDouble() ?? 0.0,
        eventId: eventId,
        icon: Icons.event,
        color: const Color(0XFFFED766),
        imageUrl: e['image_url'] ?? '',
      );
    }).toList();
  }

  Future<List<EventCard>> getAllEvents() async {
    final rows = await supabase
        .from('events')
        .select(
          'event_id, event_name, start_day, start_time, end_day, end_time, location, cost, description, image_url',
        );

    return (rows as List).map((e) {
      return EventCard(
        eventId: e['event_id'],
        title: e['event_name'] ?? '',
        subtitle: e['description'] ?? '',
        numMatches: 0,
        startDateTime: _parseDateTime(e['start_day'], e['start_time']),
        endDateTime: _parseDateTime(e['end_day'], e['end_time']),
        cost: (e['cost'] as num?)?.toDouble() ?? 0.0,
        location: e['location'] ?? '',
        icon: Icons.event,
        color: const Color(0XFFFED766),
        imageUrl: e['image_url'] ?? '',
      );
    }).toList();
  }
}

// Combines "2026-06-03" + "18:00:00" → DateTime
DateTime _parseDateTime(String? date, String? time) {
  if (date == null) return DateTime.now();
  final dateStr = date; // e.g. "2026-06-03"
  final timeStr = (time ?? '00:00:00')
      .padRight(8, '0') // ensure "HH:mm:ss" format
      .substring(0, 8); // trim any microseconds
  return DateTime.parse('${dateStr}T$timeStr'); // "2026-06-03T18:00:00"
}
