// lib/services/match_service.dart

import 'package:flutter/material.dart';

import '../models/match_card.dart';
import 'utils.dart';
import 'supabase_client.dart';
import 'package:intl/intl.dart';

class MatchService {
  // ── Helper: parse interest photos from a user data map ─────────────────
  // user_interests rows now have {interest, photo_url}
  Map<String, String> _parseInterestPhotos(Map<String, dynamic> userData) {
    final rows = userData['user_interests'] as List<dynamic>? ?? [];
    final map = <String, String>{};
    for (final row in rows) {
      final interest = row['interest'] as String?;
      final photoUrl = row['photo_url'] as String?;
      if (interest != null && photoUrl != null) {
        map[interest] = photoUrl;
      }
    }
    return map;
  }

  // ── Helper: parse plain interest list from a user data map ─────────────
  List<String> _parseInterests(Map<String, dynamic> userData) {
    return (userData['user_interests'] as List<dynamic>? ?? [])
        .map((i) => i['interest'] as String)
        .toList();
  }

  Future<List<MatchCard>> getPendingMatches(String currentUserId) async {
    // ── Fetch current user ─────────────────────────────────────────────────
    final currentUserData = await supabase
        .from('users')
        .select(
          'university, course, location, user_interests(interest, photo_url)',
        )
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

    // ── Fetch matches ──────────────────────────────────────────────────────
    final rows = await supabase
        .from('matches')
        .select(
          '*, '
          'events(event_name, start_day, meet_committee, committee_meeting_location, committee_meeting_time, committee_member_id, committee_members(id, name, role, avatar_url)), '
          'user1:user1_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest, photo_url), is_society), '
          'user2:user2_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest, photo_url), is_society)',
        )
        .inFilter('event_id', interestedEventIds)
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    // ── Track which events yielded at least one match card ─────────────────
    final eventsWithMatches = <String>{};
    final eventsUserAlreadyAcceptedCommittee = <String>{};
    final matches = <(MatchCard, int)>[];

    for (final row in rows as List) {
      final user1Id = row['user1_id'] as String;
      final user1Accepted = row['user1_accepted'] as bool?;
      final user2Accepted = row['user2_accepted'] as bool?;
      final eventId = row['event_id'] as String;
      final user1IsSociety = row['user1']['is_society'] as bool?;
      final user2IsSociety = row['user2']['is_society'] as bool?;
      final eventName =
          (row['events'] as Map<String, dynamic>?)?['event_name'] as String? ??
          '';

      final isUser1 = currentUserId == user1Id;
      final currentUserAccepted = isUser1 ? user1Accepted : user2Accepted;

      // ── If this is a society row, check if user has already accepted ──
      if (user1IsSociety == true || user2IsSociety == true) {
        if (currentUserAccepted == true) {
          eventsUserAlreadyAcceptedCommittee.add(eventId);
        }
        continue;
      }

      if (currentUserAccepted != null) continue;

      final otherUserData = isUser1
          ? row['user2'] as Map<String, dynamic>
          : row['user1'] as Map<String, dynamic>;

      if (otherUserData['is_society'] == true ||
          otherUserData['is_society'].toString() == 'true') {
        continue;
      }

      final otherUserId = otherUserData['id'] as String;
      final otherInterests = _parseInterests(otherUserData).toSet();

      final sortedInterests = [
        ...otherInterests.where((i) => currentInterests.contains(i)),
        ...otherInterests.where((i) => !currentInterests.contains(i)),
      ];

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

      // ── This event yielded a valid match card ──────────────────────────
      eventsWithMatches.add(eventId);

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
          interests: sortedInterests,
          location: otherLocation,
          imageUrl: otherUserData['avatar_url'] ?? '',
          interestPhotos: _parseInterestPhotos(otherUserData),
        ),
        score,
      ));
    }

    // ── Committee cards for events with no matches ─────────────────────────
    // Exclude events where the user has already accepted the committee card
    final eventsWithoutMatches = interestedEventIds
        .where(
          (id) =>
              !eventsWithMatches.contains(id) &&
              !eventsUserAlreadyAcceptedCommittee.contains(id),
        )
        .toList();

    if (eventsWithoutMatches.isNotEmpty) {
      final committeeRows = await supabase
          .from('events')
          .select(
            'event_id, event_name, start_day, society_id, meet_committee, '
            'committee_meeting_location, committee_meeting_time, '
            'committee_members(id, name, role, avatar_url), '
            'society:society_id(name)',
          )
          .inFilter('event_id', eventsWithoutMatches)
          .eq('meet_committee', true)
          .not('committee_member_id', 'is', null);

      for (final event in committeeRows as List) {
        final eventId = event['event_id'] as String;
        final eventName = event['event_name'] as String? ?? '';
        final meetingLocation =
            event['committee_meeting_location'] as String? ?? '';
        final meetingTimeRaw = event['committee_meeting_time'] as String?;
        final meetingTime = meetingTimeRaw != null
            ? DateFormat(
                'HH:mm',
              ).format(DateFormat('HH:mm:ss').parse(meetingTimeRaw))
            : '';
        final member = event['committee_members'] as Map<String, dynamic>?;

        if (member == null) continue;

        final memberName = member['name'] as String? ?? 'Committee Member';
        final memberRole = member['role'] as String? ?? '';
        final memberAvatar = member['avatar_url'] as String? ?? '';
        final memberId = member['id'] as String? ?? '';
        final societyName =
            (event['society'] as Map<String, dynamic>?)?['name'] as String? ??
            '';
        final societyId = event['society_id'] as String? ?? '';

        final startDayRaw = event['start_day'] as String?;
        final formattedDate = startDayRaw != null
            ? DateFormat('d MMM yyyy').format(DateTime.parse(startDayRaw))
            : '';

        matches.add((
          MatchCard(
            currentUserId: currentUserId,
            otherUserId: memberId,
            title: memberName,
            university: '',
            course: memberRole,
            bio: [
              meetingTime,
              if (formattedDate.isNotEmpty) formattedDate,
            ].join(' · '),
            eventId: eventId,
            eventName: eventName,
            yearGroup: '',
            interests: [],
            location: meetingLocation,
            imageUrl: memberAvatar,
            isCommitteeCard: true,
            societyName: societyName,
            societyId: societyId,
            interestPhotos: {},
          ),
          0,
        ));
      }
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

  Future<void> acceptCommitteeCard(MatchCard card) async {
    // For committee cards, otherUserId is a committee_members.id, not a users.id
    // so we can't use matchKey. Instead match on currentUserId + eventId only.
    final currentUserId = card.currentUserId;
    final eventId = card.eventId;

    // Find the row — current user could be user1 or user2
    final row = await supabase
        .from('matches')
        .select('user1_id, user2_id')
        .eq('event_id', eventId)
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
        .single();

    final isUser1 = row['user1_id'] == currentUserId;

    await supabase
        .from('matches')
        .update({
          if (isUser1) 'user1_accepted': true else 'user2_accepted': true,
        })
        .eq('user1_id', row['user1_id'])
        .eq('user2_id', row['user2_id'])
        .eq('event_id', eventId);
  }

  Future<List<MatchCard>> getAwaitingResponseMatches(
    String currentUserId,
  ) async {
    // ── Include photo_url in user_interests ───────────────────────────────
    final rows = await supabase
        .from('matches')
        .select(
          '*, '
          'events(event_name), '
          'user1:user1_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest, photo_url)), '
          'user2:user2_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest, photo_url))',
        )
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    final waiting = <MatchCard>[];

    for (final row in rows as List) {
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
          interests: _parseInterests(otherUserData),
          location: otherUserData['location'] ?? '',
          imageUrl: otherUserData['avatar_url'] ?? '',
          interestPhotos: _parseInterestPhotos(otherUserData),
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
      // 1. Save to the reported table as before
      await supabase.from('reported').insert({
        'reportee_userid': card.otherUserId,
        'reporter_userid': card.currentUserId,
        'description': description,
      });

      // 2. Trigger the email notification via Edge Function
      await supabase.functions.invoke(
        'send-report-email',
        body: {
          'reporteeUserId': card.otherUserId,
          'reporterUserId': card.currentUserId,
          'description': description,
        },
      );
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

    return rows
        .map((row) => _rowToConfirmedMatchCard(row, currentUserId))
        .toList();
  }

  Future<List<MatchCard>> getMutualMatches(String currentUserId) async {
    final rows = await _getConfirmedMatchRows(currentUserId);
    return rows
        .map((row) => _rowToConfirmedMatchCard(row, currentUserId))
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
    // ── Include photo_url in user_interests ───────────────────────────────
    var query = supabase
        .from('matches')
        .select(
          'event_id, '
          'events(event_name), '
          'user1:user1_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest, photo_url), is_society), '
          'user2:user2_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest, photo_url), is_society)',
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

  // ── galleryMap param removed — photos now come from user_interests ────────
  MatchCard _rowToConfirmedMatchCard(
    Map<String, dynamic> row,
    String currentUserId,
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
      interests: _parseInterests(otherUser),
      location: (otherUser['location']) ?? '',
      imageUrl: otherUser['avatar_url'] ?? '',
      interestPhotos: _parseInterestPhotos(otherUser),
    );
  }
}
