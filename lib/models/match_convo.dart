class ChatConversation {
  final String name;
  final String otherUserId;
  final List<String> interests;
  final String? imageUrl;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  int numMessages = 0;

  ChatConversation({
    required this.name,
    required this.otherUserId,
    required this.interests,
    required this.imageUrl,
    this.lastMessage = '',
    this.time = '',
    this.unreadCount = 0,
    this.isOnline = false,
    this.numMessages = 0,
  });
}

