import 'package:drp/models/match_convo.dart';
import 'package:drp/screens/dm_individual_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatSection extends StatelessWidget {
  final String title;
  final List<ChatConversation> conversations;
  final VoidCallback onRefresh;

  const ChatSection({
    super.key,
    required this.title,
    required this.conversations,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        title,
        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: true,
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
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (chat.event.isNotEmpty)
                    Text(
                      chat.event,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: const Color.fromARGB(255, 228, 138, 150),
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
                  color: chat.unreadCount > 0
                      ? Colors.black87
                      : Colors.grey[600],
                  fontWeight: chat.unreadCount > 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    chat.time,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  if (chat.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${chat.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
