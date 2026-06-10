// lib/services/conversation_service.dart
import 'supabase_client.dart';
import '../models/match_convo.dart';
import '../models/match_card.dart';
import 'utils.dart';
import 'package:flutter/foundation.dart';

class ConversationService {
  Future<List<ChatConversation>> getConversations() async {
    final currentUserId = await loadUserId();

    final matchRows = await supabase
        .from('matches')
        .select('''*, 
        user1:user1_id(id, name, avatar_url, university, course, bio, year_group, location, user_interests(interest), is_society), 
        user2:user2_id(id, name, avatar_url, university, course, bio, year_group, location, user_interests(interest), is_society),
        event:event_id(event_id, event_name)''')
        .eq('user1_accepted', true)
        .eq('user2_accepted', true)
        .or('user1_id.eq.$currentUserId, user2_id.eq.$currentUserId');

    final messageRows = await supabase
        .from('messages')
        .select('sender_id, recipient_id, content')
        .or('sender_id.eq.$currentUserId, recipient_id.eq.$currentUserId');

    // ── Batch fetch gallery URLs for all other users ─────────────────────
    final otherUserIds = (matchRows as List).map((r) {
      final user1Data = r['user1'] as Map<String, dynamic>;
      final user2Data = r['user2'] as Map<String, dynamic>;
      final otherUser = currentUserId == user1Data['id']
          ? user2Data
          : user1Data;
      return otherUser['id'] as String;
    }).toList();

    final galleryMap = await fetchGalleryUrlsForUsers(otherUserIds);
    (otherUserIds);

    return (matchRows).map((r) {
      final user1Data = r['user1'] as Map<String, dynamic>;
      final user2Data = r['user2'] as Map<String, dynamic>;

      final bool isSociety = user1Data['is_society'] || user2Data['is_society'];

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

      // ── Extract event data ───────────────────────────────────────────
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

      // ── Build MatchCard ──────────────────────────────────────────────
      final matchCard = MatchCard(
        currentUserId: currentUserId,
        otherUserId: actualOtherUserId,
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
        galleryUrls: galleryMap[actualOtherUserId] ?? [],
      );

      String previewText(String content) {
        if (content.startsWith('INVITATION_DATA:')) {
          return '📅 Invitation sent.';
        }
        if (content == 'Invitation sent.') return '📅 Invitation sent.';
        if (content.startsWith('=== ') && content.endsWith(' ===')) {
          return content.replaceAll('=== ', '').replaceAll(' ===', '');
        }
        return content;
      }

      return ChatConversation(
        matchCard: matchCard,
        numMessages: messageCount,
        lastMessage: hasHistory
            ? previewText(directMessages.last['content'] ?? '')
            : 'Interests: ${interestsList.join(', ')}',
        time: hasHistory ? 'Active' : '',
        unreadCount: 0,
        isOnline: false,
        isSociety: isSociety,
      );
    }).toList();
  }

  Future<String> recordMessage(
    String message,
    String sender,
    String receiver,
  ) async {
    try {
      final response = await supabase
          .from('messages')
          .insert({
            'sender_id': sender,
            'recipient_id': receiver,
            'content': message,
          })
          .select('message_id')
          .single();

      debugPrint('recordMessage response: $response');
      return response['message_id'].toString();
    } catch (e) {
      debugPrint('recordMessage error: $e');
      rethrow;
    }
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

  Future<void> updateInvitationStatus(String messageId, bool status) async {
    try {
      debugPrint('Updating invitation: id=$messageId status=$status');
      await supabase
          .from('messages')
          .update({'invitation_status': status})
          .eq('message_id', messageId);
      debugPrint('Update successful');
    } catch (e) {
      debugPrint('updateInvitationStatus error: $e');
    }
  }

  Future<void> updateInvitationContent(
    String messageId,
    String newContent,
    String editedBy,
  ) async {
    try {
      await supabase
          .from('messages')
          .update({
            'content': newContent,
            'invitation_status': null,
            'last_edited_by': editedBy,
          })
          .eq('message_id', messageId);
      debugPrint('updateInvitationContent successful');
    } catch (e) {
      debugPrint('updateInvitationContent error: $e');
    }
  }
}
