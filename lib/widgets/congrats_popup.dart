import 'package:drp/models/match_card.dart';
import 'package:drp/models/match_convo.dart';
import 'package:drp/screens/dm_individual_screen.dart';
import 'package:flutter/material.dart';

class CongratsPopup extends StatelessWidget {
  final MatchCard match;
  final bool isMutual;
  final VoidCallback onGoHome;

  const CongratsPopup({
    super.key, 
    required this.match, 
    required this.isMutual,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CONGRATS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0XFF8789C0),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You've accepted",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              match.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ── DM or waiting message ──
            if (isMutual)
              _button(
                label: 'DM Now',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) {
                      // ── Extract plain user ID from composite match ID ──
                      final parts = match.id.split('|');
                      final currentUserId =
                          '5f7e9d61-3865-47b2-9155-202267ee947f';
                      final otherUserId = parts[0] == currentUserId
                          ? parts[1]
                          : parts[0];

                      // ── Build a clean MatchCard with just the plain user ID ──
                      final dmCard = MatchCard(
                        id: otherUserId,
                        title: match.title,
                        university: match.university,
                        course: match.course,
                        bio: match.bio,
                        eventId: match.eventId,
                        eventName: match.eventName,
                        yearGroup: match.yearGroup,
                        interests: match.interests,
                        location: match.location,
                        imageUrl: match.imageUrl,
                      );

                      return DMScreen(
                        chat: ChatConversation(matchCard: dmCard),
                      );
                    },
                  ),
                ),
              )
            else
              Column(
                children: [
                  const Icon(
                    Icons.hourglass_top,
                    color: Color(0XFF8789C0),
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Waiting for ${match.title} to accept...\nYou'll be able to DM once they do!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),
            _button(
              label: 'Next Match',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            _button(
              label: 'Back to Home',
              onPressed: () {
                Navigator.pop(context);
                onGoHome();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _button({required String label, required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0XFF8789C0),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(label),
    );
  }
}
