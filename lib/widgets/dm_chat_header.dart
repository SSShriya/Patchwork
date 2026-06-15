import 'package:drp/screens/society_info_screen.dart';
import 'package:drp/tools/scalloped_clipper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import '../models/match_convo.dart';
import '../screens/user_profile_screen.dart';

class DmChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final ChatConversation chat;
  final VoidCallback onSuggestMeeting;
  final VoidCallback onShowHints;

  const DmChatHeader({
    super.key,
    required this.chat,
    required this.onSuggestMeeting,
    required this.onShowHints,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ScallopedClipper(),
      child: AppBar(
        // backgroundColor: _accentColor,
        // foregroundColor: Colors.white,
        title: GestureDetector(
          onTap: () {
            final card = chat.matchCard;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => chat.isSociety
                    ? SocietyInfoScreen(
                        societyId: chat.matchCard.otherUserId,
                        eventId: chat.matchCard.eventId,
                      )
                    : UserProfileScreen(card: card, accepted: true),
              ),
            );
          },
          child: Row(
            children: [
              ProfilePicture(
                name: chat.name,
                radius: 20,
                fontsize: 16,
                random: false,
                img: (chat.imageUrl?.isNotEmpty ?? false)
                    ? chat.imageUrl
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  chat.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        flexibleSpace: Opacity(
          opacity: 0.6,
          child: Image(
            image: AssetImage('assets/images/pink_gingham.png'),
            fit: BoxFit.cover,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            iconSize: 36,
            tooltip:
                'Suggest a time/place to meet ${chat.name} before ${chat.event}!',
            onPressed: onSuggestMeeting,
          ),
          if (!chat.isSociety)
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              iconSize: 36,
              tooltip: 'Prompts to help you chat with ${chat.name}',
              onPressed: onShowHints,
            ),
        ],
      ),
    );
  }
}
