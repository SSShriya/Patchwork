import 'package:drp/screens/events_screen.dart';
import 'package:drp/screens/main_shell.dart';
import 'package:flutter/material.dart';

class EventRegisteredPopup extends StatelessWidget {
  final String eventName; 

  const EventRegisteredPopup({super.key, required this.eventName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Text(
              'Thanks for signing up for',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0XFF8789C0),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              eventName.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Your matches for this event will be displayed on the homescreen as soon as possible!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const EventsScreen()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0XFF8789C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Browse More Events'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainShell()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0XFF8789C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Return Home'),
            ),
          ],
        ),
      ),
    );
  }
}