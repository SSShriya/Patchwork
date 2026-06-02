import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/match_card.dart';
import '../models/match_convo.dart';

// Single shared Supabase client for the whole app
final supabase = Supabase.instance.client;

// -- Supabase service --
class MatchService {
  // hard-coded current user ID
  final String currentUserId = '5f7e9d61-3865-47b2-9155-202267ee947f';

  // fetch all matches involving the current user where they haven't decided yet
  Future<List<MatchCard>> getPendingMatches() async {
    // get events the current user is interested in
    final interestedEventsData = await supabase
        .from('interested_events')
        .select('event_id')
        .eq('user_id', currentUserId);

    final interestedEventIds = (interestedEventsData as List)
        .map((e) => e['event_id'] as String)
        .toList();

    if (interestedEventIds.isEmpty) return [];

    // Fetch matches where:
    // - current user is either user1 or user2
    // - event is one the current user is interested in
    // - other user must also be interested
    final rows = await supabase
        .from('matches')
        .select(
          '*, events(event_name), user1:user1_id(id, name, university, course, bio, year_group, user_interests(interest)), user2:user2_id(id, name, university, course, bio, year_group, user_interests(interest))',
        )
        .inFilter('event_id', interestedEventIds)
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    final matches = <MatchCard>[];

    for (final row in rows as List) {
      final user1Id = row['user1_id'] as String;
      final user2Id = row['user2_id'] as String;
      final user1Accepted = row['user1_accepted'] as bool;
      final user2Accepted = row['user2_accepted'] as bool;
      final eventId = row['event_id'] as String;

      final isUser1 = currentUserId == user1Id;

      // skip if cur user has alr made decision
      final currentUserAccepted = isUser1 ? user1Accepted : user2Accepted;
      if (currentUserAccepted) continue;

      // get the OTHER user's data
      final otherUserData = currentUserId == user1Id
          ? row['user2'] as Map<String, dynamic>
          : row['user1'] as Map<String, dynamic>;

      final eventName =
          (row['events'] as Map<String, dynamic>?)?['event_name'] ??
          'Unknown Event';

      matches.add(
        MatchCard(
          id: '$user1Id|$user2Id|$eventId',
          title: otherUserData['name'] ?? 'Unknown',
          university: otherUserData['university'] ?? '',
          course: otherUserData['course'] ?? '',
          bio: otherUserData['bio'] ?? '',
          event: eventName,
          yearGroup: otherUserData['year_group'] ?? '',
          interests: (otherUserData['user_interests'] as List<dynamic>? ?? [])
              .map((i) => i['interest'] as String)
              .toList(),
        ),
      );
    }

    return matches;
  }

  // update the appropriate user's acceptance flag
  Future<void> recordDecision(String matchId, bool accepted) async {
    final parts = matchId.split('|');
    final user1Id = parts[0];
    final user2Id = parts[1];
    final eventId = parts[2];

    // determine which column to update based on current user
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

  // fetch confirmed conversations (both users accepted)
  Future<List<ChatConversation>> getConversations() async {
    final rows = await supabase
        .from('matches')
        .select(
          '*, user1:user1_id(id, name, user_interests(interest)), user2:user2_id(id, name, user_interests(interest))',
        )
        .eq('user1_accepted', true)
        .eq('user2_accepted', true)
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

    return (rows as List).map((r) {
      final user1Data = r['user1'] as Map<String, dynamic>;
      final user2Data = r['user2'] as Map<String, dynamic>;

      // get the OTHER user's data
      final otherUser = currentUserId == user1Data['id']
          ? user2Data
          : user1Data;
      final name = otherUser['name'] ?? 'Unknown Match';
      final interestsList =
          (otherUser['user_interests'] as List<dynamic>? ?? [])
              .map((i) => i['interest'] as String)
              .toList();

      return ChatConversation(name: name, interests: interestsList);
    }).toList();
  }
}
