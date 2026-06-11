import 'package:drp/services/society_events_service.dart';
import 'package:drp/screens/dm_home_screen.dart';
import 'package:drp/screens/society_events_screen.dart';
import 'package:drp/screens/society_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SocietyNavBar extends StatefulWidget {
  final int initialIndex;
  const SocietyNavBar({super.key, this.initialIndex = 0});

  @override
  State<SocietyNavBar> createState() => _SocietyNavBarState();
}

class _SocietyNavBarState extends State<SocietyNavBar> {
  late int _currentIndex;
  late final SocietySharedState _sharedState;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _sharedState = SocietySharedState();
    _sharedState.initialize();
  }

  @override
  void dispose() {
    _sharedState.dispose();
    super.dispose();
  }

  void goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _sharedState,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            SocietyEventsScreen(),
            DMOverviewScreen(),
            SocietyProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFFEBA6A9),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'Events',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
