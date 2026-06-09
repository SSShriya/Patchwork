// lib/services/conversation_service.dart
import 'supabase_client.dart';
import '../models/match_convo.dart';
import '../models/match_card.dart';
import 'utils.dart';

class ConversationService {
  Future<List<ChatConversation>> getConversations() async {
    final currentUserId = await loadUserId();

    final matchRows = await supabase
        .from('matches')
        .select('''*, 
        user1:user1_id(id, name, avatar_url, university, course, bio, year_group, location, user_interests(interest)), 
        user2:user2_id(id, name, avatar_url, university, course, bio, year_group, location, user_interests(interest)),
        event:event_id(event_id, event_name)''')
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

      final otherUser = currentUserId == user1Data['id']
          ? user2Data
          : user1Data;

      final actualOtherUserId = otherUser['id'] as String;

      final interestsList =
          (otherUser['user_interests'] as List<dynamic>? ?? [])
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

      // ── Extract event data ──
      final eventData = r['event'];
      String eventName = '';
      String eventId = '';

      if (eventData != null) {
        if (eventData is Map<String, dynamic>) {
          eventName = eventData['event_name'] as String? ?? '';
          eventId = eventData['event_id'] as String? ?? '';
        } else if (eventData is List && eventData.isNotEmpty) {
          final firstEvent = eventData.first;
          if (firstEvent is Map) {
            eventName = firstEvent['event_name'] as String? ?? '';
            eventId = firstEvent['event_id'] as String? ?? '';
          }
        }
      }

      // ── Build MatchCard ──
      final matchCard = MatchCard(
        id: actualOtherUserId,
        title: otherUser['name'] ?? 'Unknown Match',
        university: otherUser['university'] as String? ?? '',
        course: otherUser['course'] as String? ?? '',
        bio: otherUser['bio'] as String? ?? '',
        eventId: eventId,
        eventName: eventName,
        yearGroup: otherUser['year_group'] as String? ?? '',
        interests: interestsList,
        location: otherUser['location'] as String? ?? '',
        imageUrl: otherUser['avatar_url'] as String? ?? '',
      );

      // ── Build ChatConversation from matchCard only ──
      return ChatConversation(
        matchCard: matchCard,
        numMessages: messageCount,
        lastMessage: hasHistory
            ? directMessages.last['content'] ?? ''
            : 'Interests: ${interestsList.join(', ')}',
        time: hasHistory ? 'Active' : '',
        unreadCount: 0,
        isOnline: false,
      );
    }).toList();
  }

  Future<void> recordMessage(
    String message,
    String sender,
    String receiver,
  ) async {
    await supabase.from('messages').insert({
      'sender_id': sender,
      'recipient_id': receiver,
      'content': message,
    });
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String thisUserId,
    String otherUserId,
  ) async {
    final rows = await supabase
        .from('messages')
        .select()
        .or('sender_id.eq.$thisUserId, sender_id.eq.$otherUserId')
        .or('recipient_id.eq.$thisUserId, recipient_id.eq.$otherUserId')
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }
}
