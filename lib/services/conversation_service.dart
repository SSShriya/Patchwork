// lib/services/conversation_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/match_convo.dart';

final supabase = Supabase.instance.client;

class ConversationService {
  final String currentUserId = '5f7e9d61-3865-47b2-9155-202267ee947f';

  Future<List<ChatConversation>> getConversations() async {
    final matchRows = await supabase
      .from('matches')
      .select(
        '*, user1:user1_id(id, name, avatar_url, user_interests(interest)), user2:user2_id(id, name, avatar_url, user_interests(interest))',
      )
      .eq('user1_accepted', true)
      .eq('user2_accepted', true)
      .or('user1_id.eq.$currentUserId, user2_id.eq.$currentUserId');

    final messageRows = await supabase
      .from('messages')
      .select('sender_id, recipient_id, content')
      .or('sender_id.eq.$currentUserId, recipient_id.eq.$currentUserId');

    return (matchRows as List).map((r) {
      final user1Data = r['user1'] as Map<String, dynamic>;
      final user2Data = r['user2'] as Map<String, dynamic>;

      final otherUser = currentUserId == user1Data['id'] ? user2Data : user1Data;
      final name = otherUser['name'] ?? 'Unknown Match';
      final actualOtherUserId = otherUser['id'] as String;

      final interestsList = (otherUser['user_interests'] as List<dynamic>? ?? [])
        .map((i) => i['interest'] as String)
        .toList();

      final directMessages = (messageRows as List).where((msg) {
        final sId = msg['sender_id'] as String;
        final rId = msg['recipient_id'] as String;
        return (sId == currentUserId && rId == actualOtherUserId) ||
             (sId == actualOtherUserId && rId == currentUserId);
      }).toList();

      final messageCount = directMessages.length;
      final hasHistory = messageCount > 0;

      return ChatConversation(
        name: name,
        otherUserId: actualOtherUserId,
        interests: interestsList,
        imageUrl: otherUser['avatar_url'] as String? ?? '', // Placeholder, can be extended to fetch actual image URLs
        numMessages: messageCount, // Now truly dynamic!
        lastMessage: hasHistory ? directMessages.last['content'] ?? '' : 'No messages yet',
        time: hasHistory ? 'Active' : '', 
        unreadCount: 0,
        isOnline: false,
      );
    }).toList();
  }
  
  Future<void> recordMessage(String message, String sender, String receiver) async {
    await supabase.from('messages').insert({
      'sender_id': sender,
      'recipient_id': receiver,
      'content': message,
    });
  }

  Future<List<Map<String, dynamic>>> getMessages(String thisUserId, String otherUserId) async {
    final rows = await supabase
      .from('messages')
      .select()
      .or('sender_id.eq.$thisUserId, sender_id.eq.$otherUserId')
      .or('recipient_id.eq.$thisUserId, recipient_id.eq.$otherUserId')
      .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }
}
