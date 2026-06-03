// lib/services/conversation_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/match_convo.dart';

final supabase = Supabase.instance.client;

class ConversationService {
  final String currentUserId = '5f7e9d61-3865-47b2-9155-202267ee947f';

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
