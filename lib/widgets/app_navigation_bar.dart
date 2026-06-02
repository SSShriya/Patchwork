import 'package:drp/models/event_card.dart';
import 'package:drp/screens/events_screen.dart';
import 'package:flutter/material.dart';
import '../models/match_convo.dart';
import '../screens/dm_home_screen.dart';

class AppNavigationBar extends StatelessWidget {
  final List<ChatConversation> conversations;
  final List<EventCard> recommendedEvents;

  const AppNavigationBar({
    super.key,
    required this.conversations,
    required this.recommendedEvents,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Events'),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble),
          label: 'Messages',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on Home, do nothing
            break;
          case 1:
            // Navigate to Search screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventsScreen(
                  recommendedEvents: recommendedEvents,
                  conversations: conversations,
                ),
              ),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DMOverviewScreen(
                  conversations: conversations,
                  recommendedEvents: recommendedEvents,
                ),
              ),
            );
            // Navigate to DMOverviewScreen (not implemented)
            break;
          case 3:
            // Navigate to Profile screen (not implemented)
            break;
        }
      }, // handle navigation
    );
  }
}
