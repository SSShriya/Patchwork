import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/match_card.dart';
import '../models/match_convo.dart';

// Single shared Supabase client for the whole app
final supabase = Supabase.instance.client;

// -- Supabase service --
class MatchService {
  // Fetch all matches that haven't been decided yet
  Future<List<MatchCard>> getPendingMatches() async {
    // Get IDs of already-decided matches
    final decided = await supabase.from('decisions').select('match_id');
    final decidedIds = (decided as List)
        .map((d) => d['match_id'] as String?)
        .whereType<String>() // filters out nulls
        .toList();

    // Fetch matches not in that list
    var query = supabase.from('potential_matches').select('*, interests(interest)');
    final rows = decidedIds.isEmpty
        ? await query
        : await query.not('id', 'in', decidedIds);

    return (rows as List).map((r) => MatchCard.fromJson(r)).toList();
  }

  // Record accept/reject — this is what gets saved to Supabase
  Future<void> recordDecision(String matchId, bool accepted) async {
    await supabase.from('decisions').insert({
      'match_id': matchId,
      'accepted': accepted,
    });
  }

  // Fetch accepted matches (for a future "Accepted" screen)
  Future<List<MatchCard>> getAcceptedMatches() async {
    final rows = await supabase
        .from('decisions')
        .select('match_id, potential_matches(*)')
        .eq('accepted', true);

    return (rows as List).map((r) => MatchCard.fromJson(r['potential_matches'])).toList();
  }

  Future<List<ChatConversation>> getConversations() async {
    final rows = await supabase
        .from('decisions')
        .select('match_id, potential_matches(name, interests(interest))')
        .eq('accepted', true);

    return rows.map((r) {
        final matchData = r['potential_matches'] as Map<String, dynamic>?;
        final String name = matchData?['name'] ?? '';

        final interestsData = matchData?['interests'] as List<dynamic>? ?? [];
        final List<String> interestsList = interestsData
            .map((i) => i['interest'] as String)
            .toList();

        return ChatConversation(
          name: name,
          interests: interestsList,
        );
    }).where((c) => c.name.isNotEmpty).toList(); // Filter out any with empty names
  }
}
