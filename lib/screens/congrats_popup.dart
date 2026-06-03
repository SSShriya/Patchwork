import 'package:drp/models/match_card.dart';
import 'package:drp/models/match_convo.dart';
import 'package:drp/screens/dm_individual_screen.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class CongratsPopup extends StatelessWidget {
  final MatchCard match;
  final String currentUserId = '5f7e9d61-3865-47b2-9155-202267ee947f';

  const CongratsPopup({super.key, required this.match});

  String otherUserId() {
    final ids = match.id.split('|');
    return ids[0] == currentUserId ? ids[1] : ids[0];
  }

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
              match.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DMScreen(
                      chat: ChatConversation(
                        name: match.name, 
                        otherUserId: otherUserId(), 
                        interests: match.interests,
                        imageUrl: match.imageUrl,
                        ),
                    ),
                  ),
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
              child: const Text('DM Now'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0XFF8789C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Next Match'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
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
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
