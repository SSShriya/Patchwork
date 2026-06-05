import 'package:drp/screens/events_screen.dart';
import 'package:drp/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/dm_home_screen.dart';

class AppNavigationBar extends StatelessWidget {
  final int currentIndex;

  const AppNavigationBar({super.key, this.currentIndex = 0});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFFEBA6A9),
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),

      unselectedLabelStyle: GoogleFonts.montserrat(
        fontSize: 12,
      ),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Events'),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble),
          label: 'Messages',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        if (index == currentIndex) return; // alr here, do nothing
        switch (index) {
          case 0:
            // pop until back to route
            Navigator.popUntil(context, (route) => route.isFirst);
            break;
          case 1:
            // search screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EventsScreen()),
            );
            break;
          case 2:
            // dm screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DMOverviewScreen()),
            );
            break;
          case 3:
            // profile screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            );
            break;
        }
      },
    );
  }
}
