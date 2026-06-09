import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import '../models/match_convo.dart';
import '../widgets/user_profile_card.dart';

const _accentColor = Color(0xFF84DCC6);

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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _accentColor,
      foregroundColor: Colors.white,
      title: GestureDetector(
        onTap: () {
          final card = chat.matchCard;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  title: Text(card.title),
                ),
                body: UserProfileCard(card: card, accepted: true),
              ),
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
              img: (chat.imageUrl?.isNotEmpty ?? false) ? chat.imageUrl : null,
            ),
            const SizedBox(width: 12),
            Text(chat.name),
          ],
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
        IconButton(
          icon: const Icon(Icons.lightbulb_outline),
          iconSize: 36,
          tooltip: 'Prompts to help you chat with ${chat.name}',
          onPressed: onShowHints,
        ),
      ],
    );
  }
}
