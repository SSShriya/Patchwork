// lib/services/event_service.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_card.dart';
import 'supabase_client.dart';

// import 'utils.dart';

class EventService {
  Future<List<EventCard>> getInterestedEvents(String currentUserId) async {
    // 1. Get interested events
    final rows = await supabase
        .from('interested_events')
        .select(
          'events(event_id, event_name, start_day, start_time, end_day, end_time, location, cost, description, image_url, society_id, latitude, longitude, meet_committee,committee_meeting_location, committee_meeting_time, committee_member_id)',
        )
        .eq('user_id', currentUserId);

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final validRows = (rows as List).where((r) {
      if (r['events'] == null) return false;
      final e = r['events'] as Map<String, dynamic>;
      final endDay = DateTime.tryParse(e['end_day'] ?? '');
      // isAfter(startOfToday) means today and future are both included
      return endDay != null && !endDay.isBefore(startOfToday);
    }).toList();

    final eventIds = validRows
        .map((r) => (r['events'] as Map<String, dynamic>)['event_id'] as String)
        .toList();

    if (eventIds.isEmpty) return [];

    // 2. Map eventId to its society_id for quick local lookup
    final eventToSocietyMap = <String, String>{};
    for (final row in validRows) {
      final e = row['events'] as Map<String, dynamic>;
      eventToSocietyMap[e['event_id'] as String] = e['society_id'] ?? '';
    }

    // 3. Fetch all confirmed matches, adding user1_id and user2_id to the select statement
    final matchCounts = await supabase
        .from('matches')
        .select('event_id, user1_id, user2_id') // Added user IDs here
        .inFilter('event_id', eventIds)
        .eq('user1_accepted', true)
        .eq('user2_accepted', true)
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    // 4. Build a map of eventId to count, filtering out matches involving the society_id
    final countMap = <String, int>{};
    for (final row in matchCounts as List) {
      final eventId = row['event_id'] as String;
      final user1Id = row['user1_id'] as String;
      final user2Id = row['user2_id'] as String;
      final societyId = eventToSocietyMap[eventId];

      // SKIP this row if either user matches the society_id for this specific event
      if (user1Id == societyId || user2Id == societyId) {
        continue;
      }

      countMap[eventId] = (countMap[eventId] ?? 0) + 1;
    }

    // 5. Build EventCards using the filtered count map
    return validRows.map((row) {
      final e = row['events'] as Map<String, dynamic>;
      final eventId = e['event_id'] as String;

      return EventCard(
        title: e['event_name'] ?? '',
        subtitle: e['description'] ?? '',
        numMatches: countMap[eventId] ?? 0, // Now reflects the filtered total
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
        meetCommittee: e['meet_committee'] ?? false,
        committeeMeetingLocation: e['committee_meeting_location'],
        committeeMeetingTime: e['committee_meeting_time'],
        committeeMemberId: e['committee_member_id'],
      );
    }).toList();
  }

  Future<List<EventCard>> getAllEvents() async {
    final rows = await supabase
        .from('active_events')
        .select(
          'event_id, society_id, event_name, start_day, start_time, end_day, '
          'end_time, location, cost, description, image_url, latitude, longitude, '
          'meet_committee, committee_meeting_location, committee_meeting_time, committee_member_id',
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
        meetCommittee: e['meet_committee'] ?? false,
        committeeMeetingLocation: e['committee_meeting_location'],
        committeeMeetingTime: e['committee_meeting_time'],
        committeeMemberId: e['committee_member_id'],
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
    final rows = await supabase.rpc(
      'get_common_active_events',
      params: {'user1_id': user1Id, 'user2_id': user2Id},
    );

    return (rows as List)
        .map((r) => r['event_name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<List<EventCard>> otherUserEvents(
    String currentUserId,
    String otherUserId,
  ) async {
    final rows = await supabase.rpc(
      'get_other_user_events',
      params: {'current_user_id': currentUserId, 'other_user_id': otherUserId},
    );

    debugPrint('=== otherUserEvents raw rows: $rows ===');

    final events = (rows as List).map((e) {
      return EventCard(
        eventId: e['event_id'] ?? '',
        societyId: e['society_id'] ?? '',
        title: e['title'] ?? '',
        subtitle: e['subtitle'] ?? '',
        numMatches: 0,
        startDateTime: _parseDateTime(e['start_day'], e['start_time']),
        endDateTime: _parseDateTime(e['end_day'], e['end_time']),
        location: e['location'] ?? '',
        latitude: (e['latitude'] as num?)?.toDouble(),
        longitude: (e['longitude'] as num?)?.toDouble(),
        cost: (e['cost'] as num?)?.toDouble() ?? 0.0,
        icon: Icons.event,
        color: const Color(0XFFFED766),
        imageUrl: e['image_url'] ?? '',
      );
    }).toList();

    // sort ascending — soonest first
    events.sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
    return events;
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
