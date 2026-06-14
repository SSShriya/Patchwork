// lib/services/conversation_service.dart
import 'supabase_client.dart';
import '../models/match_convo.dart';
import '../models/match_card.dart';
import 'utils.dart';
import 'package:flutter/foundation.dart';

class ConversationService {
  // ── Helper: build interest → photo_url map from a user data row ──────────
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

  Future<List<ChatConversation>> getConversations() async {
    final currentUserId = await loadUserId();

    final matchRows = await supabase
        .from('matches')
        .select('''*, 
        matched_at,
      user1:user1_id(id, name, avatar_url, university, course, bio, year_group, location, user_interests(interest, photo_url), is_society), 
      user2:user2_id(id, name, avatar_url, university, course, bio, year_group, location, user_interests(interest, photo_url), is_society),
      event:event_id(event_id, event_name)''')
        .eq('user1_accepted', true)
        .eq('user2_accepted', true)
        .or('user1_id.eq.$currentUserId, user2_id.eq.$currentUserId');

    final messageRows = await supabase
        .from('messages')
        .select('sender_id, recipient_id, content, created_at')
        .or('sender_id.eq.$currentUserId, recipient_id.eq.$currentUserId')
        .order('created_at', ascending: true);

    final allMatches = List<Map<String, dynamic>>.from(matchRows as List);
    final allMessages = List<Map<String, dynamic>>.from(messageRows as List);

    // Debug: verify messages have created_at
    for (final msg in allMessages) {
      debugPrint(
        'MSG: ${msg['sender_id']} -> ${msg['recipient_id']} at ${msg['created_at']}',
      );
    }

    return allMatches.map((r) {
      final user1Data = r['user1'] as Map<String, dynamic>;
      final user2Data = r['user2'] as Map<String, dynamic>;

      final bool isSociety =
          user1Data['is_society'] == true || user2Data['is_society'] == true;

      final otherUser = currentUserId == user1Data['id']
          ? user2Data
          : user1Data;
      final actualOtherUserId = otherUser['id'] as String;

      final interestsList =
          (otherUser['user_interests'] as List<dynamic>? ?? [])
              .map((i) => i['interest'] as String)
              .toList();

      final directMessages = allMessages.where((msg) {
        final sId = msg['sender_id'] as String;
        final rId = msg['recipient_id'] as String;
        return (sId == currentUserId && rId == actualOtherUserId) ||
            (sId == actualOtherUserId && rId == currentUserId);
      }).toList();

      final messageCount = directMessages.length;
      final hasHistory = messageCount > 0;

      // Parse last message timestamp
      DateTime? lastMessageAt;
      if (hasHistory) {
        final rawTime = directMessages.last['created_at']?.toString();
        if (rawTime != null) {
          final normalised = rawTime.endsWith('Z') || rawTime.contains('+')
              ? rawTime
              : '${rawTime}Z';
          lastMessageAt = DateTime.tryParse(normalised)?.toUtc();
        }
      }
      debugPrint('lastMessageAt for ${otherUser['name']}: $lastMessageAt');

      // Parse matched_at timestamp
      final rawMatchedAt = r['matched_at'];
      debugPrint('matched_at raw for ${otherUser['name']}: $rawMatchedAt');

      final matchedAt = rawMatchedAt != null
          ? DateTime.tryParse(rawMatchedAt.toString())?.toUtc()
          : null;

      debugPrint('matched_at parsed for ${otherUser['name']}: $matchedAt');

      // ── Extract event data ───────────────────────────────────────────────
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

      // ── Build MatchCard ──────────────────────────────────────────────────
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
        interestPhotos: _parseInterestPhotos(otherUser),
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
        lastMessageAt: lastMessageAt,
        matchedAt: matchedAt,
      );
    }).toList();
  }

  Future<List<ChatConversation>> getSocietyConversations() async {
    final currentUserId = await loadUserId();

    // Get all messages to/from societies
    final messageRows = await supabase
        .from('messages')
        .select('sender_id, recipient_id, content, created_at')
        .or('sender_id.eq.$currentUserId,recipient_id.eq.$currentUserId')
        .order('created_at', ascending: true);

    final allMessages = List<Map<String, dynamic>>.from(messageRows as List);

    // Collect unique society IDs we've messaged
    final societyIds = <String>{};
    for (final msg in allMessages) {
      final senderId = msg['sender_id'] as String;
      final recipientId = msg['recipient_id'] as String;
      if (senderId != currentUserId) societyIds.add(senderId);
      if (recipientId != currentUserId) societyIds.add(recipientId);
    }

    if (societyIds.isEmpty) return [];

    // Fetch only the ones that are societies
    final societyRows = await supabase
        .from('users')
        .select('id, name, avatar_url, is_society')
        .inFilter('id', societyIds.toList())
        .eq('is_society', true);

    final societies = List<Map<String, dynamic>>.from(societyRows as List);
    if (societies.isEmpty) return [];

    final conversations = <ChatConversation>[];

    for (final society in societies) {
      final societyId = society['id'] as String;

      final directMessages = allMessages.where((msg) {
        final sId = msg['sender_id'] as String;
        final rId = msg['recipient_id'] as String;
        return (sId == currentUserId && rId == societyId) ||
            (sId == societyId && rId == currentUserId);
      }).toList();

      if (directMessages.isEmpty) continue;

      // Parse last message timestamp
      DateTime? lastMessageAt;
      final rawTime = directMessages.last['created_at']?.toString();
      if (rawTime != null) {
        final normalised = rawTime.endsWith('Z') || rawTime.contains('+')
            ? rawTime
            : '${rawTime}Z';
        lastMessageAt = DateTime.tryParse(normalised)?.toUtc();
      }

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

      final matchCard = MatchCard(
        currentUserId: currentUserId,
        otherUserId: societyId,
        title: society['name'] as String? ?? 'Society',
        university: '',
        course: '',
        bio: '',
        eventId: '',
        eventName: '',
        yearGroup: '',
        location: '',
        interests: [],
        imageUrl: society['avatar_url'] as String? ?? '',
      );

      conversations.add(
        ChatConversation(
          matchCard: matchCard,
          numMessages: directMessages.length,
          lastMessage: previewText(
            directMessages.last['content'] as String? ?? '',
          ),
          time: 'Active',
          unreadCount: 0,
          isOnline: false,
          isSociety: true,
          lastMessageAt: lastMessageAt,
        ),
      );
    }

    return conversations;
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

  // Used for sorting DMs by fetching eventEndTimes
  Future<Map<String, ({String endDay, String endTime})>> getEventEndTimes(
    List<String> eventIds,
  ) async {
    if (eventIds.isEmpty) return {};

    final rows = await supabase
        .from('events')
        .select('event_id, end_day, end_time')
        .inFilter('event_id', eventIds);

    final result = <String, ({String endDay, String endTime})>{};

    for (final row in rows as List) {
      final eventId = row['event_id'] as String? ?? '';
      final endDay = row['end_day'] as String? ?? '';
      final endTime = row['end_time'] as String? ?? '';

      if (eventId.isNotEmpty) {
        result[eventId] = (endDay: endDay, endTime: endTime);
      }
    }

    return result;
  }
}
