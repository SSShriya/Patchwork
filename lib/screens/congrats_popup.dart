import 'package:flutter/material.dart';
import 'home_screen.dart';

class CongratsPopup extends StatelessWidget {
  final String matchName;

  const CongratsPopup({super.key, required this.matchName});

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
              'CONGRATS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0XFF8789C0),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You've matched with",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              matchName.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: const Color(0XFF8789C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('DM Now'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () { Navigator.pop(context); },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0XFF8789C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Next Match'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () { Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen())); },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0XFF8789C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}