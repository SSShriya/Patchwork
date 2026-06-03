class ChatConversation {
  final String name;
  final List<String> interests;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;

  ChatConversation({
    required this.name,
    required this.interests,
    this.lastMessage = '',
    this.time = '',
    this.unreadCount = 0,
    this.isOnline = false,
  });
}
