import 'package:drp/models/match_convo.dart';
import 'package:drp/screens/dm_individual_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:drp/widgets/waving_emoji.dart';

class ChatSection extends StatelessWidget {
  final String title;
  final List<ChatConversation> conversations;
  final Map<String, List<String>> eventsInCommon;
  final VoidCallback onRefresh;
  final bool currentChats;

  const ChatSection({
    super.key,
    required this.title,
    required this.conversations,
    required this.eventsInCommon,
    required this.onRefresh,
    this.currentChats = false,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'Lora', fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: currentChats,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final chat = conversations[index];
            return ListTile(
              onTap: () async {
                final shouldRefresh = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => DMScreen(chat: chat)),
                );

                if (shouldRefresh == true) {
                  onRefresh();
                }
              },
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Stack(
                children: [
                  ProfilePicture(
                    name: chat.name,
                    radius: 28,
                    fontsize: 24,
                    random: false,
                    img: chat.imageUrl != null && chat.imageUrl!.isNotEmpty
                        ? chat.imageUrl
                        : null,
                  ),
                  if (chat.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.name,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (chat.event.isNotEmpty)
                    Text(
                      (eventsInCommon[chat.otherUserId] ?? [chat.event]).join(
                        ", ",
                      ),
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        color: Color.fromARGB(255, 228, 138, 150),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              subtitle: Text(
                chat.numMessages <= 0 ? 'No messages yet' : chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 12,
                  color: chat.unreadCount > 0
                      ? Colors.black87
                      : Colors.grey[600],
                  fontWeight: chat.unreadCount > 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              trailing: chat.numMessages == 0
                  ? SizedBox(
                      height:
                          56, // matches ListTile's constrained trailing height
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          WavingEmoji(size: 16),
                          SizedBox(height: 3),
                          Text(
                            'Say Hi!',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Color.fromARGB(255, 228, 138, 150),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }
}
