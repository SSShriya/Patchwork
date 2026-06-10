// lib/services/match_service.dart

import 'package:flutter/material.dart';

import '../models/match_card.dart';
import 'utils.dart';
import 'supabase_client.dart';

class MatchService {
  Future<List<MatchCard>> getPendingMatches(String currentUserId) async {
    debugPrint("getPendingMatches() has been called");

    final currentUserData = await supabase
        .from('users')
        .select('university, course, location, user_interests(interest)')
        .eq('id', currentUserId)
        .single();

    final currentUniversity = (currentUserData['university'] as String?) ?? '';
    final currentCourse = (currentUserData['course'] as String?) ?? '';
    final currentLocation = (currentUserData['location'] as String?) ?? '';
    final currentInterests =
        (currentUserData['user_interests'] as List<dynamic>? ?? [])
            .map((i) => i['interest'] as String)
            .toSet();

    final interestedEventsData = await supabase
        .from('interested_events')
        .select('event_id')
        .eq('user_id', currentUserId);

    final interestedEventIds = (interestedEventsData as List)
        .map((e) => e['event_id'] as String)
        .toList();

    if (interestedEventIds.isEmpty) return [];

    final rows = await supabase
        .from('matches')
        .select(
          '*, events(event_name), user1:user1_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest), is_society), user2:user2_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest), is_society)',
        )
        .inFilter('event_id', interestedEventIds)
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    // ── Collect all other user IDs for batch gallery fetch ──────────────
    final otherUserIds = <String>[];
    for (final row in rows as List) {
      final isUser1 = currentUserId == row['user1_id'] as String;
      final otherUserData = isUser1
          ? row['user2'] as Map<String, dynamic>
          : row['user1'] as Map<String, dynamic>;
      otherUserIds.add(otherUserData['id'] as String);
    }

    final galleryMap = await fetchGalleryUrlsForUsers(otherUserIds);

    // ── Build match cards ────────────────────────────────────────────────
    final matches = <(MatchCard, int)>[];

    for (final row in rows) {
      final user1Id = row['user1_id'] as String;
      final user1Accepted = row['user1_accepted'] as bool?;
      final user2Accepted = row['user2_accepted'] as bool?;
      final eventId = row['event_id'] as String;
      final eventName =
          (row['events'] as Map<String, dynamic>?)?['event_name'] as String? ??
          '';

      final isUser1 = currentUserId == user1Id;
      final currentUserAccepted = isUser1 ? user1Accepted : user2Accepted;
      if (currentUserAccepted != null) continue;

      final otherUserData = isUser1
          ? row['user2'] as Map<String, dynamic>
          : row['user1'] as Map<String, dynamic>;

      if (otherUserData['is_society'] == true ||
          otherUserData['is_society'].toString() == 'true') {
        break;
      }

      final otherUserId = otherUserData['id'] as String;
      final otherInterests =
          (otherUserData['user_interests'] as List<dynamic>? ?? [])
              .map((i) => i['interest'] as String)
              .toSet();

      int score = 0;
      score += currentInterests.intersection(otherInterests).length;

      final otherUniversity = (otherUserData['university'] as String?) ?? '';
      if (currentUniversity.isNotEmpty &&
          otherUniversity.isNotEmpty &&
          currentUniversity.toLowerCase() == otherUniversity.toLowerCase()) {
        score += 1;
      }

      final otherCourse = (otherUserData['course'] as String?) ?? '';
      if (currentCourse.isNotEmpty &&
          otherCourse.isNotEmpty &&
          currentCourse.toLowerCase() == otherCourse.toLowerCase()) {
        score += 1;
      }

      final otherLocation = (otherUserData['location'] as String?) ?? '';
      if (currentLocation.isNotEmpty &&
          otherLocation.isNotEmpty &&
          currentLocation.toLowerCase() == otherLocation.toLowerCase()) {
        score += 1;
      }

      if (score < 1) continue;

      matches.add((
        MatchCard(
          currentUserId: currentUserId,
          otherUserId: otherUserId,
          title: otherUserData['name'] ?? 'Unknown',
          university: otherUniversity,
          course: otherCourse,
          bio: otherUserData['bio'] ?? '',
          eventId: eventId,
          eventName: eventName,
          yearGroup: otherUserData['year_group'] ?? '',
          interests: otherInterests.toList(),
          location: otherLocation,
          imageUrl: otherUserData['avatar_url'] ?? '',
          galleryUrls: galleryMap[otherUserId] ?? [],
        ),
        score,
      ));
    }

    matches.sort((a, b) => b.$2.compareTo(a.$2));
    return matches.map((e) => e.$1).toList();
  }

