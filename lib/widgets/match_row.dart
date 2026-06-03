import 'package:flutter/material.dart';
import '../models/match_card.dart';
import 'interactive_card.dart';
import 'package:google_fonts/google_fonts.dart';

class MatchRow extends StatelessWidget {
  final List<MatchCard> cards;
  final String eventLabel;
  final void Function(int index) onTap;

  const MatchRow({
    super.key,
    required this.cards,
    required this.eventLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 10),
          child: Text(
            eventLabel,
            style: GoogleFonts.bitter(fontSize: 18, color: const Color(0xFF222222), fontWeight: FontWeight.bold)
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: cards.length,
            itemBuilder: (_, i) =>
                InteractiveCard(card: cards[i], onTap: () => onTap(i)),
          ),
        ),
      ],
    );
  }
}
