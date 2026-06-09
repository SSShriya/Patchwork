// lib/services/match_service.dart

import '../models/match_card.dart';
import 'utils.dart';
import 'supabase_client.dart';

class MatchService {
  Future<List<MatchCard>> getPendingMatches(String currentUserId) async {
    // fetch current user's profile
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

    // fetch events the current user is interested in
    final interestedEventsData = await supabase
        .from('interested_events')
        .select('event_id')
        .eq('user_id', currentUserId);

    final interestedEventIds = (interestedEventsData as List)
        .map((e) => e['event_id'] as String)
        .toList();

    if (interestedEventIds.isEmpty) return [];

    // fetch matches
    final rows = await supabase
        .from('matches')
        .select(
          '*, events(event_name), user1:user1_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest)), user2:user2_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest))',
        )
        .inFilter('event_id', interestedEventIds)
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    final matches = <(MatchCard, int)>[]; // store card + score together

    for (final row in rows as List) {
      final user1Id = row['user1_id'] as String;
      final user2Id = row['user2_id'] as String;
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

      final otherInterests =
          (otherUserData['user_interests'] as List<dynamic>? ?? [])
              .map((i) => i['interest'] as String)
              .toSet();

      // score the match
      int score = 0;

      // +1 per shared interest
      score += currentInterests.intersection(otherInterests).length;

      // +1 for shared university
      final otherUniversity = (otherUserData['university'] as String?) ?? '';
      if (currentUniversity.isNotEmpty &&
          otherUniversity.isNotEmpty &&
          currentUniversity.toLowerCase() == otherUniversity.toLowerCase()) {
        score += 1;
      }

      // +1 for shared course/degree
      final otherCourse = (otherUserData['course'] as String?) ?? '';
      if (currentCourse.isNotEmpty &&
          otherCourse.isNotEmpty &&
          currentCourse.toLowerCase() == otherCourse.toLowerCase()) {
        score += 1;
      }

      // +1 for shared location
      final otherLocation = (otherUserData['location'] as String?) ?? '';
      if (currentLocation.isNotEmpty &&
          otherLocation.isNotEmpty &&
          currentLocation.toLowerCase() == otherLocation.toLowerCase()) {
        score += 1;
      }

      // filter: only include score >= 2
      if (score < 1) continue;

      matches.add((
        MatchCard(
          id: '$user1Id|$user2Id|$eventId',
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
        ),
        score,
      ));
    }

    // sort descending by score
    matches.sort((a, b) => b.$2.compareTo(a.$2));

    return matches.map((e) => e.$1).toList();
  }

  // check if other user has accepted your match
  Future<bool> hasOtherUserAccepted(String matchId) async {
    final currentUserId = await loadUserId();

    final parts = matchId.split('|');
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

    final otherAccepted = currentUserId == user1Id
        ? row['user2_accepted'] as bool?
        : row['user1_accepted'] as bool?;

    return otherAccepted == true;
  }

  // Matches where current user accepted, other user hasn't decided yet
  Future<List<MatchCard>> getAwaitingResponseMatches(
    String currentUserId,
  ) async {
    final rows = await supabase
        .from('matches')
        .select(
          '*, events(event_name), user1:user1_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest)), user2:user2_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest))',
        )
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    final waiting = <MatchCard>[];

    for (final row in rows as List) {
      final user1Id = row['user1_id'] as String;
      final user2Id = row['user2_id'] as String;
      final user1Accepted = row['user1_accepted'] as bool?;
      final user2Accepted = row['user2_accepted'] as bool?;
      final eventId = row['event_id'] as String;
      final eventName =
          (row['events'] as Map<String, dynamic>?)?['event_name'] as String? ??
          '';

      final isUser1 = currentUserId == user1Id;
      final iAccepted = isUser1 ? user1Accepted : user2Accepted;
      final theyAccepted = isUser1 ? user2Accepted : user1Accepted;

      // I said yes, they haven't answered yet
      if (iAccepted != true || theyAccepted != null) continue;

      final otherUserData = isUser1
          ? row['user2'] as Map<String, dynamic>
          : row['user1'] as Map<String, dynamic>;

      waiting.add(
        MatchCard(
          id: '$user1Id|$user2Id|$eventId',
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
        ),
      );
    }

    return waiting;
  }

  Future<void> recordDecision(String matchId, bool accepted) async {
    final currentUserId = await loadUserId();

    final parts = matchId.split('|');
    final user1Id = parts[0];
    final user2Id = parts[1];
    final eventId = parts[2];

    final isUser1 = currentUserId == user1Id;

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

  Future<void> blockUser(String otherUserId) async {
    final currentUserId = await loadUserId();

    // insert into blocked table
    await supabase.from('blocked').upsert({
      'user1_id': currentUserId,
      'user2_id': otherUserId,
    });

    // delete matches in both possible ID orderings
    final a = currentUserId.compareTo(otherUserId) <= 0 ? currentUserId : otherUserId;
    final b = currentUserId.compareTo(otherUserId) <= 0 ? otherUserId : currentUserId;

    // also delete all matches between these two users
    await supabase
        .from('matches')
        .delete()
        .eq('user1_id', a)
        .eq('user2_id', b);
  }

  // for getting confirmed matches for an event
  Future<List<MatchCard>> getConfirmedMatchesForEvent(String eventId) async {
    final currentUserId = await loadUserId();

    final rows = await supabase
        .from('matches')
        .select(
          'events(event_name), user1:user1_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest)), user2:user2_id(id, name, university, course, bio, year_group, location, avatar_url, user_interests(interest))',
        )
        .eq('event_id', eventId)
        .eq('user1_accepted', true)
        .eq('user2_accepted', true)
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    return (rows as List).map((row) {
      final user1Data = row['user1'] as Map<String, dynamic>;
      final user2Data = row['user2'] as Map<String, dynamic>;
      final eventName =
          (row['events'] as Map<String, dynamic>?)?['event_name'] as String? ??
          '';

      final otherUser = user1Data['id'] == currentUserId
          ? user2Data
          : user1Data;

      return MatchCard(
        id: otherUser['id'],
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
      );
    }).toList();
  }

  Future<String?> getProfilePictureUrl(String userId) async {
    final String publicUrl = supabase.storage
        .from('avatars')
        .getPublicUrl('$userId/profile.jpg');

    return publicUrl;
  }
}
