import 'package:drp/models/event_card.dart';
import 'package:flutter/material.dart';
import '../models/base_card.dart';
import '../models/match_card.dart';
import 'package:intl/intl.dart';

class InteractiveCard extends StatelessWidget {
  final BaseCard card;
  final VoidCallback? onTap;

  const InteractiveCard({super.key, required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final matchCard = card is MatchCard ? card as MatchCard : null;
    final eventCard = card is EventCard ? card as EventCard : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 140,
      height: 180,
      child: Material(
        color: card.color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () => {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top Row: Icon + Matches Badge ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(card.icon, color: const Color(0xFF222222), size: 28),
                    const Spacer(),
                    if (eventCard != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF222222,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${eventCard.numMatches} ${eventCard.numMatches == 1 ? 'match' : 'matches'}',
                          style: const TextStyle(
                            color: Color(0xFF222222),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),
                // ── Title ──
                Text(
                  card.title,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // ── Subtitle ──
                Text(
                  matchCard != null && matchCard.interests.isNotEmpty
                      ? matchCard.interests.take(3).join(', ')
                      : eventCard?.subtitle ?? '',
                  style: TextStyle(
                    color: const Color(0xFF222222).withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // ── Date & Time & Location (EventCard only) ──
                if (eventCard != null) ...[
                  const Spacer(),
                  const Divider(
                    color: Color(0xFF222222),
                    thickness: 0.3,
                    height: 8,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('d MMM').format(eventCard.startDateTime)}  ·  ${DateFormat('HH:mm').format(eventCard.startDateTime)}-${DateFormat('HH:mm').format(eventCard.endDateTime)}',
                    style: TextStyle(
                      color: const Color(0xFF222222).withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 11,
                        color: const Color(0xFF222222).withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          eventCard.location,
                          style: TextStyle(
                            color: const Color(
                              0xFF222222,
                            ).withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
