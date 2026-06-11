import 'package:drp/screens/dm_home_screen.dart';
import 'package:drp/screens/society_screen.dart';
import 'package:flutter/material.dart';

class SocietyNavBar extends StatefulWidget {
  final int initialIndex;
  const SocietyNavBar({super.key, this.initialIndex = 0});

  @override
  State<SocietyNavBar> createState() => _SocietyNavBarState();
}

class _SocietyNavBarState extends State<SocietyNavBar> {
  late int _currentIndex;

  // Keep pages alive by using IndexedStack
  final List<Widget> _pages = const [SocietyScreen(), DMOverviewScreen()];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
