import 'match_card.dart';

class ChatConversation {
  final MatchCard matchCard;
  final int numMessages;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final bool isSociety;

  const ChatConversation({
    required this.matchCard,
    this.numMessages = 0,
    this.lastMessage = '',
    this.time = '',
    this.unreadCount = 0,
    this.isOnline = false,
    this.isSociety = false,
  });

  String get name => matchCard.title;
  String get otherUserId => matchCard.otherUserId;
  String get event => matchCard.eventName;
  List<String> get interests => matchCard.interests;
  String? get imageUrl => matchCard.imageUrl;
}