  Future<bool> hasOtherUserAccepted(MatchCard card) async {
    final parts = card.matchKey.split('|');
    final user1Id = parts[0];
    final user2Id = parts[1];
    final eventId = parts[2];

    final row = await supabase
        .from('matches')
        .select('user1_accepted, user2_accepted')
        .eq('user1_id', user1Id)
        .eq('user2_id', user2Id)
        .eq('event_id', eventId)
        .single();

    final otherAccepted = card.currentUserId == card.matchKey.split('|')[0]
        ? row['user2_accepted'] as bool?
        : row['user1_accepted'] as bool?;

    return otherAccepted == true;
  }

  Future<List<MatchCard>> getAwaitingResponseMatches(
    String currentUserId,
  ) async {
    final rows = await supabase
        .from('matches')
        .select(
          '*, events(event_name), user1:user1_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest)), user2:user2_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest))',
        )
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    // ── Collect other user IDs for batch gallery fetch ───────────────────
    final otherUserIds = <String>[];
    for (final row in rows as List) {
      final isUser1 = currentUserId == row['user1_id'] as String;
      final otherUserData = isUser1
          ? row['user2'] as Map<String, dynamic>
          : row['user1'] as Map<String, dynamic>;
      otherUserIds.add(otherUserData['id'] as String);
    }

    final galleryMap = await fetchGalleryUrlsForUsers(otherUserIds);

    final waiting = <MatchCard>[];

    for (final row in rows) {
      final user1Id = row['user1_id'] as String;
      final user1Accepted = row['user1_accepted'] as bool?;
      final user2Accepted = row['user2_accepted'] as bool?;
      final eventId = row['event_id'] as String;
      final eventName =
          (row['events'] as Map<String, dynamic>?)?['event_name'] as String? ??
          '';

      final isUser1 = currentUserId == user1Id;
      final iAccepted = isUser1 ? user1Accepted : user2Accepted;
      final theyAccepted = isUser1 ? user2Accepted : user1Accepted;

      if (iAccepted != true || theyAccepted != null) continue;

      final otherUserData = isUser1
          ? row['user2'] as Map<String, dynamic>
          : row['user1'] as Map<String, dynamic>;

      final otherUserId = otherUserData['id'] as String;

      waiting.add(
        MatchCard(
          currentUserId: currentUserId,
          otherUserId: otherUserId,
          title: otherUserData['name'] ?? 'Unknown',
          university: otherUserData['university'] ?? '',
          course: otherUserData['course'] ?? '',
          bio: otherUserData['bio'] ?? '',
          eventId: eventId,
          eventName: eventName,
          yearGroup: otherUserData['year_group'] ?? '',
          interests: (otherUserData['user_interests'] as List<dynamic>? ?? [])
              .map((i) => i['interest'] as String)
              .toList(),
          location: otherUserData['location'] ?? '',
          imageUrl: otherUserData['avatar_url'] ?? '',
          galleryUrls: galleryMap[otherUserId] ?? [],
        ),
      );
    }

    return waiting;
  }

  Future<void> recordDecision(MatchCard card, bool accepted) async {
    final parts = card.matchKey.split('|');
    final user1Id = parts[0];
    final user2Id = parts[1];
    final eventId = parts[2];

    final isUser1 = card.currentUserId == user1Id;

    await supabase
        .from('matches')
        .update({
          if (isUser1)
            'user1_accepted': accepted
          else
            'user2_accepted': accepted,
        })
        .eq('user1_id', user1Id)
        .eq('user2_id', user2Id)
        .eq('event_id', eventId);
  }

  Future<void> reportUser(MatchCard card, String description) async {
    try {
      await supabase.from('reported').insert({
        'reportee_userid': card.otherUserId,
        'reporter_userid': card.currentUserId,
        'description': description,
      });
    } catch (e) {
      throw Exception('Failed to report user: $e, please try again later.');
    }
  }

