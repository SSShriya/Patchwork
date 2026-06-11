// lib/services/event_service.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_card.dart';
import 'supabase_client.dart';

// import 'utils.dart';

class EventService {
  Future<List<EventCard>> getInterestedEvents(String currentUserId) async {
    // get interested events
    final rows = await supabase
        .from('interested_events')
        .select(
          'events(event_id, event_name, start_day, start_time, end_day, end_time, location, cost, description, image_url, society_id)',
        )
        .eq('user_id', currentUserId);

    final today = DateTime.now();
    final validRows = (rows as List).where((r) {
      if (r['events'] == null) return false;
      final e = r['events'] as Map<String, dynamic>;
      final endDay = DateTime.tryParse(e['end_day'] ?? '');
      return endDay != null && endDay.isAfter(today);
    }).toList();

    final eventIds = validRows
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
    return validRows.map((row) {
      final e = row['events'] as Map<String, dynamic>;
      final eventId = e['event_id'] as String;

      return EventCard(
        title: e['event_name'] ?? '',
        subtitle: e['description'] ?? '',
        numMatches: countMap[eventId] ?? 0,
        startDateTime: _parseDateTime(e['start_day'], e['start_time']),
        endDateTime: _parseDateTime(e['end_day'], e['end_time']),
        location: e['location'] ?? '',
        latitude: (e['latitude'] as num?)?.toDouble(),
        longitude: (e['longitude'] as num?)?.toDouble(),
        cost: (e['cost'] as num?)?.toDouble() ?? 0.0,
        eventId: eventId,
        societyId: e['society_id'] ?? '',
        icon: Icons.event,
        color: const Color(0XFFFED766),
        imageUrl: e['image_url'] ?? '',
      );
    }).toList();
  }

  Future<List<EventCard>> getAllEvents() async {
    final rows = await supabase
        .from('active_events')
        .select(
          'event_id, society_id, event_name, start_day, start_time, end_day, end_time, location, cost, description, image_url, latitude, longitude',
        );

    return (rows as List).map((e) {
      return EventCard(
        eventId: e['event_id'],
        societyId: e['society_id'] ?? 'ERROR',
        title: e['event_name'] ?? '',
        subtitle: e['description'] ?? '',
        numMatches: 0,
        startDateTime: _parseDateTime(e['start_day'], e['start_time']),
        endDateTime: _parseDateTime(e['end_day'], e['end_time']),
        cost: (e['cost'] as num?)?.toDouble() ?? 0.0,
        location: e['location'] ?? '',
        latitude: (e['latitude'] as num?)?.toDouble(),
        longitude: (e['longitude'] as num?)?.toDouble(),
        icon: Icons.event,
        color: const Color(0XFFFED766),
        imageUrl: e['image_url'] ?? '',
      );
    }).toList();
  }

  static Future<void> uploadEventImage(File? imageFile, String eventId) async {
    if (imageFile == null) return;

    final String filePath = '$eventId/profile.jpg';

    try {
      await supabase.storage
          .from('avatars')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      await supabase
          .from('events')
          .update({'image_url': publicUrl})
          .eq('event_id', eventId);
    } on StorageException catch (e) {
      throw Exception('Failed to upload profile picture: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during profile picture upload: $e');
    }
  }

  Future<String> getSocietyName(String societyId) async {
    final rows = await supabase
        .from('users')
        .select('name, is_society')
        .eq('id', societyId);

    if (rows.isEmpty) throw Exception('No societies found for id $societyId');

    final result = rows[0];
    if (!result['is_society']) return 'is_society is false for id $societyId';
    return result['name'];
  }

  Future<List<String>> eventsInCommon(String user1Id, String user2Id) async {
    final rows = await supabase
        .rpc('get_common_active_events', params: {
          'user1_id': user1Id,
          'user2_id': user2Id,
        });
  
    return (rows as List)
        .map((r) => r['event_name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
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
