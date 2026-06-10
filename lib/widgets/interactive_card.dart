import 'package:drp/models/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:google_fonts/google_fonts.dart';
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
      width: 180,
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
              mainAxisSize: MainAxisSize.max,
              children: [
                // ── Top Row: Icon + Matches Badge ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (card.imageUrl.isNotEmpty)
                      ProfilePicture(
                        name: card.title,
                        radius: 12,
                        fontsize: 32,
                        random: false,
                        img: card.imageUrl.isNotEmpty ? card.imageUrl : null,
                      )
                    else
                      Icon(card.icon, color: const Color(0xFF222222), size: 28),
                    const Spacer(),
                    if (eventCard != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: eventCard.numMatches == 0
                              ? // make it more obvious when there are no matches
                                const Color(0xFF220000).withValues(alpha: 0.2)
                              : const Color(0xFF84DCC6).withValues(alpha: 0.7),

                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${eventCard.numMatches} confirmed ${eventCard.numMatches == 1 ? 'match' : 'matches'}',
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
                  style: GoogleFonts.bitter(
                    color: Color(0xFF222222),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Year group for match card
                if (matchCard != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        size: 10,
                        color: const Color(0xFF222222).withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 2),

                      if (matchCard.yearGroup.isNotEmpty)
                        Expanded(
                          child: Text(
                            '${matchCard.yearGroup} · ${matchCard.university}',
                            style: GoogleFonts.merriweather(
                              fontSize: 12,
                              color: const Color(
                                0xFF222222,
                              ).withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        Expanded(
                          child: Text(
                            matchCard.university,
                            style: GoogleFonts.merriweather(
                              fontSize: 12,
                              color: const Color(
                                0xFF222222,
                              ).withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],

                // Location for match card
                if (matchCard != null && matchCard.location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: const Color(0xFF222222).withValues(alpha: 0.8),
                      ),
                      SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          matchCard.location,
                          style: GoogleFonts.merriweather(
                            color: const Color(
                              0xFF222222,
                            ).withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Subtitle ──
                if (matchCard != null && matchCard.interests.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Interests:',
                    style: GoogleFonts.merriweather(
                      color: Color(0xFF222222),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: matchCard.interests
                        .take(3)
                        .map(
                          (interest) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Text(
                                  '★ ',
                                  style: GoogleFonts.merriweather(
                                    color: Color(0xFF222222),
                                    fontSize: 13,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    interest,
                                    style: GoogleFonts.merriweather(
                                      color: Color(0xFF222222),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],

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
                    style: GoogleFonts.merriweather(
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
                          style: GoogleFonts.merriweather(
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