  Future<void> blockUser(MatchCard card) async {
    await supabase.from('blocked').upsert({
      'user1_id': card.currentUserId,
      'user2_id': card.otherUserId,
    });

    final parts = card.matchKey.split('|');

    await supabase
        .from('matches')
        .delete()
        .eq('user1_id', parts[0])
        .eq('user2_id', parts[1]);
  }

  Future<List<MatchCard>> getConfirmedMatchesForEvent(String eventId) async {
    final currentUserId = await loadUserId();
    final rows = await _getConfirmedMatchRows(currentUserId, eventId: eventId);

    for (var row in rows) {
      debugPrint(
        "DEBUG MATCH FOUND: ${row['user1']?['name']} matching with ${row['user2']?['name']}",
      );
    }
    debugPrint("getConfirmedMatchesForEvent() has been called");

    // ── Batch fetch gallery for confirmed matches ────────────────────────
    final otherUserIds = rows.map((row) {
      final user1Data = row['user1'] as Map<String, dynamic>;
      final otherUser = user1Data['id'] == currentUserId
          ? row['user2'] as Map<String, dynamic>
          : user1Data;
      return otherUser['id'] as String;
    }).toList();

    final galleryMap = await fetchGalleryUrlsForUsers(otherUserIds);

    return rows
        .map((row) => _rowToConfirmedMatchCard(row, currentUserId, galleryMap))
        .toList();
  }

  Future<List<MatchCard>> getMutualMatches(String currentUserId) async {
    final rows = await _getConfirmedMatchRows(currentUserId);

    // ── Batch fetch gallery for mutual matches ───────────────────────────
    final otherUserIds = rows.map((row) {
      final user1Data = row['user1'] as Map<String, dynamic>;
      final otherUser = user1Data['id'] == currentUserId
          ? row['user2'] as Map<String, dynamic>
          : user1Data;
      return otherUser['id'] as String;
    }).toList();

    final galleryMap = await fetchGalleryUrlsForUsers(otherUserIds);

    return rows
        .map((row) => _rowToConfirmedMatchCard(row, currentUserId, galleryMap))
        .toList();
  }

  Future<String?> getProfilePictureUrl(String userId) async {
    final String publicUrl = supabase.storage
        .from('avatars')
        .getPublicUrl('$userId/profile.jpg');

    return publicUrl;
  }

  Future<List<Map<String, dynamic>>> _getConfirmedMatchRows(
    String currentUserId, {
    String? eventId,
  }) async {
    var query = supabase
        .from('matches')
        .select(
          'event_id, events(event_name), user1:user1_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest), is_society), user2:user2_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest), is_society)',
        )
        .eq('user1_accepted', true)
        .eq('user2_accepted', true)
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    if (eventId != null) query = query.eq('event_id', eventId);

    final List<dynamic> results = await query;

    return results
        .where((row) {
          final user1 = row['user1'] as Map<String, dynamic>?;
          final user2 = row['user2'] as Map<String, dynamic>?;
          final bool isUser1Society = user1?['is_society'] ?? false;
          final bool isUser2Society = user2?['is_society'] ?? false;
          return !isUser1Society && !isUser2Society;
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  MatchCard _rowToConfirmedMatchCard(
    Map<String, dynamic> row,
    String currentUserId,
    Map<String, List<String>> galleryMap,
  ) {
    final user1Data = row['user1'] as Map<String, dynamic>;
    final user2Data = row['user2'] as Map<String, dynamic>;
    final eventName =
        (row['events'] as Map<String, dynamic>?)?['event_name'] as String? ??
        '';
    final eventId = row['event_id'] as String;
    final otherUser = user1Data['id'] == currentUserId ? user2Data : user1Data;
    final otherUserId = otherUser['id'] as String;

    return MatchCard(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      title: otherUser['name'] ?? 'Unknown',
      university: otherUser['university'] ?? '',
      course: otherUser['course'] ?? '',
      bio: otherUser['bio'] ?? '',
      eventId: eventId,
      eventName: eventName,
      yearGroup: otherUser['year_group'] ?? '',
      interests: (otherUser['user_interests'] as List<dynamic>? ?? [])
          .map((i) => i['interest'] as String)
          .toList(),
      location: (otherUser['location']) ?? '',
      imageUrl: otherUser['avatar_url'] ?? '',
      galleryUrls: galleryMap[otherUserId] ?? [],
    );
  }
}
